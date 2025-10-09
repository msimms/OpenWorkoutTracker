//
//  HealthManager.swift
//  Created by Michael Simms on 10/7/22.
//

import Foundation
import HealthKit
import CoreLocation

struct ExportCallbackType {
	var pointIndex = 0
}

func exportNextCoordinate(activityId: Optional<UnsafePointer<Int8>>, coordinate: Optional<UnsafeMutablePointer<Coordinate>>, context: Optional<UnsafeMutableRawPointer>) -> Bool {
	let healthKit = HealthManager.shared

	let tempActivityId = String(cString: UnsafeRawPointer(activityId!).assumingMemoryBound(to: CChar.self))
	let typedPointer = context!.bindMemory(to: ExportCallbackType.self, capacity: 1)

	let result = healthKit.getHistoricalActivityLocationPoint(activityId: tempActivityId, coordinate: &coordinate!.pointee, pointIndex: typedPointer.pointee.pointIndex)
	typedPointer.pointee.pointIndex += 1
	return result
}

class HealthManager {
	static let shared = HealthManager()

	private var authorized = false

	private let healthStore = HKHealthStore();
	private var workoutBuilder: HKWorkoutBuilder?
	private var routeBuilder: HKWorkoutRouteBuilder?

	public var workouts: Dictionary<String, HKWorkout> = [:] // Summaries of workouts stored in the health store, key is the activity ID which is generated automatically
	public var currentHeartRate: Double = 0.0 // Most recent heart rate reading (Apple Watch)
	public var heartRateRead: Bool = false // True if we are receiving heart rate data (Apple Watch)

	private var hrTopSampleBuf: [Double] = []
	private var hrSum: Double = 0.0
	private var totalHrSamples: UInt64 = 0
	private var powerSampleBuf: [HKQuantitySample] = [] // Used when estimating the user's FTP from cycling power samples in HealthKit

	public var estimatedMaxHr: Double? // Algorithmically estimated maximum heart rate
	public var estimatedFtp: Double? // Algorithmically estimated cycling threshold power, in watts

	private var locations: Dictionary<String, Array<CLLocation>> = [:] // Arrays of locations stored in the health store, key is the activity ID
	private var distances: Dictionary<String, Array<Double>> = [:] // Arrays of distances computed from the locations array, key is the activity ID
	private var speeds: Dictionary<String, Array<Double>> = [:] // Arrays of speeds computed from the distances array, key is the activity ID
	private var queryGroup: DispatchGroup = DispatchGroup() // Tracks queries until they are completed
	private var locationQueryGroup: DispatchGroup = DispatchGroup() // Tracks location/route queries until they are completed
	private var hrQuery: HKQuery? = nil // The query that reads heart rate on the watch
#if os(watchOS)
	private var workoutSession: HKWorkoutSession? = nil
#endif

	/// Singleton constructor
	private init() {
		NotificationCenter.default.addObserver(self, selector: #selector(self.activityStopped), name: Notification.Name(rawValue: NOTIFICATION_NAME_ACTIVITY_STOPPED), object: nil)
	}

	/// @brief Called when the application is started to verify that we have authorization for the things we need.
	func requestAuthorization() {
		
		// Check for HealthKit availability.
		guard HKHealthStore.isHealthDataAvailable() else {
			return
		}
		
		// Request authorization for things to read and write.
#if os(watchOS)
		let heightType = HKObjectType.quantityType(forIdentifier: .height)!
		let weightType = HKObjectType.quantityType(forIdentifier: .bodyMass)!
		let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate)!
		let activeEnergyBurnType = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!
		let birthdayType = HKObjectType.characteristicType(forIdentifier: .dateOfBirth)!
		let biologicalSexType = HKObjectType.characteristicType(forIdentifier: .biologicalSex)!
		var writeTypes = Set([heartRateType, activeEnergyBurnType])
		var readTypes = Set([heartRateType, heightType, weightType, birthdayType, biologicalSexType])
#else
		let heightType = HKObjectType.quantityType(forIdentifier: .height)!
		let weightType = HKObjectType.quantityType(forIdentifier: .bodyMass)!
		let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate)!
		let restingHeartRateType = HKObjectType.quantityType(forIdentifier: .restingHeartRate)!
		let vo2MaxType = HKObjectType.quantityType(forIdentifier: .vo2Max)!
		let cyclingType = HKObjectType.quantityType(forIdentifier: .distanceCycling)!
		let runType = HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning)!
		let swimType = HKObjectType.quantityType(forIdentifier: .distanceSwimming)!
		let activeEnergyBurnType = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!
		let birthdayType = HKObjectType.characteristicType(forIdentifier: .dateOfBirth)!
		let biologicalSexType = HKObjectType.characteristicType(forIdentifier: .biologicalSex)!
		let routeType = HKObjectType.seriesType(forIdentifier: HKWorkoutRouteTypeIdentifier)!
		let workoutType = HKObjectType.workoutType()
		var writeTypes = Set([heightType, weightType, heartRateType, restingHeartRateType, vo2MaxType, cyclingType, runType, swimType, activeEnergyBurnType, workoutType, routeType])
		var readTypes = Set([heightType, weightType, heartRateType, restingHeartRateType, vo2MaxType, birthdayType, biologicalSexType, workoutType, routeType])
