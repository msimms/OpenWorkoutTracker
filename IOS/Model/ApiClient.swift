//
//  ApiClient.swift
//  Created by Michael Simms on 10/9/22.
//

import Foundation

struct UnsynchedActivitiesCallbackType {
	var ids: Array<String>
}

func unsynchedActivitiesCallback(destination: Optional<UnsafePointer<Int8>>, context: Optional<UnsafeMutableRawPointer>) {
	let activityId = String(cString: UnsafeRawPointer(destination!).assumingMemoryBound(to: CChar.self))
	let typedPointer = context!.bindMemory(to: UnsynchedActivitiesCallbackType.self, capacity: 1)
	typedPointer.pointee.ids.append(activityId)
}

class ApiClient : ObservableObject {
	static let shared = ApiClient()
	@Published var loggedIn = false
	
	/// Singleton constructor
	private init() {
	}
	
	func makeRequest(url: String, method: String, data: Dictionary<String,Any>) -> Bool {

		guard Preferences.isFeatureEnabled(feature: FEATURE_BROADCAST) else {
			return true
		}

		// If we're not supposed to be using the broadcast functionality then turn around right here.
		if !Preferences.shouldBroadcastToServer() {
			return true
		}

		do {
			var request = URLRequest(url: URL(string: url)!)
			request.timeoutInterval = 30.0
			request.allowsExpensiveNetworkAccess = true
			request.httpMethod = method
			
			if data.count > 0 {
				
				// POST method, put the dictionary in the HTTP body
				if method == "POST" {
					let jsonData = try JSONSerialization.data(withJSONObject: data, options: [])
					let text = String(data: jsonData, encoding: String.Encoding.ascii)!
					let postLength = String(format: "%lu", text.count)
					
					request.setValue(postLength, forHTTPHeaderField:"Content-Length")
					request.setValue("application/json", forHTTPHeaderField:"Content-Type")
					request.httpBody = text.data(using:.utf8)
				}
				
				// GET method, append the parameters to the URL.
				else if method == "GET" {
					var newUrl = url + "?"
					for datum in data {
						newUrl = newUrl + datum.key
						newUrl = newUrl + "="
						newUrl = newUrl + String(describing: datum.value)
					}
					request.url = URL(string: newUrl)
				}
			}
			
			let session = URLSession.shared
			let dataTask = session.dataTask(with: request) { responseData, responseCode, error in
				if let httpResponse = responseCode as? HTTPURLResponse {

					var downloadedData: Dictionary<String, Any> = [:]
					downloadedData[KEY_NAME_URL] = url
					downloadedData[KEY_NAME_RESPONSE_CODE] = httpResponse
					downloadedData[KEY_NAME_RESPONSE_DATA] = responseData

					// Handle anything related to authorization. Trigger the notification no matter what so that
					// we can display error messages, etc.
					if url.contains(REMOTE_API_IS_LOGGED_IN_URL) {
						let notification = Notification(name: Notification.Name(rawValue: NOTIFICATION_NAME_LOGIN_CHECKED), object: downloadedData)
						NotificationCenter.default.post(notification)
					}
					else if url.contains(REMOTE_API_LOGIN_URL) {
						let notification = Notification(name: Notification.Name(rawValue: NOTIFICATION_NAME_LOGIN_PROCESSED), object: downloadedData)
						NotificationCenter.default.post(notification)
					}
					else if url.contains(REMOTE_API_CREATE_LOGIN_URL) {
						let notification = Notification(name: Notification.Name(rawValue: NOTIFICATION_NAME_CREATE_LOGIN_PROCESSED), object: downloadedData)
						NotificationCenter.default.post(notification)
					}
					else if url.contains(REMOTE_API_LOGOUT_URL) {
						let notification = Notification(name: Notification.Name(rawValue: NOTIFICATION_NAME_LOGGED_OUT), object: downloadedData)
						NotificationCenter.default.post(notification)
					}

					// For non-auth checks, only call trigger the notifications if we get an HTTP Ok error code.
					else if httpResponse.statusCode == 200 {

						if url.contains(REMOTE_API_LIST_FRIENDS_URL) {
							let notification = Notification(name: Notification.Name(rawValue: NOTIFICATION_NAME_FRIENDS_LIST_UPDATED), object: downloadedData)
							NotificationCenter.default.post(notification)
						}
						else if url.contains(REMOTE_API_LIST_GEAR_URL) {
							let notification = Notification(name: Notification.Name(rawValue: NOTIFICATION_NAME_GEAR_LIST_UPDATED), object: downloadedData)
							NotificationCenter.default.post(notification)
						}
						else if url.contains(REMOTE_API_LIST_PLANNED_WORKOUTS_URL) {
							let notification = Notification(name: Notification.Name(rawValue: NOTIFICATION_NAME_PLANNED_WORKOUTS_UPDATED), object: downloadedData)
							NotificationCenter.default.post(notification)
						}
						else if url.contains(REMOTE_API_REQUEST_WORKOUT_DETAILS_URL) {
							let notification = Notification(name: Notification.Name(rawValue: NOTIFICATION_NAME_PLANNED_WORKOUT_UPDATED), object: downloadedData)
							NotificationCenter.default.post(notification)
						}
						else if url.contains(REMOTE_API_LIST_INTERVAL_WORKOUTS_URL) {
							let notification = Notification(name: Notification.Name(rawValue: NOTIFICATION_NAME_INTERVAL_SESSIONS_UPDATED), object: downloadedData)
							NotificationCenter.default.post(notification)
						}
						else if url.contains(REMOTE_API_LIST_PACE_PLANS_URL) {
							let notification = Notification(name: Notification.Name(rawValue: NOTIFICATION_NAME_PACE_PLANS_UPDATED), object: downloadedData)
							NotificationCenter.default.post(notification)
						}
						else if url.contains(REMOTE_API_HAS_ACTIVITY_URL) {
							let notification = Notification(name: Notification.Name(rawValue: NOTIFICATION_NAME_HAS_ACTIVITY_RESPONSE), object: downloadedData)
							NotificationCenter.default.post(notification)
						}
						else if url.contains(REMOTE_API_REQUEST_ACTIVITY_METADATA_URL) {
							let notification = Notification(name: Notification.Name(rawValue: NOTIFICATION_NAME_ACTIVITY_METADATA), object: downloadedData)
							NotificationCenter.default.post(notification)
						}
						else if url.contains(REMOTE_API_REQUEST_TO_FOLLOW_URL) {
							let notification = Notification(name: Notification.Name(rawValue: NOTIFICATION_NAME_REQUEST_TO_FOLLOW_RESULT), object: downloadedData)
							NotificationCenter.default.post(notification)
						}
						else if url.contains(REMOTE_API_EXPORT_ACTIVITY_URL) {
							let notification = Notification(name: Notification.Name(rawValue: NOTIFICATION_NAME_DOWNLOADED_ACTIVITY), object: downloadedData)
							NotificationCenter.default.post(notification)
						}
						else if url.contains(REMOTE_API_DELETE_ACTIVITY_URL) {
						}
						else if url.contains(REMOTE_API_CREATE_TAG_URL) {
						}
						else if url.contains(REMOTE_API_DELETE_TAG_URL) {
						}
						else if url.contains(REMOTE_API_CLAIM_DEVICE_URL) {
						}
						else if url.contains(REMOTE_API_UPDATE_ACTIVITY_METADATA_URL) {
						}
						else if url.contains(REMOTE_API_LIST_UNSYNCHED_ACTIVITIES_URL) {
							let notification = Notification(name: Notification.Name(rawValue: NOTIFICATION_NAME_UNSYNCHED_ACTIVITIES_LIST), object: downloadedData)
							NotificationCenter.default.post(notification)
						}
						else if url.contains(REMOTE_API_UPLOAD_ACTIVITY_FILE_URL) {
						}
						else if url.contains(REMOTE_API_CREATE_INTERVAL_WORKOUT_URL) {
						}
						else if url.contains(REMOTE_API_CREATE_PACE_PLAN_URL) {
						}
					}
					else {
						NSLog("Error code received from the server for " + url)
					}
				}
			}
			
			dataTask.resume()
			return true
		}
		catch {
		}
		return false
	}
	
