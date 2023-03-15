//
//  WatchSession.swift
//  Created by Michael Simms on 10/31/22.
//

import Foundation
import WatchConnectivity

// Possible message types and their parameters.
let WATCH_MSG_TYPE =                       "Msg Type"
let WATCH_MSG_SYNC_PREFS =                 "Sync Prefs"
let WATCH_MSG_REGISTER_DEVICE =            "Register Device"
let WATCH_MSG_PARAM_DEVICE_ID =            "Device ID"
let WATCH_MSG_REQUEST_SESSION_KEY =        "Request Session Key"
let WATCH_MSG_PARAM_SESSION_KEY =          "Session Key"
let WATCH_MSG_PARAM_SESSION_KEY_EXPIRY =   "Session Key Expiry"
let WATCH_MSG_DOWNLOAD_INTERVAL_SESSIONS = "Download Interval Sessions"
let WATCH_MSG_DOWNLOAD_PACE_PLANS =        "Download Pace Plans"
let WATCH_MSG_INTERVAL_SESSION =           "Interval Session"
let WATCH_MSG_PACE_PLAN =                  "Pace Plan"
let WATCH_MSG_CHECK_ACTIVITY =             "Check Activity"
let WATCH_MSG_REQUEST_ACTIVITY =           "Request Activity"
let WATCH_MSG_MARK_ACTIVITY_AS_SYNCHED =   "Mark Synched Activity"
let WATCH_MSG_PARAM_ACTIVITY_ID =          "Activity ID"
let WATCH_MSG_PARAM_ACTIVITY_TYPE =        "Activity Type"
let WATCH_MSG_PARAM_ACTIVITY_NAME =        "Activity Name"
let WATCH_MSG_PARAM_ACTIVITY_DESCRIPTION = "Activity Description"
let WATCH_MSG_PARAM_ACTIVITY_START_TIME =  "Activity Start Time"
let WATCH_MSG_PARAM_ACTIVITY_END_TIME =    "Activity End Time"
let WATCH_MSG_PARAM_ACTIVITY_LOCATIONS =   "Activity Locations"
let WATCH_MSG_PARAM_FILE_FORMAT =          "File Format"

class WatchSession : NSObject, WCSessionDelegate, ObservableObject {
	var watchSession: WCSession = WCSession.default
	var timeOfLastMessage: time_t = 0  // Timestamp of the last time we got a message, use this to keep us from spamming
	@Published var isConnected: Bool = false

	func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
		let msgType = message[WATCH_MSG_TYPE] as? String

