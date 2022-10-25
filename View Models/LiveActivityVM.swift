//
//  ActivityVM.swift
//  Created by Michael Simms on 9/23/22.
//

import Foundation
import MapKit

let VALUE_NOT_SET_STR: String = "--"
let COUNTDOWN_SECS: UInt = 4 // one more than 3 to handle the edge condition

struct AttributeNameCallbackType {
	var names: Array<String>
}

func attributeNameCallback(name: Optional<UnsafePointer<Int8>>, context: Optional<UnsafeMutableRawPointer>) {
	let attributeName = String(cString: UnsafeRawPointer(name!).assumingMemoryBound(to: CChar.self))
	let typedPointer = context!.bindMemory(to: AttributeNameCallbackType.self, capacity: 1)
	typedPointer.pointee.names.append(attributeName)
}

class LiveActivityVM : ObservableObject {
	@Published var currentMessage: String = ""

	@Published var title1: String = "Title"
	@Published var title2: String = "Title"
	@Published var title3: String = "Title"
	@Published var title4: String = "Title"
	@Published var title5: String = "Title"
	@Published var title6: String = "Title"
	@Published var title7: String = "Title"
	@Published var title8: String = "Title"
	@Published var title9: String = "Title"
	
	@Published var value1: String = ""
	@Published var value2: String = ""
	@Published var value3: String = ""
	@Published var value4: String = ""
	@Published var value5: String = ""
	@Published var value6: String = ""
	@Published var value7: String = ""
	@Published var value8: String = ""
	@Published var value9: String = ""
	
	@Published var units1: String = "Units"
	@Published var units2: String = "Units"
	@Published var units3: String = "Units"
	@Published var units4: String = "Units"
	@Published var units5: String = "Units"
	@Published var units6: String = "Units"
	@Published var units7: String = "Units"
	@Published var units8: String = "Units"
	@Published var units9: String = "Units"
	
	@Published var viewType: ActivityViewType = ACTIVITY_VIEW_COMPLEX
	@Published var autoStartEnabled: Bool = false

	var isInProgress: Bool = false
	var isPaused: Bool = false
	var isStopped: Bool = false // Has been stopped (after being started)
	var countdownSecsRemaining: UInt = 0

	var locationTrack: Array<CLLocationCoordinate2D> = []
	var currentLat: Double = 0.0
	var currentLon: Double = 0.0
#if !os(watchOS)
	@Published var route: MKPolyline = MKPolyline()
#endif

	private var autoStartCoordinate: Coordinate = Coordinate(latitude: 0.0, longitude: 0.0, altitude: 0.0, horizontalAccuracy: 0.0, verticalAccuracy: 0.0, time: 0)
	private var sensorMgr = SensorMgr.shared
	private var activityAttributePrefs: Array<String> = []
	private var timer: Timer = Timer()
	private var activityId: String = ""
	private var activityType: String = ""

	init (activityType: String) {
		self.create(activityType: activityType)
		self.activityType = activityType
	}
	