	func login(username: String, password: String) -> Bool {
		var postDict: Dictionary<String, String> = [:]
		postDict[PARAM_USERNAME] = username
		postDict[PARAM_PASSWORD] = password
		postDict[PARAM_DEVICE] = Preferences.uuid()
		
		let urlStr = String(format: "%@://%@/%@", Preferences.broadcastProtocol(), Preferences.broadcastHostName(), REMOTE_API_LOGIN_URL)
		return self.makeRequest(url: urlStr, method: "POST", data: postDict)
	}
	
	func createLogin(username: String, password1: String, password2: String, realname: String) -> Bool {
		var postDict: Dictionary<String, String> = [:]
		postDict[PARAM_USERNAME] = username
		postDict[PARAM_PASSWORD1] = password1
		postDict[PARAM_PASSWORD2] = password2
		postDict[PARAM_REALNAME] = realname
		postDict[PARAM_DEVICE] = Preferences.uuid()
		
		let urlStr = String(format: "%@://%@/%@", Preferences.broadcastProtocol(), Preferences.broadcastHostName(), REMOTE_API_CREATE_LOGIN_URL)
		return self.makeRequest(url: urlStr, method: "POST", data: postDict)
	}
	
	func isLoggedIn() -> Bool {
		let urlStr = String(format: "%@://%@/%@", Preferences.broadcastProtocol(), Preferences.broadcastHostName(), REMOTE_API_IS_LOGGED_IN_URL)
		return self.makeRequest(url: urlStr, method: "GET", data: [:])
	}
	
