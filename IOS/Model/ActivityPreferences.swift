//
//  ActivityPreferences.swift
//  Created by Michael Simms on 9/29/22.
//

import Foundation
import SwiftUI
import UIKit

let ACTIVITY_PREF_VIEW_TYPE =                            "View Type"
let ACTIVITY_PREF_ATTRIBUTE_COLOR =                      "Attribute Color"
let ACTIVITY_PREF_BACKGROUND_COLOR =                     "Background Color"
let ACTIVITY_PREF_LABEL_COLOR =                          "Label Color"
let ACTIVITY_PREF_TEXT_COLOR =                           "Text Color"
let ACTIVITY_PREF_SHOW_HEART_RATE_PERCENT =              "Show Heart Rate Percent"
let ACTIVITY_PREF_START_STOP_BEEP =                      "Start/Stop Beep"
let ACTIVITY_PREF_SPLIT_BEEP =                           "Split Beep"
let ACTIVITY_PREF_SCREEN_AUTO_LOCK =                     "Screen Auto-Locking"
let ACTIVITY_PREF_ALLOW_SCREEN_PRESSES_DURING_ACTIVITY = "Allow Screen Presses During Activity"
let ACTIVITY_PREF_COUNTDOWN =                            "Countdown Timer"
let ACTIVITY_PREF_MIN_LOCATION_HORIZONTAL_ACCURACY =     "Horizontal Accuracy"
let ACTIVITY_PREF_MIN_LOCATION_VERTICAL_ACCURACY =       "Vertical Accuracy"
let ACTIVITY_PREF_BAD_LOCATION_FILTER_OPTION =           "Bad Location Filter"
let ACTIVITY_PREF_ATTRIBUTES =                           "Attributes"
let ACTIVITY_PREF_SHOW_THREAT_SPEED =                    "Show Threat Speed"

let COLOR_NAME_WHITE  = "White"
let COLOR_NAME_GRAY   = "Gray"
let COLOR_NAME_BLACK  = "Black"
let COLOR_NAME_RED    = "Red"
let COLOR_NAME_GREEN  = "Green"
let COLOR_NAME_BLUE   = "Blue"
let COLOR_NAME_YELLOW = "Yellow"

let DEFAULT_MIN_ACCURACY_METERS = 50

enum LocationFilterOption : Int {
	case LOCATION_FILTER_WARN = 0
	case LOCATION_FILTER_DROP
}

class ActivityPreferences {
	var defaultCyclingLayout: Array<String> = []
	var defaultRunningLayout: Array<String> = []
	var defaultStationaryBikeLayout: Array<String> = []
	var defaultTreadmillLayout: Array<String> = []
	var defaultHikingLayout: Array<String> = []
	var defaultSwimmingLayout: Array<String> = []
	var defaultLiftingLayout: Array<String> = []
	var defaultTriathlonLayout: Array<String> = []
	var defaultPoolSwimmingLayout: Array<String> = []