		if msgType == WATCH_MSG_SYNC_PREFS {
		}
		else if msgType == WATCH_MSG_REGISTER_DEVICE {
			if let deviceId = message[WATCH_MSG_PARAM_DEVICE_ID] as? String {
				let _ = ApiClient.shared.claimDevice(deviceId: deviceId)
			}
		}
		else if msgType == WATCH_MSG_REQUEST_SESSION_KEY {
		}
		else if msgType == WATCH_MSG_DOWNLOAD_INTERVAL_SESSIONS {
		}
		else if msgType == WATCH_MSG_INTERVAL_SESSION {
		}
		else if msgType == WATCH_MSG_PACE_PLAN {
		}
		else if msgType == WATCH_MSG_CHECK_ACTIVITY {
		}
		else if msgType == WATCH_MSG_REQUEST_ACTIVITY {
		}
		else if msgType == WATCH_MSG_MARK_ACTIVITY_AS_SYNCHED {
		}
	}

	func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: ([String : Any]) -> Void) {
		let msgType = message[WATCH_MSG_TYPE] as? String

		if msgType == WATCH_MSG_SYNC_PREFS {
		}
		else if msgType == WATCH_MSG_REGISTER_DEVICE {
		}
		else if msgType == WATCH_MSG_REQUEST_SESSION_KEY {
			self.generateWatchSessionKey(replyHandler: replyHandler)
		}
		else if msgType == WATCH_MSG_DOWNLOAD_INTERVAL_SESSIONS {
		}
		else if msgType == WATCH_MSG_INTERVAL_SESSION {
		}
		else if msgType == WATCH_MSG_PACE_PLAN {
		}
		else if msgType == WATCH_MSG_CHECK_ACTIVITY {
			if let activityId = message[WATCH_MSG_PARAM_ACTIVITY_ID] as? String {
				self.checkForActivity(activityId: activityId, replyHandler: replyHandler)
			}
		}
		else if msgType == WATCH_MSG_REQUEST_ACTIVITY {
		}
		else if msgType == WATCH_MSG_MARK_ACTIVITY_AS_SYNCHED {
		}
	}

	func session(_ session: WCSession, didReceive file: WCSessionFile) {
		do {
			if let msgMetadata = file.metadata as? Dictionary<String, AnyObject> {
				let activityId = msgMetadata[WATCH_MSG_PARAM_ACTIVITY_ID] as? String
				let activityType = msgMetadata[WATCH_MSG_PARAM_ACTIVITY_TYPE] as? String
				let activityName = msgMetadata[WATCH_MSG_PARAM_ACTIVITY_NAME] as? String
				let activityDesc = msgMetadata[WATCH_MSG_PARAM_ACTIVITY_DESCRIPTION] as? String

				if IsActivityInDatabase(activityId) {
					NSLog("Received a duplicate activity from the watch.")
					return
				}

				// An activity file is received from the watch app.
				if ImportActivityFromFile(file.fileURL.absoluteString, activityType, activityId) {
					UpdateActivityName(activityId, activityName)
					UpdateActivityDescription(activityId, activityDesc)
				}
				else {
					NSLog("Failed to import an activity from the watch.");
				}

				try FileManager.default.removeItem(at: file.fileURL)
			}
			else {
				NSLog("Invalid metadata when processing a file from the watch.")
			}
		}
		catch {
			NSLog("Exception when processing a file from the watch.")
		}
	}

	func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
	}
	
	func session(_ session: WCSession, didFinish fileTransfer: WCSessionFileTransfer, error: Error?) {
		do {
			let fileName = fileTransfer.file.fileURL.absoluteString

			if let activityId = fileTransfer.file.metadata![WATCH_MSG_PARAM_ACTIVITY_ID] as? String {
				CreateActivitySync(activityId, SYNC_DEST_PHONE)
			}
			try FileManager.default.removeItem(at: URL(string: fileName)!)
		}
		catch {
		}
	}

	func sessionReachabilityDidChange(_ session: WCSession) {
		do {
			if session.isReachable {
				self.isConnected = true

#if os(watchOS)
				// Startup stuff.
				if self.timeOfLastMessage == 0 {
					self.sendRegisterDeviceMsgToPhone()
					self.sendRequestSessionKeyMsgToPhone()
					self.requestIntervalWorkoutsFromPhone()
					self.requestPacePlansFromPhone()
				}
				
				// Rate limit the server synchronizations. Let's not be spammy.
				let now = time(nil)
				if now - self.timeOfLastMessage > 300 {
					try self.checkIfActivitiesAreUploadedToPhone()
					self.timeOfLastMessage = now
				}
#endif
			}
			else {
				self.isConnected = false
			}
		}
		catch {
		}
	}

#if !os(watchOS)
	func sessionDidBecomeInactive(_ session: WCSession) {
	}
	
	func sessionDidDeactivate(_ session: WCSession) {
	}
