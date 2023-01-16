//
//  LocationSensor.swift
//  Created by Michael Simms on 10/3/22.
//

import Foundation
import CoreLocation

// Subscribe to the notification with this name to receive updates.
let NOTIFICATION_NAME_LOCATION = "ALLocationUpdated"

// Keys for the dictionary associated with the notification.
let KEY_NAME_LATITUDE = "Latitude"
let KEY_NAME_LONGITUDE = "Longitude"
let KEY_NAME_ALTITUDE = "Altitude"
let KEY_NAME_HORIZONTAL_ACCURACY = "Horizontal Accuracy"
let KEY_NAME_VERTICAL_ACCURACY = "Vertical Accuracy"
let KEY_NAME_LOCATION_TIMESTAMP_MS = "Time"

class LocationSensor : NSObject, CLLocationManagerDelegate {
	var locationManager: CLLocationManager = CLLocationManager()
	var currentLocation: CLLocation = CLLocation()
	var minAllowedHorizontalAccuracy: CLLocationAccuracy = 0.0
	var minAllowedVerticalAccuracy: CLLocationAccuracy = 0.0
	var discardBadDataPoints: Bool = false
	
	override init() {
		super.init()
		
		self.locationManager.delegate = self
		self.locationManager.activityType = CLActivityType.fitness
		self.locationManager.distanceFilter = kCLDistanceFilterNone
		self.locationManager.desiredAccuracy = kCLLocationAccuracyBest
		self.locationManager.allowsBackgroundLocationUpdates = true
		
		NotificationCenter.default.addObserver(self, selector: #selector(self.activityStarted), name: Notification.Name(rawValue: NOTIFICATION_NAME_ACTIVITY_STARTED), object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(self.activityStopped), name: Notification.Name(rawValue: NOTIFICATION_NAME_ACTIVITY_STOPPED), object: nil)
	}
	
	func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
	}
	
	func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
		for location in locations {
			let latitude = location.coordinate.latitude
			let longitude = location.coordinate.longitude
			let alt = location.altitude
			let horizontalAccuracy = location.horizontalAccuracy
			let verticalAccuracy = location.verticalAccuracy
			let theTimeMs = location.timestamp.timeIntervalSince1970 * 1000
			var processLocation = true
			
			// Check for bad data.
			if self.discardBadDataPoints {
				if horizontalAccuracy > self.minAllowedHorizontalAccuracy || verticalAccuracy > self.minAllowedVerticalAccuracy {
					processLocation = false
				}
			}
			
			// Write to the database, maybe.
			if processLocation {
				ProcessLocationReading(latitude, longitude, alt, horizontalAccuracy, verticalAccuracy, UInt64(theTimeMs))
			}
			else {
				var notificationData: Dictionary<String, String> = [:]
				notificationData[KEY_NAME_MESSAGE] = "Bad location data."
				let notification = Notification(name: Notification.Name(rawValue: NOTIFICATION_NAME_PRINT_MESSAGE), object: notificationData)
				NotificationCenter.default.post(notification)
			}
			
			// Inform any subscribers.
			var locData: Dictionary<String, Double> = [:]
			locData[KEY_NAME_LATITUDE] = latitude
			locData[KEY_NAME_LONGITUDE] = longitude
			locData[KEY_NAME_ALTITUDE] = alt
			locData[KEY_NAME_HORIZONTAL_ACCURACY] = horizontalAccuracy
			locData[KEY_NAME_VERTICAL_ACCURACY] = verticalAccuracy
			locData[KEY_NAME_LOCATION_TIMESTAMP_MS] = Double(theTimeMs)
			let notification = Notification(name: Notification.Name(rawValue: NOTIFICATION_NAME_LOCATION), object: locData)
			NotificationCenter.default.post(notification)
			
			self.currentLocation = location
		}
	}
	
	func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
	}
	
	func start() {
		if CLLocationManager.locationServicesEnabled() {
			switch self.locationManager.authorizationStatus {
			case CLAuthorizationStatus.denied:
				self.locationManager.requestAlwaysAuthorization()
				break
			case CLAuthorizationStatus.restricted:
				self.locationManager.requestAlwaysAuthorization()
				break
			case CLAuthorizationStatus.authorizedAlways:
				self.locationManager.startUpdatingLocation()
				break
			case CLAuthorizationStatus.authorizedWhenInUse:
				self.locationManager.startUpdatingLocation()
				break
			case CLAuthorizationStatus.notDetermined:
				self.locationManager.requestAlwaysAuthorization()
				break
			default:
				break
			}
		}
	}
	
	func stop() {
		self.locationManager.stopUpdatingLocation()
	}
	
	/// @brief This method is called in response to an activity started notification.
	@objc func activityStarted(notification: NSNotification) {
		let activityType = String(cString: UnsafeRawPointer(GetCurrentActivityType()).assumingMemoryBound(to: CChar.self))
		let filterOption = ActivityPreferences.getLocationFilterOption(activityType: activityType)

		switch filterOption {
		case .LOCATION_FILTER_WARN:
			self.discardBadDataPoints = false
			break
		case .LOCATION_FILTER_DROP:
			self.discardBadDataPoints = true
			break
		}
		
		self.minAllowedHorizontalAccuracy = CLLocationAccuracy(ActivityPreferences.getMinLocationHorizontalAccuracy(activityType: activityType))
		self.minAllowedVerticalAccuracy = CLLocationAccuracy(ActivityPreferences.getMinLocationVerticalAccuracy(activityType: activityType))
	}
	
	/// @brief This method is called in response to an activity stopped notification.
	@objc func activityStopped(notification: NSNotification) {
	}
}
