//
//  ApiClient.swift
//  Created by Michael Simms on 10/9/22.
//

import Foundation

enum LoginStatus : Int {
	case LOGIN_STATUS_UNKNOWN = 0
	case LOGIN_STATUS_SUCCESS
	case LOGIN_STATUS_FAILURE
}

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
	@Published var loginStatus: LoginStatus = LoginStatus.LOGIN_STATUS_UNKNOWN

	/// Singleton constructor
	private init() {
	}
	
	func isCurrentlyLoggedIn() -> Bool {
		return self.loginStatus == LoginStatus.LOGIN_STATUS_SUCCESS
	}

	func extractActivityIdParamFromUrl(requestUrl: URL) -> String? {
		let components = URLComponents(url: requestUrl, resolvingAgainstBaseURL: false)!
		
		if let queryItems = components.queryItems {
			for queryItem in queryItems {
				if queryItem.name == PARAM_ACTIVITY_ID {
					return queryItem.value!
				}
			}
		}
		return nil
	}

	func makeRequest(url: String, method: String, data: Dictionary<String, Any>, onResponse: @escaping (Data?, HTTPURLResponse) -> Void) -> Bool {

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
					let jsonString = String(data: jsonData, encoding: String.Encoding.utf8)!
					let postLength = String(format: "%lu", jsonString.count)
					
					request.setValue(postLength, forHTTPHeaderField: "Content-Length")
					request.setValue("application/json", forHTTPHeaderField: "Content-Type")
					request.httpBody = jsonString.data(using:.utf8)
				}
				
				// GET method, append the parameters to the URL.
				else if method == "GET" || method == "DELETE" {
					var newUrl = url + "?"
					var first = true

					for datum in data {
						if first == false {
							newUrl = newUrl + "&"
						}
						newUrl = newUrl + datum.key.replacingOccurrences(of: " ", with: "%20")
						newUrl = newUrl + "="
						newUrl = newUrl + String(describing: datum.value).replacingOccurrences(of: " ", with: "%20")
						first = false
					}
					request.url = URL(string: newUrl)
				}
			}
			
			let session = URLSession.shared
			let dataTask = session.dataTask(with: request) { responseData, responseCode, error in
				if let httpResponseCode = responseCode as? HTTPURLResponse {

					// Handle anything related to authorization. Trigger the callback no matter what so that
					// we can display error messages, etc.
					if url.contains(REMOTE_API_IS_LOGGED_IN_URL) {
						onResponse(responseData, httpResponseCode)
					}
					else if url.contains(REMOTE_API_LOGIN_URL) {
						onResponse(responseData, httpResponseCode)
					}
					else if url.contains(REMOTE_API_CREATE_LOGIN_URL) {
						onResponse(responseData, httpResponseCode)
					}
					else if url.contains(REMOTE_API_LOGOUT_URL) {
						onResponse(responseData, httpResponseCode)
					}

					// For non-auth checks, only call trigger the callback if we get an HTTP Ok error code.
					else if httpResponseCode.statusCode == 200 {

						if url.contains(REMOTE_API_LIST_FRIENDS_URL) {
							onResponse(responseData, httpResponseCode)
						}
						else if url.contains(REMOTE_API_LIST_GEAR_URL) {
							onResponse(responseData, httpResponseCode)
						}
						else if url.contains(REMOTE_API_LIST_RACES_URL) {
							onResponse(responseData, httpResponseCode)
						}
						else if url.contains(REMOTE_API_LIST_PLANNED_WORKOUTS_URL) {
							onResponse(responseData, httpResponseCode)
						}
						else if url.contains(REMOTE_API_LIST_INTERVAL_WORKOUTS_URL) {
							onResponse(responseData, httpResponseCode)
						}
						else if url.contains(REMOTE_API_LIST_PACE_PLANS_URL) {
							onResponse(responseData, httpResponseCode)
						}
						else if url.contains(REMOTE_API_HAS_ACTIVITY_URL) {
							onResponse(responseData, httpResponseCode)
						}
						else if url.contains(REMOTE_API_REQUEST_ACTIVITY_METADATA_URL) {
							onResponse(responseData, httpResponseCode)
						}
						else if url.contains(REMOTE_API_REQUEST_TO_FOLLOW_URL) {
							onResponse(responseData, httpResponseCode)
						}
						else if url.contains(REMOTE_API_REQUEST_USER_SETTINGS_URL) {
							onResponse(responseData, httpResponseCode)
						}
						else if url.contains(REMOTE_API_EXPORT_ACTIVITY_URL) {
							onResponse(responseData, httpResponseCode)
						}
						else if url.contains(REMOTE_API_LIST_UNSYNCHED_ACTIVITIES_URL) {
							onResponse(responseData, httpResponseCode)
						}
						else if url.contains(REMOTE_API_LIST_ACTIVITY_PHOTOS_URL) {
							onResponse(responseData, httpResponseCode)
						}
						else if url.contains(REMOTE_API_UPLOAD_ACTIVITY_PHOTO_URL) {
							onResponse(responseData, httpResponseCode)
						}
						else if url.contains(REMOTE_API_DELETE_ACTIVITY_PHOTO_URL) {
							onResponse(responseData, httpResponseCode)
						}
					}
					else {
						NSLog("Error code \(httpResponseCode.statusCode) received from the server for \(url)")
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
	
	func buildApiUrlStr(request: String) -> String {
		return String(format: "%@://%@/%@", Preferences.broadcastProtocol(), Preferences.broadcastHostName(), request)
	}
	
	func buildPhotoRequestUrlStr(userId: String, photoId: String) -> String {
		return String(format: "%@://%@/photos/%@/%@", Preferences.broadcastProtocol(), Preferences.broadcastHostName(), userId, photoId)
	}

	func login(username: String, password: String, onResponse: @escaping (Data?, HTTPURLResponse) -> Void) -> Bool {
		var postDict: Dictionary<String, String> = [:]
		postDict[PARAM_USERNAME] = username
		postDict[PARAM_PASSWORD] = password
		postDict[PARAM_DEVICE] = Preferences.uuid()
		
		let urlStr = self.buildApiUrlStr(request: REMOTE_API_LOGIN_URL)
		return self.makeRequest(url: urlStr, method: "POST", data: postDict, onResponse: onResponse)
	}
	
	func createLogin(username: String, password1: String, password2: String, realname: String, onResponse: @escaping (Data?, HTTPURLResponse) -> Void) -> Bool {
		var postDict: Dictionary<String, String> = [:]
		postDict[PARAM_USERNAME] = username
		postDict[PARAM_PASSWORD1] = password1
		postDict[PARAM_PASSWORD2] = password2
		postDict[PARAM_REALNAME] = realname
		postDict[PARAM_DEVICE] = Preferences.uuid()
		
		let urlStr = self.buildApiUrlStr(request: REMOTE_API_CREATE_LOGIN_URL)
		return self.makeRequest(url: urlStr, method: "POST", data: postDict, onResponse: onResponse)
	}
	
	func checkLoginStatus(onResponse: @escaping (Data?, HTTPURLResponse) -> Void) -> Bool {
		let urlStr = self.buildApiUrlStr(request: REMOTE_API_IS_LOGGED_IN_URL)
		return self.makeRequest(url: urlStr, method: "GET", data: [:], onResponse: onResponse)
	}
	
	func logout(onResponse: @escaping (Data?, HTTPURLResponse) -> Void) -> Bool {
		let urlStr = self.buildApiUrlStr(request: REMOTE_API_LOGOUT_URL)
		return self.makeRequest(url: urlStr, method: "POST", data: [:], onResponse: onResponse)
	}
	
	func listFriends(onResponse: @escaping (Data?, HTTPURLResponse) -> Void) -> Bool {
		let urlStr = self.buildApiUrlStr(request: REMOTE_API_LIST_FRIENDS_URL)
		return self.makeRequest(url: urlStr, method: "GET", data: [:], onResponse: onResponse)
	}
	
	func listGear(onResponse: @escaping (Data?, HTTPURLResponse) -> Void) -> Bool {
		let urlStr = self.buildApiUrlStr(request: REMOTE_API_LIST_GEAR_URL)
		return self.makeRequest(url: urlStr, method: "GET", data: [:], onResponse: onResponse)
	}

	func createGear(item: GearSummary, onResponse: @escaping (Data?, HTTPURLResponse) -> Void) throws -> Bool {
		let urlStr = self.buildApiUrlStr(request: REMOTE_API_CREATE_GEAR_URL)
		let jsonData = try JSONEncoder().encode(item)
		guard let dictionary = try JSONSerialization.jsonObject(with: jsonData, options: .allowFragments) as? [String: Any] else {
			return false
		}
		return self.makeRequest(url: urlStr, method: "POST", data: dictionary, onResponse: onResponse)
	}

	func updateGear(item: GearSummary, onResponse: @escaping (Data?, HTTPURLResponse) -> Void) throws -> Bool {
		let urlStr = self.buildApiUrlStr(request: REMOTE_API_UPDATE_GEAR_URL)
		let jsonData = try JSONEncoder().encode(item)
		guard let dictionary = try JSONSerialization.jsonObject(with: jsonData, options: .allowFragments) as? [String: Any] else {
			return false
		}
		return self.makeRequest(url: urlStr, method: "POST", data: dictionary, onResponse: onResponse)
	}

	func deleteGear(gearId: UUID, onResponse: @escaping (Data?, HTTPURLResponse) -> Void) -> Bool {
		var deleteDict: Dictionary<String, String> = [:]
		deleteDict[PARAM_GEAR_ID] = gearId.uuidString

		let urlStr = self.buildApiUrlStr(request: REMOTE_API_DELETE_GEAR_URL)
		return self.makeRequest(url: urlStr, method: "DELETE", data: deleteDict, onResponse: onResponse)
	}
	
	func listRaces(onResponse: @escaping (Data?, HTTPURLResponse) -> Void) -> Bool {
		let urlStr = self.buildApiUrlStr(request: REMOTE_API_LIST_RACES_URL)
		return self.makeRequest(url: urlStr, method: "GET", data: [:], onResponse: onResponse)
	}

	func listPlannedWorkouts(onResponse: @escaping (Data?, HTTPURLResponse) -> Void) -> Bool {
		let urlStr = self.buildApiUrlStr(request: REMOTE_API_LIST_PLANNED_WORKOUTS_URL)
		return self.makeRequest(url: urlStr, method: "GET", data: [:], onResponse: onResponse)
	}
	
	func listIntervalSessions(onResponse: @escaping (Data?, HTTPURLResponse) -> Void) -> Bool {
		let urlStr = self.buildApiUrlStr(request: REMOTE_API_LIST_INTERVAL_WORKOUTS_URL)
		return self.makeRequest(url: urlStr, method: "GET", data: [:], onResponse: onResponse)
	}
	
	func listPacePlans(onResponse: @escaping (Data?, HTTPURLResponse) -> Void) -> Bool {
		let urlStr = self.buildApiUrlStr(request: REMOTE_API_LIST_PACE_PLANS_URL)
		return self.makeRequest(url: urlStr, method: "GET", data: [:], onResponse: onResponse)
	}
	
	func requestActivityMetadata(activityId: String, onResponse: @escaping (Data?, HTTPURLResponse) -> Void) -> Bool {
		if Preferences.shouldBroadcastToServer() && self.isCurrentlyLoggedIn() {
			var postDict: Dictionary<String, String> = [:]
			postDict[PARAM_ACTIVITY_ID] = activityId
			
			let urlStr = self.buildApiUrlStr(request: REMOTE_API_REQUEST_ACTIVITY_METADATA_URL)
			return self.makeRequest(url: urlStr, method: "GET", data: postDict, onResponse: onResponse)
		}
		return false
	}

	func requestToFollow(target: String, onResponse: @escaping (Data?, HTTPURLResponse) -> Void) -> Bool {
		var postDict: Dictionary<String, String> = [:]
		postDict[PARAM_TARGET_EMAIL] = target
		
		let urlStr = self.buildApiUrlStr(request: REMOTE_API_REQUEST_TO_FOLLOW_URL)
		return self.makeRequest(url: urlStr, method: "GET", data: postDict, onResponse: onResponse)
	}

	func requestUserSettings(settings: Array<String>, onResponse: @escaping (Data?, HTTPURLResponse) -> Void) -> Bool {
		var postDict: Dictionary<String, String> = [:]
		postDict[PARAM_SETTINGS] = ""
		
		var first = true
		for setting in settings {
			if !first {
				postDict[PARAM_SETTINGS]! += ","
			}
			postDict[PARAM_SETTINGS]! += setting
			first = false
		}

		let urlStr = self.buildApiUrlStr(request: REMOTE_API_REQUEST_USER_SETTINGS_URL)
		return self.makeRequest(url: urlStr, method: "GET", data: postDict, onResponse: onResponse)
	}
	
	func exportActivity(activityId: String, onResponse: @escaping (Data?, HTTPURLResponse) -> Void) -> Bool {
		var postDict: Dictionary<String, String> = [:]
		postDict[PARAM_ACTIVITY_ID] = activityId
		postDict[PARAM_EXPORT_FORMAT] = "tcx"

		let urlStr = self.buildApiUrlStr(request: REMOTE_API_EXPORT_ACTIVITY_URL)
		return self.makeRequest(url: urlStr, method: "GET", data: postDict, onResponse: onResponse)
	}

	func deleteActivity(activityId: String, onResponse: @escaping (Data?, HTTPURLResponse) -> Void) -> Bool {
		var postDict: Dictionary<String, String> = [:]
		postDict[PARAM_ACTIVITY_ID] = activityId
		
		let urlStr = self.buildApiUrlStr(request: REMOTE_API_DELETE_ACTIVITY_URL)
		return self.makeRequest(url: urlStr, method: "POST", data: postDict, onResponse: onResponse)
	}

	func createTag(tag: String, activityId: String, onResponse: @escaping (Data?, HTTPURLResponse) -> Void) -> Bool {
		var postDict: Dictionary<String, String> = [:]
		postDict[PARAM_TAG + "0"] = tag
		postDict[PARAM_ACTIVITY_ID] = activityId
		
		let urlStr = self.buildApiUrlStr(request: REMOTE_API_CREATE_TAG_URL)
		return self.makeRequest(url: urlStr, method: "POST", data: postDict, onResponse: onResponse)
	}

	func deleteTag(tag: String, activityId: String, onResponse: @escaping (Data?, HTTPURLResponse) -> Void) -> Bool {
		var postDict: Dictionary<String, String> = [:]
		postDict[PARAM_TAG] = tag
		postDict[PARAM_ACTIVITY_ID] = activityId
		
		let urlStr = self.buildApiUrlStr(request: REMOTE_API_DELETE_TAG_URL)
		return self.makeRequest(url: urlStr, method: "POST", data: postDict, onResponse: onResponse)
	}

	func claimDevice(deviceId: String, onResponse: @escaping (Data?, HTTPURLResponse) -> Void) -> Bool {
		var postDict: Dictionary<String, String> = [:]
		postDict[PARAM_DEVICE_ID2] = deviceId

		let urlStr = self.buildApiUrlStr(request: REMOTE_API_CLAIM_DEVICE_URL)
		return self.makeRequest(url: urlStr, method: "POST", data: postDict, onResponse: onResponse)
	}

	func setActivityName(activityId: String, name: String, onResponse: @escaping (Data?, HTTPURLResponse) -> Void) -> Bool {
		var postDict: Dictionary<String, String> = [:]
		postDict[PARAM_ACTIVITY_ID] = activityId
		postDict[PARAM_ACTIVITY_NAME] = name
		
		let urlStr = self.buildApiUrlStr(request: REMOTE_API_UPDATE_ACTIVITY_METADATA_URL)
		return self.makeRequest(url: urlStr, method: "POST", data: postDict, onResponse: onResponse)
	}
	
	func startNewLap(activityId: String, startTimeMs: UInt64, onResponse: @escaping (Data?, HTTPURLResponse) -> Void) -> Bool {
		var postDict: Dictionary<String, String> = [:]
		postDict[PARAM_ACTIVITY_ID] = activityId
		postDict[PARAM_LAP_START_TIME] = String(startTimeMs)

		let urlStr = self.buildApiUrlStr(request: REMOTE_API_CREATE_NEW_LAP_URL)
		return self.makeRequest(url: urlStr, method: "POST", data: postDict, onResponse: onResponse)
	}
	
	func setActivityType(activityId: String, type: String, onResponse: @escaping (Data?, HTTPURLResponse) -> Void) -> Bool {
		var postDict: Dictionary<String, String> = [:]
		postDict[PARAM_ACTIVITY_ID] = activityId
		postDict[PARAM_ACTIVITY_TYPE] = type
		
		let urlStr = self.buildApiUrlStr(request: REMOTE_API_UPDATE_ACTIVITY_METADATA_URL)
		return self.makeRequest(url: urlStr, method: "POST", data: postDict, onResponse: onResponse)
	}
	
	func setActivityDescription(activityId: String, description: String, onResponse: @escaping (Data?, HTTPURLResponse) -> Void) -> Bool {
		var postDict: Dictionary<String, String> = [:]
		postDict[PARAM_ACTIVITY_ID] = activityId
		postDict[PARAM_ACTIVITY_DESCRIPTION] = description
		
		let urlStr = self.buildApiUrlStr(request: REMOTE_API_UPDATE_ACTIVITY_METADATA_URL)
		return self.makeRequest(url: urlStr, method: "POST", data: postDict, onResponse: onResponse)
	}
	
	func requestUpdatesSince(timestamp: Date, onResponse: @escaping (Data?, HTTPURLResponse) -> Void) -> Bool {
		var postDict: Dictionary<String, String> = [:]
		postDict[PARAM_TIMESTAMP] = String(UInt64(timestamp.timeIntervalSince1970))
		
		let urlStr = self.buildApiUrlStr(request: REMOTE_API_LIST_UNSYNCHED_ACTIVITIES_URL)
		return self.makeRequest(url: urlStr, method: "GET", data: postDict, onResponse: onResponse)
	}
	
	func requestActivityPhotos(activityId: String, onResponse: @escaping (Data?, HTTPURLResponse) -> Void) -> Bool {
		var postDict: Dictionary<String, String> = [:]
		postDict[PARAM_ACTIVITY_ID] = activityId

		let urlStr = self.buildApiUrlStr(request: REMOTE_API_LIST_ACTIVITY_PHOTOS_URL)
		return self.makeRequest(url: urlStr, method: "GET", data: postDict, onResponse: onResponse)
	}
	
	func hasActivity(activityId: String, onResponse: @escaping (Data?, HTTPURLResponse) -> Void) -> Bool {
		var postDict: Dictionary<String, String> = [:]
		postDict[PARAM_ACTIVITY_ID] = activityId
		
		let urlStr = self.buildApiUrlStr(request: REMOTE_API_HAS_ACTIVITY_URL)
		return self.makeRequest(url: urlStr, method: "GET", data: postDict, onResponse: onResponse)
	}
	
	func sendActivity(activityId: String, name: String, contents: Data, onResponse: @escaping (Data?, HTTPURLResponse) -> Void) -> Bool {
		let base64Encoded = contents.base64EncodedString()
		var postDict: Dictionary<String, String> = [:]
		postDict[PARAM_ACTIVITY_ID] = activityId
		postDict[PARAM_UPLOADED_FILE_NAME] = name
		postDict[PARAM_UPLOADED_FILE_DATA] = base64Encoded
		
		let urlStr = self.buildApiUrlStr(request: REMOTE_API_UPLOAD_ACTIVITY_FILE_URL)
		return self.makeRequest(url: urlStr, method: "POST", data: postDict, onResponse: onResponse)
	}
	
	func uploadActivityPhoto(activityId: String, imageData: Data, onResponse: @escaping (Data?, HTTPURLResponse) -> Void) -> Bool {
		let base64Encoded = imageData.base64EncodedString()
		var postDict: Dictionary<String, String> = [:]
		postDict[PARAM_ACTIVITY_ID] = activityId
		postDict[PARAM_UPLOADED_FILE_DATA] = base64Encoded

		let urlStr = self.buildApiUrlStr(request: REMOTE_API_UPLOAD_ACTIVITY_PHOTO_URL)
		return self.makeRequest(url: urlStr, method: "POST", data: postDict, onResponse: onResponse)
	}
	
	func deleteActivityPhoto(activityId: String, photoId: String, onResponse: @escaping (Data?, HTTPURLResponse) -> Void) -> Bool {
		var deleteDict: Dictionary<String, String> = [:]
		deleteDict[PARAM_ACTIVITY_ID] = activityId
		deleteDict[PARAM_ACTIVITY_PHOTO_ID] = photoId

		let urlStr = self.buildApiUrlStr(request: REMOTE_API_DELETE_ACTIVITY_PHOTO_URL)
		return self.makeRequest(url: urlStr, method: "DELETE", data: deleteDict, onResponse: onResponse)
	}
	
	func sendPlannedWorkouts(workoutsJson: String, onResponse: @escaping (Data?, HTTPURLResponse) -> Void) -> Bool {
		let urlStr = self.buildApiUrlStr(request: REMOTE_API_CREATE_PLANNED_WORKOUTS_URL)
		let workoutsDict: Dictionary<String, String> = ["workouts": workoutsJson]
		return self.makeRequest(url: urlStr, method: "POST", data: workoutsDict, onResponse: onResponse)
	}

	func sendIntervalSession(description: Dictionary<String, String>, onResponse: @escaping (Data?, HTTPURLResponse) -> Void) -> Bool {
		let urlStr = self.buildApiUrlStr(request: REMOTE_API_CREATE_INTERVAL_WORKOUT_URL)
		return self.makeRequest(url: urlStr, method: "POST", data: description, onResponse: onResponse)
	}
	
	func sendPacePlan(description: Dictionary<String, Any>, onResponse: @escaping (Data?, HTTPURLResponse) -> Void) -> Bool {
		let urlStr = self.buildApiUrlStr(request: REMOTE_API_CREATE_PACE_PLAN_URL)
		return self.makeRequest(url: urlStr, method: "POST", data: description, onResponse: onResponse)
	}
	
	func sendPacePlansToServer(onResponse: @escaping (Data?, HTTPURLResponse) -> Void) -> Bool {
		if InitializePacePlanList() {
			
			var pacePlanIndex = 0
			var done = false
			var result = true
			
			while !done {
				if let rawPacePlanDescPtr = RetrievePacePlanAsJSON(pacePlanIndex) {
					let pacePlanDescPtr = UnsafeRawPointer(rawPacePlanDescPtr)
					let pacePlanDesc = String(cString: pacePlanDescPtr.assumingMemoryBound(to: CChar.self))
					let summaryDict = try! JSONSerialization.jsonObject(with: Data(pacePlanDesc.utf8), options: []) as! [String:Any]

					result = result && self.sendPacePlan(description: summaryDict, onResponse: onResponse)
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

	func sendUpdatedUserHeight(timestamp: Date, onResponse: @escaping (Data?, HTTPURLResponse) -> Void) -> Bool {
		var postDict: Dictionary<String,String> = [:]
		postDict[PARAM_USER_HEIGHT] = String(format:"%f", Preferences.heightCm())
		postDict[PARAM_TIMESTAMP] = String(format:"%llu", time_t(timestamp.timeIntervalSince1970))

		let urlStr = self.buildApiUrlStr(request: REMOTE_API_UPDATE_PROFILE_URL)
		return self.makeRequest(url: urlStr, method: "POST", data: postDict, onResponse: onResponse)
	}

	func sendUpdatedUserWeight(timestamp: Date, onResponse: @escaping (Data?, HTTPURLResponse) -> Void) -> Bool {
		var postDict: Dictionary<String,String> = [:]
		postDict[PARAM_USER_WEIGHT] = String(format:"%f", Preferences.weightKg())
		postDict[PARAM_TIMESTAMP] = String(format:"%llu", time_t(timestamp.timeIntervalSince1970))

		let urlStr = self.buildApiUrlStr(request: REMOTE_API_UPDATE_PROFILE_URL)
		return self.makeRequest(url: urlStr, method: "POST", data: postDict, onResponse: onResponse)
	}

	func sendUpdatedUserBirthDate(timestamp: Date, onResponse: @escaping (Data?, HTTPURLResponse) -> Void) -> Bool {
		var postDict: Dictionary<String,String> = [:]
		postDict[PARAM_USER_WEIGHT] = String(format:"%llu", Preferences.birthDate())
		postDict[PARAM_TIMESTAMP] = String(format:"%llu", time_t(timestamp.timeIntervalSince1970))

		let urlStr = self.buildApiUrlStr(request: REMOTE_API_UPDATE_PROFILE_URL)
		return self.makeRequest(url: urlStr, method: "POST", data: postDict, onResponse: onResponse)
	}

	func sendUpdatedUserFtp(timestamp: Date, onResponse: @escaping (Data?, HTTPURLResponse) -> Void) -> Bool {
		var postDict: Dictionary<String,String> = [:]
		postDict[PARAM_USER_FTP] = String(format:"%f", Preferences.ftp())
		postDict[PARAM_TIMESTAMP] = String(format:"%llu", time_t(timestamp.timeIntervalSince1970))

		let urlStr = self.buildApiUrlStr(request: REMOTE_API_UPDATE_PROFILE_URL)
		return self.makeRequest(url: urlStr, method: "POST", data: postDict, onResponse: onResponse)
	}

	func sendUpdatedUserRestingHr(timestamp: Date, onResponse: @escaping (Data?, HTTPURLResponse) -> Void) -> Bool {
		var postDict: Dictionary<String,String> = [:]
		postDict[PARAM_USER_RESTING_HR] = String(format:"%f", Preferences.restingHr())
		postDict[PARAM_TIMESTAMP] = String(format:"%llu", timestamp.timeIntervalSince1970)
		
		let urlStr = self.buildApiUrlStr(request: REMOTE_API_UPDATE_PROFILE_URL)
		return self.makeRequest(url: urlStr, method: "POST", data: postDict, onResponse: onResponse)
	}

	func sendUpdatedUserMaxHr(timestamp: Date, onResponse: @escaping (Data?, HTTPURLResponse) -> Void) -> Bool {
		var postDict: Dictionary<String,String> = [:]
		postDict[PARAM_USER_MAX_HR] = String(format:"%f", Preferences.maxHr())
		postDict[PARAM_TIMESTAMP] = String(format:"%llu", time_t(timestamp.timeIntervalSince1970))
		
		let urlStr = self.buildApiUrlStr(request: REMOTE_API_UPDATE_PROFILE_URL)
		return self.makeRequest(url: urlStr, method: "POST", data: postDict, onResponse: onResponse)
	}

	func sendUpdatedUserVO2Max(timestamp: Date, onResponse: @escaping (Data?, HTTPURLResponse) -> Void) -> Bool {
		var postDict: Dictionary<String,String> = [:]
		postDict[PARAM_USER_VO2MAX] = String(format:"%f", Preferences.vo2Max())
		postDict[PARAM_TIMESTAMP] = String(format:"%llu", timestamp.timeIntervalSince1970)
		
		let urlStr = self.buildApiUrlStr(request: REMOTE_API_UPDATE_PROFILE_URL)
		return self.makeRequest(url: urlStr, method: "POST", data: postDict, onResponse: onResponse)
	}

	func sendUserDetailsToServer(onResponse: @escaping (Data?, HTTPURLResponse) -> Void) -> Bool {
		var timestamp: time_t = 0
		var weightKg: Double = 0.0

		if GetUsersCurrentWeight(&timestamp, &weightKg) {
			return self.sendUpdatedUserWeight(timestamp: Date(timeIntervalSince1970: TimeInterval(timestamp)), onResponse: onResponse)
		}
		return true // User may not have any weight data
	}

	func sendMissingActivitiesToServer(onResponse: @escaping (Data?, HTTPURLResponse) -> Void) -> Bool {
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
				result = result && self.hasActivity(activityId: activityId, onResponse: onResponse)
			}
			
			return result
		}
		return false
	}

	/// @brief Request the latest of everything from the server.  Also, send the server anything it is missing as well.
	func syncWithServer() -> Bool {
		var result = true

		if Preferences.shouldBroadcastToServer() && self.isCurrentlyLoggedIn() {

			// Rate limit the server synchronizations. Let's not be spammy.
			let now = time(nil)
			let lastServerSync = Preferences.lastServerSyncTime()
			if now - lastServerSync > 60 {
				let deviceId = Preferences.uuid()
				if deviceId != nil {

					// Associate this device with the user.
					result = self.claimDevice(deviceId: deviceId!, onResponse: { responseData, responseCode in
					})

					// Get all the things.
#if !os(watchOS)
					result = result && self.listGear(onResponse: { responseData, responseCode in
						CommonApp.shared.gearListUpdated(responseData: responseData, responseCode: responseCode)
					})
					result = result && self.listRaces(onResponse: { responseData, responseCode in
						CommonApp.shared.raceListUpdated(responseData: responseData, responseCode: responseCode)
					})
					result = result && self.listPlannedWorkouts(onResponse: { responseData, responseCode in
						CommonApp.shared.plannedWorkoutsUpdated(responseData: responseData, responseCode: responseCode)
					})
					result = result && self.requestUserSettings(settings: [WORKOUT_INPUT_GOAL_TYPE], onResponse: { responseData, responseCode in
						CommonApp.shared.requestUserSettingsResponse(responseData: responseData, responseCode: responseCode)
					})
#endif
					result = result && self.listIntervalSessions(onResponse: { responseData, responseCode in
						CommonApp.shared.intervalSessionsUpdated(responseData: responseData, responseCode: responseCode)
					})
					result = result && self.listPacePlans(onResponse: { responseData, responseCode in
						CommonApp.shared.pacePlansUpdated(responseData: responseData, responseCode: responseCode)
					})

					// Send all the things.
#if !os(watchOS)
					result = result && self.sendUserDetailsToServer(onResponse: { responseData, responseCode in
					})
					result = result && self.sendMissingActivitiesToServer(onResponse: { responseData, responseCode in
					})
					result = result && self.sendPacePlansToServer(onResponse: { responseData, responseCode in
					})
#endif
					
					// Ask for the server's activity list, from the time of the last activity received.
					let lastServerImport = Preferences.lastServerImportTime()
					result = result && self.requestUpdatesSince(timestamp: Date(timeIntervalSince1970: TimeInterval(lastServerImport)), onResponse: { responseData, responseCode in
					})

					Preferences.setLastServerSyncTime(value: now)
				}
			}
		}
		return result
	}
}