	func logout() -> Bool {
		let urlStr = String(format: "%@://%@/%@", Preferences.broadcastProtocol(), Preferences.broadcastHostName(), REMOTE_API_LOGOUT_URL)
		return self.makeRequest(url: urlStr, method: "POST", data: [:])
	}
	
	func listFriends() -> Bool {
		let urlStr = String(format: "%@://%@/%@", Preferences.broadcastProtocol(), Preferences.broadcastHostName(), REMOTE_API_LIST_FRIENDS_URL)
		return self.makeRequest(url: urlStr, method: "GET", data: [:])
	}
	
	func listGear() -> Bool {
		let urlStr = String(format: "%@://%@/%@", Preferences.broadcastProtocol(), Preferences.broadcastHostName(), REMOTE_API_LIST_GEAR_URL)
		return self.makeRequest(url: urlStr, method: "GET", data: [:])
	}
	
	func listPlannedWorkouts() -> Bool {
		let urlStr = String(format: "%@://%@/%@", Preferences.broadcastProtocol(), Preferences.broadcastHostName(), REMOTE_API_LIST_PLANNED_WORKOUTS_URL)
		return self.makeRequest(url: urlStr, method: "GET", data: [:])
	}
	
	func listIntervalSessions() -> Bool {
		let urlStr = String(format: "%@://%@/%@", Preferences.broadcastProtocol(), Preferences.broadcastHostName(), REMOTE_API_LIST_INTERVAL_WORKOUTS_URL)
		return self.makeRequest(url: urlStr, method: "GET", data: [:])
	}
	
	func listPacePlans() -> Bool {
		let urlStr = String(format: "%@://%@/%@", Preferences.broadcastProtocol(), Preferences.broadcastHostName(), REMOTE_API_LIST_PACE_PLANS_URL)
		return self.makeRequest(url: urlStr, method: "GET", data: [:])
	}
	
	func requestActivityMetadata(activityId: String) -> Bool {
		var postDict: Dictionary<String, String> = [:]
		postDict[PARAM_ACTIVITY_ID] = activityId
		
		let urlStr = String(format: "%@://%@/%@", Preferences.broadcastProtocol(), Preferences.broadcastHostName(), REMOTE_API_REQUEST_ACTIVITY_METADATA_URL)
		return self.makeRequest(url: urlStr, method: "GET", data: postDict)
	}
	
	func requestWorkoutDetails(workoutId: String) -> Bool {
		var postDict: Dictionary<String, String> = [:]
		postDict[PARAM_WORKOUT_ID] = workoutId
		postDict["format"] = "json"
		
		let urlStr = String(format: "%@://%@/%@", Preferences.broadcastProtocol(), Preferences.broadcastHostName(), REMOTE_API_REQUEST_WORKOUT_DETAILS_URL)
		return self.makeRequest(url: urlStr, method: "GET", data: postDict)
	}
	
	func requestToFollow(target: String) -> Bool {
		var postDict: Dictionary<String, String> = [:]
		postDict[PARAM_TARGET_EMAIL] = target
		
		let urlStr = String(format: "%@://%@/%@", Preferences.broadcastProtocol(), Preferences.broadcastHostName(), REMOTE_API_REQUEST_TO_FOLLOW_URL)
		return self.makeRequest(url: urlStr, method: "GET", data: postDict)
	}
	
