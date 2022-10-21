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
	
	func requestAuthorization(completion: @escaping (Bool, Error?) -> Void) {
		
		// Check for HealthKit availability.
		guard HKHealthStore.isHealthDataAvailable() else {
			completion(false, nil)
			return
		}
		
		// Request authorization.
		let workoutType = HKQuantityType.workoutType()
		let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate)!
		let sampleTypes = Set([workoutType, heartRateType])
		healthStore.requestAuthorization(toShare: nil, read: sampleTypes, completion: completion)
	}
}