#endif

	/// @brief Called by the Watch app to initialize the session
	func startWatchSession() {
		if WCSession.isSupported() {
			self.timeOfLastMessage = 0
			self.watchSession.delegate = self
			self.watchSession.activate()
			NotificationCenter.default.addObserver(self, selector: #selector(self.activityStopped), name: Notification.Name(rawValue: NOTIFICATION_NAME_ACTIVITY_STOPPED), object: nil)
		}
	}

	/// @brief Called when the watch is requesting a session key so that it can authenticate with the (optional) server.
	func generateWatchSessionKey(replyHandler: ([String : Any]) -> Void) {
		let cookies = HTTPCookieStorage.sharedCookieStorage(forGroupContainerIdentifier: "group.mjs-software.OpenWorkoutTracker").cookies
		if cookies != nil {
			for cookie in cookies! {
				if cookie.value(forKey: HTTPCookiePropertyKey.name.rawValue) as! String == SESSION_COOKIE_NAME {
					var msgData: Dictionary<String,Any> = [:]
					msgData[WATCH_MSG_PARAM_SESSION_KEY] = cookie.name
					msgData[WATCH_MSG_PARAM_SESSION_KEY_EXPIRY] = cookie.expiresDate
					replyHandler(msgData)
				}
			}
		}
	}
	
	/// @brief Sends our unique identifier to the phone.
	func sendRegisterDeviceMsgToPhone() {
		var msgData: Dictionary<String,String> = [:]
		msgData[WATCH_MSG_TYPE] = WATCH_MSG_REGISTER_DEVICE
		msgData[WATCH_MSG_PARAM_DEVICE_ID] = Preferences.uuid()
		self.watchSession.sendMessage(msgData, replyHandler: nil)
	}

	/// @brief Called to request a new session key from the phone. The session key is needed for sending to the (optional) server (from an LTE-enabled watch)
	/// and has be be requested from the phone since the watch doesn't have a good way to enter a username and password.
	func sendRequestSessionKeyMsgToPhone() {
		var msgData: Dictionary<String,String> = [:]
		msgData[WATCH_MSG_TYPE] = WATCH_MSG_REQUEST_SESSION_KEY
		self.watchSession.sendMessage(msgData, replyHandler: (([String : Any]) -> Void)? {_ in })
	}

	func requestIntervalWorkoutsFromPhone() {
	}

	func requestPacePlansFromPhone() {
	}

	/// @brief Responds to an activity check from the watch. Checks if we have the activity, if we don't then request it from the watch.
	func checkForActivity(activityId: String, replyHandler: ([String : Any]) -> Void) {
		// Don't try to import anything when we're in the middle of doing an activity.
		if IsActivityCreated() {
			return
		}

		if IsActivityInDatabase(activityId) {
			var msgData: Dictionary<String,String> = [:]
			msgData[WATCH_MSG_TYPE] = WATCH_MSG_MARK_ACTIVITY_AS_SYNCHED
			msgData[WATCH_MSG_PARAM_ACTIVITY_ID] = activityId
			replyHandler(msgData)
		}
		else {
			var msgData: Dictionary<String,String> = [:]
			msgData[WATCH_MSG_TYPE] = WATCH_MSG_REQUEST_ACTIVITY
			msgData[WATCH_MSG_PARAM_ACTIVITY_ID] = activityId
			replyHandler(msgData)
		}
	}

	/// @brief Called when connecting to the phone so we can determine which activities to send.
	func checkIfActivitiesAreUploadedToPhone() throws {
		var numHistoricalActivities = GetNumHistoricalActivities()
		var numRequestedSyncs = 0

		// Only reload the historical activities list if we really have to as it's rather
		// computationally expensive for something running on a watch.
		if numHistoricalActivities == 0 {
			InitializeHistoricalActivityList()
			numHistoricalActivities = GetNumHistoricalActivities()
		}

		if numHistoricalActivities > 0 {

			// Check each activity. Loop in reverse order because the most recent activities are probably the most interesting.
			for i in stride(from: numHistoricalActivities - 1, to: 0, by: -1) {
				let activityIdPtr = UnsafeRawPointer(ConvertActivityIndexToActivityId(i)) // Returns const char*, no need to dealloc
				
				if activityIdPtr != nil {
					let activityId = String(cString: activityIdPtr!.assumingMemoryBound(to: CChar.self))

					// If it's already been synched then skip it. Otherwise, offer up the activity.
					if IsActivitySynched(activityId, SYNC_DEST_PHONE) == false {
						numRequestedSyncs += 1
						let _ = try self.sendActivityFileToPhone(activityId: activityId)
					}
					
					if numRequestedSyncs >= 1 {
						break
					}
					if IsActivityCreated() {
						break
					}
				}
			}
		}
	}

	/// @brief Returns the "best" file format for exporting an activity of the specified type.
	private func preferredExportFormatForActivityType(activityType: String) -> FileFormat {
		if activityType == ACTIVITY_TYPE_POOL_SWIMMING {
			return FILE_CSV
		}
		return FILE_TCX
	}

	func sendActivityFileToPhone(activityId: String) throws -> Bool {
		var numHistoricalActivities = GetNumHistoricalActivities()
		var result = false
		
		// Only reload the historical activities list if we really have to as it's rather
		// computationally expensive for something running on a watch.
		if numHistoricalActivities == 0 {
			InitializeHistoricalActivityList()
			numHistoricalActivities = GetNumHistoricalActivities()
		}

		if numHistoricalActivities > 0 {
			let activityIndex = ConvertActivityIdToActivityIndex(activityId)
			let activityTypePtr = UnsafeRawPointer(GetHistoricalActivityType(activityIndex))
			let activityNamePtr = UnsafeRawPointer(GetHistoricalActivityName(activityIndex))
			let activityDescPtr = UnsafeRawPointer(GetHistoricalActivityDescription(activityIndex))

			defer {
				if activityTypePtr != nil {
					activityTypePtr!.deallocate()
				}
				if activityNamePtr != nil {
					activityNamePtr!.deallocate()
				}
				if activityDescPtr != nil {
					activityDescPtr!.deallocate()
				}
			}

			if activityTypePtr != nil && activityNamePtr != nil {
				let activityType = String(cString: activityTypePtr!.assumingMemoryBound(to: CChar.self))
				let activityName = String(cString: activityNamePtr!.assumingMemoryBound(to: CChar.self))
				let activityDesc = String(cString: activityDescPtr!.assumingMemoryBound(to: CChar.self))
				let fileFormat = self.preferredExportFormatForActivityType(activityType: activityType)

				var startTime: time_t = 0
				var endTime: time_t = 0

				if GetHistoricalActivityStartAndEndTime(activityIndex, &startTime, &endTime) {
					let groupUrl = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.mjs-software.OpenWorkoutTracker")
					if groupUrl != nil {
						let summary = ActivitySummary()
						summary.id = activityId
						summary.type = activityType
						summary.name = activityName
						summary.description = activityDesc

						// Load the activity from the database.
						let storedActivityVM = StoredActivityVM(activitySummary: summary)
						storedActivityVM.load()

						// Export the activity to a file.
						let groupPath = groupUrl!.path(percentEncoded: false)
						let fileName = try storedActivityVM.exportActivityToFile(fileFormat: fileFormat, dirName: groupPath)
						if fileName.count > 0 {
							var activityMetaData: Dictionary<String, Any> = [:]
							activityMetaData[WATCH_MSG_PARAM_ACTIVITY_ID] = activityId
							activityMetaData[WATCH_MSG_PARAM_ACTIVITY_TYPE] = activityType
							activityMetaData[WATCH_MSG_PARAM_ACTIVITY_NAME] = activityName
							activityMetaData[WATCH_MSG_PARAM_ACTIVITY_DESCRIPTION] = activityDesc
							activityMetaData[WATCH_MSG_PARAM_ACTIVITY_START_TIME] = startTime
							activityMetaData[WATCH_MSG_PARAM_ACTIVITY_END_TIME] = endTime
							activityMetaData[WATCH_MSG_PARAM_FILE_FORMAT] = Int(fileFormat.rawValue)

							// Send to the phone.
							let fileUrl = URL(string: fileName)
							self.watchSession.transferFile(fileUrl!, metadata: activityMetaData)

							// Delete the temporary file.
							try FileManager.default.removeItem(at: fileUrl!)

							result = true
						}
						else {
							NSLog("Activity export failed (file export).")
						}
					}
					else {
						NSLog("Activity export failed (nil group URL).")
					}
				}
				else {
					NSLog("Activity export failed (undefined activity start time).")
				}
			}
		}

		return result
	}
	
	/// @brief This method is called in response to an activity stopped notification.
	@objc func activityStopped(notification: NSNotification) {
		if self.watchSession.isReachable {
		}
	}
}