	func create(activityType: String) {
		
		// Create the backend structures needed to do the activity.
		CreateActivityObject(activityType)

		// What attributes does the user wish to display when doing this activity?
		let activityPrefs = ActivityPreferences()
		self.activityAttributePrefs = activityPrefs.getActivityLayout(activityType: activityType)

		// Preferred view layout.
		self.viewType = ActivityPreferences.getDefaultViewForActivityType(activityType: activityType)

		// Configure the location accuracy parameters.
		self.sensorMgr.location.minAllowedHorizontalAccuracy = Double(ActivityPreferences.getMinLocationHorizontalAccuracy(activityType: activityType))
		self.sensorMgr.location.minAllowedVerticalAccuracy = Double(ActivityPreferences.getMinLocationVerticalAccuracy(activityType: activityType))

		// Start the sensors.
		self.sensorMgr.startSensors()
		
		// Generate a unique identifier for this activity.
		self.activityId = NSUUID().uuidString

		//let screenLocking = ActivityPreferences.getScreenAutoLocking(activityType: activityType)
		//UIApplication.shared.isIdleTimerDisabled = !screenLocking

		// Timer to periodically refresh the view.
		self.timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { tempTimer in
			
			// Autostart?
			if !self.isInProgress && self.autoStartEnabled {
				let MIN_AUTOSTART_DISTANCE = 25.0 // Meters

				let currentLocation = self.sensorMgr.location.currentLocation
				let currentCoordinate: Coordinate = Coordinate(latitude: currentLocation.coordinate.latitude, longitude: currentLocation.coordinate.longitude, altitude: currentLocation.altitude, horizontalAccuracy: 0.0, verticalAccuracy: 0.0, time: 0)

				let distance = DistanceBetweenCoordinates(currentCoordinate, self.autoStartCoordinate)
				if distance > MIN_AUTOSTART_DISTANCE {
					if !self.doStart() {
						NSLog("Failed to start the activity after enough movement to trigger an autostart.")
					}
				}
			}

			// Countdown?
			else if self.countdownSecsRemaining > 0 {
				self.countdownSecsRemaining -= 1
				if self.countdownSecsRemaining == 0 {
					if !self.doStart() {
						NSLog("Failed to start the activity after the countdown timer expired.")
					}
				}
			}
			
			// Split beep?
			
			// Update the location and route.
			if IsMovingActivity() {
				self.currentLat = self.sensorMgr.location.currentLocation.coordinate.latitude
				self.currentLon = self.sensorMgr.location.currentLocation.coordinate.latitude
				self.locationTrack.append(CLLocationCoordinate2D(latitude: self.currentLat, longitude: self.currentLon))
#if !os(watchOS)
				self.route = MKPolyline(coordinates: self.locationTrack, count: self.locationTrack.count)
#endif
			}

			// Update the displayed attributes.
			var index = 1
			for activityAttribute in self.activityAttributePrefs {
				var attr = QueryLiveActivityAttribute(activityAttribute)
				ConvertToPreferredUntis(&attr)
				
				let valueStr = LiveActivityVM.formatActivityValue(attribute: attr)
				let measureStr = LiveActivityVM.formatActivityMeasureType(measureType: attr.measureType)

				switch index {
				case 1:
					self.title1 = activityAttribute
					self.value1 = valueStr
					self.units1 = measureStr
					break
				case 2:
					self.title2 = activityAttribute
					self.value2 = valueStr
					self.units2 = measureStr
					break
				case 3:
					self.title3 = activityAttribute
					self.value3 = valueStr
					self.units3 = measureStr
					break
				case 4:
					self.title4 = activityAttribute
					self.value4 = valueStr
					self.units4 = measureStr
					break
				case 5:
					self.title5 = activityAttribute
					self.value5 = valueStr
					self.units5 = measureStr
					break
				case 6:
					self.title6 = activityAttribute
					self.value6 = valueStr
					self.units6 = measureStr
					break
				case 7:
					self.title7 = activityAttribute
					self.value7 = valueStr
					self.units7 = measureStr
					break
				case 8:
					self.title8 = activityAttribute
					self.value8 = valueStr
					self.units8 = measureStr
					break
				case 9:
					self.title9 = activityAttribute
					self.value9 = valueStr
					self.units9 = measureStr
					break
				default:
					break
				}
				index += 1
			}
		}
	}
	
	/// @brief Enables (or disables) auto start.
	func setAutoStart() -> Bool {
		let currentState = IsAutoStartEnabled()
		self.autoStartEnabled = !currentState

		// Remember where we were when the autostart button was pressed.
		if self.autoStartEnabled {
			let autoStartLocation = self.sensorMgr.location.currentLocation
			self.autoStartCoordinate = Coordinate(latitude: autoStartLocation.coordinate.latitude, longitude: autoStartLocation.coordinate.longitude, altitude: autoStartLocation.altitude, horizontalAccuracy: 0.0, verticalAccuracy: 0.0, time: 0)
		}

		SetAutoStart(self.autoStartEnabled)
		return self.autoStartEnabled
	}

	/// @brief Helper function for starting an activity..
	func doStart() -> Bool {
		if StartActivity(self.activityId) {

			// Update state.
			self.isInProgress = true
			self.isPaused = false
			self.autoStartEnabled = false

			// Tell any subscribers that we've started an activity.
			var notificationData: Dictionary<String, String> = [:]
			notificationData[KEY_NAME_ACTIVITY_ID] = self.activityId
			let notification = Notification(name: Notification.Name(rawValue: NOTIFICATION_NAME_ACTIVITY_STARTED), object: notificationData)
			NotificationCenter.default.post(notification)

			return true
		}
		return false
	}