	func exportActivity(activityId: String) -> Bool {
		var postDict: Dictionary<String, String> = [:]
		postDict[PARAM_ACTIVITY_ID] = activityId
		postDict[PARAM_EXPORT_FORMAT] = "tcx"

		let urlStr = String(format: "%@://%@/%@", Preferences.broadcastProtocol(), Preferences.broadcastHostName(), REMOTE_API_EXPORT_ACTIVITY_URL)
		return self.makeRequest(url: urlStr, method: "GET", data: postDict)
	}

	func deleteActivity(activityId: String) -> Bool {
		var postDict: Dictionary<String, String> = [:]
		postDict[PARAM_ACTIVITY_ID] = activityId
		
		let urlStr = String(format: "%@://%@/%@", Preferences.broadcastProtocol(), Preferences.broadcastHostName(), REMOTE_API_DELETE_ACTIVITY_URL)
		return self.makeRequest(url: urlStr, method: "POST", data: postDict)
	}
	
	func createTag(tag: String, activityId: String) -> Bool {
		var postDict: Dictionary<String, String> = [:]
		postDict[PARAM_TAG] = tag
		postDict[PARAM_ACTIVITY_ID] = activityId
		
		let urlStr = String(format: "%@://%@/%@", Preferences.broadcastProtocol(), Preferences.broadcastHostName(), REMOTE_API_CREATE_TAG_URL)
		return self.makeRequest(url: urlStr, method: "POST", data: postDict)
	}
	
	func deleteTag(tag: String, activityId: String) -> Bool {
		var postDict: Dictionary<String, String> = [:]
		postDict[PARAM_TAG] = tag
		postDict[PARAM_ACTIVITY_ID] = activityId
		
		let urlStr = String(format: "%@://%@/%@", Preferences.broadcastProtocol(), Preferences.broadcastHostName(), REMOTE_API_DELETE_TAG_URL)
		return self.makeRequest(url: urlStr, method: "POST", data: postDict)
	}
	
	func claimDevice(deviceId: String) -> Bool {
		var postDict: Dictionary<String, String> = [:]
		postDict[PARAM_DEVICE_ID2] = deviceId

		let urlStr = String(format: "%@://%@/%@", Preferences.broadcastProtocol(), Preferences.broadcastHostName(), REMOTE_API_CLAIM_DEVICE_URL)
		return self.makeRequest(url: urlStr, method: "POST", data: postDict)
	}
	
	func setActivityName(activityId: String, name: String) -> Bool {
		var postDict: Dictionary<String, String> = [:]
		postDict[PARAM_ACTIVITY_ID] = activityId
		postDict[PARAM_ACTIVITY_NAME] = name
		
		let urlStr = String(format: "%@://%@/%@", Preferences.broadcastProtocol(), Preferences.broadcastHostName(), REMOTE_API_UPDATE_ACTIVITY_METADATA_URL)
		return self.makeRequest(url: urlStr, method: "POST", data: postDict)
	}
	
	func setActivityType(activityId: String, type: String) -> Bool {
		var postDict: Dictionary<String, String> = [:]
		postDict[PARAM_ACTIVITY_ID] = activityId
		postDict[PARAM_ACTIVITY_TYPE] = type
		
		let urlStr = String(format: "%@://%@/%@", Preferences.broadcastProtocol(), Preferences.broadcastHostName(), REMOTE_API_UPDATE_ACTIVITY_METADATA_URL)
		return self.makeRequest(url: urlStr, method: "POST", data: postDict)
	}
	
	func setActivityDescription(activityId: String, description: String) -> Bool {
		var postDict: Dictionary<String, String> = [:]
		postDict[PARAM_ACTIVITY_ID] = activityId
		postDict[PARAM_ACTIVITY_DESCRIPTION] = description
		
		let urlStr = String(format: "%@://%@/%@", Preferences.broadcastProtocol(), Preferences.broadcastHostName(), REMOTE_API_UPDATE_ACTIVITY_METADATA_URL)
		return self.makeRequest(url: urlStr, method: "POST", data: postDict)
	}
	
	func requestUpdatesSince(timestamp: Date) -> Bool {
		var postDict: Dictionary<String, String> = [:]
		postDict[PARAM_TIMESTAMP] = String(UInt64(timestamp.timeIntervalSince1970))
		
		let urlStr = String(format: "%@://%@/%@", Preferences.broadcastProtocol(), Preferences.broadcastHostName(), REMOTE_API_LIST_UNSYNCHED_ACTIVITIES_URL)
		return self.makeRequest(url: urlStr, method: "GET", data: postDict)
	}
	