	init() {
#if TARGET_OS_WATCH
		self.defaultCyclingLayout = [ ACTIVITY_ATTRIBUTE_CURRENT_LAP_TIME,
									  ACTIVITY_ATTRIBUTE_DISTANCE_TRAVELED,
									  ACTIVITY_ATTRIBUTE_CURRENT_SPEED,
									  ACTIVITY_ATTRIBUTE_MOVING_TIME,
									  ACTIVITY_ATTRIBUTE_AVG_SPEED,
									  ACTIVITY_ATTRIBUTE_HEART_RATE,
									  ACTIVITY_ATTRIBUTE_AVG_HEART_RATE,
									  ACTIVITY_ATTRIBUTE_CADENCE,
									  ACTIVITY_ATTRIBUTE_CALORIES_BURNED ]
		self.defaultRunningLayout = [ ACTIVITY_ATTRIBUTE_CURRENT_LAP_TIME,
									  ACTIVITY_ATTRIBUTE_DISTANCE_TRAVELED,
									  ACTIVITY_ATTRIBUTE_CURRENT_PACE,
									  ACTIVITY_ATTRIBUTE_MOVING_TIME,
									  ACTIVITY_ATTRIBUTE_AVG_PACE,
									  ACTIVITY_ATTRIBUTE_STEPS_TAKEN,
									  ACTIVITY_ATTRIBUTE_CALORIES_BURNED,
									  ACTIVITY_ATTRIBUTE_HEART_RATE,
									  ACTIVITY_ATTRIBUTE_AVG_HEART_RATE ]
#else
		self.defaultCyclingLayout = [ ACTIVITY_ATTRIBUTE_CURRENT_LAP_TIME,
									  ACTIVITY_ATTRIBUTE_MOVING_TIME,
									  ACTIVITY_ATTRIBUTE_DISTANCE_TRAVELED,
									  ACTIVITY_ATTRIBUTE_CURRENT_SPEED,
									  ACTIVITY_ATTRIBUTE_AVG_SPEED,
									  ACTIVITY_ATTRIBUTE_HEART_RATE,
									  ACTIVITY_ATTRIBUTE_AVG_HEART_RATE,
									  ACTIVITY_ATTRIBUTE_CADENCE,
									  ACTIVITY_ATTRIBUTE_CALORIES_BURNED ]
		self.defaultRunningLayout = [ ACTIVITY_ATTRIBUTE_CURRENT_LAP_TIME,
									  ACTIVITY_ATTRIBUTE_MOVING_TIME,
									  ACTIVITY_ATTRIBUTE_DISTANCE_TRAVELED,
									  ACTIVITY_ATTRIBUTE_CURRENT_PACE,
									  ACTIVITY_ATTRIBUTE_AVG_PACE,
									  ACTIVITY_ATTRIBUTE_STEPS_TAKEN,
									  ACTIVITY_ATTRIBUTE_CALORIES_BURNED,
									  ACTIVITY_ATTRIBUTE_HEART_RATE,
									  ACTIVITY_ATTRIBUTE_AVG_HEART_RATE ]
#endif
		self.defaultStationaryBikeLayout = [ ACTIVITY_ATTRIBUTE_CURRENT_LAP_TIME,
											 ACTIVITY_ATTRIBUTE_DISTANCE_TRAVELED,
											 ACTIVITY_ATTRIBUTE_CALORIES_BURNED,
											 ACTIVITY_ATTRIBUTE_NUM_WHEEL_REVOLUTIONS,
											 ACTIVITY_ATTRIBUTE_WHEEL_SPEED,
											 ACTIVITY_ATTRIBUTE_HEART_RATE,
											 ACTIVITY_ATTRIBUTE_AVG_HEART_RATE,
											 ACTIVITY_ATTRIBUTE_CADENCE,
											 ACTIVITY_ATTRIBUTE_AVG_CADENCE ]
		self.defaultTreadmillLayout = [ ACTIVITY_ATTRIBUTE_CURRENT_LAP_TIME,
										ACTIVITY_ATTRIBUTE_DISTANCE_TRAVELED,
										ACTIVITY_ATTRIBUTE_CURRENT_PACE,
										ACTIVITY_ATTRIBUTE_MOVING_TIME,
										ACTIVITY_ATTRIBUTE_AVG_PACE,
										ACTIVITY_ATTRIBUTE_STEPS_TAKEN,
										ACTIVITY_ATTRIBUTE_CALORIES_BURNED,
										ACTIVITY_ATTRIBUTE_HEART_RATE,
										ACTIVITY_ATTRIBUTE_AVG_HEART_RATE ]
		self.defaultHikingLayout  = [ ACTIVITY_ATTRIBUTE_CURRENT_LAP_TIME,
									  ACTIVITY_ATTRIBUTE_MOVING_TIME,
									  ACTIVITY_ATTRIBUTE_DISTANCE_TRAVELED,
									  ACTIVITY_ATTRIBUTE_ELAPSED_TIME,
									  ACTIVITY_ATTRIBUTE_BIGGEST_CLIMB,
									  ACTIVITY_ATTRIBUTE_STEPS_TAKEN,
									  ACTIVITY_ATTRIBUTE_CALORIES_BURNED,
									  ACTIVITY_ATTRIBUTE_HEART_RATE,
									  ACTIVITY_ATTRIBUTE_AVG_HEART_RATE ]
		self.defaultSwimmingLayout = [ ACTIVITY_ATTRIBUTE_CURRENT_LAP_TIME,
									   ACTIVITY_ATTRIBUTE_DISTANCE_TRAVELED,
									   ACTIVITY_ATTRIBUTE_SWIM_STROKES,
									   ACTIVITY_ATTRIBUTE_ELAPSED_TIME,
									   ACTIVITY_ATTRIBUTE_CALORIES_BURNED,
									   ACTIVITY_ATTRIBUTE_HEART_RATE,
									   ACTIVITY_ATTRIBUTE_AVG_HEART_RATE ]
		self.defaultLiftingLayout = [ ACTIVITY_ATTRIBUTE_ELAPSED_TIME,
									  ACTIVITY_ATTRIBUTE_REPS,
									  ACTIVITY_ATTRIBUTE_SETS,
									  ACTIVITY_ATTRIBUTE_HEART_RATE,
									  ACTIVITY_ATTRIBUTE_AVG_HEART_RATE,
									  ACTIVITY_ATTRIBUTE_CALORIES_BURNED ]
#if TARGET_OS_WATCH
		self.defaultTriathlonLayout = [ ACTIVITY_ATTRIBUTE_DISTANCE_TRAVELED,
										ACTIVITY_ATTRIBUTE_CURRENT_SPEED,
										ACTIVITY_ATTRIBUTE_MOVING_TIME,
										ACTIVITY_ATTRIBUTE_AVG_SPEED,
										ACTIVITY_ATTRIBUTE_CADENCE,
										ACTIVITY_ATTRIBUTE_HEART_RATE,
										ACTIVITY_ATTRIBUTE_AVG_HEART_RATE,
										ACTIVITY_ATTRIBUTE_CALORIES_BURNED ]
#else
		self.defaultTriathlonLayout = [ ACTIVITY_ATTRIBUTE_MOVING_TIME,
										ACTIVITY_ATTRIBUTE_DISTANCE_TRAVELED,
										ACTIVITY_ATTRIBUTE_POWER,
										ACTIVITY_ATTRIBUTE_CURRENT_SPEED,
										ACTIVITY_ATTRIBUTE_AVG_SPEED,
										ACTIVITY_ATTRIBUTE_HEART_RATE,
										ACTIVITY_ATTRIBUTE_AVG_HEART_RATE,
										ACTIVITY_ATTRIBUTE_CADENCE,
										ACTIVITY_ATTRIBUTE_CALORIES_BURNED ]
#endif
		self.defaultPoolSwimmingLayout = [ ACTIVITY_ATTRIBUTE_ELAPSED_TIME,
										   ACTIVITY_ATTRIBUTE_POOL_DISTANCE_TRAVELED,
										   ACTIVITY_ATTRIBUTE_NUM_LAPS,
										   ACTIVITY_ATTRIBUTE_SWIM_STROKES,
										   ACTIVITY_ATTRIBUTE_HEART_RATE,
										   ACTIVITY_ATTRIBUTE_CALORIES_BURNED,
										   ACTIVITY_ATTRIBUTE_POOL_LENGTH ]
	}

