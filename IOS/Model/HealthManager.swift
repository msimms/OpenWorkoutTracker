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
	var workouts: Dictionary<String, HKWorkout> = [:] // summaries of workouts stored in the health store, key is the activity ID which is generated automatically
	private var locations: Dictionary<String, Array<CLLocation>> = [:] // arrays of locations stored in the health store, key is the activity ID
	private var distances: Dictionary<String, Array<Double>> = [:] // arrays of distances computed from the locations array, key is the activity ID
	private var speeds: Dictionary<String, Array<Double>> = [:] // arrays of speeds computed from the distances array, key is the activity ID
	private var queryGroup: DispatchGroup = DispatchGroup() // tracks queries until they are completed

	/// Singleton constructor
	private init() {
		NotificationCenter.default.addObserver(self, selector: #selector(self.activityStopped), name: Notification.Name(rawValue: NOTIFICATION_NAME_ACTIVITY_STOPPED), object: nil)
	}
	
	func requestAuthorization() {
		
		// Check for HealthKit availability.
		guard HKHealthStore.isHealthDataAvailable() else {
			return
		}
		
		// Request authorization for things to read and write.
#if TARGET_OS_WATCH
		let heightType = HKObjectType.quantityType(forIdentifier: .height)!
		let weightType = HKObjectType.quantityType(forIdentifier: .bodyMass)!
		let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate)!
		let activeEnergyBurnType = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!
		let birthdayType = HKObjectType.characteristicType(forIdentifier: .dateOfBirth)!
		let biologicalSexType = HKObjectType.characteristicType(forIdentifier: .biologicalSex)!
		let writeTypes = Set([heartRateType, activeEnergyBurnType])
		let readTypes = Set([heartRateType, heightType, weightType, birthdayType, biologicalSexType])
#else
		let heightType = HKObjectType.quantityType(forIdentifier: .height)!
		let weightType = HKObjectType.quantityType(forIdentifier: .bodyMass)!
		let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate)!
		let bikeType = HKObjectType.quantityType(forIdentifier: .distanceCycling)!
		let runType = HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning)!
		let swimType = HKObjectType.quantityType(forIdentifier: .distanceSwimming)!
		let activeEnergyBurnType = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!
		let birthdayType = HKObjectType.characteristicType(forIdentifier: .dateOfBirth)!
		let biologicalSexType = HKObjectType.characteristicType(forIdentifier: .biologicalSex)!
		let workoutType = HKObjectType.workoutType()
		let writeTypes = Set([heightType, weightType, heartRateType, bikeType, runType, swimType, activeEnergyBurnType])
		let readTypes = Set([heartRateType, heightType, weightType, birthdayType, biologicalSexType, workoutType])
