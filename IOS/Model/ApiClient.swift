//
//  ApiClient.swift
//  Created by Michael Simms on 10/9/22.
//

import Foundation

class ApiClient {
	static let shared = ApiClient()
	var loggedIn = false
	
	/// Singleton constructor
	private init() {
	}
	
	func makeRequest(url: String, method: String, data: Dictionary<String,String>) -> Bool {
		do {
			var request = URLRequest(url: URL(string: url)!)
			request.timeoutInterval = 30.0
			request.allowsExpensiveNetworkAccess = true
			request.httpMethod = method
			
			if data.count > 0 {
				let jsonData = try JSONSerialization.data(withJSONObject: data, options: [])
				let text = String(data: jsonData, encoding: String.Encoding.ascii)!
				let postLength = String(format: "%lu", data.count)
				
				request.setValue(postLength, forHTTPHeaderField:"Content-Length")
				request.setValue("application/json", forHTTPHeaderField:"Content-Type")
				request.httpBody = text.data(using:.utf8)
			}
			
			let session = URLSession.shared
			let dataTask = session.dataTask(with: request) { data, response, error in
				if let httpResponse = response as? HTTPURLResponse {
					
					if url.contains(REMOTE_API_IS_LOGGED_IN_URL) {
					}
					else if url.contains(REMOTE_API_LOGIN_URL) {
					}
					else if url.contains(REMOTE_API_CREATE_LOGIN_URL) {
					}
					else if url.contains(REMOTE_API_LOGOUT_URL) {
					}
					else if url.contains(REMOTE_API_LIST_FRIENDS_URL) {
					}
					else if url.contains(REMOTE_API_LIST_GEAR_URL) {
					}
					else if url.contains(REMOTE_API_LIST_PLANNED_WORKOUTS_URL) {
					}
					else if url.contains(REMOTE_API_LIST_INTERVAL_WORKOUTS_URL) {
					}
					else if url.contains(REMOTE_API_LIST_PACE_PLANS_URL) {
					}
					else if url.contains(REMOTE_API_LIST_UNSYNCHED_ACTIVITIES_URL) {
					}
					else if url.contains(REMOTE_API_HAS_ACTIVITY_URL) {
					}
					else if url.contains(REMOTE_API_REQUEST_ACTIVITY_METADATA_URL) {
					}
					else if url.contains(REMOTE_API_REQUEST_WORKOUT_DETAILS_URL) {
					}
					else if url.contains(REMOTE_API_REQUEST_TO_FOLLOW_URL) {
					}
				}
				else {
				}
			}
			
			dataTask.resume()
		}
		catch {
		}
		return false
	}
	
	func login(username: String, password: String) -> Bool {
		var postDict: Dictionary<String,String> = [:]
		postDict[PARAM_USERNAME] = username
		postDict[PARAM_PASSWORD] = password
		postDict[PARAM_DEVICE] = Preferences.uuid()
		
		let urlStr = String(format: "%@://%@/%@", Preferences.broadcastProtocol(), Preferences.broadcastHostName(), REMOTE_API_LOGIN_URL)
		return self.makeRequest(url: urlStr, method: "POST", data: postDict)
	}
	
	func createLogin(username: String, password1: String, password2: String, realname: String) -> Bool {
		var postDict: Dictionary<String,String> = [:]
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
		return self.makeRequest(url: urlStr, method: "POST", data: [:])
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
		var postDict: Dictionary<String,String> = [:]
		postDict[PARAM_ACTIVITY_ID] = activityId
		
		let urlStr = String(format: "%@://%@/%@", Preferences.broadcastProtocol(), Preferences.broadcastHostName(), REMOTE_API_REQUEST_ACTIVITY_METADATA_URL)
		return self.makeRequest(url: urlStr, method: "GET", data: postDict)
	}
	
