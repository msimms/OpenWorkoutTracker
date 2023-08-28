//
//  ActivityVM.swift
//  Created by Michael Simms on 9/23/22.
//

import Foundation
import MapKit
import SwiftUI
import AVFoundation

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
	
	@Published var title1: String = ""
	@Published var title2: String = ""
	@Published var title3: String = ""
	@Published var title4: String = ""
	@Published var title5: String = ""
	@Published var title6: String = ""
	@Published var title7: String = ""
	@Published var title8: String = ""
	@Published var title9: String = ""
	
	@Published var value1: String = ""
	@Published var value2: String = ""
	@Published var value3: String = ""
	@Published var value4: String = ""
	@Published var value5: String = ""
	@Published var value6: String = ""
	@Published var value7: String = ""
	@Published var value8: String = ""
	@Published var value9: String = ""
	
	@Published var units1: String = ""
	@Published var units2: String = ""
	@Published var units3: String = ""
	@Published var units4: String = ""
	@Published var units5: String = ""
	@Published var units6: String = ""
	@Published var units7: String = ""
	@Published var units8: String = ""
	@Published var units9: String = ""
	
	@Published var viewType: ActivityViewType = ACTIVITY_VIEW_COMPLEX
	
	var isInProgress: Bool = false
	var isPaused: Bool = false
	var isStopped: Bool = false // Has been stopped (after being started)
	var autoStartEnabled: Bool = false
	var isMovingActivity: Bool = false
	var countdownSecsRemaining: UInt = 0
	
#if !os(watchOS)
	var locationTrack: Array<CLLocationCoordinate2D> = []
	@Published var trackLine: MKPolyline = MKPolyline()