#endif

		// Have to do this down here since there's a version check.
		if #available(iOS 17.0, macOS 14.0, watchOS 10.0, *) {
			let powerType = HKObjectType.quantityType(forIdentifier: .cyclingPower)!
			let ftpType = HKObjectType.quantityType(forIdentifier: .cyclingFunctionalThresholdPower)!

			writeTypes.insert(powerType)
			writeTypes.insert(ftpType)
			readTypes.insert(powerType)
			readTypes.insert(ftpType)
		}

		// Request authorization for all the things we need from HealthKit.
		self.healthStore.requestAuthorization(toShare: writeTypes, read: readTypes) { result, error in

			// Read the user's age.
			do {
				try self.getAge()
			}
			catch {
				NSLog("Failed to read the user's age from HealthKit.")
			}

			// Read the user's height and weight.
			do {
				try self.getHeight()
				try self.getWeight()
			}
			catch {
				NSLog("Failed to read the user's height and weight from HealthKit.")
			}
			
			// Read the user's resting heart rate and then estimate their maximum heart rate.
			do {
				try self.getRestingHr()
#if !os(watchOS)
				try self.estimateMaxHr()
#endif
			}
			catch {
				NSLog("Failed to read heart rate information from HealthKit.")
			}

			// Read the user's VO2Max.
			do {
				try self.getVO2Max()
			}
			catch {
				NSLog("Failed to read the VO2Max from HealthKit.")
			}

			do {
#if !os(watchOS)
				try self.getBestRecent5KEffort()
#endif
			}
			catch {
				NSLog("Failed to read the workout history from HealthKit.")
			}

			do {
				try self.getFtp()
#if !os(watchOS)
				try self.estimateFtp()
#endif
			}
			catch {
				NSLog("Failed to read the cycling FTP from HealthKit.")
			}
		}
	}

	/// @brief Returns the most recent entry in the health store for the specified quantity type (example: getting the most recent resting heart rate value).
	func mostRecentQuantitySampleOfType(quantityType: HKQuantityType, callback: @escaping (HKQuantitySample?, Error?) -> ()) {
		
		// Since we are interested in retrieving the user's latest sample, we sort the samples in descending
		// order, and set the limit to 1. We are not filtering the data, and so the predicate is set to nil.
		let timeSortDescriptor = NSSortDescriptor.init(key: HKSampleSortIdentifierEndDate, ascending: false)
		let query = HKSampleQuery.init(sampleType: quantityType, predicate: nil, limit: 1, sortDescriptors: [timeSortDescriptor], resultsHandler: { query, results, error in
			
			// Error case: Call the callback handler, passing nil for the results.
			if results == nil || results!.count == 0 {
				callback(nil, error)
			}
			
			// Normal case: Call the callback handler with the results.
			else {
				let sample = results!.first as! HKQuantitySample?
				callback(sample, error)
			}
		})
		
		// Execute asynchronously.
		self.healthStore.execute(query)
	}

	/// @brief Returns the last year's health store entries for the specified quantity type (example: getting the most recent N heart rate samples).
	func recentQuantitySamplesOfType(quantityType: HKQuantityType, callback: @escaping (HKQuantitySample?, Error?) -> ()) {
		
		let oneYear = (365.25 * 24.0 * 60.0 * 60.0)
		let startTime = Date(timeIntervalSince1970: Date().timeIntervalSince1970 - oneYear)
		let endTime = Date()
		let predicate = HKQuery.predicateForSamples(withStart: startTime, end: endTime, options: [.strictStartDate])
		
		let query = HKSampleQuery.init(sampleType: quantityType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil, resultsHandler: { query, results, error in
			
			// Error case: Call the callback handler, passing nil for the results.
			if results == nil || results!.count == 0 {
				callback(nil, error ?? nil)
			}
			
			// Normal case: Call the callback handler with the results.
			else {
				for sample in results! {
					let quantitySample = sample as! HKQuantitySample?
					callback(quantitySample, error)
				}
			}
		})
		
		// Execute asynchronously.
		self.healthStore.execute(query)
	}

	func quantitySamplesOfType(quantityType: HKQuantityType, callback: @escaping (HKQuantitySample?, Error?) -> ()) {
		
		// We are not filtering the data, so the predicate is set to nil.
		let query = HKSampleQuery.init(sampleType: quantityType, predicate: nil, limit: HKObjectQueryNoLimit, sortDescriptors: nil, resultsHandler: { query, results, error in
			
			// Error case: Call the callback handler, passing nil for the results.
			if results == nil || results!.count == 0 {
				callback(nil, error ?? nil)
			}
			
			// Normal case: Call the callback handler with the results.
			else {
				for sample in results! {
					let quantitySample = sample as! HKQuantitySample?
					callback(quantitySample, error)
				}
			}
		})
		
		// Execute asynchronously.
		self.healthStore.execute(query)
	}

	func subscribeToQuantitySamplesOfType(quantityType: HKQuantityType, callback: @escaping (HKQuantity?, Date?, Error?) -> ()) -> HKQuery {

		let datePredicate = HKQuery.predicateForSamples(withStart: Date(), end: nil, options:HKQueryOptions.strictStartDate)
		let query = HKAnchoredObjectQuery.init(type: quantityType, predicate: datePredicate, anchor: nil, limit: HKObjectQueryNoLimit, resultsHandler: { query, addedObjects, deletedObjects, newAnchor, error in
			
			if addedObjects != nil {
				for sample in addedObjects! {
					if let quantitySample = sample as? HKQuantitySample {
						callback(quantitySample.quantity, quantitySample.endDate, error)
					}
				}
			}
		})
		
		query.updateHandler = { query, addedObjects, deletedObjects, newAnchor, error in
			for sample in addedObjects! {
				if let quantitySample = sample as? HKQuantitySample {
					callback(quantitySample.quantity, quantitySample.endDate, error)
				}
			}
		}
		
		// Execute asynchronously.
		self.healthStore.execute(query)

		// Background delivery.
		self.healthStore.enableBackgroundDelivery(for: quantityType, frequency: .immediate, withCompletion: {(succeeded: Bool, error: Error!) in
		})

		return query
	}

	/// @brief Gets the user's age from HealthKit and updates the copy in our database.
	func getAge() throws {
		let dateOfBirth = try self.healthStore.dateOfBirthComponents()
		let gregorianCalendar = NSCalendar.init(calendarIdentifier: NSCalendar.Identifier.gregorian)!
		let tempDate = gregorianCalendar.date(from: dateOfBirth)
		
		Preferences.setBirthDate(value: time_t(tempDate!.timeIntervalSince1970))
	}
	
	/// @brief Gets the user's height from HealthKit and updates the copy in our database.
	func getHeight() throws {
		let heightType = HKObjectType.quantityType(forIdentifier: .height)!
		
		self.mostRecentQuantitySampleOfType(quantityType: heightType) { sample, error in
			if let heightSample = sample {
				let heightUnit = HKUnit.meterUnit(with: HKMetricPrefix.centi)
				let usersHeight = heightSample.quantity.doubleValue(for: heightUnit)

				Preferences.setHeightCm(value: usersHeight)
			}
		}
	}

	/// @brief Gets the user's weight from HealthKit and updates the copy in our database.
	func getWeight() throws {
		let weightType = HKObjectType.quantityType(forIdentifier: .bodyMass)!
		
		self.mostRecentQuantitySampleOfType(quantityType: weightType) { sample, error in
			if let weightSample = sample {
				let weightUnit = HKUnit.gramUnit(with: HKMetricPrefix.kilo)
				let usersWeight = weightSample.quantity.doubleValue(for: weightUnit)

				Preferences.setWeightKg(value: usersWeight)
			}
		}
	}
	
	/// @brief Gets the user's resting heart rate from HealthKit and updates the copy in our database.
	func getRestingHr() throws {
		let hrType = HKObjectType.quantityType(forIdentifier: .restingHeartRate)!
		
		self.mostRecentQuantitySampleOfType(quantityType: hrType) { sample, error in
			if let restingHrSample = sample {
				let hrUnit: HKUnit = HKUnit.count().unitDivided(by: HKUnit.minute())
				let restingHr = restingHrSample.quantity.doubleValue(for: hrUnit)

				Preferences.setEstimatedRestingHr(value: restingHr)
			}
		}
	}
	
	func setRestingHr(hr: Double) {
		let now = Date()
		let hrUnit: HKUnit = HKUnit.count().unitDivided(by: HKUnit.minute())
		let hrQuantity = HKQuantity.init(unit: hrUnit, doubleValue: hr)
		let hrType = HKQuantityType.init(HKQuantityTypeIdentifier.restingHeartRate)
		let hrSample = HKQuantitySample.init(type: hrType, quantity: hrQuantity, start: now, end: now)

		self.healthStore.save(hrSample, withCompletion: { result, error in
		})
	}
	
	/// @brief Estimates the user's maximum heart rate from the last year of HealthKit data.
	func estimateMaxHr() throws {
		let hrType = HKObjectType.quantityType(forIdentifier: .heartRate)!

		self.recentQuantitySamplesOfType(quantityType: hrType) { sample, error in
			if let hrSample = sample {
				let hrUnit: HKUnit = HKUnit.count().unitDivided(by: HKUnit.minute())
				let hrValue = hrSample.quantity.doubleValue(for: hrUnit)

				self.hrSum += hrValue
				self.totalHrSamples += 1

				// Filtering out bad data, part 1: Apply the sigmoid squishification
				// function to each reading, based on their offset from the mean.
				let mean = self.hrSum / Double(self.totalHrSamples)
				let offset = hrValue - mean
				let sig = 1.0 / (1.0 + exp(-offset))
				let squishedValue = hrValue * sig
				
				// Filtering out bad data, part 2: Take the average of the
				// highest HR readings.
				let MAX_BUF_SIZE = 64
				if self.hrTopSampleBuf.count == 0 || squishedValue > self.hrTopSampleBuf[0] {
					self.hrTopSampleBuf.append(hrValue)
					self.hrTopSampleBuf.sort()
					if self.hrTopSampleBuf.count > MAX_BUF_SIZE {
						self.hrTopSampleBuf.remove(at: 0)
					}
					
					let bufSum = self.hrTopSampleBuf.reduce(0, +)
					let bufAvg = bufSum / Double(self.hrTopSampleBuf.count)

					if self.estimatedMaxHr == nil || bufAvg > self.estimatedMaxHr! {
						self.estimatedMaxHr = hrValue
						Preferences.setEstimatedMaxHr(value: self.estimatedMaxHr!)
					}
				}
			}
		}
	}

	/// @brief Gets the user's VO2Max from HealthKit  and updates the copy in our database.
	func getVO2Max() throws {
		let vo2MaxType = HKObjectType.quantityType(forIdentifier: .vo2Max)!
		
		self.mostRecentQuantitySampleOfType(quantityType: vo2MaxType) { sample, error in
			if let vo2MaxSample = sample {
				let kgmin = HKUnit.gramUnit(with: .kilo).unitMultiplied(by: .minute())
				let vo2MaxUnit = HKUnit.literUnit(with: .milli).unitDivided(by: kgmin)
				let vo2Max = vo2MaxSample.quantity.doubleValue(for: vo2MaxUnit)
				
				Preferences.setEstimatedVO2Max(value: vo2Max)
			}
		}
	}

	func setVO2Max(vo2Max: Double) {
		let now = Date()
		let kgmin = HKUnit.gramUnit(with: .kilo).unitMultiplied(by: .minute())
		let vo2MaxUnit = HKUnit.literUnit(with: .milli).unitDivided(by: kgmin)
		let vo2MaxQuantity = HKQuantity.init(unit: vo2MaxUnit, doubleValue: vo2Max)
		let vo2MaxType = HKObjectType.quantityType(forIdentifier: .vo2Max)!
		let vo2MaxSample = HKQuantitySample.init(type: vo2MaxType, quantity: vo2MaxQuantity, start: now, end: now)
		
		self.healthStore.save(vo2MaxSample, withCompletion: {_,_ in })
	}

	/// @brief Estimates the user's cycling FTP based on cycling power data in HealthKit. Uses 95% of the best recent 20 minute effort.
	func estimateFtp() throws {
		if #available(iOS 17.0, macOS 14.0, watchOS 10.0, *) {
			let powerType = HKObjectType.quantityType(forIdentifier: .cyclingPower)!
			self.powerSampleBuf.removeAll()

			self.recentQuantitySamplesOfType(quantityType: powerType) { sample, error in
				if let powerSample = sample {
					let powerUnit: HKUnit = HKUnit.watt()
					
					// Add to the sample buffer.
					self.powerSampleBuf.append(powerSample)
					if self.powerSampleBuf.count > 1 {
						
						// Remove anything that falls outside of our 20 minute window.
						var startTime = self.powerSampleBuf[0].startDate
						let endTime = powerSample.endDate
						while endTime.timeIntervalSince1970 - startTime.timeIntervalSince1970 > (20 * 60) && self.powerSampleBuf.count > 1{
							self.powerSampleBuf.removeFirst()
							startTime = self.powerSampleBuf[0].startDate
						}
						
						// Make sure we didn't empty the buffer when purging old data.
						// Also make sure we have something close to 20 mimutes of data.
						if endTime.timeIntervalSince1970 - startTime.timeIntervalSince1970 > (19.5 * 60) && self.powerSampleBuf.count > 1 {
							
							// Compute the average.
							var sum: Double = 0.0
							for bufSample in self.powerSampleBuf {
								sum += bufSample.quantity.doubleValue(for: powerUnit)
							}
							let avg = sum / Double(self.powerSampleBuf.count)
							let estimate = avg * 0.95
							
							if self.estimatedFtp == nil || estimate > self.estimatedFtp! {
								self.estimatedFtp = estimate
								Preferences.setEstimatedFtp(value: estimate)
							}
						}
					}
				}
			}
		}
	}

	/// @brief Gets the user's cycling FTP from HealthKit  and updates the copy in our database.
	func getFtp() throws {
		if #available(iOS 17.0, macOS 14.0, watchOS 10.0, *) {
			let powerType = HKObjectType.quantityType(forIdentifier: .cyclingFunctionalThresholdPower)!
			
			self.mostRecentQuantitySampleOfType(quantityType: powerType) { sample, error in
				if let powerSample = sample {
					let powerUnit: HKUnit = HKUnit.watt()
					let ftp = powerSample.quantity.doubleValue(for: powerUnit)

					Preferences.setUserDefinedFtp(value: ftp)
				}
			}
		}
	}

	func setFtp(ftp: Double) {
		if #available(iOS 17.0, macOS 14.0, watchOS 10.0, *) {
			let now = Date()
			let powerQuantity = HKQuantity.init(unit: HKUnit.watt(), doubleValue: ftp)
			let powerType = HKQuantityType.init(HKQuantityTypeIdentifier.cyclingFunctionalThresholdPower)
			let powerSample = HKQuantitySample.init(type: powerType, quantity: powerQuantity, start: now, end: now)

			self.healthStore.save(powerSample, withCompletion: {_,_ in })
		}
	}

	/// @brief Gets the user's best 5K effort from the last six months of HealthKit data.
	func getBestRecent5KEffort() throws {
		let startTime = Date(timeIntervalSince1970: Date().timeIntervalSince1970 - 86400.0 * 7.0 * 26.0)
		let predicate = HKQuery.predicateForWorkouts(with: HKWorkoutActivityType.running)
		let sortDescriptor = NSSortDescriptor.init(key: HKSampleSortIdentifierStartDate, ascending: false)
		let quantityType = HKWorkoutType.workoutType()
		let sampleQuery = HKSampleQuery.init(sampleType: quantityType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: [sortDescriptor], resultsHandler: { query, samples, error in
			var bestDuration: TimeInterval?

			if samples != nil {
				for sample in samples! {
					if let workout = sample as? HKWorkout {
						if workout.startDate.timeIntervalSince1970 >= startTime.timeIntervalSince1970 {
							let distance = workout.totalDistance
							
							if distance != nil {
								if (distance?.doubleValue(for: HKUnit.meter()))! >= 5000.0 {
									if bestDuration == nil || workout.duration < bestDuration! {
										bestDuration = workout.duration
									}
								}
							}
						}
					}
				}
			}

			if bestDuration != nil {
				Preferences.setBestRecent5KSecs(value: UInt32(bestDuration!))
			}

			self.queryGroup.leave()
		})
		
		self.queryGroup.enter()
		self.healthStore.execute(sampleQuery)
	}

	func clearWorkoutsList() {
		self.workouts.removeAll()
		self.locations.removeAll()
		self.distances.removeAll()
		self.speeds.removeAll()
	}
	
	func readWorkoutsFromHealthStoreOfType(activityType: HKWorkoutActivityType) {
		let predicate = HKQuery.predicateForWorkouts(with: activityType)
		let sortDescriptor = NSSortDescriptor.init(key: HKSampleSortIdentifierStartDate, ascending: false)
		let quantityType = HKWorkoutType.workoutType()
		let sampleQuery = HKSampleQuery.init(sampleType: quantityType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: [sortDescriptor], resultsHandler: { query, samples, error in

			if samples != nil {
				for sample in samples! {
					if let workout = sample as? HKWorkout {
						self.workouts[UUID().uuidString] = workout
					}
				}
			}
			self.queryGroup.leave()
		})

		self.queryGroup.enter()
		self.healthStore.execute(sampleQuery)
	}
	
	func readRunningWorkoutsFromHealthStore() {
		self.readWorkoutsFromHealthStoreOfType(activityType: HKWorkoutActivityType.running)
	}

	func readWalkingWorkoutsFromHealthStore() {
		self.readWorkoutsFromHealthStoreOfType(activityType: HKWorkoutActivityType.walking)
	}

	func readCyclingWorkoutsFromHealthStore() {
		self.readWorkoutsFromHealthStoreOfType(activityType: HKWorkoutActivityType.cycling)
	}
	
	func readSwimWorkoutsFromHealthStore() {
		self.readWorkoutsFromHealthStoreOfType(activityType: HKWorkoutActivityType.swimming)
	}

	func readAllActivitiesFromHealthStore() {
		self.clearWorkoutsList()
		self.readRunningWorkoutsFromHealthStore()
		self.readWalkingWorkoutsFromHealthStore()
		self.readCyclingWorkoutsFromHealthStore()
		self.readSwimWorkoutsFromHealthStore()
		self.waitForHealthKitQueries()
	}

	func calculateSpeedsFromDistances(distances: Array<Double>, activityId: String) {
		var speeds: Array<Double> = [0]
		
		for (index, distance2) in distances.enumerated() {
			if index > 0 {
				let distance1 = distances[index - 1]
				let speed = distance2 - distance1;

				speeds.append(speed)
			}
		}
		
		self.speeds[activityId] = speeds
	}

	func calculateDistancesFromLocations(locations: Array<CLLocation>, activityId: String) {
		var distances: Array<Double> = [0]

		for (index, loc2) in locations.enumerated() {
			if index > 0 {
				let loc1 = locations[index - 1]

				let c1 = Coordinate(latitude: loc1.coordinate.latitude, longitude: loc1.coordinate.longitude, altitude: 0.0, horizontalAccuracy: 0.0, verticalAccuracy: 0.0, time: 0)
				let c2 = Coordinate(latitude: loc2.coordinate.latitude, longitude: loc2.coordinate.longitude, altitude: 0.0, horizontalAccuracy: 0.0, verticalAccuracy: 0.0, time: 0 )

				let distance = DistanceBetweenCoordinates(c1, c2)
				distances.append(distance)
			}
		}

		self.distances[activityId] = distances
		
		// Now update the speed calculations.
		self.calculateSpeedsFromDistances(distances: distances, activityId: activityId)
	}

	private func readLocationPointsFromHealthStoreForWorkoutRoute(route: HKWorkoutRoute, activityId: String) {
		let query = HKWorkoutRouteQuery.init(route: route) { _, routeData, done, error in

			if routeData != nil {
				if var activityLocations = self.locations[activityId] {
					activityLocations.append(contentsOf: routeData!)
					self.locations[activityId] = activityLocations
				}
				else {
					self.locations[activityId] = Array(routeData!)
				}
			}
			
			if done {
				if let activityLocations = self.locations[activityId] {
					self.calculateDistancesFromLocations(locations: activityLocations, activityId:activityId)
				}
				self.queryGroup.leave()
			}
		}

		self.queryGroup.enter()
		self.healthStore.execute(query)
	}

	func readLocationPointsFromHealthStoreForWorkout(workout: HKWorkout, activityId: String) {
		let predicate = HKQuery.predicateForObjects(from: workout)
		let sampleType = HKSeriesType.workoutRoute()
		let query = HKAnchoredObjectQuery.init(type: sampleType, predicate: predicate, anchor: nil, limit: HKObjectQueryNoLimit, resultsHandler: { _, samples, _, _, error in

			if samples != nil {
				for sample in samples! {
					if let route = sample as? HKWorkoutRoute {
						self.readLocationPointsFromHealthStoreForWorkoutRoute(route: route, activityId: activityId)
					}
				}
			}

			self.queryGroup.leave()
		})

		self.queryGroup.enter()
		self.healthStore.execute(query)
		self.waitForHealthKitQueries()
	}

	func readLocationPointsFromHealthStoreForActivityId(activityId: String) {
		guard let workout = self.workouts[activityId] else {
			return
		}
		self.readLocationPointsFromHealthStoreForWorkout(workout: workout, activityId: activityId)
	}

	func getHistoricalActivityLocationPoint(activityId: String, coordinate: inout Coordinate, pointIndex: Int) -> Bool {
		if let locations = self.locations[activityId] {
			if pointIndex < locations.count {
				coordinate.latitude = locations[pointIndex].coordinate.latitude
				coordinate.longitude = locations[pointIndex].coordinate.longitude
				coordinate.altitude = locations[pointIndex].altitude
				coordinate.time = UInt64(locations[pointIndex].timestamp.timeIntervalSince1970) * 1000 // Convert to milliseconds
				return true
			}
		}
		return false
	}

	/// @brief Blocks until all HealthKit queries have completed.
	func waitForHealthKitQueries() {
		self.queryGroup.wait()
	}

	func timeRangesOverlapWithStartRange1(startRange1: time_t, endRange1: time_t, startRange2: time_t, endRange2: time_t) -> Bool {
		return ((startRange1 >= startRange2 && startRange1 < endRange2) ||
				(endRange1 >= startRange2 && endRange1 < endRange2) ||
				(startRange2 >= startRange1 && startRange2 < endRange1) ||
				(endRange2 >= startRange1 && endRange2 < endRange1));
	}

	/// @brief Searches the HealthKit activity list for duplicates and removes them, keeping the first in the list.
	func removeDuplicateActivities() {
		var itemsToRemove: Array<String> = []

		for (_, activityId1) in self.workouts.keys.enumerated() {
			guard let workout1 = self.workouts[activityId1] else {
				break
			}

			let workoutStartTime1 = workout1.startDate.timeIntervalSince1970
			let workoutEndTime1 = workout1.endDate.timeIntervalSince1970

			var found = false
			for (_, activityId2) in self.workouts.keys.enumerated() {
				guard let workout2 = self.workouts[activityId2] else {
					break
				}

				// Remove any duplicates appearing after we've found our original id.
				if found {
					let workoutStartTime2 = workout2.startDate.timeIntervalSince1970
					let workoutEndTime2 = workout2.endDate.timeIntervalSince1970

					// Is either the start time or the end time of the first activity within the bounds of the second activity?
					if self.timeRangesOverlapWithStartRange1(startRange1: time_t(workoutStartTime1), endRange1: time_t(workoutEndTime1), startRange2: time_t(workoutStartTime2), endRange2: time_t(workoutEndTime2)) {
						itemsToRemove.append(activityId2)
					}
				}
				
				if activityId1 == activityId2 {
					found = true
				}
			}
		}

		for itemToRemove in itemsToRemove {
			self.workouts.removeValue(forKey: itemToRemove)
		}
	}
	
	/// @brief Used for de-duplicating the HealthKit activity list, so we don't see activities recorded with this app twice.
	func removeActivitiesThatOverlapWithStartTime(startTime: time_t, endTime: time_t) {
		var itemsToRemove: Array<String> = []

		for (_, activityId) in self.workouts.keys.enumerated() {
			guard let workout = self.workouts[activityId] else {
				break
			}

			let workoutStartTime = workout.startDate.timeIntervalSince1970
			let workoutEndTime = workout.endDate.timeIntervalSince1970

			// Is either the start time or the end time of the first activity within the bounds of the second activity?
			if self.timeRangesOverlapWithStartRange1(startRange1: startTime, endRange1: endTime, startRange2: time_t(workoutStartTime), endRange2: time_t(workoutEndTime)) {
				itemsToRemove.append(activityId)
			}
		}

		for itemToRemove in itemsToRemove {
			self.workouts.removeValue(forKey: itemToRemove)
		}
	}

	/// @brief Grabs the latest weight reading from HealthKit and adds it to the database.
	func updateWeightHistoryFromHealthKit() {
		let weightType = HKQuantityType.init(HKQuantityTypeIdentifier.bodyMass)

		self.quantitySamplesOfType(quantityType: weightType, callback: { sample, error in
			guard sample != nil else {
				return
			}
			ProcessWeightReading(sample!.quantity.doubleValue(for: HKUnit.gramUnit(with: HKMetricPrefix.kilo)), time_t(sample!.startDate.timeIntervalSince1970))
		})
	}

	/// @brief Adds the height reading to HealthKit.
	func saveHeightIntoHealthStore(height: Double, unitSystem: UnitSystem) {
		var units = HKUnit.inch()
		if unitSystem == UNIT_SYSTEM_METRIC {
			units = HKUnit.meterUnit(with: HKMetricPrefix.centi)
		}
		let now = Date()
		let heightQuantity = HKQuantity.init(unit: units, doubleValue: height)
		let heightType = HKQuantityType.init(HKQuantityTypeIdentifier.height)
		let heightSample = HKQuantitySample.init(type: heightType, quantity: heightQuantity, start: now, end: now)
		self.healthStore.save(heightSample, withCompletion: {_,_ in })
	}

	/// @brief Adds the weight reading to HealthKit.
	func saveWeightIntoHealthStore(weight: Double, unitSystem: UnitSystem) {
		var units = HKUnit.pound()
		if unitSystem == UNIT_SYSTEM_METRIC {
			units = HKUnit.gramUnit(with: HKMetricPrefix.kilo)
		}
		let now = Date()
		let weightQuantity = HKQuantity.init(unit: units, doubleValue: weight)
		let weightType = HKQuantityType.init(HKQuantityTypeIdentifier.bodyMass)
		let weightSample = HKQuantitySample.init(type: weightType, quantity: weightQuantity, start: now, end: now)
		self.healthStore.save(weightSample, withCompletion: {_,_ in })
	}

	/// @brief Adds the heart rate reading reading to HealthKit.
	func saveHeartRateIntoHealthStore(beats: Double) {
		let now = Date()
		let hrUnit: HKUnit = HKUnit.count().unitDivided(by: HKUnit.minute())
		let hrQuantity = HKQuantity.init(unit: hrUnit, doubleValue: beats)
		let hrType = HKQuantityType.init(HKQuantityTypeIdentifier.heartRate)
		let hrSample = HKQuantitySample.init(type: hrType, quantity: hrQuantity, start: now, end: now)
		self.healthStore.save(hrSample, withCompletion: { result, error in
		})
	}

	/// @brief Adds the cycling power reading to HealthKit.
	func saveCyclingPowerIntoHealthStore(watts: Double) {
		if #available(iOS 17.0, macOS 14.0, watchOS 10.0, *) {
			let now = Date()
			let powerUnit: HKUnit = HKUnit.watt()
			let powerQuantity = HKQuantity.init(unit: powerUnit, doubleValue: watts)
			let powerType = HKQuantityType.init(HKQuantityTypeIdentifier.cyclingPower)
			let powerSample = HKQuantitySample.init(type: powerType, quantity: powerQuantity, start: now, end: now)

			self.healthStore.save(powerSample, withCompletion: { result, error in
			})
		}
	}

	func endWorkout(endTime: Date, endRoute: Bool) {
		guard let builder = self.workoutBuilder else {
			return
		}

		builder.endCollection(withEnd: endTime) { (success, error) in
			if let error = error {
				NSLog("Error ending workout collection: \(error.localizedDescription)")
				return
			}

			builder.finishWorkout(completion: { (workout, error) in
				if let error = error {
					NSLog("Error finishing workout: \(error.localizedDescription)")
					return
				}
				else if let workout = workout {
					if endRoute {
						self.endWorkoutRoute(workout: workout)
					}
				}
			})
		}
	}

	func addDistanceSample(distance: HKQuantity, startTime: Date, endTime: Date, distanceQuantityType: HKQuantityTypeIdentifier) {
		guard let builder = self.workoutBuilder else {
			return
		}

		guard let distanceType = HKQuantityType.quantityType(forIdentifier: distanceQuantityType) else { return }
		let distanceSample = HKQuantitySample(type: distanceType, quantity: distance, start: startTime, end: endTime)
		
		builder.add([distanceSample]) { (success, error) in
			if let error = error {
				NSLog("Error adding distance sample: \(error.localizedDescription)")
			}
		}
	}

	func addCaloriesBurnedSample(calories: Double, startTime: Date, endTime: Date) {
		guard let builder = self.workoutBuilder else {
			return
		}

		let calorieUnit = HKUnit.kilocalorie()
		let calorieQuantity = HKQuantity.init(unit: calorieUnit, doubleValue: calories)
		let calorieType = HKQuantityType.init(HKQuantityTypeIdentifier.activeEnergyBurned)
		let calorieSample = HKQuantitySample.init(type: calorieType, quantity: calorieQuantity, start: startTime, end: endTime)

		builder.add([calorieSample]) { (success, error) in
			if let error = error {
				NSLog("Error adding calorie sample: \(error.localizedDescription)")
			}
		}
	}
	
	func saveWorkoutRoute(locations: Array<CLLocationCoordinate2D>) {
		guard let builder = self.routeBuilder else {
			return
		}
		guard locations.count > 0 else {
			return
		}

		var tempLocations: [CLLocation] = []
		for location in locations {
			tempLocations.append(CLLocation(latitude: location.latitude, longitude: location.longitude))
		}

		builder.insertRouteData(tempLocations) { (success, error) in
			if let error = error {
				NSLog("Error inserting route data: \(error.localizedDescription)")
			}
		}
	}
	
	func endWorkoutRoute(workout: HKWorkout) {
		guard let builder = self.routeBuilder else {
			return
		}

		builder.finishRoute(with: workout, metadata: nil) { (newRoute, error) in
			if let error = error {
				NSLog("Error finishing route: \(error.localizedDescription)")
			}
		}
	}

	func convertIndexToActivityId(index: size_t) -> String {
		let keys = self.workouts.keys
		let dictIndex = keys.index(keys.startIndex, offsetBy: index)
		return keys[dictIndex]
	}
	
	func getHistoricalActivityType(activityId: String) -> String {
		let workout = self.workouts[activityId]

		if workout != nil {
			return HealthManager.healthKitWorkoutToActivityType(workout: workout!)
		}
		return ""
	}

	private func quantityInUserPreferredUnits(qty: HKQuantity) -> Double {
		if Preferences.preferredUnitSystem() == UNIT_SYSTEM_METRIC {
			return qty.doubleValue(for: HKUnit.meterUnit(with: HKMetricPrefix.kilo))
		}
		return qty.doubleValue(for: HKUnit.mile())
	}

	func getWorkoutAttribute(attributeName: String, activityId: String) -> ActivityAttributeType {
		var attr: ActivityAttributeType = InitializeActivityAttribute(TYPE_NOT_SET, MEASURE_NOT_SET, UNIT_SYSTEM_METRIC)
		attr.valid = false

		guard let workout = self.workouts[activityId] else {
			return attr
		}

		if attributeName == ACTIVITY_ATTRIBUTE_DISTANCE_TRAVELED {
			let qty = workout.totalDistance

			if qty != nil {
				attr.value.doubleVal = self.quantityInUserPreferredUnits(qty: qty!)
				attr.valueType = TYPE_DOUBLE
				attr.measureType = MEASURE_DISTANCE
				attr.valid = true
			}
			else {
				attr.valid = false
			}
		}
		else if attributeName == ACTIVITY_ATTRIBUTE_ELAPSED_TIME {
			let qty = workout.duration

			attr.value.timeVal = time_t(Date(timeIntervalSince1970: qty).timeIntervalSince1970)
			attr.valueType = TYPE_TIME
			attr.measureType = MEASURE_TIME
			attr.valid = true
		}
		else if attributeName == ACTIVITY_ATTRIBUTE_MOVING_TIME {
			let qty = workout.duration

			attr.value.timeVal = time_t(Date(timeIntervalSince1970: qty).timeIntervalSince1970)
			attr.valueType = TYPE_TIME
			attr.measureType = MEASURE_TIME
			attr.valid = true
		}
		else if attributeName == ACTIVITY_ATTRIBUTE_MAX_CADENCE {
			attr.value.doubleVal = 0.0
			attr.valueType = TYPE_DOUBLE
			attr.measureType = MEASURE_RPM
			attr.valid = false
		}
		else if attributeName == ACTIVITY_ATTRIBUTE_MAX_HEART_RATE {
			attr.value.doubleVal = 0.0
			attr.valueType = TYPE_DOUBLE
			attr.measureType = MEASURE_BPM
			attr.valid = false
		}
		else if attributeName == ACTIVITY_ATTRIBUTE_STARTING_LATITUDE {
			if let locations = self.locations[activityId] {
				if locations.count > 0 {
					attr.value.doubleVal = locations[0].coordinate.latitude
					attr.valid = true
				}
				else {
					attr.value.doubleVal = 0.0
					attr.valid = false
				}
			}
			attr.valueType = TYPE_DOUBLE
			attr.measureType = MEASURE_DEGREES
		}
		else if attributeName == ACTIVITY_ATTRIBUTE_STARTING_LONGITUDE {
			if let locations = self.locations[activityId] {
				if locations.count > 0 {
					attr.value.doubleVal = locations[0].coordinate.longitude
					attr.valid = true
				}
				else {
					attr.value.doubleVal = 0.0
					attr.valid = false
				}
			}
			attr.valueType = TYPE_DOUBLE
			attr.measureType = MEASURE_DEGREES
		}
		else if attributeName == ACTIVITY_ATTRIBUTE_CALORIES_BURNED {
			if let energyBurned = workout.totalEnergyBurned {
				attr.value.doubleVal = energyBurned.doubleValue(for: HKUnit.largeCalorie())
				attr.valueType = TYPE_DOUBLE
				attr.measureType = MEASURE_CALORIES
				attr.valid = true
			}
			else {
				attr.valid = false
			}
		}
		return attr
	}

	/// @brief Exports the activity with the specified ID to a file of the given format in the given directory..
	func exportActivityToFile(activityId: String, fileFormat: FileFormat, dirName: String) throws -> String {
		var newFileName = ""

		if let workout = self.workouts[activityId] {

			// The file name starts with the directory and will include the start time and the sport type.
			let sportType = self.getHistoricalActivityType(activityId: activityId)

			// Start and end times.
			let startTime: time_t = time_t(workout.startDate.timeIntervalSince1970)

			// Callback struct.
			let pointer = UnsafeMutablePointer<ExportCallbackType>.allocate(capacity: 1)
			
			defer {
				pointer.deinitialize(count: 1)
				pointer.deallocate()
			}
			
			pointer.pointee = ExportCallbackType()

			let fileNamePtr = UnsafeRawPointer(ExportActivityUsingCallbackData(activityId, fileFormat, dirName, startTime, sportType, exportNextCoordinate, pointer))
			
			guard fileNamePtr != nil else {
				throw ActivityExportException.runtimeError("Export failed!")
			}
			
			newFileName = String(cString: fileNamePtr!.assumingMemoryBound(to: CChar.self))
			
			do {
				fileNamePtr!.deallocate()
			}
		}

		return newFileName
	}

	/// @brief To be called when starting an activity.
	func startActivity(activityType: String, startTime: Date) {
		// Configure the workout
		let configuration = HKWorkoutConfiguration()
		configuration.activityType = HealthManager.activityTypeToHKWorkoutType(activityType: activityType)
		configuration.locationType = HealthManager.activityTypeToHKWorkoutSessionLocationType(activityType: activityType)

		// Swim-specifc configuration.
		if configuration.activityType == HKWorkoutActivityType.swimming {
			configuration.swimmingLocationType = HealthManager.activityTypeToHKWorkoutSwimmingLocationType(activityType: activityType)
			if configuration.locationType == HKWorkoutSessionLocationType.indoor {
				configuration.lapLength = HealthManager.poolLengthToHKQuantity()
			}
		}

		// Initialize the workout builder
		self.workoutBuilder = HKWorkoutBuilder(healthStore: self.healthStore, configuration: configuration, device: .local())

		// Initialize the workout route builder.
		self.routeBuilder = HKWorkoutRouteBuilder(healthStore: self.healthStore, device: nil)

		// Start data collection
		self.workoutBuilder?.beginCollection(withStart: startTime) { (success, error) in
			if let error = error {
				NSLog("Error starting workout collection: \(error.localizedDescription)")
			}
		}

#if os(watchOS)
		// Start the session in HealthKit. The app will get put into the background on the watch if we don't do this.
		do {
			self.workoutSession = try HKWorkoutSession(healthStore: self.healthStore, configuration: configuration)
			if let session = self.workoutSession {
				session.startActivity(with: startTime)
			}
		}
		catch {
		}

		// Subscribe to heart rate updates.
		if Preferences.useWatchHeartRate() {
			self.subscribeToHeartRateUpdates()
		}
#endif
	}

	/// @brief This method is called in response to an activity stopped notification.
	@objc func activityStopped(notification: NSNotification) {
		
		if let notificationData = notification.object as? Dictionary<String, Any> {

			if  let activityType = notificationData[KEY_NAME_ACTIVITY_TYPE] as? String,
				let startTime = notificationData[KEY_NAME_START_TIME] as? Date,
				let endTime = notificationData[KEY_NAME_END_TIME] as? Date,
				let distance = notificationData[KEY_NAME_DISTANCE] as? Double,
				let calories = notificationData[KEY_NAME_CALORIES] as? Double,
				let locations = notificationData[KEY_NAME_LOCATIONS] as? Array<CLLocationCoordinate2D> {

				let units = HealthManager.unitSystemToHKDistanceUnit(units: Preferences.preferredUnitSystem())

				// HealthKit limitation: Cannot have activities lasting longer than four days.
				if endTime.timeIntervalSince1970 - startTime.timeIntervalSince1970 < (86400 * 4) {

					if (distance > 0.01) {
						let distanceQuantity = HKQuantity.init(unit: units, doubleValue: distance)
						let distanceQuantityType = HealthManager.activityTypeToDistanceQuantityType(activityType: activityType)

						self.addDistanceSample(distance: distanceQuantity, startTime: startTime, endTime: endTime, distanceQuantityType: distanceQuantityType)
						self.saveWorkoutRoute(locations: locations)
					}

					self.addCaloriesBurnedSample(calories: calories, startTime: startTime, endTime: endTime)
				}

				self.endWorkout(endTime: endTime, endRoute: locations.count > 0)
			}
		}
	}

	func subscribeToHeartRateUpdates() {
		guard self.hrQuery == nil else {
			return
		}

		let sampleType = HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.heartRate)
		self.hrQuery = self.subscribeToQuantitySamplesOfType(quantityType: sampleType!, callback: { quantity, date, error in
			if quantity != nil && date != nil {
				let heartRateUnit: HKUnit = HKUnit.count().unitDivided(by: HKUnit.minute())
				let unixTime = date!.timeIntervalSince1970 // Apple Watch processor is 32-bit, so time_t is 32-bit as well

				self.currentHeartRate = quantity!.doubleValue(for: heartRateUnit)
				self.heartRateRead = true
				ProcessHrmReading(self.currentHeartRate, UInt64(unixTime))
			}
		})
	}

	func unsubscribeFromHeartRateUpdates() {
		guard self.hrQuery != nil else {
			return
		}

		self.healthStore.stop(self.hrQuery!)
		self.hrQuery = nil
	}

	func stopWorkout(endTime: Date) {
#if os(watchOS)
		if let session = self.workoutSession {
			session.stopActivity(with: endTime)
			session.end()
		}
#endif
	}