	func requestWorkoutDetails(workoutId: String) -> Bool {
		var postDict: Dictionary<String,String> = [:]
		postDict[PARAM_WORKOUT_ID] = workoutId
		postDict["format"] = "json"
		
		let urlStr = String(format: "%@://%@/%@", Preferences.broadcastProtocol(), Preferences.broadcastHostName(), REMOTE_API_REQUEST_WORKOUT_DETAILS_URL)
		return self.makeRequest(url: urlStr, method: "GET", data: postDict)
	}
	
	func requestToFollow(target: String) -> Bool {
		var postDict: Dictionary<String,String> = [:]
		postDict[PARAM_TARGET_EMAIL] = target
		
		let urlStr = String(format: "%@://%@/%@", Preferences.broadcastProtocol(), Preferences.broadcastHostName(), REMOTE_API_REQUEST_TO_FOLLOW_URL)
		return self.makeRequest(url: urlStr, method: "GET", data: postDict)
	}
	
	func deleteActivity(activityId: String) -> Bool {
		var postDict: Dictionary<String,String> = [:]
		postDict[PARAM_ACTIVITY_ID] = activityId
		
		let urlStr = String(format: "%@://%@/%@", Preferences.broadcastProtocol(), Preferences.broadcastHostName(), REMOTE_API_DELETE_ACTIVITY_URL)
		return self.makeRequest(url: urlStr, method: "POST", data: postDict)
	}
	
	func createTag(tag: String, activityId: String) -> Bool {
		var postDict: Dictionary<String,String> = [:]
		postDict[PARAM_TAG] = tag
		postDict[PARAM_ACTIVITY_ID] = activityId
		
		let urlStr = String(format: "%@://%@/%@", Preferences.broadcastProtocol(), Preferences.broadcastHostName(), REMOTE_API_CREATE_TAG_URL)
		return self.makeRequest(url: urlStr, method: "POST", data: postDict)
	}
	
	func deleteTag(tag: String, activityId: String) -> Bool {
		var postDict: Dictionary<String,String> = [:]
		postDict[PARAM_TAG] = tag
		postDict[PARAM_ACTIVITY_ID] = activityId
		
		let urlStr = String(format: "%@://%@/%@", Preferences.broadcastProtocol(), Preferences.broadcastHostName(), REMOTE_API_DELETE_TAG_URL)
		return self.makeRequest(url: urlStr, method: "POST", data: postDict)
	}
	
	func claimDevice(deviceId: String) -> Bool {
		var postDict: Dictionary<String,String> = [:]
		postDict[PARAM_DEVICE_ID2] = deviceId
		
		let urlStr = String(format: "%@://%@/%@", Preferences.broadcastProtocol(), Preferences.broadcastHostName(), REMOTE_API_CLAIM_DEVICE_URL)
		return self.makeRequest(url: urlStr, method: "POST", data: postDict)
	}
	
	func setActivityName(activityId: String, name: String) -> Bool {
		var postDict: Dictionary<String,String> = [:]
		postDict[PARAM_ACTIVITY_ID] = activityId
		postDict[PARAM_ACTIVITY_NAME] = name
		
		let urlStr = String(format: "%@://%@/%@", Preferences.broadcastProtocol(), Preferences.broadcastHostName(), REMOTE_API_UPDATE_ACTIVITY_PROFILE_URL)
		return self.makeRequest(url: urlStr, method: "POST", data: postDict)
	}
	
	func setActivityType(activityId: String, type: String) -> Bool {
		var postDict: Dictionary<String,String> = [:]
		postDict[PARAM_ACTIVITY_ID] = activityId
		postDict[PARAM_ACTIVITY_TYPE] = type
		
		let urlStr = String(format: "%@://%@/%@", Preferences.broadcastProtocol(), Preferences.broadcastHostName(), REMOTE_API_UPDATE_ACTIVITY_PROFILE_URL)
		return self.makeRequest(url: urlStr, method: "POST", data: postDict)
	}
	