	static func buildKeyStr(activityType: String, attributeName: String) -> String {
		return String(format:"%@ %@", activityType, attributeName)
	}

	static func getDefaultViewForActivityType(activityType: String) -> ActivityViewType {
		let mydefaults: UserDefaults = UserDefaults.standard
		let keyName = buildKeyStr(activityType: activityType, attributeName: ACTIVITY_PREF_VIEW_TYPE)
		
		// Default value
		if mydefaults.object(forKey: keyName) == nil {
			if activityType == ACTIVITY_TYPE_CYCLING || activityType == ACTIVITY_TYPE_STATIONARY_CYCLING || activityType == ACTIVITY_TYPE_VIRTUAL_CYCLING {
				return ACTIVITY_VIEW_COMPLEX
			}
			else if activityType == ACTIVITY_TYPE_HIKING || activityType == ACTIVITY_TYPE_WALKING || activityType == ACTIVITY_TYPE_MOUNTAIN_BIKING {
				return ACTIVITY_VIEW_MAPPED
			}
			else if activityType == ACTIVITY_TYPE_RUNNING {
				return ACTIVITY_VIEW_COMPLEX
			}
			return ACTIVITY_VIEW_SIMPLE
		}

		let value = mydefaults.integer(forKey: keyName)
		
		if value == ACTIVITY_VIEW_COMPLEX.rawValue {
			return ACTIVITY_VIEW_COMPLEX
		}
		else if value == ACTIVITY_VIEW_SIMPLE.rawValue {
			return ACTIVITY_VIEW_SIMPLE
		}
		else if value == ACTIVITY_VIEW_MAPPED.rawValue {
			return ACTIVITY_VIEW_MAPPED
		}
		return ACTIVITY_VIEW_COMPLEX
	}

