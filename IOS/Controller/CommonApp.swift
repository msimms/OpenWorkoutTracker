//
//  CommonApp.swift
//  Created by Michael Simms on 10/1/22.
//

import Foundation
#if os(watchOS)
import SwiftUI // for WKInterfaceDevice
#endif
import os

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
	var watchSession = WatchSession()
	var stateLock = OSAllocatedUnfairLock()

	/// Singleton constructor
	private init() {
		// Initialize the backend, including the database.
		var baseUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].standardizedFileURL
		baseUrl = baseUrl.appendingPathComponent("Activities.sqlite")
		if Initialize(baseUrl.absoluteString) == false {
			NSLog("Initialize failed.")
		}

		// Build the list of activity types the backend can handle.
		CommonApp.activityTypes = []
#if os(watchOS)
		GetActivityTypes(activityTypeCallback, nil, true, true, true)
#else
		GetActivityTypes(activityTypeCallback, nil, true, false, true)
#endif

		// Enable battery monitoring.
#if os(watchOS)
		WKInterfaceDevice.current().isBatteryMonitoringEnabled = true
#endif

		// Do we have a device ID, because we should?
		if Preferences.uuid() == nil {
			Preferences.setUuid(value: UUID().uuidString)
		}
		
		// Are we supposed to use the optional web server?
		if Preferences.shouldBroadcastToServer() {
			let _ = ApiClient.shared.checkLoginStatus()
		}
		
		// Set the user's preferred unit system.
		SetPreferredUnitSystem(Preferences.preferredUnitSystem())
		
		// Initialize HealthKit.
		self.healthMgr.requestAuthorization()
		
#if !os(watchOS)
		// Update our copy of the user's weight history.
		self.healthMgr.updateWeightHistoryFromHealthKit()