	func setActivityDescription(activityId: String, description: String) -> Bool {
		var postDict: Dictionary<String,String> = [:]
		postDict[PARAM_ACTIVITY_ID] = activityId
		postDict[PARAM_ACTIVITY_DESCRIPTION] = description
		
		let urlStr = String(format: "%@://%@/%@", Preferences.broadcastProtocol(), Preferences.broadcastHostName(), REMOTE_API_UPDATE_ACTIVITY_PROFILE_URL)
		return self.makeRequest(url: urlStr, method: "POST", data: postDict)
	}
	
	func requestUpdatesSince(timestamp: Date) -> Bool {
		var postDict: Dictionary<String,String> = [:]
		postDict[PARAM_TIMESTAMP] = String(format:"%ull", timestamp.timeIntervalSince1970)
		
		let urlStr = String(format: "%@://%@/%@", Preferences.broadcastProtocol(), Preferences.broadcastHostName(), REMOTE_API_LIST_UNSYNCHED_ACTIVITIES_URL)
		return self.makeRequest(url: urlStr, method: "GET", data: postDict)
	}
	
	func hasActivity(activityId: String, hash: String) -> Bool {
		var postDict: Dictionary<String,String> = [:]
		postDict[PARAM_ACTIVITY_ID] = activityId
		postDict[PARAM_ACTIVITY_HASH] = hash
		
		let urlStr = String(format: "%@://%@/%@", Preferences.broadcastProtocol(), Preferences.broadcastHostName(), REMOTE_API_HAS_ACTIVITY_URL)
		return self.makeRequest(url: urlStr, method: "GET", data: postDict)
	}
	
	func sendActivity(activityId: String, name: String, contents: Data) -> Bool {
		let base64Encoded = contents.base64EncodedString()
		var postDict: Dictionary<String,String> = [:]
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
	
	func sendPacePlan(description: Dictionary<String, String>) -> Bool {
		let urlStr = String(format: "%@://%@/%@", Preferences.broadcastProtocol(), Preferences.broadcastHostName(), REMOTE_API_CREATE_PACE_PLAN_URL)
		return self.makeRequest(url: urlStr, method: "POST", data: description)
	}
	
	func sendUpdatedUserHeight(timestamp: Date) -> Bool {
		var postDict: Dictionary<String,String> = [:]
		postDict[PARAM_USER_HEIGHT] = String(format:"%f", Preferences.heightCm())
		postDict[PARAM_TIMESTAMP] = String(format:"%ull", timestamp.timeIntervalSince1970)

		let urlStr = String(format: "%@://%@/%@", Preferences.broadcastProtocol(), Preferences.broadcastHostName(), REMOTE_API_UPDATE_PROFILE_URL)
		return self.makeRequest(url: urlStr, method: "POST", data: postDict)
	}
	
	func sendUpdatedUserWeight(timestamp: Date) -> Bool {
		var postDict: Dictionary<String,String> = [:]
		postDict[PARAM_USER_WEIGHT] = String(format:"%f", Preferences.weightKg())
		postDict[PARAM_TIMESTAMP] = String(format:"%ull", timestamp.timeIntervalSince1970)
		
		let urlStr = String(format: "%@://%@/%@", Preferences.broadcastProtocol(), Preferences.broadcastHostName(), REMOTE_API_UPDATE_PROFILE_URL)
		return self.makeRequest(url: urlStr, method: "POST", data: postDict)
	}
	
	func sendUpdatedUserFtp(timestamp: Date) -> Bool {
		var postDict: Dictionary<String,String> = [:]
		postDict[PARAM_USER_FTP] = String(format:"%f", Preferences.ftp())
		postDict[PARAM_TIMESTAMP] = String(format:"%ull", timestamp.timeIntervalSince1970)

		let urlStr = String(format: "%@://%@/%@", Preferences.broadcastProtocol(), Preferences.broadcastHostName(), REMOTE_API_UPDATE_PROFILE_URL)
		return self.makeRequest(url: urlStr, method: "POST", data: postDict)
	}
}