	static func setDefaultViewForActivityType(activityType: String, viewType: ActivityViewType) {
		let mydefaults: UserDefaults = UserDefaults.standard
		let keyName = buildKeyStr(activityType: activityType, attributeName: ACTIVITY_PREF_VIEW_TYPE)

		switch viewType {
		case ACTIVITY_VIEW_COMPLEX:
			mydefaults.set(ACTIVITY_VIEW_COMPLEX.rawValue, forKey: keyName)
			break
		case ACTIVITY_VIEW_SIMPLE:
			mydefaults.set(ACTIVITY_VIEW_SIMPLE.rawValue, forKey: keyName)
			break
		case ACTIVITY_VIEW_MAPPED:
			mydefaults.set(ACTIVITY_VIEW_MAPPED.rawValue, forKey: keyName)
			break
		default:
			break
		}
	}

	func getDefaultActivityLayout(activityType: String) -> Array<String> {
		var defaults : Array<String> = []
		
		if activityType == ACTIVITY_TYPE_CYCLING || activityType == ACTIVITY_TYPE_MOUNTAIN_BIKING {
			defaults = self.defaultCyclingLayout
		}
		else if activityType == ACTIVITY_TYPE_STATIONARY_CYCLING {
			defaults = self.defaultStationaryBikeLayout
		}
		else if activityType == ACTIVITY_TYPE_VIRTUAL_CYCLING {
			defaults = self.defaultStationaryBikeLayout
		}
		else if activityType == ACTIVITY_TYPE_TREADMILL {
			defaults = self.defaultTreadmillLayout
		}
		else if activityType == ACTIVITY_TYPE_HIKING || activityType == ACTIVITY_TYPE_WALKING {
			defaults = self.defaultHikingLayout
		}
		else if activityType == ACTIVITY_TYPE_RUNNING {
			defaults = self.defaultRunningLayout
		}
		else if activityType == ACTIVITY_TYPE_OPEN_WATER_SWIMMING {
			defaults = self.defaultSwimmingLayout
		}
		else if activityType == ACTIVITY_TYPE_POOL_SWIMMING {
			defaults = self.defaultPoolSwimmingLayout
		}
		else if activityType == ACTIVITY_TYPE_TRIATHLON {
			defaults = self.defaultTriathlonLayout
		}
		else {
			defaults = self.defaultLiftingLayout
		}
		return defaults
	}

	func getActivityLayout(activityType: String) -> Array<String> {
		let mydefaults: UserDefaults = UserDefaults.standard
		let keyName = ActivityPreferences.buildKeyStr(activityType: activityType, attributeName: ACTIVITY_PREF_ATTRIBUTES)

		// Default value
		if mydefaults.object(forKey: keyName) == nil {
			return self.getDefaultActivityLayout(activityType: activityType)
		}
		return mydefaults.array(forKey: keyName) as! Array<String>
	}
	
