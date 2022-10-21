//
//  CommonApp.swift
//  Created by Michael Simms on 10/1/22.
//

import Foundation

class CommonApp {
	private var sensorMgr = SensorMgr.shared
	private var broadcastMgr = BroadcastManager.shared
	private var healthMgr = HealthManager.shared

	func healthKitCompletion(result: Bool, error: Error?) {
		if result {
		}
		else {
		}
	}

	init() {
		// Initialize the backend, including the database.
		var baseUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].standardizedFileURL
		//var baseUrl = FileManager.default.url(forUbiquityContainerIdentifier: nil)
		//baseUrl = baseUrl.appendingPathComponent("Documents")
		baseUrl = baseUrl.appendingPathComponent("Activities.sqlite")
		Initialize(baseUrl.absoluteString)
		
		// Initialize HealthKit.
		self.healthMgr.requestAuthorization(completion: healthKitCompletion)
	}
}