#endif
		
		// Initialize the watch session.
		self.watchSession.startWatchSession()
		
		// Send the user's details to the backend.
		self.updateUserProfile()
		
		// Things we care about knowing from the server.
		NotificationCenter.default.addObserver(self, selector: #selector(self.loginStatusUpdated), name: Notification.Name(rawValue: NOTIFICATION_NAME_LOGIN_CHECKED), object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(self.loginProcessed), name: Notification.Name(rawValue: NOTIFICATION_NAME_LOGIN_PROCESSED), object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(self.createLoginProcessed), name: Notification.Name(rawValue: NOTIFICATION_NAME_CREATE_LOGIN_PROCESSED), object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(self.logoutProcessed), name: Notification.Name(rawValue: NOTIFICATION_NAME_LOGGED_OUT), object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(self.friendsListUpdated), name: Notification.Name(rawValue: NOTIFICATION_NAME_FRIENDS_LIST_UPDATED), object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(self.requestToFollowResponse), name: Notification.Name(rawValue: NOTIFICATION_NAME_REQUEST_TO_FOLLOW_RESULT), object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(self.requestUserSettingsResponse), name: Notification.Name(rawValue: NOTIFICATION_NAME_REQUEST_USER_SETTINGS_RESULT), object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(self.downloadedActivityReceived), name: Notification.Name(rawValue: NOTIFICATION_NAME_DOWNLOADED_ACTIVITY_RECEIVED), object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(self.gearListUpdated), name: Notification.Name(rawValue: NOTIFICATION_NAME_GEAR_LIST_UPDATED), object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(self.raceListUpdated), name: Notification.Name(rawValue: NOTIFICATION_NAME_RACE_LIST_UPDATED), object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(self.plannedWorkoutsUpdated), name: Notification.Name(rawValue: NOTIFICATION_NAME_PLANNED_WORKOUTS_UPDATED), object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(self.intervalSessionsUpdated), name: Notification.Name(rawValue: NOTIFICATION_NAME_INTERVAL_SESSIONS_UPDATED), object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(self.pacePlansUpdated), name: Notification.Name(rawValue: NOTIFICATION_NAME_PACE_PLANS_UPDATED), object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(self.unsynchedActivitiesListReceived), name: Notification.Name(rawValue: NOTIFICATION_NAME_UNSYNCHED_ACTIVITIES_LIST), object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(self.hasActivityResponse), name: Notification.Name(rawValue: NOTIFICATION_NAME_HAS_ACTIVITY_RESPONSE), object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(self.activityMetadataReceived), name: Notification.Name(rawValue: NOTIFICATION_NAME_ACTIVITY_METADATA), object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(self.activityStopped), name: Notification.Name(rawValue: NOTIFICATION_NAME_ACTIVITY_STOPPED), object: nil)
		
		// Sync with the server.
		let _ = ApiClient.shared.syncWithServer()
	}
	
	/// @brief Sends the user's details to the backend. Should be called on application startup as well as whenever the values are changed.
	func updateUserProfile() {
		let userLevel = Preferences.activityLevel()
		let userGender = Preferences.biologicalGender()
		let userBirthdate = Preferences.birthDate()
		let userWeightKg = Preferences.weightKg()
		let userHeightCm = Preferences.heightCm()
		let ftp = Preferences.ftp()
		let restingHr = Preferences.restingHr()
		let maxHr = Preferences.maxHr()
		let vo2Max = Preferences.vo2Max()
		let bestRecent5KSecs = Preferences.bestRecent5KSecs()

		SetUserProfile(userLevel, userGender, userBirthdate, userWeightKg, userHeightCm, ftp, restingHr, maxHr, vo2Max, bestRecent5KSecs, 5000.0)
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
	
	/// @brief Sends an activity to the server.
	func exportActivityToWeb(activityId: String) async throws {
		let summary = ActivitySummary()
		summary.id = activityId
		summary.source = ActivitySummary.Source.database
		
		let storedActivityVM = StoredActivityVM(activitySummary: summary)
		storedActivityVM.load()

		let fileName = try storedActivityVM.exportActivityToTempFile(fileFormat: FILE_GPX)
		let fileUrl = URL(string: "file://" + fileName)
		let fileContents = try Data(contentsOf: fileUrl!)
		let _ = ApiClient.shared.sendActivity(activityId: summary.id, name: fileUrl!.lastPathComponent, contents: fileContents)
		
		try FileManager.default.removeItem(at: fileUrl!)
	}

	/// @brief Called to add data to HealthKit from a newly imported activity.
	func importActivityToHealthKit(activityId: String) {

		// Add heart data to HealthKit.
		let numHrReadings = GetNumHistoricalSensorReadings(activityId, SENSOR_TYPE_HEART_RATE);
		if numHrReadings > 0 {
			for hrIndex in 0...numHrReadings - 1 {
				var timestamp: time_t = 0
				var value: Double = 0.0

				if GetHistoricalActivitySensorReading(activityId, SENSOR_TYPE_HEART_RATE, hrIndex, &timestamp, &value) {
					HealthManager.shared.saveHeartRateIntoHealthStore(beats: value, timestamp: Date(timeIntervalSince1970: TimeInterval(timestamp)))
				}
			}
		}

		if IsCyclingActivity() {

			// Add power data to HealthKit.
			let numPowerReadings = GetNumHistoricalSensorReadings(activityId, SENSOR_TYPE_POWER);
			if numPowerReadings > 0 {
				for powerIndex in 0...numPowerReadings - 1 {
					var timestamp: time_t = 0
					var value: Double = 0.0

					if GetHistoricalActivitySensorReading(activityId, SENSOR_TYPE_POWER, powerIndex, &timestamp, &value) {
						HealthManager.shared.saveCyclingPowerIntoHealthStore(watts: value, timestamp: Date(timeIntervalSince1970: TimeInterval(timestamp)))
					}
				}
			}
		}
	}

	/// @brief This method is called when the server returns login status.
	@objc func loginStatusUpdated(notification: NSNotification) {
		if let data = notification.object as? Dictionary<String, AnyObject> {
			if let responseCode = data[KEY_NAME_RESPONSE_CODE] as? HTTPURLResponse {
				if responseCode.statusCode == 200 {
					ApiClient.shared.loginStatus = LoginStatus.LOGIN_STATUS_SUCCESS
					
					// This will request all the things we need from the server.
					let _ = ApiClient.shared.syncWithServer()
				}
				else {
					ApiClient.shared.loginStatus = LoginStatus.LOGIN_STATUS_FAILURE
				}
			}
		}
	}
	
	/// @brief This method is called when the server acknowledges a login.
	@objc func loginProcessed(notification: NSNotification) {
		do {
			if let data = notification.object as? Dictionary<String, AnyObject> {
				if let responseCode = data[KEY_NAME_RESPONSE_CODE] as? HTTPURLResponse {
					if responseCode.statusCode == 200 {
						ApiClient.shared.loginStatus = LoginStatus.LOGIN_STATUS_SUCCESS

						if let responseData = data[KEY_NAME_RESPONSE_DATA] as? Data {
							if let sessionDict = try JSONSerialization.jsonObject(with: responseData, options: []) as? Dictionary<String, AnyObject> {
								let sessionCookieStr = sessionDict["cookie"]
								let sessionExpiry = sessionDict["expiry"] as! TimeInterval
								
								let cookieProperties: Dictionary<HTTPCookiePropertyKey, Any> = [
									HTTPCookiePropertyKey.domain: Preferences.broadcastHostName(),
									HTTPCookiePropertyKey.path: "/",
									HTTPCookiePropertyKey.name: SESSION_COOKIE_NAME,
									HTTPCookiePropertyKey.value: sessionCookieStr as Any,
									HTTPCookiePropertyKey.secure: "TRUE",
									HTTPCookiePropertyKey.expires: NSDate(timeIntervalSince1970: sessionExpiry)
								]
								
								let cookie = HTTPCookie(properties: cookieProperties)
								HTTPCookieStorage.shared.setCookie(cookie!)
								
								if let userId = sessionDict["user_id"] as? String {
									Preferences.setUserId(value: userId)
								}
							}
						}
						
						// This will request all the things we need from the server.
						let _ = ApiClient.shared.syncWithServer()
					}
					else {
						ApiClient.shared.loginStatus = LoginStatus.LOGIN_STATUS_FAILURE
					}
				}
			}
		}
		catch {
		}
	}
	
	/// @brief This method is called when the server acknowledges a login creation.
	@objc func createLoginProcessed(notification: NSNotification) {
		if let data = notification.object as? Dictionary<String, AnyObject> {
			if let responseCode = data[KEY_NAME_RESPONSE_CODE] as? HTTPURLResponse {
				if responseCode.statusCode == 200 {
					ApiClient.shared.loginStatus = LoginStatus.LOGIN_STATUS_SUCCESS

					// This will request all the things we need from the server.
					let _ = ApiClient.shared.syncWithServer()
				}
				else {
					ApiClient.shared.loginStatus = LoginStatus.LOGIN_STATUS_FAILURE
				}
			}
		}
	}
	
	/// @brief This method is called when the server acknowledges a session logout.
	@objc func logoutProcessed(notification: NSNotification) {
		if let data = notification.object as? Dictionary<String, AnyObject> {
			if let responseCode = data[KEY_NAME_RESPONSE_CODE] as? HTTPURLResponse {
				if responseCode.statusCode == 200 || responseCode.statusCode == 403 {
					ApiClient.shared.loginStatus = LoginStatus.LOGIN_STATUS_FAILURE
				}
			}
		}
	}
	
	/// @brief This method is called when the server returns an updated friends list.
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
	
	@objc func requestToFollowResponse(notification: NSNotification) {
		do {
			if let data = notification.object as? Dictionary<String, AnyObject> {
				if let responseData = data[KEY_NAME_RESPONSE_DATA] as? Data {
					if let responseDict = try JSONSerialization.jsonObject(with: responseData, options: []) as? Dictionary<String, AnyObject> {
						let friendsVM = FriendsVM()
						friendsVM.updateFriendRequestFromDict(dict: responseDict)
					}
				}
			}
		}
		catch {
			NSLog(error.localizedDescription)
		}
	}
	
	/// @brief This method is called when the server returns updated user settings.
	@objc func requestUserSettingsResponse(notification: NSNotification) {
		do {
			if let data = notification.object as? Dictionary<String, AnyObject> {
				if let responseData = data[KEY_NAME_RESPONSE_DATA] as? Data {
					if let responseArray = try JSONSerialization.jsonObject(with: responseData, options: []) as? [Any] {
						for item in responseArray {
							if let itemDict = item as? Dictionary<String, AnyObject> {
								if let firstItem = itemDict.first {
									if firstItem.key == WORKOUT_INPUT_GOAL_TYPE {
										if let value = firstItem.value as? String {
											Preferences.setWorkoutGoal(value: WorkoutsVM.workoutGoalStringToEnum(goalStr: value))
										}
									}
								}
							}
						}
					}
				}
			}
		}
		catch {
			NSLog(error.localizedDescription)
		}
	}
	
	/// @brief Called when the notification to import an activity is received.
	@objc func downloadedActivityReceived(notification: NSNotification) {
		do {
			if let data = notification.object as? Dictionary<String, AnyObject> {
				if let responseData = data[KEY_NAME_RESPONSE_DATA] as? Data,
				   let requestUrl = data[KEY_NAME_URL] as? URL {

					// Parse the URL.
					let components = URLComponents(url: requestUrl, resolvingAgainstBaseURL: false)!

					if let queryItems = components.queryItems {
						var activityId: String?
						var exportFormat: String?
						
						// Grab the activity ID and file format out of the URL parameters.
						for queryItem in queryItems {
							if queryItem.name == PARAM_ACTIVITY_ID {
								activityId = queryItem.value!
							}
							else if queryItem.name == PARAM_EXPORT_FORMAT {
								exportFormat = queryItem.value!
							}
						}
						
						if activityId != nil && exportFormat != nil {
							let directory = NSTemporaryDirectory()
							let fileName = NSUUID().uuidString + "." + exportFormat!
							let fullUrl = NSURL.fileURL(withPathComponents: [directory, fileName])
							
							if fullUrl != nil {
								try responseData.write(to: fullUrl!)

								// Only one thread should do this at a time.
								self.stateLock.lock()

								// Bring the file into the local database.
								if ImportActivityFromFile(fullUrl?.absoluteString, "", activityId) {

									// The activity is now in the database, load it up so we can do things.
									CreateHistoricalActivityObject(activityId)
									LoadHistoricalActivity(activityId)
									LoadAllHistoricalActivitySensorData(activityId)

									// Add relevant data to HealthKit.
									importActivityToHealthKit(activityId: activityId!)

									// Keep track of the most recently synched activity.
									var startTime: time_t = 0
									var endTime: time_t = 0
									if GetHistoricalActivityStartAndEndTime(activityId, &startTime, &endTime) {
										let lastSynchedActivityTime = Preferences.lastServerImportTime()
										
										if startTime > lastSynchedActivityTime {
											Preferences.setLastServerImportTime(value: startTime)
										}
									}
									else {
										NSLog("GetHistoricalActivityStartAndEndTime failed!")
									}

									// Delete any cached data.
									FreeHistoricalActivityObject(activityId)
									FreeHistoricalActivitySensorData(activityId)
								}
								else {
									NSLog("Import failed!")
								}

								// Allow other threads to finish importing.
								self.stateLock.unlock()

								try FileManager.default.removeItem(at: fullUrl!)
							}
							else {
								NSLog("Cannot find the downloaded file!")
							}
						}
						else {
							NSLog("Activity ID and Format not provided!")
						}
					}
					else {
						NSLog("Cannot parse downloaded file URL!")
					}
				}
				else {
					NSLog("Response URL or Response Data not provided!")
				}
			}
		}
		catch {
			NSLog(error.localizedDescription)
		}
	}
	
	/// @brief Callback in response to a gear list request.
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
	
	/// @brief This method is called when the server returns an updated race list.
	@objc func raceListUpdated(notification: NSNotification) {
		do {
			if let data = notification.object as? Dictionary<String, AnyObject> {
				if let responseData = data[KEY_NAME_RESPONSE_DATA] as? Data {
					let workoutsVM: WorkoutsVM = WorkoutsVM()
					let raceList = try JSONSerialization.jsonObject(with: responseData, options: []) as! [Any]
					
					for race in raceList {
						if let raceDict = race as? Dictionary<String, AnyObject> {
							workoutsVM.importRaceCalendar(dict: raceDict)
						}
					}
				}
			}
		}
		catch {
			NSLog(error.localizedDescription)
		}
	}

	/// @brief This method is called when the server returns an updated workout.
	@objc func plannedWorkoutsUpdated(notification: NSNotification) {
		do {
			if let data = notification.object as? Dictionary<String, AnyObject> {
				if let responseData = data[KEY_NAME_RESPONSE_DATA] as? Data {
					let workoutsVM: WorkoutsVM = WorkoutsVM()
					let workoutsList = try JSONSerialization.jsonObject(with: responseData, options: []) as! [Any]
					
					if workoutsList.count > 0 {
						
						// Remove any existing workouts.
						if workoutsVM.deleteAllWorkouts() {
							for workout in workoutsList {
								if let workoutDict = workout as? Dictionary<String, AnyObject> {
									try workoutsVM.importWorkoutFromDict(dict: workoutDict)
								}
							}
						}
						else {
							NSLog("Error deleting existing workout suggestions.")
						}
					}
				}
			}
		}
		catch {
			NSLog(error.localizedDescription)
		}
	}

	/// @brief This method is called when the server returns interval sessions.
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

	/// @brief This method is called when the server returns pace plans.
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
	
	/// @brief The app requests a list of activities since a particular timestamp; this method is called for the response, which is a list of activit IDs
	@objc func unsynchedActivitiesListReceived(notification: NSNotification) {
		do {
			if let data = notification.object as? Dictionary<String, AnyObject> {
				if let responseData = data[KEY_NAME_RESPONSE_DATA] as? Data {
					let activitiesIdList = try JSONSerialization.jsonObject(with: responseData, options: []) as! [String]

					for activityId in activitiesIdList {
						if IsActivityInDatabase(activityId) == false {
							let _ = ApiClient.shared.exportActivity(activityId: activityId)
						}
					}
				}
			}
		}
		catch {
			NSLog(error.localizedDescription)
		}
	}
	
	/// @brief The app sends a list of activities to the server; this method is called for each response.
	@objc func hasActivityResponse(notification: NSNotification) {
		do {
			if let data = notification.object as? Dictionary<String, AnyObject> {
				if let responseData = data[KEY_NAME_RESPONSE_DATA] as? Data {
					if let responseDict = try JSONSerialization.jsonObject(with: responseData, options: []) as? Dictionary<String, AnyObject> {
						let app = CommonApp.shared
						let activityId = responseDict[PARAM_ACTIVITY_ID] as! String
						let codeStr = responseDict[PARAM_CODE]
						let codeNum = codeStr as? UInt32
						let code = ActivityMatch(rawValue: codeNum!)
						
						switch (code) {
						case ACTIVITY_MATCH_CODE_NO_ACTIVITY:
							// Send the activity - server has never heard of this activity.
							Task.init {
								do {
									try await app.exportActivityToWeb(activityId: activityId)
								} catch {
								}
							}
							break
						case ACTIVITY_MATCH_CODE_HASH_NOT_COMPUTED:
							// Mark it as synced - server already has this activity, but it could be different.
							let _ = app.markAsSynchedToWeb(activityId: activityId)
							break
						case ACTIVITY_MATCH_CODE_HASH_DOES_NOT_MATCH:
							// Mark it as synced - server already has this activity, but it is different
							let _ = app.markAsSynchedToWeb(activityId: activityId)
							break
						case ACTIVITY_MATCH_CODE_HASH_MATCHES:
							// Mark it as synced - server already has this activity
							let _ = app.markAsSynchedToWeb(activityId: activityId)
							break
						case ACTIVITY_MATCH_CODE_HASH_NOT_PROVIDED:
							// Mark it as synced - server already has this activity, but it could be different.
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
	
	/// @brief This method is called in when the server returns activity metadata.
	@objc func activityMetadataReceived(notification: NSNotification) {
		do {
			if let data = notification.object as? Dictionary<String, AnyObject> {
				if let responseData = data[KEY_NAME_RESPONSE_DATA] as? Data {
					if let responseDict = try JSONSerialization.jsonObject(with: responseData, options: []) as? Dictionary<String, Any> {
						let activityId = responseDict[PARAM_ACTIVITY_ID] as? String
						
						// If we were sent the activity name, description, or tags then update it in the database.
						if activityId != nil {
							let activityName = responseDict[PARAM_ACTIVITY_NAME]
							let activityDesc = responseDict[PARAM_ACTIVITY_DESCRIPTION]
							let tags = responseDict[PARAM_ACTIVITY_TAGS]
							
							if activityName != nil {
								if UpdateActivityName(activityId, activityName as? String) == false {
									NSLog("Update activity name failed.")
								}
							}
							if activityDesc != nil {
								if UpdateActivityDescription(activityId, activityDesc as? String) == false {
									NSLog("Update activity description failed.")
								}
							}
							if tags != nil {
								let tagsList = tags as? [String]
								for tag in tagsList! {
									if !HasTag(activityId, tag) {
										if CreateTag(activityId, tag) == false {
											NSLog("Create tag failed.")
										}
									}
								}
							}
							
							let updatedNotification = Notification(name: Notification.Name(rawValue: NOTIFICATION_NAME_ACTIVITY_METADATA_UPDATED), object: responseDict)
							NotificationCenter.default.post(updatedNotification)
						}
					}
				}
			}
		}
		catch {
			NSLog(error.localizedDescription)
		}
	}
	
	/// @brief This method is called in response to an activity stopped notification.
	@objc func activityStopped(notification: NSNotification) {
		
		do {
			if let notificationData = notification.object as? Dictionary<String, Any> {
				if  let activityId = notificationData[KEY_NAME_ACTIVITY_ID] as? String,
					let activityType = notificationData[KEY_NAME_ACTIVITY_TYPE] as? String {
					
					var description: String = activityType

					let activityNamePtr = UnsafeRawPointer(RetrieveActivityName(activityId))
					
					defer {
						if activityNamePtr != nil {
							activityNamePtr!.deallocate()
						}
					}
					
					if activityNamePtr != nil {
						let activityName = String(cString: activityNamePtr!.assumingMemoryBound(to: CChar.self))
						description += " "
						description = activityName
					}
					
					Preferences.setMostRecentActivityDescription(value: description)
				}
			}
		}
	}
}