	static func setActivityLayout(activityType: String, layout: Array<String>) {
		let mydefaults: UserDefaults = UserDefaults.standard
		let keyName = ActivityPreferences.buildKeyStr(activityType: activityType, attributeName: ACTIVITY_PREF_ATTRIBUTES)
		mydefaults.set(layout, forKey: keyName)
	}

	static func getActivityAttributeColorName(activityType: String, attributeName: String) -> String {
		let mydefaults: UserDefaults = UserDefaults.standard
		let keyName = ActivityPreferences.buildKeyStr(activityType: activityType, attributeName: ACTIVITY_PREF_ATTRIBUTE_COLOR) + " for " + attributeName
		let colorName = mydefaults.string(forKey: keyName)

		// Default value
		if colorName == nil {
			return COLOR_NAME_WHITE
		}
		return colorName!
	}

	static func setActivityAttributeColorName(activityType: String, attributeName: String, colorName: String) {
		let mydefaults: UserDefaults = UserDefaults.standard
		let keyName = ActivityPreferences.buildKeyStr(activityType: activityType, attributeName: ACTIVITY_PREF_ATTRIBUTE_COLOR) + " for " + attributeName
		mydefaults.set(colorName, forKey: keyName)
	}

	static func getBackgroundColorName(activityType: String) -> String {
		let mydefaults: UserDefaults = UserDefaults.standard
		let colorName = mydefaults.string(forKey: buildKeyStr(activityType: activityType, attributeName: ACTIVITY_PREF_BACKGROUND_COLOR))

		// Default value
		if colorName == nil {
			return COLOR_NAME_WHITE
		}
		return colorName!
	}

	static func getLabelColorName(activityType: String) -> String {
		let mydefaults: UserDefaults = UserDefaults.standard
		let colorName = mydefaults.string(forKey: buildKeyStr(activityType: activityType, attributeName: ACTIVITY_PREF_LABEL_COLOR))

		// Default value
		if colorName == nil {
			return COLOR_NAME_GRAY
		}
		return colorName!
	}

	static func getTextColorName(activityType: String) -> String {
		let mydefaults: UserDefaults = UserDefaults.standard
		let colorName = mydefaults.string(forKey: buildKeyStr(activityType: activityType, attributeName: ACTIVITY_PREF_TEXT_COLOR))

		// Default value
		if colorName == nil {
			return COLOR_NAME_BLACK
		}
		return colorName!
	}

	static func getActivityAttributeColor(activityType: String, attributeName: String) -> Color {
		let colorStr = getActivityAttributeColorName(activityType: activityType, attributeName: attributeName)
		return convertColorNameToObject(colorName: colorStr)
	}
	
	static func getBackgroundColor(activityType: String) -> Color {
		let colorStr = getBackgroundColorName(activityType: activityType)
		return convertColorNameToObject(colorName: colorStr)
	}

	static func getLabelColor(activityType: String) -> Color {
		let colorStr = getLabelColorName(activityType: activityType)
		return convertColorNameToObject(colorName: colorStr)
	}

	static func getTextColor(activityType: String) -> Color {
		let colorStr = getTextColorName(activityType: activityType)
		return convertColorNameToObject(colorName: colorStr)
	}
	
	static func convertColorNameToObject(colorName: String) -> Color {
		if colorName == COLOR_NAME_WHITE {
			return .white
		}
		if colorName == COLOR_NAME_GRAY {
			return .gray
		}
		if colorName == COLOR_NAME_BLACK {
			return .black
		}
		if colorName == COLOR_NAME_RED {
			return .red
		}
		if colorName == COLOR_NAME_GREEN {
			return .green
		}
		if colorName == COLOR_NAME_BLUE {
			return .blue
		}
		if colorName == COLOR_NAME_YELLOW {
			return .yellow
		}
		return .black
	}

