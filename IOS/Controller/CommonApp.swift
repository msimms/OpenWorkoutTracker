//
//  CommonApp.swift
//  Created by Michael Simms on 10/1/22.
//

import Foundation

func activityTypeCallback(name: Optional<UnsafePointer<Int8>>, context: Optional<UnsafeMutableRawPointer>) {
	let activityType = String(cString: UnsafeRawPointer(name!).assumingMemoryBound(to: CChar.self))
	CommonApp.activityTypes.append(activityType)
}

class CommonApp : ObservableObject {
	static var activityTypes: Array<String> = []

	private var sensorMgr = SensorMgr.shared
	private var broadcastMgr = BroadcastManager.shared
	private var healthMgr = HealthManager.shared
	private var apiClient = ApiClient.shared

	@Published var isLoggedIn: Bool = false

	static func getActivityTypes() -> Array<String> {
		return self.activityTypes
	}
	
	func healthKitCompletion(result: Bool, error: Error?) {
		if result {
		}
		else {
		}
	}

	init() {
		// Initialize the backend, including the database.
		var baseUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].standardizedFileURL
		baseUrl = baseUrl.appendingPathComponent("Activities.sqlite")
		Initialize(baseUrl.absoluteString)

		// Build the list of activity types the backend can handle.
		CommonApp.activityTypes = []
		GetActivityTypes(activityTypeCallback, nil, true, true, true)

		// Do we have a device ID, because we should?
		if Preferences.uuid() == nil {
			Preferences.setUuid(value: UUID().uuidString)
		}

		// Initialize HealthKit.
		self.healthMgr.requestAuthorization(completion: healthKitCompletion)
	}
}
