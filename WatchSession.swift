//
//  WatchSession.swift
//  Created by Michael Simms on 10/31/22.
//

import Foundation
import WatchConnectivity

class WatchSession : NSObject, WCSessionDelegate {
	var watchSession: WatchSession = WatchSession()
	var timeOfLastMessage: time_t = 0  // Timestamp of the last time we got a message, use this to keep us from spamming
	
	func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
	}
	
#if !os(watchOS)
	func sessionDidBecomeInactive(_ session: WCSession) {
	}
	
	func sessionDidDeactivate(_ session: WCSession) {
	}
#endif
	
	func startWatchSession() {
	}

	func sendActivityFileToPhone(activityId: String) -> Bool {
		return false
	}
}
