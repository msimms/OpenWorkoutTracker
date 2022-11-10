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
let WATCH_MSG_DOWNLOAD_INTERVAL_WORKOUTS = "Download Interval Workouts"
let WATCH_MSG_DOWNLOAD_PACE_PLANS =        "Download Pace Plans"
let WATCH_MSG_INTERVAL_WORKOUT =           "Interval Workout"
let WATCH_MSG_PACE_PLAN =                  "Pace Plan"
let WATCH_MSG_CHECK_ACTIVITY =             "Check Activity"
let WATCH_MSG_REQUEST_ACTIVITY =           "Request Activity"
let WATCH_MSG_MARK_ACTIVITY_AS_SYNCHED =   "Mark Synched Activity"
let WATCH_MSG_PARAM_ACTIVITY_ID =          "Activity ID"
let WATCH_MSG_PARAM_ACTIVITY_TYPE =        "Activity Type"
let WATCH_MSG_PARAM_ACTIVITY_NAME =        "Activity Name"
let WATCH_MSG_PARAM_ACTIVITY_START_TIME =  "Activity Start Time"
let WATCH_MSG_PARAM_ACTIVITY_END_TIME =    "Activity End Time"
let WATCH_MSG_PARAM_ACTIVITY_LOCATIONS =   "Activity Locations"
let WATCH_MSG_PARAM_FILE_FORMAT =          "File Format"

class WatchSession : NSObject, WCSessionDelegate {
	var watchSession: WCSession = WCSession.default
	var timeOfLastMessage: time_t = 0  // Timestamp of the last time we got a message, use this to keep us from spamming
	
	func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
	}

	func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
	}
	
	func session(_ session: WCSession, didFinish fileTransfer: WCSessionFileTransfer, error: Error?) {
		do {
			let fileName = fileTransfer.file.fileURL.absoluteString

			if let activityId = fileTransfer.file.metadata![WATCH_MSG_PARAM_ACTIVITY_ID] as? String {
				CreateActivitySync(activityId, SYNC_DEST_PHONE);
			}
			try FileManager.default.removeItem(at: URL(string: fileName)!)
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
		NotificationCenter.default.addObserver(self, selector: #selector(self.activityStopped), name: Notification.Name(rawValue: NOTIFICATION_NAME_ACTIVITY_STOPPED), object: nil)
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

	/// @brief Called when connecting to the phone so we can determine which activities to send.
	func checkIfActivitiesAreUploadedToPhone() {
	}

	func sendActivityFileToPhone(activityId: String) -> Bool {
		return false
	}
	
	/// @brief This method is called in response to an activity stopped notification.
	@objc func activityStopped(notification: NSNotification) {
	}
}