	func hasActivity(activityId: String) -> Bool {
		var postDict: Dictionary<String, String> = [:]
		postDict[PARAM_ACTIVITY_ID] = activityId
		
		let urlStr = String(format: "%@://%@/%@", Preferences.broadcastProtocol(), Preferences.broadcastHostName(), REMOTE_API_HAS_ACTIVITY_URL)
		return self.makeRequest(url: urlStr, method: "GET", data: postDict)
	}
	
	func sendActivity(activityId: String, name: String, contents: Data) -> Bool {
		let base64Encoded = contents.base64EncodedString()
		var postDict: Dictionary<String, String> = [:]
		postDict[PARAM_ACTIVITY_ID] = activityId
		postDict[PARAM_UPLOADED_FILE_NAME] = name
		postDict[PARAM_UPLOADED_FILE_DATA] = base64Encoded
		
		let urlStr = String(format: "%@://%@/%@", Preferences.broadcastProtocol(), Preferences.broadcastHostName(), REMOTE_API_UPLOAD_ACTIVITY_FILE_URL)
		return self.makeRequest(url: urlStr, method: "POST", data: postDict)
	}
	
	func sendIntervalSession(description: Dictionary<String, String>) -> Bool {
		let urlStr = String(format: "%@://%@/%@", Preferences.broadcastProtocol(), Preferences.broadcastHostName(), REMOTE_API_CREATE_INTERVAL_WORKOUT_URL)
		return self.makeRequest(url: urlStr, method: "POST", data: description)
	}
	
	func sendPacePlan(description: Dictionary<String, Any>) -> Bool {
		let urlStr = String(format: "%@://%@/%@", Preferences.broadcastProtocol(), Preferences.broadcastHostName(), REMOTE_API_CREATE_PACE_PLAN_URL)
		return self.makeRequest(url: urlStr, method: "POST", data: description)
	}
	
	func sendPacePlansToServer() -> Bool {
		if InitializePacePlanList() {
			
			var pacePlanIndex = 0
			var done = false
			var result = true
			
			while !done {
				if let rawPacePlanDescPtr = RetrievePacePlanAsJSON(pacePlanIndex) {
					let pacePlanDescPtr = UnsafeRawPointer(rawPacePlanDescPtr)
					let pacePlanDesc = String(cString: pacePlanDescPtr.assumingMemoryBound(to: CChar.self))
					let summaryDict = try! JSONSerialization.jsonObject(with: Data(pacePlanDesc.utf8), options: []) as! [String:Any]

					result = result && self.sendPacePlan(description: summaryDict)
					pacePlanIndex += 1
				}
				else {
					done = true
				}
			}
			return result
		}
		return false
	}

	func sendUpdatedUserHeight(timestamp: Date) -> Bool {
		var postDict: Dictionary<String,String> = [:]
		postDict[PARAM_USER_HEIGHT] = String(format:"%f", Preferences.heightCm())
		postDict[PARAM_TIMESTAMP] = String(format:"%llu", time_t(timestamp.timeIntervalSince1970))

		let urlStr = String(format: "%@://%@/%@", Preferences.broadcastProtocol(), Preferences.broadcastHostName(), REMOTE_API_UPDATE_PROFILE_URL)
		return self.makeRequest(url: urlStr, method: "POST", data: postDict)
	}

	func sendUpdatedUserWeight(timestamp: Date) -> Bool {
		var postDict: Dictionary<String,String> = [:]
		postDict[PARAM_USER_WEIGHT] = String(format:"%f", Preferences.weightKg())
		postDict[PARAM_TIMESTAMP] = String(format:"%llu", time_t(timestamp.timeIntervalSince1970))

		let urlStr = String(format: "%@://%@/%@", Preferences.broadcastProtocol(), Preferences.broadcastHostName(), REMOTE_API_UPDATE_PROFILE_URL)
		return self.makeRequest(url: urlStr, method: "POST", data: postDict)
	}

	func sendUpdatedUserBirthDate(timestamp: Date) -> Bool {
		var postDict: Dictionary<String,String> = [:]
		postDict[PARAM_USER_WEIGHT] = String(format:"%llu", Preferences.birthDate())
		postDict[PARAM_TIMESTAMP] = String(format:"%llu", time_t(timestamp.timeIntervalSince1970))

		let urlStr = String(format: "%@://%@/%@", Preferences.broadcastProtocol(), Preferences.broadcastHostName(), REMOTE_API_UPDATE_PROFILE_URL)
		return self.makeRequest(url: urlStr, method: "POST", data: postDict)
	}