#if os(watchOS)
	func workoutSession(_ workoutSession: HKWorkoutSession, didChangeTo toState: HKWorkoutSessionState, from fromState: HKWorkoutSessionState, date: Date) {
	}
	
	func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) {
	}
#endif

	/// @brief Utility method for converting between the specified unit system and HKUnit.
	static func unitSystemToHKDistanceUnit(units: UnitSystem) -> HKUnit {
		switch units {
		case UNIT_SYSTEM_METRIC:
			return HKUnit.meterUnit(with: HKMetricPrefix.kilo)
		case UNIT_SYSTEM_US_CUSTOMARY:
			return HKUnit.mile()
		default:
			break
		}
		return HKUnit.mile()
	}
	
	/// @brief Utility method for converting between the activity type strings used in this app and the distance quantity enums used by Apple.
	static func activityTypeToDistanceQuantityType(activityType: String) -> HKQuantityTypeIdentifier {
		if activityType == ACTIVITY_TYPE_CYCLING {
			return .distanceCycling
		}
		else if activityType == ACTIVITY_TYPE_HIKING {
			return .distanceWalkingRunning
		}
		else if activityType == ACTIVITY_TYPE_MOUNTAIN_BIKING {
			return .distanceCycling
		}
		else if activityType == ACTIVITY_TYPE_RUNNING {
			return .distanceWalkingRunning
		}
		else if activityType == ACTIVITY_TYPE_STATIONARY_CYCLING {
			return .distanceCycling
		}
		else if activityType == ACTIVITY_TYPE_VIRTUAL_CYCLING {
			return .distanceCycling
		}
		else if activityType == ACTIVITY_TYPE_TREADMILL {
			return .distanceWalkingRunning
		}
		else if activityType == ACTIVITY_TYPE_WALKING {
			return .distanceWalkingRunning
		}
		else if activityType == ACTIVITY_TYPE_OPEN_WATER_SWIMMING {
			return .distanceSwimming
		}
		else if activityType == ACTIVITY_TYPE_POOL_SWIMMING {
			return .distanceSwimming
		}
		return .distanceWalkingRunning
	}

	/// @brief Utility method for converting between the activity type strings used in this app and the workout enums used by Apple.
	static func activityTypeToHKWorkoutType(activityType: String) -> HKWorkoutActivityType {
		if activityType == ACTIVITY_TYPE_CHINUP {
			return HKWorkoutActivityType.functionalStrengthTraining
		}
		else if activityType == ACTIVITY_TYPE_CYCLING {
			return HKWorkoutActivityType.cycling
		}
		else if activityType == ACTIVITY_TYPE_HIKING {
			return HKWorkoutActivityType.hiking
		}
		else if activityType == ACTIVITY_TYPE_MOUNTAIN_BIKING {
			return HKWorkoutActivityType.cycling
		}
		else if activityType == ACTIVITY_TYPE_RUNNING {
			return HKWorkoutActivityType.running
		}
		else if activityType == ACTIVITY_TYPE_SQUAT {
			return HKWorkoutActivityType.functionalStrengthTraining
		}
		else if activityType == ACTIVITY_TYPE_STATIONARY_CYCLING {
			return HKWorkoutActivityType.cycling
		}
		else if activityType == ACTIVITY_TYPE_VIRTUAL_CYCLING {
			return HKWorkoutActivityType.cycling
		}
		else if activityType == ACTIVITY_TYPE_TREADMILL {
			return HKWorkoutActivityType.running
		}
		else if activityType == ACTIVITY_TYPE_PULLUP {
			return HKWorkoutActivityType.functionalStrengthTraining
		}
		else if activityType == ACTIVITY_TYPE_PUSHUP {
			return HKWorkoutActivityType.functionalStrengthTraining
		}
		else if activityType == ACTIVITY_TYPE_WALKING {
			return HKWorkoutActivityType.walking
		}
		else if activityType == ACTIVITY_TYPE_OPEN_WATER_SWIMMING {
			return HKWorkoutActivityType.swimming
		}
		else if activityType == ACTIVITY_TYPE_POOL_SWIMMING {
			return HKWorkoutActivityType.swimming
		}
		return HKWorkoutActivityType.fencing // Shouldn't get here, so return something funny to make it easier to debug if we do.
	}

	/// @brief Utility method for converting between the activity type strings used in this app and the workout enums used by Apple.
	static func healthKitWorkoutToActivityType(workout: HKWorkout) -> String {
		switch workout.workoutActivityType {
		case HKWorkoutActivityType.cycling:
			return ACTIVITY_TYPE_CYCLING
		case HKWorkoutActivityType.hiking:
			return ACTIVITY_TYPE_HIKING
		case HKWorkoutActivityType.running:
			return ACTIVITY_TYPE_RUNNING
		case HKWorkoutActivityType.walking:
			return ACTIVITY_TYPE_WALKING
		case HKWorkoutActivityType.swimming:
			return ACTIVITY_TYPE_POOL_SWIMMING
		default:
			break
		}
		return ""
	}

	/// @brief Utility method for converting between the activity type strings used in this app and the workout session location enums used by Apple.
	static func activityTypeToHKWorkoutSessionLocationType(activityType: String) -> HKWorkoutSessionLocationType {
		if activityType == ACTIVITY_TYPE_CHINUP {
			return HKWorkoutSessionLocationType.indoor
		}
		else if activityType == ACTIVITY_TYPE_CYCLING {
			return HKWorkoutSessionLocationType.outdoor
		}
		else if activityType == ACTIVITY_TYPE_HIKING {
			return HKWorkoutSessionLocationType.outdoor
		}
		else if activityType == ACTIVITY_TYPE_MOUNTAIN_BIKING {
			return HKWorkoutSessionLocationType.outdoor
		}
		else if activityType == ACTIVITY_TYPE_RUNNING {
			return HKWorkoutSessionLocationType.outdoor
		}
		else if activityType == ACTIVITY_TYPE_SQUAT {
			return HKWorkoutSessionLocationType.indoor
		}
		else if activityType == ACTIVITY_TYPE_STATIONARY_CYCLING {
			return HKWorkoutSessionLocationType.indoor
		}
		else if activityType == ACTIVITY_TYPE_VIRTUAL_CYCLING {
			return HKWorkoutSessionLocationType.indoor
		}
		else if activityType == ACTIVITY_TYPE_TREADMILL {
			return HKWorkoutSessionLocationType.indoor
		}
		else if activityType == ACTIVITY_TYPE_PULLUP {
			return HKWorkoutSessionLocationType.indoor
		}
		else if activityType == ACTIVITY_TYPE_PUSHUP {
			return HKWorkoutSessionLocationType.indoor
		}
		else if activityType == ACTIVITY_TYPE_WALKING {
			return HKWorkoutSessionLocationType.outdoor
		}
		else if activityType == ACTIVITY_TYPE_OPEN_WATER_SWIMMING {
			return HKWorkoutSessionLocationType.outdoor
		}
		else if activityType == ACTIVITY_TYPE_POOL_SWIMMING {
			return HKWorkoutSessionLocationType.indoor
		}
		return HKWorkoutSessionLocationType.unknown // Shouldn't get here
	}
	
	/// @brief Utility method for converting between the activity type strings used in this app and the workout session swimming location enums used by Apple.
	static func activityTypeToHKWorkoutSwimmingLocationType(activityType: String) -> HKWorkoutSwimmingLocationType {
		if activityType == ACTIVITY_TYPE_OPEN_WATER_SWIMMING {
			return HKWorkoutSwimmingLocationType.openWater
		}
		else if activityType == ACTIVITY_TYPE_POOL_SWIMMING {
			return HKWorkoutSwimmingLocationType.pool
		}
		return HKWorkoutSwimmingLocationType.unknown
	}
	
	static func poolLengthToHKQuantity() -> HKQuantity {
		switch Preferences.poolLengthUnits() {
		case UNIT_SYSTEM_METRIC:
			return HKQuantity.init(unit: HKUnit.meterUnit(with: HKMetricPrefix.none), doubleValue: Double(Preferences.poolLength()))
		case UNIT_SYSTEM_US_CUSTOMARY:
			return HKQuantity.init(unit: HKUnit.yard(), doubleValue: Double(Preferences.poolLength()))
		default:
			break
		}
		return HKQuantity.init(unit: HKUnit.meterUnit(with: HKMetricPrefix.none), doubleValue: Double(Preferences.poolLength()))
	}
}
