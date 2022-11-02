//
//  HealthManager.swift
//  Created by Michael Simms on 10/7/22.
//

import Foundation
import HealthKit

class HealthManager {
	static let shared = HealthManager()
	
	var authorized = false
	let healthStore = HKHealthStore();
	
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
			let heightUnit = HKUnit.meterUnit(with: HKMetricPrefix.centi)
			let usersHeight = sample!.quantity.doubleValue(for: heightUnit)
			Preferences.setHeightCm(value: usersHeight)
		}
	}

	/// @brief Gets the user's weight from HealthKit and updates the copy in our database.
	func updateUsersWeight() throws {
		let weightType = HKObjectType.quantityType(forIdentifier: .bodyMass)!
		
		self.mostRecentQuantitySampleOfType(quantityType: weightType) { sample, error in
			let weightUnit = HKUnit.meterUnit(with: HKMetricPrefix.kilo)
			let usersWeight = sample!.quantity.doubleValue(for: weightUnit)
			Preferences.setWeightKg(value: usersWeight)
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

	/// @brief Exports the activity with the specified ID to a file of the given format in the given directory..
	func exportActivityToFile(activityId: String, fileFormat: FileFormat, dirName: String) -> String {
		return ""
	}

	/// @brief This method is called in response to a heart rate updated notification from the watch.
	@objc func heartRateUpdated(notification: NSNotification) {
	}

	/// @brief This method is called in response to an activity stopped notification.
	@objc func activityStopped(notification: NSNotification) {
	}

	/// @brief Utility method for converting between the specified unit system and HKUnit.
	func unitSystemToHKDistanceUnit(units: UnitSystem) -> HKUnit {
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
	func activityTypeToHKWorkoutType(activityType: String) -> HKWorkoutActivityType {
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
	
	/// @brief Utility method for converting between the activity type strings used in this app and the workout session location enums used by Apple.
	func activityTypeToHKWorkoutSessionLocationType(activityType: String) -> HKWorkoutSessionLocationType {
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
	func activityTypeToHKWorkoutSwimmingLocationType(activityType: String) -> HKWorkoutSwimmingLocationType {
		if activityType == ACTIVITY_TYPE_OPEN_WATER_SWIMMING {
			return HKWorkoutSwimmingLocationType.openWater
		}
		else if activityType == ACTIVITY_TYPE_POOL_SWIMMING {
			return HKWorkoutSwimmingLocationType.pool
		}
		return HKWorkoutSwimmingLocationType.unknown
	}
	
	func poolLengthToHKQuantity() -> HKQuantity {
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