	/// @brief Starts the activity. Called from the UI.
	func start() -> Bool {
		if ActivityPreferences.getCountdown(activityType: self.activityType) {
			self.countdownSecsRemaining = COUNTDOWN_SECS
			return true
		}
		return doStart()
	}

	/// @brief Stops the activity.
	func stop() -> String {
		if StopCurrentActivity() {

			// So we don't have to recompute everything each time the activity is loaded, save a summary.
			SaveActivitySummaryData();
			
			// Delete the object.
			DestroyCurrentActivity();
			
			// Stop requesting data from sensors.
			self.sensorMgr.stopSensors()

			// Update state.
			self.isInProgress = false
			self.isPaused = false
			self.autoStartEnabled = false
			self.isStopped = true

			// Tell any subscribers that we've stopped an activity.
			var notificationData: Dictionary<String, String> = [:]
			notificationData[KEY_NAME_ACTIVITY_ID] = self.activityId
			let notification = Notification(name: Notification.Name(rawValue: NOTIFICATION_NAME_ACTIVITY_STOPPED), object: notificationData)
			NotificationCenter.default.post(notification)
		}
		return self.activityId
	}

	/// @brief Pauses the activity.
	func pause() {
		self.isPaused = PauseCurrentActivity()
	}

	/// @brief Starts a new lap.
	func lap() {
		StartNewLap()
	}
	
	func getCurrentActivityType() -> String {
		let ptr = UnsafeRawPointer(GetCurrentActivityType())
		let activityType = String(cString: ptr!.assumingMemoryBound(to: CChar.self))

		defer {
			ptr!.deallocate()
		}
		return activityType
	}
	
	func getCurrentActivityId() -> String {
		let activityId = String(cString: UnsafeRawPointer(GetCurrentActivityId()).assumingMemoryBound(to: CChar.self))
		return activityId
	}

	/// @brief Lists all the attributes that are applicable to the current activity.
	func getActivityAttributeNames() -> Array<String> {
		let pointer = UnsafeMutablePointer<AttributeNameCallbackType>.allocate(capacity: 1)

		defer {
			pointer.deinitialize(count: 1)
			pointer.deallocate()
		}

		pointer.pointee = AttributeNameCallbackType(names: [])
		GetActivityAttributeNames(attributeNameCallback, pointer)
		let attributeNames = pointer.pointee.names

		return attributeNames
	}

	func setDisplayedActivityAttributeName(position: Int, attributeName: String) {
		self.activityAttributePrefs.remove(at: position)
		self.activityAttributePrefs.insert(attributeName, at: position)

		let activityPrefs = ActivityPreferences()
		activityPrefs.setActivityLayout(activityType: self.activityType, layout: self.activityAttributePrefs)
	}

	/// @brief Utility function for formatting things like Elapsed Time, etc.
	static func formatSeconds(numSeconds: time_t) -> String {
		let SECS_PER_DAY  = 86400
		let SECS_PER_HOUR = 3600
		let SECS_PER_MIN  = 60

		var tempSeconds = numSeconds
		let days = (tempSeconds / SECS_PER_DAY)
		tempSeconds -= (days * SECS_PER_DAY)
		let hours = (tempSeconds / SECS_PER_HOUR)
		tempSeconds -= (hours * SECS_PER_HOUR)
		let minutes = (tempSeconds / SECS_PER_MIN)
		tempSeconds -= (minutes * SECS_PER_MIN)
		let seconds = (tempSeconds % SECS_PER_MIN)

		if days > 0 {
			return String(format: "%02d:%02d:%02d:%02d", days, hours, minutes, seconds)
		}
		else if hours > 0 {
			return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
		}
		return String(format: "%02d:%02d", minutes, seconds)
	}