	static func setBackgroundColor(activityType: String, colorName: String) {
		let mydefaults: UserDefaults = UserDefaults.standard
		mydefaults.set(colorName, forKey: buildKeyStr(activityType: activityType, attributeName: ACTIVITY_PREF_BACKGROUND_COLOR))
	}
	
	static func setLabelColor(activityType: String, colorName: String) {
		let mydefaults: UserDefaults = UserDefaults.standard
		mydefaults.set(colorName, forKey: buildKeyStr(activityType: activityType, attributeName: ACTIVITY_PREF_LABEL_COLOR))
	}

	static func setTextColor(activityType: String, colorName: String) {
		let mydefaults: UserDefaults = UserDefaults.standard
		mydefaults.set(colorName, forKey: buildKeyStr(activityType: activityType, attributeName: ACTIVITY_PREF_TEXT_COLOR))
	}

	static func getShowHeartRatePercent(activityType: String) -> Bool {
		let mydefaults: UserDefaults = UserDefaults.standard
		let keyName = buildKeyStr(activityType: activityType, attributeName: ACTIVITY_PREF_SHOW_HEART_RATE_PERCENT)
		
		// Default value
		if mydefaults.object(forKey: keyName) == nil {
			return false
		}
		return mydefaults.bool(forKey: keyName)
	}

	static func setShowHeartRatePercent(activityType: String, value: Bool) {
		let mydefaults: UserDefaults = UserDefaults.standard
		mydefaults.set(value, forKey: buildKeyStr(activityType: activityType, attributeName: ACTIVITY_PREF_SHOW_HEART_RATE_PERCENT))
	}

	static func getStartStopBeepEnabled(activityType: String) -> Bool {
		let mydefaults: UserDefaults = UserDefaults.standard
		let keyName = buildKeyStr(activityType: activityType, attributeName: ACTIVITY_PREF_START_STOP_BEEP)
		
		// Default value
		if mydefaults.object(forKey: keyName) == nil {
			return false
		}
		return mydefaults.bool(forKey: keyName)
	}

	static func setStartStopBeepEnabled(activityType: String, value: Bool) {
		let mydefaults: UserDefaults = UserDefaults.standard
		mydefaults.set(value, forKey: buildKeyStr(activityType: activityType, attributeName: ACTIVITY_PREF_START_STOP_BEEP))
	}

	static func getSplitBeepEnabled(activityType: String) -> Bool {
		let mydefaults: UserDefaults = UserDefaults.standard
		let keyName = buildKeyStr(activityType: activityType, attributeName: ACTIVITY_PREF_SPLIT_BEEP)
		
		// Default value
		if mydefaults.object(forKey: keyName) == nil {
			return false
		}
		return mydefaults.bool(forKey: keyName)
	}

	static func setSplitBeepEnabled(activityType: String, value: Bool) {
		let mydefaults: UserDefaults = UserDefaults.standard
		mydefaults.set(value, forKey: buildKeyStr(activityType: activityType, attributeName: ACTIVITY_PREF_SPLIT_BEEP))
	}

	static func getScreenAutoLocking(activityType: String) -> Bool {
		let mydefaults: UserDefaults = UserDefaults.standard
		let keyName = buildKeyStr(activityType: activityType, attributeName: ACTIVITY_PREF_SCREEN_AUTO_LOCK)

		// Default value
		if mydefaults.object(forKey: keyName) == nil {
			return true
		}
		return mydefaults.bool(forKey: keyName)
	}

	static func setScreenAutoLocking(activityType: String, value: Bool) {
		let mydefaults: UserDefaults = UserDefaults.standard
		mydefaults.set(value, forKey: buildKeyStr(activityType: activityType, attributeName: ACTIVITY_PREF_SCREEN_AUTO_LOCK))
	}

