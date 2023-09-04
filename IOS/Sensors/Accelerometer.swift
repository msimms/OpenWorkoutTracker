//
//  Accelerometer.swift
//  Created by Michael Simms on 10/3/22.
//

import Foundation
import CoreMotion

// Subscribe to the notification with this name to receive updates.
let NOTIFICATION_NAME_ACCELEROMETER = "ALAccelerometerUpdated"

// Keys for the dictionary associated with the notification.
let KEY_NAME_ACCEL_X = AXIS_NAME_X
let KEY_NAME_ACCEL_Y = AXIS_NAME_Y
let KEY_NAME_ACCEL_Z = AXIS_NAME_Z
let KEY_NAME_ACCELEROMETER_TIMESTAMP_MS = "Time"

class Accelerometer {
	var motionManager: CMMotionManager = CMMotionManager()

	func start() {
		if self.motionManager.isAccelerometerAvailable {
#if TARGET_OS_WATCH
			self.motionManager.accelerometerUpdateInterval = 0.2
#else
			self.motionManager.accelerometerUpdateInterval = 0.1
#endif

			self.motionManager.startAccelerometerUpdates(to: OperationQueue.main, withHandler: { accelerometerData, error in
				let rawData = self.motionManager.accelerometerData
				let theTimeMs = Date().timeIntervalSince1970 * 1000
				var accelData: Dictionary<String, Double> = [:]
				accelData[KEY_NAME_ACCEL_X] = rawData?.acceleration.x
				accelData[KEY_NAME_ACCEL_Y] = rawData?.acceleration.y
				accelData[KEY_NAME_ACCEL_Z] = rawData?.acceleration.z
				accelData[KEY_NAME_ACCELEROMETER_TIMESTAMP_MS] = Double(theTimeMs)
				let notification = Notification(name: Notification.Name(rawValue: NOTIFICATION_NAME_ACCELEROMETER), object: accelData)
				NotificationCenter.default.post(notification)
			})
		}
	}

	func stop() {
		if self.motionManager.isAccelerometerAvailable {
			self.motionManager.stopAccelerometerUpdates()
		}
	}
}