#endif
		healthStore.requestAuthorization(toShare: writeTypes, read: readTypes) { result, error in
			do {
				try self.updateUsersAge()
				try self.updateUsersHeight()
				try self.updateUsersWeight()
			}
			catch {
			}
		}
	}
	
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
	
	func quantitySamplesOfType(quantityType: HKQuantityType, callback: @escaping (HKQuantitySample?, Error?) -> ()) {
		
		// We are not filtering the data, and so the predicate is set to nil.
		let query = HKSampleQuery.init(sampleType: quantityType, predicate: nil, limit: HKObjectQueryNoLimit, sortDescriptors: nil, resultsHandler: { query, results, error in
			
			// Error case: Call the callback handler, passing nil for the results.
			if results == nil || results!.count == 0 {
				callback(nil, error!)
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
	
	/// @brief Gets the user's age from HealthKit and updates the copy in our database.
	func updateUsersAge() throws {
		let dateOfBirth = try self.healthStore.dateOfBirthComponents()
		let gregorianCalendar = NSCalendar.init(calendarIdentifier: NSCalendar.Identifier.gregorian)!
		let tempDate = gregorianCalendar.date(from: dateOfBirth)
		
		Preferences.setBirthDate(value: time_t(tempDate!.timeIntervalSince1970))
	}
	
	/// @brief Gets the user's height from HealthKit and updates the copy in our database.
	func updateUsersHeight() throws {
		let heightType = HKObjectType.quantityType(forIdentifier: .height)!
		
		self.mostRecentQuantitySampleOfType(quantityType: heightType) { sample, error in
			if sample != nil {
				let heightUnit = HKUnit.meterUnit(with: HKMetricPrefix.centi)
				let usersHeight = sample!.quantity.doubleValue(for: heightUnit)
				Preferences.setHeightCm(value: usersHeight)
			}
		}
	}

	/// @brief Gets the user's weight from HealthKit and updates the copy in our database.
	func updateUsersWeight() throws {
		let weightType = HKObjectType.quantityType(forIdentifier: .bodyMass)!
		
		self.mostRecentQuantitySampleOfType(quantityType: weightType) { sample, error in
			if sample != nil {
				let weightUnit = HKUnit.gramUnit(with: HKMetricPrefix.kilo)
				let usersWeight = sample!.quantity.doubleValue(for: weightUnit)
				Preferences.setWeightKg(value: usersWeight)
			}
		}
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

	func readAllActivitiesFromHealthStore() {
		self.clearWorkoutsList()
		self.readRunningWorkoutsFromHealthStore()
		self.readWalkingWorkoutsFromHealthStore()
		self.readCyclingWorkoutsFromHealthStore()
		self.waitForHealthKitQueries()
	}

	func calculateSpeedsFromDistances(distances: Array<Double>, activityId: String) {
		var speeds: Array<Double> = [0]
		
		for (index, distance2) in distances.enumerated() {
			let distance1 = distances[index - 1]

			let speed = distance2 - distance1;
			speeds.append(speed)
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
				}
				else {
					self.locations[activityId] = Array(routeData!)
				}
			}
			
			if done {
				if let activityLocations = self.locations[activityId] {
					self.calculateDistancesFromLocations(locations: activityLocations, activityId:activityId)
				}
			}
		}

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
		})
		
		self.healthStore.execute(query)
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

	func saveWeightIntoHealthStore(weight: Double, unitSystem: UnitSystem) {
		var units = HKUnit.inch()
		if unitSystem == UNIT_SYSTEM_METRIC {
			units = HKUnit.meterUnit(with: HKMetricPrefix.centi)
		}
		let now = Date()
		let weightQuantity = HKQuantity.init(unit: units, doubleValue: weight)
		let weightType = HKQuantityType.init(HKQuantityTypeIdentifier.bodyMass)
		let weightSample = HKQuantitySample.init(type: weightType, quantity: weightQuantity, start: now, end: now)
		self.healthStore.save(weightSample, withCompletion: {_,_ in })
	}

	func saveHeartRateIntoHealthStore(beats: Double) {
	}

	func saveRunningWorkoutIntoHealthStore(distance: Double, units: HKUnit, startDate: Date, endDate: Date) {
		let distanceQuantity = HKQuantity.init(unit: units, doubleValue: distance)
		let distanceType = HKQuantityType.init(HKQuantityTypeIdentifier.distanceWalkingRunning)
		let distanceSample = HKQuantitySample.init(type: distanceType, quantity: distanceQuantity, start: startDate, end: endDate)
		self.healthStore.save(distanceSample, withCompletion: {_,_ in })
	}

	func saveCyclingWorkoutIntoHealthStore(distance: Double, units: HKUnit, startDate: Date, endDate: Date) {
		let distanceQuantity = HKQuantity.init(unit: units, doubleValue: distance)
		let distanceType = HKQuantityType.init(HKQuantityTypeIdentifier.distanceCycling)
		let distanceSample = HKQuantitySample.init(type: distanceType, quantity: distanceQuantity, start: startDate, end: endDate)
		self.healthStore.save(distanceSample, withCompletion: {_,_ in })
	}

	func saveCaloriesBurnedIntoHealthStore(calories: Double, startDate: Date, endDate: Date) {
		let calorieUnit = HKUnit.kilocalorie()
		let calorieQuantity = HKQuantity.init(unit: calorieUnit, doubleValue: calories)
		let calorieType = HKQuantityType.init(HKQuantityTypeIdentifier.activeEnergyBurned)
		let calorieSample = HKQuantitySample.init(type: calorieType, quantity: calorieQuantity, start: startDate, end: endDate)
		self.healthStore.save(calorieSample, withCompletion: {_,_ in })
	}

	func convertIndexToActivityId(index: size_t) -> String {
		let keys = self.workouts.keys
		let dictIndex = keys.index(keys.startIndex, offsetBy: index)
		return keys[dictIndex]
	}
	
	func getHistoricalActivityType(activityId: String) -> String {
		let workout = self.workouts[activityId]

		if workout != nil {
			switch workout!.workoutActivityType {
			case HKWorkoutActivityType.cycling:
				return ACTIVITY_TYPE_CYCLING
			case HKWorkoutActivityType.running:
				return ACTIVITY_TYPE_RUNNING
			case HKWorkoutActivityType.walking:
				return ACTIVITY_TYPE_WALKING
			default:
				break
			}
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
			attr.value.doubleVal = self.quantityInUserPreferredUnits(qty: qty!)
			attr.valueType = TYPE_DOUBLE
			attr.measureType = MEASURE_DISTANCE
			attr.valid = true
		}
		else if attributeName == ACTIVITY_ATTRIBUTE_ELAPSED_TIME {
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
		return attr;
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

	/// @brief This method is called in response to a heart rate updated notification from the watch.
	@objc func heartRateUpdated(notification: NSNotification) {

		if let notificationData = notification.object as? Dictionary<String, Any> {

			if  let idStr = notificationData[KEY_NAME_PERIPHERAL_OBJ] as? String,
				let rate = notificationData[KEY_NAME_HEART_RATE] as? Double {
				
				if Preferences.shouldUsePeripheral(uuid: idStr) {
					self.saveHeartRateIntoHealthStore(beats: rate)
				}
			}
		}
	}

	/// @brief This method is called in response to an activity stopped notification.
	@objc func activityStopped(notification: NSNotification) {
		
		if let notificationData = notification.object as? Dictionary<String, Any> {

			if  let activityType = notificationData[KEY_NAME_ACTIVITY_TYPE] as? String,
				let startTime = notificationData[KEY_NAME_START_TIME] as? Date,
				let endTime = notificationData[KEY_NAME_END_TIME] as? Date,
				let distance = notificationData[KEY_NAME_DISTANCE] as? Double,
				let calories = notificationData[KEY_NAME_CALORIES] as? Double {
				
				let units = HealthManager.unitSystemToHKDistanceUnit(units: Preferences.preferredUnitSystem())

				// HealthKit limitation: Cannot have activities lasting longer than four days.
				if endTime.timeIntervalSince1970 - startTime.timeIntervalSince1970 < 345600 {
					if activityType == ACTIVITY_TYPE_CYCLING || activityType == ACTIVITY_TYPE_MOUNTAIN_BIKING {
						self.saveCyclingWorkoutIntoHealthStore(distance: distance, units: units, startDate: startTime, endDate: endTime)
					}
					else if activityType == ACTIVITY_TYPE_RUNNING || activityType == ACTIVITY_TYPE_WALKING {
						self.saveRunningWorkoutIntoHealthStore(distance: distance, units: units, startDate: startTime, endDate: endTime)
					}
				}
				
				self.saveCaloriesBurnedIntoHealthStore(calories: calories, startDate: startTime, endDate: endTime)
			}
		}
	}

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
		else if activityType == ACTIVITY_TYPE_STATIONARY_BIKE {
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
		else if activityType == ACTIVITY_TYPE_STATIONARY_BIKE {
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
