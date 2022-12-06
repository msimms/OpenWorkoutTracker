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
	static let shared = CommonApp()
	static var activityTypes: Array<String> = []
	
	private var sensorMgr = SensorMgr.shared
	private var broadcastMgr = BroadcastManager.shared
	private var healthMgr = HealthManager.shared
	private var apiClient = ApiClient.shared

	/// Singleton constructor
	private init() {
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
	
		// Set the user's preferred unit system.
		SetPreferredUnitSystem(Preferences.preferredUnitSystem())

		// Initialize HealthKit.
		self.healthMgr.requestAuthorization()

		// Things we care about knowing from the server.
		NotificationCenter.default.addObserver(self, selector: #selector(self.loginStatusUpdated), name: Notification.Name(rawValue: NOTIFICATION_NAME_LOGIN_CHECKED), object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(self.loginProcessed), name: Notification.Name(rawValue: NOTIFICATION_NAME_LOGIN_PROCESSED), object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(self.createLoginProcessed), name: Notification.Name(rawValue: NOTIFICATION_NAME_CREATE_LOGIN_PROCESSED), object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(self.logoutProcessed), name: Notification.Name(rawValue: NOTIFICATION_NAME_LOGGED_OUT), object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(self.friendsListUpdated), name: Notification.Name(rawValue: NOTIFICATION_NAME_FRIENDS_LIST_UPDATED), object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(self.gearListUpdated), name: Notification.Name(rawValue: NOTIFICATION_NAME_GEAR_LIST_UPDATED), object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(self.plannedWorkoutsUpdated), name: Notification.Name(rawValue: NOTIFICATION_NAME_PLANNED_WORKOUTS_UPDATED), object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(self.intervalSessionsUpdated), name: Notification.Name(rawValue: NOTIFICATION_NAME_INTERVAL_SESSIONS_UPDATED), object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(self.pacePlansUpdated), name: Notification.Name(rawValue: NOTIFICATION_NAME_PACE_PLANS_UPDATED), object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(self.unsynchedActivitiesListReceived), name: Notification.Name(rawValue: NOTIFICATION_NAME_UNSYNCHED_ACTIVITIES_LIST), object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(self.hasActivityResponse), name: Notification.Name(rawValue: NOTIFICATION_NAME_HAS_ACTIVITY_RESPONSE), object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(self.activityMetadataReceived), name: Notification.Name(rawValue: NOTIFICATION_NAME_ACTIVITY_METADATA), object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(self.plannedWorkoutUpdated), name: Notification.Name(rawValue: NOTIFICATION_NAME_PLANNED_WORKOUT_UPDATED), object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(self.requestToFollowResponse), name: Notification.Name(rawValue: NOTIFICATION_NAME_REQUEST_TO_FOLLOW_RESULT), object: nil)

		// Sync with the server.
		let _ = self.apiClient.syncWithServer()
	}

	@objc func loginStatusUpdated(notification: NSNotification) {
		if let data = notification.object as? Dictionary<String, AnyObject> {
			if let responseCode = data[KEY_NAME_RESPONSE_CODE] as? HTTPURLResponse {
				if responseCode.statusCode == 200 {
					self.apiClient.loggedIn = true
				}
			}
		}
	}

	@objc func loginProcessed(notification: NSNotification) {
		do {
			if let data = notification.object as? Dictionary<String, AnyObject> {
				if let responseCode = data[KEY_NAME_RESPONSE_CODE] as? HTTPURLResponse {
					if responseCode.statusCode == 200 {
						self.apiClient.loggedIn = true
						let _ = self.apiClient.syncWithServer() // re-sync

						if let data = notification.object as? Dictionary<String, AnyObject> {
							if let responseData = data[KEY_NAME_RESPONSE_DATA] as? Data {
								if let sessionDict = try JSONSerialization.jsonObject(with: responseData, options: []) as? Dictionary<String, AnyObject> {
									let sessionCookieStr = sessionDict["cookie"]
									let sessionExpiry = sessionDict["expiry"]
								}
							}
						}
					}
				}
			}
		}
		catch {
		}
	}

	@objc func createLoginProcessed(notification: NSNotification) {
		if let data = notification.object as? Dictionary<String, AnyObject> {
			if let responseCode = data[KEY_NAME_RESPONSE_CODE] as? HTTPURLResponse {
				if responseCode.statusCode == 200 {
					self.apiClient.loggedIn = true
					let _ = self.apiClient.syncWithServer() // re-sync
				}
			}
		}
	}

	@objc func logoutProcessed(notification: NSNotification) {
		if let data = notification.object as? Dictionary<String, AnyObject> {
			if let responseCode = data[KEY_NAME_RESPONSE_CODE] as? HTTPURLResponse {
				if responseCode.statusCode == 200 {
					self.apiClient.loggedIn = false
				}
			}
		}
	}
	
	@objc func friendsListUpdated(notification: NSNotification) {
		do {
			if let data = notification.object as? Dictionary<String, AnyObject> {
				if let responseData = data[KEY_NAME_RESPONSE_DATA] as? Data {
					let friendsVM: FriendsVM = FriendsVM()
					let friendsList = try JSONSerialization.jsonObject(with: responseData, options: []) as! [Any]
					for friend in friendsList {
						if let friendDict = friend as? Dictionary<String, AnyObject> {
							friendsVM.updateFriendFromDict(dict: friendDict)
						}
					}
				}
			}
		}
		catch {
		}
	}

	@objc func gearListUpdated(notification: NSNotification) {
		do {
			if let data = notification.object as? Dictionary<String, AnyObject> {
				if let responseData = data[KEY_NAME_RESPONSE_DATA] as? Data {
					let gearVM: GearVM = GearVM()
					let gearList = try JSONSerialization.jsonObject(with: responseData, options: []) as! [Any]
					for gear in gearList {
						if let gearDict = gear as? Dictionary<String, AnyObject> {
							gearVM.updateGearFromDict(dict: gearDict)
						}
					}
				}
			}
		}
		catch {
		}
	}
	
	@objc func plannedWorkoutsUpdated(notification: NSNotification) {
		do {
			if let data = notification.object as? Dictionary<String, AnyObject> {
				if let responseData = data[KEY_NAME_RESPONSE_DATA] as? Data {
					let workoutsVM: WorkoutsVM = WorkoutsVM()
					let workoutsList = try JSONSerialization.jsonObject(with: responseData, options: []) as! [Any]
					for workout in workoutsList {
						if let workoutDict = workout as? Dictionary<String, AnyObject> {
							workoutsVM.updateWorkoutFromDict(dict: workoutDict)
						}
					}
				}
			}
		}
		catch {
		}
	}

	@objc func intervalSessionsUpdated(notification: NSNotification) {
		do {
			if let data = notification.object as? Dictionary<String, AnyObject> {
				if let responseData = data[KEY_NAME_RESPONSE_DATA] as? Data {
					let intervalSessionsVM = IntervalSessionsVM.shared
					let sessionsList = try JSONSerialization.jsonObject(with: responseData, options: []) as! [Any]
					for session in sessionsList {
						if let sessionDict = session as? Dictionary<String, AnyObject> {
							intervalSessionsVM.updateIntervalSessionFromDict(dict: sessionDict)
						}
					}
				}
			}
		}
		catch {
		}
	}

	@objc func pacePlansUpdated(notification: NSNotification) {
		do {
			if let data = notification.object as? Dictionary<String, AnyObject> {
				if let responseData = data[KEY_NAME_RESPONSE_DATA] as? Data {
					let pacePlansVM = PacePlansVM.shared
					let planList = try JSONSerialization.jsonObject(with: responseData, options: []) as! [Any]
					for plan in planList {
						if let planDict = plan as? Dictionary<String, AnyObject> {
							let _ = pacePlansVM.updatePacePlanFromDict(summaryDict: planDict)
						}
					}
				}
			}
		}
		catch {
		}
	}
	
	@objc func unsynchedActivitiesListReceived(notification: NSNotification) {
		do {
			if let data = notification.object as? Dictionary<String, AnyObject> {
				if let responseData = data[KEY_NAME_RESPONSE_DATA] as? Data {
					let activitiesList = try JSONSerialization.jsonObject(with: responseData, options: []) as! [Any]
					for activity in activitiesList {
					}
				}
			}
		}
		catch {
		}
	}
	
	@objc func hasActivityResponse(notification: NSNotification) {
		do {
			if let data = notification.object as? Dictionary<String, AnyObject> {
				if let responseData = data[KEY_NAME_RESPONSE_DATA] as? Data {
				}
			}
		}
		catch {
		}
	}
	
	@objc func activityMetadataReceived(notification: NSNotification) {
		do {
			if let data = notification.object as? Dictionary<String, AnyObject> {
				if let responseData = data[KEY_NAME_RESPONSE_DATA] as? Data {
				}
			}
		}
		catch {
		}
	}
	
	@objc func plannedWorkoutUpdated(notification: NSNotification) {
		do {
			if let data = notification.object as? Dictionary<String, AnyObject> {
				if let responseData = data[KEY_NAME_RESPONSE_DATA] as? Data {
				}
			}
		}
		catch {
		}
	}
	
	@objc func requestToFollowResponse(notification: NSNotification) {
		do {
			if let data = notification.object as? Dictionary<String, AnyObject> {
				if let responseData = data[KEY_NAME_RESPONSE_DATA] as? Data {
				}
			}
		}
		catch {
		}
	}
}