#endif
	
	private var autoStartCoordinate: Coordinate = Coordinate(latitude: 0.0, longitude: 0.0, altitude: 0.0, horizontalAccuracy: 0.0, verticalAccuracy: 0.0, time: 0)
	private var prevCoordinate: Coordinate = Coordinate(latitude: 0.0, longitude: 0.0, altitude: 0.0, horizontalAccuracy: 0.0, verticalAccuracy: 0.0, time: 0)
	private var activityAttributePrefs: Array<String> = []
	private var timer: Timer?
	private var activityId: String = ""
	private var activityType: String = ""
	private var audioPlayer: AVAudioPlayer?
	private var currentMessageTime: time_t = 0 // timestamp of when the current message was set, allows us to know when to clear it
	
	init(activityType: String, recreateOrphanedActivities: Bool) {
		self.create(activityType: activityType, recreateOrphanedActivities: recreateOrphanedActivities)
	}
	
	func create(activityType: String, recreateOrphanedActivities: Bool) {

		NotificationCenter.default.addObserver(self, selector: #selector(self.messageReceived), name: Notification.Name(rawValue: NOTIFICATION_NAME_PRINT_MESSAGE), object: nil)

		self.activityType = activityType

		var activityTypeToUse = activityType
		var orphanedActivityIndex: size_t = 0
		var isNewActivity: Bool = true

		// Perhaps the app shutdown poorly (phone rebooted, etc.).
		// Check for an existing, in progress, activity.
		if IsActivityOrphaned(&orphanedActivityIndex) || IsActivityInProgress() {

			let orphanedActivityIdPtr = UnsafeRawPointer(ConvertActivityIndexToActivityId(orphanedActivityIndex)) // const char*, no need to dealloc
			let orphanedActivityTypePtr = UnsafeRawPointer(GetHistoricalActivityType(orphanedActivityIndex))
			var activityRecreated = false

			defer {
				orphanedActivityTypePtr!.deallocate()
			}

			let orphanedActivityType = String(cString: orphanedActivityTypePtr!.assumingMemoryBound(to: CChar.self))
			if orphanedActivityType.count > 0 {
				activityTypeToUse = orphanedActivityType

				if recreateOrphanedActivities {
					ReCreateOrphanedActivity(orphanedActivityIndex)
					
					self.activityId = String(cString: orphanedActivityIdPtr!.assumingMemoryBound(to: CChar.self))
					self.isInProgress = true
					isNewActivity = false
					activityRecreated = true
				}
			}

			if activityRecreated == false {
				self.loadHistoricalActivityByIndex(activityIndex: orphanedActivityIndex)
			}
		}

		// Create the backend structures needed to do the activity.
		if isNewActivity == true {
			CreateActivityObject(activityTypeToUse)

			// Generate a unique identifier for this activity.
			self.activityId = NSUUID().uuidString
		}

		// Which attributes does the user wish to display when doing this activity?
		let activityPrefs = ActivityPreferences()
		self.activityAttributePrefs = activityPrefs.getActivityLayout(activityType: activityTypeToUse)

		// Preferred view layout.
		self.viewType = ActivityPreferences.getDefaultViewForActivityType(activityType: activityTypeToUse)

		// Configure the location accuracy parameters.
		SensorMgr.shared.location.minAllowedHorizontalAccuracy = Double(ActivityPreferences.getMinLocationHorizontalAccuracy(activityType: activityTypeToUse))
		SensorMgr.shared.location.minAllowedVerticalAccuracy = Double(ActivityPreferences.getMinLocationVerticalAccuracy(activityType: activityTypeToUse))

		// Start the sensors.
		SensorMgr.shared.startSensors()

		// This won't change. Cache it.
		self.isMovingActivity = IsMovingActivity()

		// Have we played the start beep yet?
		var playedStartBeep = false

		// Used for determining if we need to play the split beep.
		var lastSplitNum = 0
		var splitAttrName = ACTIVITY_ATTRIBUTE_NUM_KM_SPLITS
		if Preferences.preferredUnitSystem() == UNIT_SYSTEM_US_CUSTOMARY {
			splitAttrName = ACTIVITY_ATTRIBUTE_NUM_MILE_SPLITS
		}

		// Stop the existing timer.
		if self.timer != nil {
			self.timer?.invalidate()
			self.timer = nil
		}

		// Timer to periodically refresh the view.
		self.timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { tempTimer in

			// Clear the message display?
			if self.currentMessageTime > 0 {
				let now = time(nil)
				if now - self.currentMessageTime >= 3 {
					self.currentMessage = ""
					self.currentMessageTime = 0
				}
			}
			
			// Autostart?
			if !self.isInProgress && self.autoStartEnabled {
				let MIN_AUTOSTART_DISTANCE = 25.0 // Meters

				let currentLocation = SensorMgr.shared.location.currentLocation
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
				else {
					self.playPingSound()
				}
			}
			
			// Start and split beeps?
			if self.isMovingActivity && self.isInProgress {
				
				// Have we started a new mile or kilometer?
				var newSplit = false
				let attr = QueryLiveActivityAttribute(splitAttrName)
				if attr.valid && attr.value.intVal > lastSplitNum {
					newSplit = true
					lastSplitNum += 1
				}
				
#if os(watchOS)
				// Start beep
				if !playedStartBeep && Preferences.watchStartStopBeeps() {
					self.playBeepSound()
					playedStartBeep = true
				}
				
				// Split beep
				if newSplit && self.activityType == ACTIVITY_TYPE_RUNNING {
					if Preferences.watchRunSplitBeeps() {
						self.playPingSound()
					}
				}
#else
				// Start beep
				if !playedStartBeep && ActivityPreferences.getStartStopBeepEnabled(activityType: activityTypeToUse) {
					self.playBeepSound()
					playedStartBeep = true
				}
				
				// Split beep
				if newSplit && ActivityPreferences.getSplitBeepEnabled(activityType: activityTypeToUse) {
					self.playPingSound()
				}
#endif
			}
			
			// Update the interval session.
			if CheckCurrentIntervalSession() {
				
				if IsIntervalSessionComplete() {
					self.currentMessage = "The interval session is complete."
				}
				else {
					var segment: IntervalSessionSegment = IntervalSessionSegment()
					
					if GetCurrentIntervalSessionSegment(&segment) {
						let segmentVm: IntervalSegment = IntervalSegment(backendStruct: segment)
						let description = segmentVm.intervalDescription()
						let progress = segmentVm.intervalProgressDescription()

						self.currentMessage = description + " " + progress
					}
				}
			}
			
#if !os(watchOS)
			// Update the location and route.
			if self.isMovingActivity && self.isInProgress {
				let currentLocation = SensorMgr.shared.location.currentLocation
				let currentCoordinate: Coordinate = Coordinate(latitude: currentLocation.coordinate.latitude, longitude: currentLocation.coordinate.longitude, altitude: currentLocation.altitude, horizontalAccuracy: 0.0, verticalAccuracy: 0.0, time: 0)
				
				// Performance optimization. Don't add every point to the track.
				let distance = DistanceBetweenCoordinates(currentCoordinate, self.prevCoordinate)
				if distance > 10 {
					self.locationTrack.append(CLLocationCoordinate2D(latitude: currentCoordinate.latitude, longitude: currentCoordinate.longitude))
					self.trackLine = MKPolyline(coordinates: self.locationTrack, count: self.locationTrack.count)
					self.prevCoordinate = currentCoordinate
				}
			}
#endif
			
			// Update the displayed attributes.
			for (index, activityAttribute) in self.activityAttributePrefs.enumerated() {
				var attr = QueryLiveActivityAttribute(activityAttribute)
				
				// Make sure we're dealing with the units the user wants to see.
				ConvertToPreferredUnits(&attr)
				
				// If the activity hasn't been started yet then we should just grab sensor data directly
				// instead of looking in the database.
				if !self.isInProgress {
					if activityAttribute == ACTIVITY_ATTRIBUTE_HEART_RATE {
						attr = InitializeActivityAttribute(TYPE_INTEGER, MEASURE_BPM, UNIT_SYSTEM_METRIC)
#if os(watchOS)
						attr.value.intVal = UInt64(HealthManager.shared.currentHeartRate)
						attr.valid = HealthManager.shared.heartRateRead
#else
						attr.value.intVal = UInt64(SensorMgr.shared.currentHeartRateBpm)
						attr.valid = SensorMgr.shared.heartRateConnected
#endif
					}
					else if activityAttribute == ACTIVITY_ATTRIBUTE_POWER {
						attr = InitializeActivityAttribute(TYPE_INTEGER, MEASURE_POWER, UNIT_SYSTEM_METRIC)
						attr.value.intVal = UInt64(SensorMgr.shared.currentPowerWatts)
						attr.valid = SensorMgr.shared.powerConnected
					}
					else if activityAttribute == ACTIVITY_ATTRIBUTE_CADENCE {
						attr = InitializeActivityAttribute(TYPE_INTEGER, MEASURE_RPM, UNIT_SYSTEM_METRIC)
						attr.value.intVal = UInt64(SensorMgr.shared.currentCadenceRpm)
						attr.valid = SensorMgr.shared.cadenceConnected
					}
				}
				
				let valueStr = LiveActivityVM.formatActivityValue(attribute: attr)
				var measureStr = LiveActivityVM.formatActivityMeasureType(measureType: attr.measureType)
				
				// To keep the spacing even if the unit string is empty then add something so the spacing stays even on the UI
				if measureStr.count == 0 {
					measureStr = " "
				}
				
				switch index {
				case 0:
					self.title1 = activityAttribute
					self.value1 = valueStr
					self.units1 = measureStr
					break
				case 1:
					self.title2 = activityAttribute
					self.value2 = valueStr
					self.units2 = measureStr
					break
				case 2:
					self.title3 = activityAttribute
					self.value3 = valueStr
					self.units3 = measureStr
					break
				case 3:
					self.title4 = activityAttribute
					self.value4 = valueStr
					self.units4 = measureStr
					break
				case 4:
					self.title5 = activityAttribute
					self.value5 = valueStr
					self.units5 = measureStr
					break
				case 5:
					self.title6 = activityAttribute
					self.value6 = valueStr
					self.units6 = measureStr
					break
				case 6:
					self.title7 = activityAttribute
					self.value7 = valueStr
					self.units7 = measureStr
					break
				case 7:
					self.title8 = activityAttribute
					self.value8 = valueStr
					self.units8 = measureStr
					break
				case 8:
					self.title9 = activityAttribute
					self.value9 = valueStr
					self.units9 = measureStr
					break
				default:
					break
				}
			}
		}
	}
	
	func loadHistoricalActivityByIndex(activityIndex: size_t) {
		// Delete any cached data.
		FreeHistoricalActivityObject(activityIndex)
		FreeHistoricalActivitySensorData(activityIndex)
		
		// Create the object.
		CreateHistoricalActivityObject(activityIndex)
		
		// Load all data.
		LoadHistoricalActivitySummaryData(activityIndex)
		if LoadAllHistoricalActivitySensorData(activityIndex) {
			var startTime: time_t = 0
			var endTime: time_t = 0
			
			GetHistoricalActivityStartAndEndTime(activityIndex, &startTime, &endTime)
			
			// If the activity was orphaned then the end time will be zero.
			if endTime == 0 {
				FixHistoricalActivityEndTime(activityIndex)
			}
			
			if SaveHistoricalActivitySummaryData(activityIndex) {
				LoadHistoricalActivitySummaryData(activityIndex)
				LoadHistoricalActivityLapData(activityIndex)
			}
		}
	}

	/// @brief Enables (or disables) auto start.
	func setAutoStart() -> Bool {
		let currentState = IsAutoStartEnabled()
		self.autoStartEnabled = !currentState
		
		// Remember where we were when the autostart button was pressed.
		if self.autoStartEnabled {
			let autoStartLocation = SensorMgr.shared.location.currentLocation
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
	func stop() -> ActivitySummary {
		let summary = ActivitySummary()
		
		if StopCurrentActivity() {
			
			let startTime = QueryLiveActivityAttribute(ACTIVITY_ATTRIBUTE_START_TIME)
			let endTime = QueryLiveActivityAttribute(ACTIVITY_ATTRIBUTE_END_TIME)
			let distance = QueryLiveActivityAttribute(ACTIVITY_ATTRIBUTE_DISTANCE_TRAVELED)
			let calories = QueryLiveActivityAttribute(ACTIVITY_ATTRIBUTE_CALORIES_BURNED)
			
			// So we don't have to recompute everything each time the activity is loaded, save a summary.
			SaveActivitySummaryData()
			
			// Delete the object.
			DestroyCurrentActivity()
			
			// Stop requesting data from sensors.
			SensorMgr.shared.stopSensors()
			
			// Stop the screen refresh timer.
			if self.timer != nil {
				self.timer?.invalidate()
				self.timer = nil
			}

			// Update state.
			self.isInProgress = false
			self.isPaused = false
			self.autoStartEnabled = false
			self.isStopped = true
			
			// Fill in the summary struct.
			summary.id = self.activityId
			summary.type = self.activityType
			summary.startTime = Date(timeIntervalSince1970: TimeInterval(startTime.value.intVal))
			summary.endTime = Date(timeIntervalSince1970: TimeInterval(endTime.value.intVal))
			summary.source = ActivitySummary.Source.database
			
			// Tell any subscribers that we've stopped an activity.
			var notificationData: Dictionary<String, Any> = [:]
			notificationData[KEY_NAME_ACTIVITY_ID] = self.activityId
			notificationData[KEY_NAME_ACTIVITY_TYPE] = self.activityType
			notificationData[KEY_NAME_START_TIME] = summary.startTime
			notificationData[KEY_NAME_END_TIME] = summary.endTime
			notificationData[KEY_NAME_DISTANCE] = distance.value.doubleVal
			notificationData[KEY_NAME_CALORIES] = calories.value.doubleVal
#if os(watchOS)
			notificationData[KEY_NAME_LOCATIONS] = []
#else
			notificationData[KEY_NAME_LOCATIONS] = self.locationTrack
#endif
			let notification = Notification(name: Notification.Name(rawValue: NOTIFICATION_NAME_ACTIVITY_STOPPED), object: notificationData)
			NotificationCenter.default.post(notification)
		}
		return summary
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
		return pointer.pointee.names
	}
	
	func setDisplayedActivityAttributeName(position: Int, attributeName: String) {
		self.activityAttributePrefs.remove(at: position)
		self.activityAttributePrefs.insert(attributeName, at: position)
		
		ActivityPreferences.setActivityLayout(activityType: self.activityType, layout: self.activityAttributePrefs)
	}
	
	func setWatchActivityAttributeColor(attributeName: String, colorName: String) {
		ActivityPreferences.setActivityAttributeColorName(activityType: self.activityType, attributeName: attributeName, colorName: colorName)
	}
	
	func getWatchActivityAttributeColor(attributeName: String) -> Color {
		return ActivityPreferences.getActivityAttributeColor(activityType: self.activityType, attributeName: attributeName)
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
	
	func playBeepSound() {
		let alertSound = URL(fileURLWithPath: Bundle.main.path(forResource: "BrightBeep", ofType: "aif")!)
		
		try! audioPlayer = AVAudioPlayer(contentsOf: alertSound)
		audioPlayer!.play()
	}
	
	func playPingSound() {
		let alertSound = URL(fileURLWithPath: Bundle.main.path(forResource: "Ping", ofType: "aif")!)
		
		try! audioPlayer = AVAudioPlayer(contentsOf: alertSound)
		audioPlayer!.play()
	}
	
	@objc func messageReceived(notification: NSNotification) {
		if let data = notification.object as? Dictionary<String, AnyObject> {
			if  let message = data[KEY_NAME_MESSAGE] as? String {
				self.currentMessage = message
				self.currentMessageTime = time(nil)
			}
		}
	}
}