	static func getAllowScreenPressesDuringActivity(activityType: String) -> Bool {
		let mydefaults: UserDefaults = UserDefaults.standard
		let keyName = buildKeyStr(activityType: activityType, attributeName: ACTIVITY_PREF_ALLOW_SCREEN_PRESSES_DURING_ACTIVITY)

		// Default value
		if mydefaults.object(forKey: keyName) == nil {
			return false
		}
		return mydefaults.bool(forKey: keyName)
	}

	static func setAllowScreenPressesDuringActivity(activityType: String, value: Bool) {
		let mydefaults: UserDefaults = UserDefaults.standard
		mydefaults.set(value, forKey: buildKeyStr(activityType: activityType, attributeName: ACTIVITY_PREF_ALLOW_SCREEN_PRESSES_DURING_ACTIVITY))
	}

	static func getCountdown(activityType: String) -> Bool {
		let mydefaults: UserDefaults = UserDefaults.standard
		let keyName = buildKeyStr(activityType: activityType, attributeName: ACTIVITY_PREF_COUNTDOWN)

		// Default value
		if mydefaults.object(forKey: keyName) == nil {
			if activityType == ACTIVITY_TYPE_BENCH_PRESS ||
			   activityType == ACTIVITY_TYPE_CHINUP ||
			   activityType == ACTIVITY_TYPE_PULLUP ||
			   activityType == ACTIVITY_TYPE_PUSHUP ||
			   activityType == ACTIVITY_TYPE_SQUAT {
				return true // Three second countdown for strength activities.
			}
			else {
				return false // No countdown for cycling, running, etc.
			}
		}
		return mydefaults.bool(forKey: keyName)
	}

	static func setCountdown(activityType: String, value: Bool) {
		let mydefaults: UserDefaults = UserDefaults.standard
		mydefaults.set(value, forKey: buildKeyStr(activityType: activityType, attributeName: ACTIVITY_PREF_COUNTDOWN))
	}

	static func getMinLocationHorizontalAccuracy(activityType: String) -> Int {
		let mydefaults: UserDefaults = UserDefaults.standard
		let keyName = buildKeyStr(activityType: activityType, attributeName: ACTIVITY_PREF_MIN_LOCATION_HORIZONTAL_ACCURACY)
		
		// Default value
		if mydefaults.object(forKey: keyName) == nil {
			return DEFAULT_MIN_ACCURACY_METERS
		}
		return mydefaults.integer(forKey: keyName)
	}

	static func setMinLocationHorizontalAccuracy(activityType: String, meters: Int) {
		let mydefaults: UserDefaults = UserDefaults.standard
		mydefaults.set(meters, forKey: buildKeyStr(activityType: activityType, attributeName: ACTIVITY_PREF_MIN_LOCATION_HORIZONTAL_ACCURACY))
	}

	static func getMinLocationVerticalAccuracy(activityType: String) -> Int {
		let mydefaults: UserDefaults = UserDefaults.standard
		let keyName = buildKeyStr(activityType: activityType, attributeName: ACTIVITY_PREF_MIN_LOCATION_VERTICAL_ACCURACY)
		
		// Default value
		if mydefaults.object(forKey: keyName) == nil {
			return DEFAULT_MIN_ACCURACY_METERS
		}
		return mydefaults.integer(forKey: keyName)
	}

	static func setMinLocationVerticalAccuracy(activityType: String, meters: Int) {
		let mydefaults: UserDefaults = UserDefaults.standard
		mydefaults.set(meters, forKey: buildKeyStr(activityType: activityType, attributeName: ACTIVITY_PREF_MIN_LOCATION_VERTICAL_ACCURACY))
	}

	static func getLocationFilterOption(activityType: String) -> LocationFilterOption {
		let mydefaults: UserDefaults = UserDefaults.standard
		let keyName = buildKeyStr(activityType: activityType, attributeName: ACTIVITY_PREF_BAD_LOCATION_FILTER_OPTION)
		
		// Default value
		if mydefaults.object(forKey: keyName) == nil {
			return LocationFilterOption.LOCATION_FILTER_DROP
		}

		let value = mydefaults.integer(forKey: keyName)
		if value == LocationFilterOption.LOCATION_FILTER_WARN.rawValue {
			return LocationFilterOption.LOCATION_FILTER_WARN
		}
		return LocationFilterOption.LOCATION_FILTER_DROP
	}