	func sendUpdatedUserFtp(timestamp: Date) -> Bool {
		var postDict: Dictionary<String,String> = [:]
		postDict[PARAM_USER_FTP] = String(format:"%f", Preferences.userDefinedFtp())
		postDict[PARAM_TIMESTAMP] = String(format:"%llu", time_t(timestamp.timeIntervalSince1970))

		let urlStr = String(format: "%@://%@/%@", Preferences.broadcastProtocol(), Preferences.broadcastHostName(), REMOTE_API_UPDATE_PROFILE_URL)
		return self.makeRequest(url: urlStr, method: "POST", data: postDict)
	}

	func sendUpdatedUserMaxHr(timestamp: Date) -> Bool {
		var postDict: Dictionary<String,String> = [:]
		postDict[PARAM_USER_MAX_HR] = String(format:"%f", Preferences.userDefinedMaxHr())
		postDict[PARAM_TIMESTAMP] = String(format:"%llu", time_t(timestamp.timeIntervalSince1970))
		
		let urlStr = String(format: "%@://%@/%@", Preferences.broadcastProtocol(), Preferences.broadcastHostName(), REMOTE_API_UPDATE_PROFILE_URL)
		return self.makeRequest(url: urlStr, method: "POST", data: postDict)
	}

	func sendUpdatedUserRestingHr(timestamp: Date) -> Bool {
		var postDict: Dictionary<String,String> = [:]
		postDict[PARAM_USER_RESTING_HR] = String(format:"%f", Preferences.restingHr())
		postDict[PARAM_TIMESTAMP] = String(format:"%llu", timestamp.timeIntervalSince1970)
		
		let urlStr = String(format: "%@://%@/%@", Preferences.broadcastProtocol(), Preferences.broadcastHostName(), REMOTE_API_UPDATE_PROFILE_URL)
		return self.makeRequest(url: urlStr, method: "POST", data: postDict)
	}

	func sendUserDetailsToServer() -> Bool {
		var timestamp: time_t = 0
		var weightKg: Double = 0.0

		if GetUsersCurrentWeight(&timestamp, &weightKg) {
			return self.sendUpdatedUserWeight(timestamp: Date(timeIntervalSince1970: TimeInterval(timestamp)))
		}
		return true // User may not have any weight data
	}

	func sendMissingActivitiesToServer() -> Bool {
		// List activities that haven't been synched to the server.
		let pointer = UnsafeMutablePointer<UnsynchedActivitiesCallbackType>.allocate(capacity: 1)
		
		defer {
			pointer.deinitialize(count: 1)
			pointer.deallocate()
		}
		
		pointer.pointee = UnsynchedActivitiesCallbackType(ids: [])
		GetActivityAttributeNames(attributeNameCallback, pointer)

		if RetrieveActivityIdsNotSynchedToWeb(unsynchedActivitiesCallback, pointer) {
			let activityIds = pointer.pointee.ids
			var result = true

			// For each activity that isn't listed as being synced to the web, offer it to the web server.
			for activityId in activityIds {

				// Ask the server if it wants this activity. Response is handled by handleHasActivityResponse.
				result = result && self.hasActivity(activityId: activityId)
			}
			
			return result
		}
		return false
	}

	/// @brief Request the latest of everything from the server.  Also, send the server anything it is missing as well.
	func syncWithServer() -> Bool {
		var result = true

		if Preferences.shouldBroadcastToServer() && self.loggedIn {

/*			guard let _ = SCNetworkReachabilityCreateWithName(kCFAllocatorDefault, Preferences.broadcastHostName()) else {
				return false
			} */

			// Rate limit the server synchronizations. Let's not be spammy.
			let now = time(nil)
			let lastServerSync = Preferences.lastServerSyncTime()
			if now - lastServerSync > 60 {
				let deviceId = Preferences.uuid()
				if deviceId != nil {
					result = self.claimDevice(deviceId: deviceId!)
					result = result && self.listGear()
					result = result && self.listPlannedWorkouts()
					result = result && self.listIntervalSessions()
					result = result && self.listPacePlans()
					result = result && self.sendUserDetailsToServer()
					result = result && self.sendMissingActivitiesToServer()
					result = result && self.sendPacePlansToServer()
					
					result = result && self.requestUpdatesSince(timestamp: Date(timeIntervalSince1970: TimeInterval(lastServerSync)))
					Preferences.setLastServerSyncTime(value: now)
				}
			}
		}
		return result
	}
}
