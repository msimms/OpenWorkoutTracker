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

struct SensorTypeCallbackType {
	var types: Array<SensorType>
}

@Observable
class RenderedActivityAttribute {
	var title: String = ""
	var value: String = ""
	var units: String = ""
	var position: Int = 0;
}

func attributeNameCallback(name: Optional<UnsafePointer<Int8>>, context: Optional<UnsafeMutableRawPointer>) {
	let attributeName = String(cString: UnsafeRawPointer(name!).assumingMemoryBound(to: CChar.self))
	let typedPointer = context!.bindMemory(to: AttributeNameCallbackType.self, capacity: 1)
	typedPointer.pointee.names.append(attributeName)
}

func sensorTypeCallback(type: SensorType, context: Optional<UnsafeMutableRawPointer>) {
	let typedPointer = context!.bindMemory(to: SensorTypeCallbackType.self, capacity: 1)
	typedPointer.pointee.types.append(type)
}

class LiveActivityVM : ObservableObject {
	static var shared: LiveActivityVM? = nil

	@Published var currentMessage: String = ""

	@Published var attr1: RenderedActivityAttribute = RenderedActivityAttribute()
	@Published var attr2: RenderedActivityAttribute = RenderedActivityAttribute()
	@Published var attr3: RenderedActivityAttribute = RenderedActivityAttribute()
	@Published var attr4: RenderedActivityAttribute = RenderedActivityAttribute()
	@Published var attr5: RenderedActivityAttribute = RenderedActivityAttribute()
	@Published var attr6: RenderedActivityAttribute = RenderedActivityAttribute()
	@Published var attr7: RenderedActivityAttribute = RenderedActivityAttribute()
	@Published var attr8: RenderedActivityAttribute = RenderedActivityAttribute()
	@Published var attr9: RenderedActivityAttribute = RenderedActivityAttribute()

	@Published var viewType: ActivityViewType = ACTIVITY_VIEW_COMPLEX
	
	var activityTypeToUse: String = ""
	var isInProgress: Bool = false
	var isPaused: Bool = false
	var isStopped: Bool = false // Has been stopped (after being started)
	var autoStartEnabled: Bool = false
	var isMovingActivity: Bool = false
	var needsFullScreenRefresh: Bool = true
	var countdownSecsRemaining: UInt = 0
	
#if !os(watchOS)
	var locationTrack: Array<CLLocationCoordinate2D> = []
	@Published var trackLine: MKPolyline = MKPolyline()
#endif
	
	private var autoStartCoordinate: Coordinate = Coordinate(latitude: 0.0, longitude: 0.0, altitude: 0.0, horizontalAccuracy: 0.0, verticalAccuracy: 0.0, time: 0)
	private var prevCoordinate: Coordinate = Coordinate(latitude: 0.0, longitude: 0.0, altitude: 0.0, horizontalAccuracy: 0.0, verticalAccuracy: 0.0, time: 0)
	private var activityAttributePrefs: Array<String> = []
	private var timer: Timer?
	public var activityId: String = ""
	private var activityType: String = ""
	private var audioPlayer: AVAudioPlayer?
	private var currentMessageTime: time_t = 0 // timestamp of when the current message was set, allows us to know when to clear it
	
	init(activityType: String, recreateOrphanedActivities: Bool) {
		self.create(activityType: activityType, recreateOrphanedActivities: recreateOrphanedActivities)
		LiveActivityVM.shared = self
	}

