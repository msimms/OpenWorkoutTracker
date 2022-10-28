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
			}
			catch {
			}
		}
	}

	/*	func mostRecentQuantitySampleOfType:(HKQuantityType*)quantityType callback:(void (^)(HKQuantity*, NSDate*, NSError*))callback {
		// It's invalid to call this without a callback handler.
		if (!callback)
		{
			return;
		}
		
		// Since we are interested in retrieving the user's latest sample, we sort the samples in descending
		// order, and set the limit to 1. We are not filtering the data, and so the predicate is set to nil.
		NSSortDescriptor* timeSortDescriptor = [[NSSortDescriptor alloc] initWithKey:HKSampleSortIdentifierEndDate ascending:NO];
		HKSampleQuery* query = [[HKSampleQuery alloc] initWithSampleType:quantityType
															   predicate:nil
																   limit:1
														 sortDescriptors:@[timeSortDescriptor]
														  resultsHandler:^(HKSampleQuery* query, NSArray* results, NSError* error)
								{
			// Error case: Call the callback handler, passing nil for the results.
			if (!results)
			{
				callback(nil, nil, error);
			}
			
			// Normal case: Call the callback handler with the results.
			else
			{
				HKQuantitySample* quantitySample = results.firstObject;
				callback(quantitySample.quantity, quantitySample.startDate, error);
			}
		}];

		// Execute asynchronously.
		self.healthStore.execute(query)
	} */

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

	}
}