	/// @brief Utility function for converting an activity attribute structure to something human readable.
	static func formatActivityValue(attribute: ActivityAttributeType) -> String {
		if attribute.valid {
			switch attribute.valueType {
			case TYPE_NOT_SET:
				return VALUE_NOT_SET_STR
			case TYPE_TIME:
				return LiveActivityVM.formatSeconds(numSeconds: attribute.value.timeVal)
			case TYPE_DOUBLE:
				if attribute.measureType == MEASURE_DISTANCE {
					return String(format: "%0.2f", attribute.value.doubleVal)
				}
				else if attribute.measureType == MEASURE_DEGREES {
					return String(format: "%0.6f", attribute.value.doubleVal)
				}
				else if attribute.measureType == MEASURE_PERCENTAGE {
					return String(format: "%0.1f", attribute.value.doubleVal * 1000.0)
				}
				else if attribute.measureType == MEASURE_BPM {
					return String(format: "%0.0f", attribute.value.doubleVal)
				}
				else if attribute.measureType == MEASURE_RPM {
					return String(format: "%0.0f", attribute.value.doubleVal)
				}
				else if attribute.measureType == MEASURE_CALORIES {
					return String(format: "%0.0f", attribute.value.doubleVal)
				}
				else {
					return String(format: "%0.1f", attribute.value.doubleVal)
				}
			case TYPE_INTEGER:
				return String(format: "%llu", attribute.value.intVal)
			default:
				return ""
			}
		}
		else {
			return VALUE_NOT_SET_STR
		}
	}

	/// @brief Utility function for formatting unit strings.
	static func formatActivityMeasureType(measureType: ActivityAttributeMeasureType) -> String {
		switch measureType {
		case MEASURE_NOT_SET:
			return ""
		case MEASURE_TIME:
			return ""
		case MEASURE_PACE:
			let preferredUnits = Preferences.preferredUnitSystem()
			if preferredUnits == UNIT_SYSTEM_METRIC {
				return "mins/km"
			}
			else if preferredUnits == UNIT_SYSTEM_US_CUSTOMARY {
				return "mins/mile"
			}
			return ""
		case MEASURE_SPEED:
			let preferredUnits = Preferences.preferredUnitSystem()
			if preferredUnits == UNIT_SYSTEM_METRIC {
				return "kph"
			}
			else if preferredUnits == UNIT_SYSTEM_US_CUSTOMARY {
				return "mph"
			}
			return ""
		case MEASURE_DISTANCE:
			let preferredUnits = Preferences.preferredUnitSystem()
			if preferredUnits == UNIT_SYSTEM_METRIC {
				return "kms"
			}
			else if preferredUnits == UNIT_SYSTEM_US_CUSTOMARY {
				return "miles"
			}
			return ""
		case MEASURE_WEIGHT:
			let preferredUnits = Preferences.preferredUnitSystem()
			if preferredUnits == UNIT_SYSTEM_METRIC {
				return "kgs"
			}
			else if preferredUnits == UNIT_SYSTEM_US_CUSTOMARY {
				return "lbs"
			}
			return ""
		case MEASURE_HEIGHT:
			let preferredUnits = Preferences.preferredUnitSystem()
			if preferredUnits == UNIT_SYSTEM_METRIC {
				return "cm"
			}
			else if preferredUnits == UNIT_SYSTEM_US_CUSTOMARY {
				return "inches"
			}
			return ""
		case MEASURE_ALTITUDE:
			let preferredUnits = Preferences.preferredUnitSystem()
			if preferredUnits == UNIT_SYSTEM_METRIC {
				return "meters"
			}
			else if preferredUnits == UNIT_SYSTEM_US_CUSTOMARY {
				return "ft"
			}
			return ""
		case MEASURE_COUNT:
			return ""
		case MEASURE_BPM:
			return "bpm"
		case MEASURE_POWER:
			return "watts"
		case MEASURE_CALORIES:
			return "kcal"
		case MEASURE_DEGREES:
			return "deg"
		case MEASURE_G:
			return "G"
		case MEASURE_PERCENTAGE:
			return "%"
		case MEASURE_RPM:
			return "rpm"
		case MEASURE_LOCATION_ACCURACY:
			return "meters"
		case MEASURE_INDEX:
			return ""
		case MEASURE_ID:
			return ""
		default:
			return ""
		}
	}
}
