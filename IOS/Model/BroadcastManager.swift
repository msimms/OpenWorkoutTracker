//
//  BroadcastManager.swift
//  Created by Michael Simms on 9/29/22.
//

import Foundation

class BroadcastManager {
	static let shared = BroadcastManager()
	
	var locationCache: Array<String> = []      // Locations to be sent
	var accelerometerCache: Array<String> = [] // Accelerometer readings to be sent
	var lastCacheFlush: UInt64 = 0             // Unix time of the cache flush
	var deviceId: String = ""                  // Unique identifier for the device doing the sending
	var dataBeingSent: String = ""             // Formatted data to be sent
	var errorSending: Bool = false             // Whether or not the last send was successful
	var currentActivityId: String = ""         // Cached for performance reasons
	var currentActivityType: String = ""       // Cached for performance reasons

	/// Singleton constructor
	private init() {
		NotificationCenter.default.addObserver(self, selector: #selector(self.accelerometerUpdated), name: Notification.Name(rawValue: NOTIFICATION_NAME_ACCELEROMETER), object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(self.locationUpdated), name: Notification.Name(rawValue: NOTIFICATION_NAME_LOCATION), object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(self.activityStarted), name: Notification.Name(rawValue: NOTIFICATION_NAME_ACTIVITY_STARTED), object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(self.activityStopped), name: Notification.Name(rawValue: NOTIFICATION_NAME_ACTIVITY_STOPPED), object: nil)
	}
	
	func getCurrentActivityId() -> String {
		let activityId = String(cString: UnsafeRawPointer(GetCurrentActivityId()).assumingMemoryBound(to: CChar.self))
		return activityId
	}
	
	func getCurrentActivityType() -> String {
		let activityType = String(cString: UnsafeRawPointer(GetCurrentActivityType()).assumingMemoryBound(to: CChar.self))
		return activityType
	}
	
	func displayMessage(text: String) {
	}
	
	func updateBroadcastStatus(status: Bool) {
	}

	func sendToServer(hostName: String, path: String, data: String, activityId: String, isStopped: Bool) {
		let protocolStr = Preferences.broadcastProtocol()
		let urlStr = String(format: "%@://%@/%s", protocolStr, hostName, path)
		let postLength = String(format: "%lu", data.count)
		
		var request = URLRequest(url: URL(string: urlStr)!)
		request.timeoutInterval = 30.0
		request.allowsExpensiveNetworkAccess = true
		request.httpMethod = "POST"
		request.setValue(postLength, forHTTPHeaderField:"Content-Length")
		request.setValue("application/json", forHTTPHeaderField:"Content-Type")
		request.httpBody = data.data(using: .utf8)
		
		let session = URLSession.shared
		let dataTask = session.dataTask(with: request) { data, response, error in
			if let httpResponse = response as? HTTPURLResponse {
				if httpResponse.statusCode == 200 {
					self.updateBroadcastStatus(status: true)
					self.dataBeingSent = ""
					self.errorSending = false
					
					if isStopped {
//						dispatch_async(dispatch_get_main_queue(),^{
//							[[NSNotificationCenter defaultCenter] postNotificationName:@NOTIFICATION_NAME_BROADCAST_MGR_SENT_ACTIVITY object:activityId];
//						} );
					}
				}
				else {
//					self.displayMessage(text: MESSAGE_ERROR_SENDING)
					self.updateBroadcastStatus(status: false)
					self.errorSending = true
				}
			}
		}
		dataTask.resume()
	}

	func flushGlobalBroadcastCacheRest(isStopped: Bool) {
		// No host name set, just return.
		let hostName = Preferences.broadcastHostName()
		if hostName.count == 0 {
			print("Broadcast host name not specified.")
			return
		}
		
		// Still waiting on last data to be sent.
		if self.dataBeingSent.count > 0 {
			if self.errorSending {
				self.sendToServer(hostName: hostName, path: REMOTE_API_UPDATE_STATUS_URL, data: self.dataBeingSent, activityId: self.currentActivityId, isStopped: isStopped)
				print("Resending.")
			}
			else {
				print("Waiting on previous data to be sent.")
			}
			self.lastCacheFlush = UInt64(time(nil))
			return
		}
		
		// Write cached location data to the JSON string.
		var post = "{\"locations\": ["
		var numLocObjsBeingSent = 0
		for text in self.locationCache {
			if numLocObjsBeingSent > 0 {
				post += ",\n"
			}
			post += text
			numLocObjsBeingSent += 1
		}
		self.locationCache.removeAll()
		post += "]"
		
		// Write cached accelerometer data to the JSON string.
		post += "accelerometer\": ["
		var numAccelObjsBeingSent = 0
		for text in self.accelerometerCache {
			if numAccelObjsBeingSent > 0 {
				post += ",\n"
			}
			post += text
			numAccelObjsBeingSent += 1
		}
		self.accelerometerCache.removeAll()
		post += "]"
		
		// Add the device ID to the JSON string.
		if self.deviceId.count > 0 {
			post += String(format: ",\n\"%s\":\"%@\"", KEY_NAME_DEVICE_ID, self.deviceId)
		}
		
		// Add the activity ID to the JSON string.
		post += String(format: ",\n\"%s\":\"%@\"", KEY_NAME_ACTIVITY_ID, self.currentActivityId)
		
		// Add the activity type to the JSON string.
		post += String(format: ",\n\"%s\":\"%s\"", KEY_NAME_ACTIVITY_TYPE, self.currentActivityType)
		
		// Add the user name to the JSON string.
		let userName = Preferences.broadcastUserName()
		if userName != nil && userName!.count > 0 {
			post += String(format: ",\n\"%s\":\"%@\"", ACTIVITY_ATTRIBUTE_USER_NAME, userName!)
		}
		post += "}\n"
		
		if (numLocObjsBeingSent > 0) || (numAccelObjsBeingSent > 0) {
			self.sendToServer(hostName: hostName, path: REMOTE_API_UPDATE_STATUS_URL, data: post, activityId: self.currentActivityId, isStopped: isStopped)
		}
		
		self.lastCacheFlush = UInt64(time(nil))
	}
	
	func broadcast() {
		// Flush at the user-specified interval. Default to 60 seconds if one was not specified.
		let rate = Preferences.broadcastRate()
		
		if ((self.locationCache.count > 0 || self.accelerometerCache.count > 0) && (UInt64(time(nil)) - self.lastCacheFlush > rate)) {
			self.flushGlobalBroadcastCacheRest(isStopped: false)
		}
	}
	
	/// @brief This method is called in response to an accelerometer updated notification.
	@objc func accelerometerUpdated(notification: NSNotification) {
		if !Preferences.shouldBroadcastToServer() {
			return
		}
		if !IsActivityInProgress() {
			return
		}
		if !(IsLiftingActivity() || IsSwimmingActivity()) {
			return
		}

		if let accelerometerData = notification.object as? Dictionary<String, AnyObject> {

			do {
				let jsonData = try JSONSerialization.data(withJSONObject: accelerometerData, options: [])
				let text = String(data: jsonData, encoding: String.Encoding.ascii)!
				
				self.accelerometerCache.append(text)
				self.broadcast()
			}
			catch {
			}
		}
	}
	
	/// @brief This method is called in response to a location updated notification.
	@objc func locationUpdated(notification: NSNotification) {
		if !Preferences.shouldBroadcastToServer() {
			return
		}
		if !IsActivityInProgress() {
			return
		}
		if !IsMovingActivity() {
			return
		}
		
		if var locationData = notification.object as? Dictionary<String, AnyObject> {

			do {
				var attr = QueryLiveActivityAttribute(ACTIVITY_ATTRIBUTE_DISTANCE_TRAVELED)
				if attr.valid {
					locationData[ACTIVITY_ATTRIBUTE_DISTANCE_TRAVELED] = attr.value.doubleVal as AnyObject?
				}
				
				attr = QueryLiveActivityAttribute(ACTIVITY_ATTRIBUTE_AVG_SPEED);
				if attr.valid {
					ConvertToBroadcastUnits(&attr)
					locationData[ACTIVITY_ATTRIBUTE_AVG_SPEED] = attr.value.doubleVal as AnyObject?
				}
				
				attr = QueryLiveActivityAttribute(ACTIVITY_ATTRIBUTE_CURRENT_SPEED);
				if attr.valid {
					ConvertToBroadcastUnits(&attr);
					locationData[ACTIVITY_ATTRIBUTE_CURRENT_SPEED] = attr.value.doubleVal as AnyObject?
				}
				
				attr = QueryLiveActivityAttribute(ACTIVITY_ATTRIBUTE_MOVING_SPEED);
				if attr.valid {
					ConvertToBroadcastUnits(&attr);
					locationData[ACTIVITY_ATTRIBUTE_MOVING_SPEED] = attr.value.doubleVal as AnyObject?
				}
				
				attr = QueryLiveActivityAttribute(ACTIVITY_ATTRIBUTE_AVG_PACE);
				if attr.valid {
					ConvertToBroadcastUnits(&attr);
					locationData[ACTIVITY_ATTRIBUTE_AVG_PACE] = attr.value.doubleVal as AnyObject?
				}
				
				attr = QueryLiveActivityAttribute(ACTIVITY_ATTRIBUTE_AVG_HEART_RATE);
				if attr.valid {
					locationData[ACTIVITY_ATTRIBUTE_AVG_HEART_RATE] = attr.value.doubleVal as AnyObject?
				}
				
				attr = QueryLiveActivityAttribute(ACTIVITY_ATTRIBUTE_HEART_RATE);
				if attr.valid {
					locationData[ACTIVITY_ATTRIBUTE_HEART_RATE] = attr.value.doubleVal as AnyObject?
				}
				
				attr = QueryLiveActivityAttribute(ACTIVITY_ATTRIBUTE_AVG_CADENCE);
				if attr.valid {
					locationData[ACTIVITY_ATTRIBUTE_AVG_CADENCE] = attr.value.doubleVal as AnyObject?
				}
				
				attr = QueryLiveActivityAttribute(ACTIVITY_ATTRIBUTE_CADENCE);
				if attr.valid {
					locationData[ACTIVITY_ATTRIBUTE_CADENCE] = attr.value.doubleVal as AnyObject?
				}
				
				attr = QueryLiveActivityAttribute(ACTIVITY_ATTRIBUTE_AVG_POWER);
				if attr.valid {
					locationData[ACTIVITY_ATTRIBUTE_AVG_POWER] = attr.value.doubleVal as AnyObject?
				}
				
				attr = QueryLiveActivityAttribute(ACTIVITY_ATTRIBUTE_POWER);
				if attr.valid {
					locationData[ACTIVITY_ATTRIBUTE_POWER] = attr.value.doubleVal as AnyObject?
				}
				
				attr = QueryLiveActivityAttribute(ACTIVITY_ATTRIBUTE_THREAT_COUNT);
				if attr.valid {
					locationData[ACTIVITY_ATTRIBUTE_THREAT_COUNT] = attr.value.doubleVal as AnyObject?
				}
				
				let jsonData = try JSONSerialization.data(withJSONObject: locationData, options: [])
				let text = String(data: jsonData, encoding: String.Encoding.ascii)!
				
				self.locationCache.append(text)
				self.broadcast()
			}
			catch {
			}
		}
	}

	/// @brief This method is called in response to an activity started notification.
	@objc func activityStarted(notification: NSNotification) {
		self.locationCache.removeAll()
		self.accelerometerCache.removeAll()
		self.lastCacheFlush = UInt64(time(nil))
		self.currentActivityId = self.getCurrentActivityId()
		self.currentActivityType = self.getCurrentActivityType()
	}
	
	/// @brief This method is called in response to an activity stopped notification.
	@objc func activityStopped(notification: NSNotification) {
		self.flushGlobalBroadcastCacheRest(isStopped: true)
	}
}
