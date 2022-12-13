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

	func markAsSynchedToWeb(activityId: String) -> Bool {
		return CreateActivitySync(activityId, SYNC_DEST_WEB)
	}
	
	func markAsSynchedToICloudDrive(activityId: String) -> Bool {
		return CreateActivitySync(activityId, SYNC_DEST_ICLOUD_DRIVE)
	}

	func markAsSynchedToWatch(activityId: String) -> Bool {
		return CreateActivitySync(activityId, SYNC_DEST_WATCH)
	}

	func exportActivityToWeb(activityId: String) throws {
		let summary = ActivitySummary()
		summary.id = activityId
		summary.source = ActivitySummary.Source.database
		
		let storedActivityVM = StoredActivityVM(activitySummary: summary)
		let fileName = try storedActivityVM.exportActivityToFile(fileFormat: FILE_GPX)

		try FileManager.default.removeItem(at: URL(string: fileName)!)
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
			NSLog(error.localizedDescription)
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
			NSLog(error.localizedDescription)
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
			NSLog(error.localizedDescription)
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
			NSLog(error.localizedDescription)
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
			NSLog(error.localizedDescription)
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
			NSLog(error.localizedDescription)
		}
	}
	
	@objc func hasActivityResponse(notification: NSNotification) {
		do {
			if let data = notification.object as? Dictionary<String, AnyObject> {
				if let responseData = data[KEY_NAME_RESPONSE_DATA] as? Data {
					if let responseDict = try JSONSerialization.jsonObject(with: responseData, options: []) as? Dictionary<String, AnyObject> {
						let app = CommonApp.shared
						let activityId = responseDict[PARAM_ACTIVITY_ID] as! String
						let codeStr = responseDict[PARAM_CODE]
						let code = codeStr as? ActivityMatch

						switch (code) {
						case ACTIVITY_MATCH_CODE_NO_ACTIVITY:
							// Send the activity
							try app.exportActivityToWeb(activityId: activityId)
							break
						case ACTIVITY_MATCH_CODE_HASH_NOT_COMPUTED:
							// Mark it as synced
							let _ = app.markAsSynchedToWeb(activityId: activityId)
							break
						case ACTIVITY_MATCH_CODE_HASH_DOES_NOT_MATCH:
							// Mark it as synced
							let _ = app.markAsSynchedToWeb(activityId: activityId)
							break
						case ACTIVITY_MATCH_CODE_HASH_MATCHES:
							// Mark it as synced
							let _ = app.markAsSynchedToWeb(activityId: activityId)
							break
						case ACTIVITY_MATCH_CODE_HASH_NOT_PROVIDED:
							// Mark it as synced
							let _ = app.markAsSynchedToWeb(activityId: activityId)
							break
						default:
							break
						}
					}
				}
			}
		}
		catch {
			NSLog(error.localizedDescription)
		}
	}
	
	@objc func activityMetadataReceived(notification: NSNotification) {
		do {
			if let data = notification.object as? Dictionary<String, AnyObject> {
				if let responseData = data[KEY_NAME_RESPONSE_DATA] as? Data {
					if let responseDict = try JSONSerialization.jsonObject(with: responseData, options: []) as? Dictionary<String, AnyObject> {
					}
				}
			}
		}
		catch {
			NSLog(error.localizedDescription)
		}
	}
	
	@objc func plannedWorkoutUpdated(notification: NSNotification) {
		do {
			if let data = notification.object as? Dictionary<String, AnyObject> {
				if let responseData = data[KEY_NAME_RESPONSE_DATA] as? Data {
					if let responseDict = try JSONSerialization.jsonObject(with: responseData, options: []) as? Dictionary<String, AnyObject> {
					}
				}
			}
		}
		catch {
			NSLog(error.localizedDescription)
		}
	}
	
	@objc func requestToFollowResponse(notification: NSNotification) {
		do {
			if let data = notification.object as? Dictionary<String, AnyObject> {
				if let responseData = data[KEY_NAME_RESPONSE_DATA] as? Data {
					if let responseDict = try JSONSerialization.jsonObject(with: responseData, options: []) as? Dictionary<String, AnyObject> {
					}
				}
			}
		}
		catch {
			NSLog(error.localizedDescription)
		}
	}
}