	static func setLocationFilterOption(activityType: String, option: LocationFilterOption) {
		let mydefaults: UserDefaults = UserDefaults.standard
		mydefaults.set(option.rawValue, forKey: buildKeyStr(activityType: activityType, attributeName: ACTIVITY_PREF_BAD_LOCATION_FILTER_OPTION))
	}

	static func hasShownHelp(activityType: String) -> Bool {
		if activityType == ACTIVITY_TYPE_CHINUP || activityType == ACTIVITY_TYPE_PULLUP {
			return Preferences.hasShownPullUpHelp()
		}
		else if activityType == ACTIVITY_TYPE_CYCLING || activityType == ACTIVITY_TYPE_MOUNTAIN_BIKING {
			return Preferences.hasShownCyclingHelp()
		}
		else if activityType == ACTIVITY_TYPE_PUSHUP {
			return Preferences.hasShownPushUpHelp()
		}
		else if activityType == ACTIVITY_TYPE_RUNNING {
			return Preferences.hasShownRunningHelp()
		}
		else if activityType == ACTIVITY_TYPE_SQUAT {
			return Preferences.hasShownSquatHelp()
		}
		else if activityType == ACTIVITY_TYPE_STATIONARY_CYCLING {
			return Preferences.hasShownStationaryBikeHelp()
		}
		else if activityType == ACTIVITY_TYPE_VIRTUAL_CYCLING {
			return Preferences.hasShownStationaryBikeHelp()
		}
		else if activityType == ACTIVITY_TYPE_TREADMILL {
			return Preferences.hasShownTreadmillHelp()
		}
		return true
	}

	static func markHasShownHelp(activityType: String) {
		if activityType == ACTIVITY_TYPE_CHINUP || activityType == ACTIVITY_TYPE_PULLUP {
			Preferences.setHasShownPullUpHelp(value: true)
		}
		else if activityType == ACTIVITY_TYPE_CYCLING || activityType == ACTIVITY_TYPE_MOUNTAIN_BIKING {
			Preferences.setHasShownCyclingHelp(value: true)
		}
		else if activityType == ACTIVITY_TYPE_PUSHUP {
			Preferences.setHasShownPushUpHelp(value: true)
		}
		else if activityType == ACTIVITY_TYPE_RUNNING {
			Preferences.setHasShownRunningHelp(value: true)
		}
		else if activityType == ACTIVITY_TYPE_SQUAT {
			Preferences.setHasShownSquatHelp(value: true)
		}
		else if activityType == ACTIVITY_TYPE_STATIONARY_CYCLING {
			Preferences.setHasShownStationaryBikeHelp(value: true)
		}
		else if activityType == ACTIVITY_TYPE_VIRTUAL_CYCLING {
			Preferences.setHasShownStationaryBikeHelp(value: true)
		}
		else if activityType == ACTIVITY_TYPE_TREADMILL {
			Preferences.setHasShownTreadmillHelp(value: true)
		}
	}

	static func getShowThreatSpeed(activityType: String) -> Bool {
		let mydefaults: UserDefaults = UserDefaults.standard
		let keyName = buildKeyStr(activityType: activityType, attributeName: ACTIVITY_PREF_SHOW_THREAT_SPEED)

		// Default value
		if mydefaults.object(forKey: keyName) == nil {
			return false
		}
		return mydefaults.bool(forKey: keyName)
	}

	static func setShowThreatSpeed(activityType: String, value: Bool) {
		let mydefaults: UserDefaults = UserDefaults.standard
		mydefaults.set(value, forKey: buildKeyStr(activityType: activityType, attributeName: ACTIVITY_PREF_SHOW_THREAT_SPEED))
	}
}