	func create(activityType: String, recreateOrphanedActivities: Bool) {

		NotificationCenter.default.addObserver(self, selector: #selector(self.messageReceived), name: Notification.Name(rawValue: NOTIFICATION_NAME_PRINT_MESSAGE), object: nil)

		self.activityType = activityType
		self.activityTypeToUse = activityType

		var orphanedActivityIndex: size_t = 0
		var isNewActivity: Bool = true

		// Perhaps the app shutdown poorly (phone rebooted, etc.).
		// Check for an existing, in progress, activity.
		if IsActivityOrphaned(&orphanedActivityIndex) || IsActivityInProgress() {

			let orphanedActivityIdPtr = UnsafeRawPointer(ConvertActivityIndexToActivityId(orphanedActivityIndex)) // const char*, no need to dealloc
			let orphanedActivityTypePtr = UnsafeRawPointer(GetHistoricalActivityType(orphanedActivityIdPtr))
			var activityRecreated = false

			defer {
				orphanedActivityTypePtr!.deallocate()
			}

			let orphanedActivityType = String(cString: orphanedActivityTypePtr!.assumingMemoryBound(to: CChar.self))
			if orphanedActivityType.count > 0 {
				self.activityTypeToUse = orphanedActivityType

				if recreateOrphanedActivities {
					ReCreateOrphanedActivity(orphanedActivityIndex)
					
					self.activityId = String(cString: orphanedActivityIdPtr!.assumingMemoryBound(to: CChar.self))
					self.isInProgress = true
					isNewActivity = false
					activityRecreated = true
				}
			}

			if activityRecreated == false {
				self.loadHistoricalActivity(activityIndex: orphanedActivityIndex)
			}
		}

		// Create the backend structures needed to do the activity.
		if isNewActivity == true {
			CreateActivityObject(self.activityTypeToUse)

			// Generate a unique identifier for this activity.
			self.activityId = NSUUID().uuidString
		}

		// Which attributes does the user wish to display when doing this activity?
		let activityPrefs = ActivityPreferences()
		self.activityAttributePrefs = activityPrefs.getActivityLayout(activityType: self.activityTypeToUse)

		// Preferred view layout.
		self.viewType = ActivityPreferences.getDefaultViewForActivityType(activityType: self.activityTypeToUse)

		// Which sensors are useful?
		let sensorTypes = getUsableSensorTypes()

		// Configure the location accuracy parameters.
		SensorMgr.shared.location.minAllowedHorizontalAccuracy = Double(ActivityPreferences.getMinLocationHorizontalAccuracy(activityType: self.activityTypeToUse))
		SensorMgr.shared.location.minAllowedVerticalAccuracy = Double(ActivityPreferences.getMinLocationVerticalAccuracy(activityType: self.activityTypeToUse))

		// Start the sensors.
		// This is intentionally done here when the activity is being created and before the activity is started so
		// the user can see sensor values and debug any issues before starting the activity.
		SensorMgr.shared.startSensors(usableSensors: sensorTypes)

		// This won't change. Cache it.
		self.isMovingActivity = IsMovingActivity()
		let isCyclingActivity = IsCyclingActivity()

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
		self.needsFullScreenRefresh = true
		let startStopBeepEnabled = ActivityPreferences.getStartStopBeepEnabled(activityType: self.activityTypeToUse)
		let splitBeepEnabled = ActivityPreferences.getSplitBeepEnabled(activityType: self.activityTypeToUse)
		let preferredUnits = Preferences.preferredUnitSystem()
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
				if !playedStartBeep && startStopBeepEnabled {
					self.playBeepSound()
					playedStartBeep = true
				}
				
				// Split beep
				if newSplit && splitBeepEnabled {
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
					self.trackLine.title = "Track"
					self.prevCoordinate = currentCoordinate
				}
			}
#endif
			
			// Add heart rate and power into the health store.
			// Adding heart rate would be redundant on the Apple Watch.
#if !os(watchOS)
			let hrAttr = QueryLiveActivityAttribute(ACTIVITY_ATTRIBUTE_HEART_RATE)
			if hrAttr.valid {
				HealthManager.shared.saveHeartRateIntoHealthStore(beats: hrAttr.value.doubleVal)
			}
#endif
			if isCyclingActivity {
				let powerAttr = QueryLiveActivityAttribute(ACTIVITY_ATTRIBUTE_POWER)
				if powerAttr.valid {
					HealthManager.shared.saveCyclingPowerIntoHealthStore(watts: powerAttr.value.doubleVal)
				}
			}

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
						let watts = SensorMgr.shared.currentPowerWatts
						attr = InitializeActivityAttribute(TYPE_INTEGER, MEASURE_POWER, UNIT_SYSTEM_METRIC)
						attr.value.intVal = UInt64(watts)
						attr.valid = SensorMgr.shared.powerConnected
					}
					else if activityAttribute == ACTIVITY_ATTRIBUTE_CADENCE {
						attr = InitializeActivityAttribute(TYPE_INTEGER, MEASURE_RPM, UNIT_SYSTEM_METRIC)
						attr.value.intVal = UInt64(SensorMgr.shared.currentCadenceRpm)
						attr.valid = SensorMgr.shared.cadenceConnected
					}
				}
				
				let valueStr = StringUtils.formatActivityValue(attribute: attr)
				var measureStr = StringUtils.formatActivityMeasureTypeWithUnitSystem(measureType: attr.measureType, preferredUnits: preferredUnits)
				
				// To keep the spacing even if the unit string is empty then add something so the spacing stays even on the UI
				if measureStr.count == 0 {
					measureStr = " "
				}
				
				switch index {
				case 0:
					self.attr1.value = valueStr
					if self.needsFullScreenRefresh {
						self.attr1.title = activityAttribute
						self.attr1.units = measureStr
						self.attr1.position = index
					}
					break
				case 1:
					self.attr2.value = valueStr
					if self.needsFullScreenRefresh {
						self.attr2.title = activityAttribute
						self.attr2.units = measureStr
						self.attr2.position = index
					}
					break
				case 2:
					self.attr3.value = valueStr
					if self.needsFullScreenRefresh {
						self.attr3.title = activityAttribute
						self.attr3.units = measureStr
						self.attr3.position = index
					}
					break
				case 3:
					self.attr4.value = valueStr
					if self.needsFullScreenRefresh {
						self.attr4.title = activityAttribute
						self.attr4.units = measureStr
						self.attr4.position = index
					}
					break
				case 4:
					self.attr5.value = valueStr
					if self.needsFullScreenRefresh {
						self.attr5.title = activityAttribute
						self.attr5.units = measureStr
						self.attr5.position = index
					}
					break
				case 5:
					self.attr6.value = valueStr
					if self.needsFullScreenRefresh {
						self.attr6.title = activityAttribute
						self.attr6.units = measureStr
						self.attr6.position = index
					}
					break
				case 6:
					self.attr7.value = valueStr
					if self.needsFullScreenRefresh {
						self.attr7.title = activityAttribute
						self.attr7.units = measureStr
						self.attr7.position = index
					}
					break
				case 7:
					self.attr8.value = valueStr
					if self.needsFullScreenRefresh {
						self.attr8.title = activityAttribute
						self.attr8.units = measureStr
						self.attr8.position = index
					}
					break
				case 8:
					self.attr9.value = valueStr
					if self.needsFullScreenRefresh {
						self.attr9.title = activityAttribute
						self.attr9.units = measureStr
						self.attr9.position = index
					}
					break
				default:
					break
				}
			}

			self.needsFullScreenRefresh = false
		}
	}
	
	func loadHistoricalActivity(activityIndex: size_t) {
		// Delete any cached data.
		FreeHistoricalActivityObject(self.activityId)
		FreeHistoricalActivitySensorData(self.activityId)
		
		// Create the object.
		CreateHistoricalActivityObject(self.activityId)
		
		// Load all data.
		LoadHistoricalActivitySummaryData(self.activityId)
		if LoadAllHistoricalActivitySensorData(self.activityId) {
			var startTime: time_t = 0
			var endTime: time_t = 0
			
			GetHistoricalActivityStartAndEndTime(self.activityId, &startTime, &endTime)
			
			// If the activity was orphaned then the end time will be zero.
			if endTime == 0 {
				FixHistoricalActivityEndTime(self.activityId)
			}
			
			if SaveHistoricalActivitySummaryData(self.activityId) {
				if LoadHistoricalActivitySummaryData(self.activityId) == false {
					NSLog("Failed to load historical activity summary data.")
				}
				if LoadHistoricalActivityLapData(self.activityId) == false {
					NSLog("Failed to load historical activity lap data.")
				}
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
		// If this is a pool swimming activity then we want to set the pool length.
		if self.activityType == ACTIVITY_TYPE_POOL_SWIMMING {
			let poolLength = Preferences.poolLength()
			let poolLengthUnits = Preferences.poolLengthUnits()
			SetPoolLength(UInt16(poolLength), poolLengthUnits)
		}

		// Call the common start code, this takes care of creating the activity in the database, etc.
		if StartActivity(self.activityId) {
			
			// Update state.
			self.isInProgress = true
			self.isPaused = false
			self.autoStartEnabled = false
			
			// Start the activity in HealthKit.
			HealthManager.shared.startActivity(activityType: self.activityType, startTime: Date())

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
			
			// Stop the activity in HealthKit.
			HealthManager.shared.stopWorkout(endTime: summary.endTime)

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
		if StartNewLap() {
			var startTimeMs: UInt64 = 0

			if MetaDataForLap(NumLaps(), &startTimeMs, nil, nil, nil) {
				let _ = ApiClient.shared.startNewLap(activityId: self.activityId, startTimeMs: startTimeMs)
			}
		}
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

	func getUsableSensorTypes() -> Array<SensorType> {
		let pointer = UnsafeMutablePointer<SensorTypeCallbackType>.allocate(capacity: 1)
		
		defer {
			pointer.deinitialize(count: 1)
			pointer.deallocate()
		}
		
		pointer.pointee = SensorTypeCallbackType(types: [])
		GetUsableSensorTypes(sensorTypeCallback, pointer)
		return pointer.pointee.types
	}

	func setDisplayedActivityAttributeName(position: Int, attributeName: String) {
		self.activityAttributePrefs.remove(at: position)
		self.activityAttributePrefs.insert(attributeName, at: position)
		self.needsFullScreenRefresh = true

		ActivityPreferences.setActivityLayout(activityType: self.activityTypeToUse, layout: self.activityAttributePrefs)
	}
	
	func setWatchActivityAttributeColor(attributeName: String, colorName: String) {
		ActivityPreferences.setActivityAttributeColorName(activityType: self.activityType, attributeName: attributeName, colorName: colorName)
	}
	
	func getWatchActivityAttributeColor(attributeName: String) -> Color {
		return ActivityPreferences.getActivityAttributeColor(activityType: self.activityType, attributeName: attributeName)
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
