//
//  Preferences.swift
//  Created by Michael Simms on 9/29/22.
//

import Foundation

///
/// The names of the preferences as stored in the plist file.
///

let PREF_NAME_UUID =                                  "UUID"
let PREF_NAME_UNITS =                                 "Units"
let PREF_NAME_ACTIVITY_LEVEL =                        "Activity Level"
let PREF_NAME_GENDER =                                "Gender"
let PREF_NAME_HEIGHT_CM =                             "Height"
let PREF_NAME_WEIGHT_KG =                             "Weight"
let PREF_NAME_BIRTH_DATE =                            "Birth Date"
let PREF_NAME_FTP =                                   "FTP"
let PREF_NAME_AUTOSCALE_MAP =                         "Autoscale Map"
let PREF_NAME_SCAN_FOR_SENSORS =                      "Scan for Sensors"
let PREF_NAME_BROADCAST_TO_SERVER =                   "Broadcast Global"
let PREF_NAME_BROADCAST_USER_NAME =                   "Broadcast User Name"
let PREF_NAME_BROADCAST_RATE =                        "Broadcast Rate"
let PREF_NAME_BROADCAST_PROTOCOL =                    "Broadcast Protocol"
let PREF_NAME_BROADCAST_HOST_NAME =                   "Broadcast Host Name"
let PREF_NAME_BROADCAST_SHOW_ICON =                   "Broadcast Show Icon"
let PREF_NAME_ALWAYS_CONNECT =                        "Always Connect"
let PREF_NAME_WILL_INTEGRATE_HEALTH_KIT_ACTIVITIES =  "Will Integrate HealthKit Activities"
let PREF_NAME_HIDE_HEALTH_KIT_DUPLICATES =            "Hide HealthKit Duplicates"
let PREF_NAME_AUTO_SAVE_TO_ICLOUD =                   "Auto Save To iCloud Drive"
let PREF_NAME_HAS_SHOWN_FIRST_TIME_USE_MSG =          "Has Shown First Time Use Message"
let PREF_NAME_HAS_SHOWN_PULL_UP_HELP =                "Has Shown Pull Up Help"
let PREF_NAME_HAS_SHOWN_PUSH_UP_HELP =                "Has Shown Push Up Help"
let PREF_NAME_HAS_SHOWN_RUNNING_HELP =                "Has Shown Running Help"
let PREF_NAME_HAS_SHOWN_CYCLING_HELP =                "Has Shown Cycling Help"
let PREF_NAME_HAS_SHOWN_SQUAT_HELP =                  "Has Shown Squat Help"
let PREF_NAME_HAS_SHOWN_STATIONARY_BIKE_HELP =        "Has Shown Stationary Bike Help"
let PREF_NAME_HAS_SHOWN_TREADMILL_HELP =              "Has Shown Treadmill Help"
let PREF_NAME_USE_WATCH_HEART_RATE =                  "Use Watch Heart Rate"
let PREF_NAME_USE_WATCH_RUN_SPLIT_BEEPS =             "Watch Run Split Beeps"
let PREF_NAME_WATCH_START_STOP_BEEPS =                "Watch Start Stop Beeps"
let PREF_NAME_WATCH_ALLOW_PRESSES_DURING_ACTIVITY =   "Watch Allow Presses During Activity"
let PREF_NAME_WORKOUT_GOAL =                          "Workout Goal"
let PREF_NAME_WORKOUT_GOAL_TYPE =                     "Workout Goal Type"
let PREF_NAME_WORKOUT_GOAL_DATE =                     "Workout Goal Date"
let PREF_NAME_WORKOUT_LONG_RUN_DAY =                  "Workout Long Run Day"
let PREF_NAME_WORKOUTS_CAN_INCLUDE_POOL_SWIMS =       "Workouts Can Include Pool Swims"
let PREF_NAME_WORKOUTS_CAN_INCLUDE_OPEN_WATER_SWIMS = "Workouts Can Include Open Water Swims"
let PREF_NAME_WORKOUTS_CAN_INCLUDE_BIKE_RIDES =       "Workouts Can Include Bike Rides"
let PREF_NAME_WORKOUTS_CAN_INCLUDE_RUNNING =          "Workouts Can Include Running"
let PREF_NAME_POOL_LENGTH =                           "Pool Length"
let PREF_NAME_POOL_LENGTH_UNITS =                     "Pool Length Units"
let PREF_NAME_LAST_SERVER_SYNC_TIME =                 "Last Server Sync Time"

let PREF_NAME_METRIC =       "units_metric"
let PREF_NAME_US_CUSTOMARY = "units_us_customary"

///
/// Default preference values
///

let MIN_BROADCAST_RATE =     60
let MAX_BROADCAST_RATE =     5

let DEFAULT_BROADCAST_RATE = 30
let DEFAULT_PROTOCOL =       "https"
let DEFAULT_HOST_NAME =      "openworkout.cloud"
let DEFAULT_POOL_LENGTH =    MEASURE_NOT_SET

let DEFAULT_HEIGHT_CM =      178.0
let DEFAULT_WEIGHT_KG =      77.0
let DEFAULT_BIRTH_DATE =     315532800 // Jan 1, 1980

class Preferences {
	static func uuid() -> String? {
		let mydefaults: UserDefaults = UserDefaults.standard
		return mydefaults.string(forKey: PREF_NAME_UUID)
	}
	
	//
	// Get methods
	//

	static func activityLevel() -> ActivityLevel {
		let mydefaults: UserDefaults = UserDefaults.standard
		let value = mydefaults.integer(forKey: PREF_NAME_ACTIVITY_LEVEL)

		if value == ACTIVITY_LEVEL_SEDENTARY.rawValue {
			return ACTIVITY_LEVEL_SEDENTARY
		}
		if value == ACTIVITY_LEVEL_LIGHT.rawValue {
			return ACTIVITY_LEVEL_LIGHT
		}
		if value == ACTIVITY_LEVEL_MODERATE.rawValue {
			return ACTIVITY_LEVEL_MODERATE
		}
		if value == ACTIVITY_LEVEL_ACTIVE.rawValue {
			return ACTIVITY_LEVEL_ACTIVE
		}
		if value == ACTIVITY_LEVEL_EXTREME.rawValue {
			return ACTIVITY_LEVEL_EXTREME
		}
		return ACTIVITY_LEVEL_MODERATE
	}
	
	static func biologicalGender() -> Gender {
		let mydefaults: UserDefaults = UserDefaults.standard
		let value = mydefaults.integer(forKey: PREF_NAME_GENDER)

		if value == GENDER_MALE.rawValue {
			return GENDER_MALE
		}
		if value == GENDER_FEMALE.rawValue {
			return GENDER_FEMALE
		}
		return GENDER_MALE
	}

	static func heightCm() -> Double {
		let mydefaults: UserDefaults = UserDefaults.standard
		if mydefaults.object(forKey: PREF_NAME_HEIGHT_CM) == nil {
			return DEFAULT_HEIGHT_CM
		}
		return mydefaults.double(forKey: PREF_NAME_HEIGHT_CM)
	}
	
	static func weightKg() -> Double {
		let mydefaults: UserDefaults = UserDefaults.standard
		if mydefaults.object(forKey: PREF_NAME_WEIGHT_KG) == nil {
			return DEFAULT_WEIGHT_KG
		}
		return mydefaults.double(forKey: PREF_NAME_WEIGHT_KG)
	}
	
	static func birthDate() -> time_t {
		let mydefaults: UserDefaults = UserDefaults.standard
		if mydefaults.object(forKey: PREF_NAME_BIRTH_DATE) == nil {
			return DEFAULT_BIRTH_DATE
		}
		return mydefaults.integer(forKey: PREF_NAME_BIRTH_DATE)
	}

	static func ftp() -> Double {
		let mydefaults: UserDefaults = UserDefaults.standard
		return mydefaults.double(forKey: PREF_NAME_FTP)
	}

	static func preferredUnitSystem() -> UnitSystem {
		let mydefaults: UserDefaults = UserDefaults.standard
		let str = mydefaults.string(forKey: PREF_NAME_UNITS)
		
		if str != nil {
			if str == PREF_NAME_US_CUSTOMARY {
				return UNIT_SYSTEM_US_CUSTOMARY
			}
			if str == PREF_NAME_METRIC {
				return UNIT_SYSTEM_METRIC
			}
		}
		return UNIT_SYSTEM_US_CUSTOMARY;
	}
	
	static func shouldAutoScaleMap() -> Bool {
		let mydefaults: UserDefaults = UserDefaults.standard
		return mydefaults.bool(forKey: PREF_NAME_AUTOSCALE_MAP)
	}
	
	static func shouldScanForSensors() -> Bool {
		let mydefaults: UserDefaults = UserDefaults.standard
		return mydefaults.bool(forKey: PREF_NAME_SCAN_FOR_SENSORS)
	}
	
	static func shouldBroadcastToServer() -> Bool {
		let mydefaults: UserDefaults = UserDefaults.standard
		return mydefaults.bool(forKey: PREF_NAME_BROADCAST_TO_SERVER)
	}
	
	static func broadcastUserName() -> String {
		let mydefaults: UserDefaults = UserDefaults.standard
		let result = mydefaults.string(forKey: PREF_NAME_BROADCAST_USER_NAME)
		if result != nil {
			return result!
		}
		return ""
	}
	
	static func broadcastRate() -> Int {
		let mydefaults: UserDefaults = UserDefaults.standard
		var rate = mydefaults.integer(forKey: PREF_NAME_BROADCAST_RATE)
		
		if rate == 0 {
			rate = DEFAULT_BROADCAST_RATE
		}
		if rate < MAX_BROADCAST_RATE {
			rate = MAX_BROADCAST_RATE
		}
		if rate > MIN_BROADCAST_RATE {
			rate = MIN_BROADCAST_RATE
		}
		return rate
	}
	
	static func broadcastProtocol() -> String {
		let mydefaults: UserDefaults = UserDefaults.standard
		let result = mydefaults.string(forKey: PREF_NAME_BROADCAST_PROTOCOL)
		if result != nil {
			return result!
		}
		return DEFAULT_PROTOCOL
	}
	
	static func broadcastHostName() -> String {
		let mydefaults: UserDefaults = UserDefaults.standard
		let result = mydefaults.string(forKey: PREF_NAME_BROADCAST_HOST_NAME)
		if result != nil {
			return result!
		}
		return DEFAULT_HOST_NAME
	}
	
	static func broadcastShowIcon() -> Bool {
		let mydefaults: UserDefaults = UserDefaults.standard
		return mydefaults.bool(forKey: PREF_NAME_BROADCAST_SHOW_ICON)
	}
	
	static func willIntegrateHealthKitActivities() -> Bool {
		let mydefaults: UserDefaults = UserDefaults.standard
		return mydefaults.bool(forKey: PREF_NAME_WILL_INTEGRATE_HEALTH_KIT_ACTIVITIES)
	}
	
	static func hideHealthKitDuplicates() -> Bool {
		let mydefaults: UserDefaults = UserDefaults.standard
		return mydefaults.bool(forKey: PREF_NAME_HIDE_HEALTH_KIT_DUPLICATES)
	}
	
	static func autoSaveToICloudDrive() -> Bool {
		let mydefaults: UserDefaults = UserDefaults.standard
		return mydefaults.bool(forKey: PREF_NAME_AUTO_SAVE_TO_ICLOUD)
	}
	
	static func hasShownFirstTimeUseMessage() -> Bool {
		let mydefaults: UserDefaults = UserDefaults.standard
		return mydefaults.bool(forKey: PREF_NAME_HAS_SHOWN_FIRST_TIME_USE_MSG)
	}
	
	static func hasShownPullUpHelp() -> Bool {
		let mydefaults: UserDefaults = UserDefaults.standard
		return mydefaults.bool(forKey: PREF_NAME_HAS_SHOWN_PULL_UP_HELP)
	}
	
	static func hasShownPushUpHelp() -> Bool {
		let mydefaults: UserDefaults = UserDefaults.standard
		return mydefaults.bool(forKey: PREF_NAME_HAS_SHOWN_PUSH_UP_HELP)
	}
	
	static func hasShownRunningHelp() -> Bool {
		let mydefaults: UserDefaults = UserDefaults.standard
		return mydefaults.bool(forKey: PREF_NAME_HAS_SHOWN_RUNNING_HELP)
	}
	
	static func hasShownCyclingHelp() -> Bool {
		let mydefaults: UserDefaults = UserDefaults.standard
		return mydefaults.bool(forKey: PREF_NAME_HAS_SHOWN_CYCLING_HELP)
	}
	
	static func hasShownSquatHelp() -> Bool {
		let mydefaults: UserDefaults = UserDefaults.standard
		return mydefaults.bool(forKey: PREF_NAME_HAS_SHOWN_SQUAT_HELP)
	}
	
	static func hasShownStationaryBikeHelp() -> Bool {
		let mydefaults: UserDefaults = UserDefaults.standard
		return mydefaults.bool(forKey: PREF_NAME_HAS_SHOWN_STATIONARY_BIKE_HELP)
	}
	
	static func hasShownTreadmillHelp() -> Bool {
		let mydefaults: UserDefaults = UserDefaults.standard
		return mydefaults.bool(forKey: PREF_NAME_HAS_SHOWN_TREADMILL_HELP)
	}
	
	static func useWatchHeartRate() -> Bool {
		let mydefaults: UserDefaults = UserDefaults.standard
		return mydefaults.bool(forKey: PREF_NAME_USE_WATCH_HEART_RATE)
	}
	
	static func watchRunSplitBeeps() -> Bool {
		let mydefaults: UserDefaults = UserDefaults.standard
		return mydefaults.bool(forKey: PREF_NAME_USE_WATCH_RUN_SPLIT_BEEPS)
	}

	static func watchStartStopBeeps() -> Bool {
		let mydefaults: UserDefaults = UserDefaults.standard
		return mydefaults.bool(forKey: PREF_NAME_WATCH_START_STOP_BEEPS)
	}
	
	static func watchAllowPressesDuringActivity() -> Bool {
		let mydefaults: UserDefaults = UserDefaults.standard
		return mydefaults.bool(forKey: PREF_NAME_WATCH_ALLOW_PRESSES_DURING_ACTIVITY)
	}

	static func workoutGoal() -> Goal {
		let mydefaults: UserDefaults = UserDefaults.standard
		let goal = mydefaults.integer(forKey: PREF_NAME_WORKOUT_GOAL)
		
		if goal == GOAL_FITNESS.rawValue {
			return GOAL_FITNESS
		}
		if goal == GOAL_5K_RUN.rawValue {
			return GOAL_5K_RUN
		}
		if goal == GOAL_10K_RUN.rawValue {
			return GOAL_10K_RUN
		}
		if goal == GOAL_15K_RUN.rawValue {
			return GOAL_15K_RUN
		}
		if goal == GOAL_HALF_MARATHON_RUN.rawValue {
			return GOAL_HALF_MARATHON_RUN
		}
		if goal == GOAL_MARATHON_RUN.rawValue {
			return GOAL_MARATHON_RUN
		}
		if goal == GOAL_50K_RUN.rawValue {
			return GOAL_50K_RUN
		}
		if goal == GOAL_50_MILE_RUN.rawValue {
			return GOAL_50_MILE_RUN
		}
		if goal == GOAL_SPRINT_TRIATHLON.rawValue {
			return GOAL_SPRINT_TRIATHLON
		}
		if goal == GOAL_OLYMPIC_TRIATHLON.rawValue {
			return GOAL_OLYMPIC_TRIATHLON
		}
		if goal == GOAL_HALF_IRON_DISTANCE_TRIATHLON.rawValue {
			return GOAL_HALF_IRON_DISTANCE_TRIATHLON
		}
		if goal == GOAL_IRON_DISTANCE_TRIATHLON.rawValue {
			return GOAL_IRON_DISTANCE_TRIATHLON
		}
		return GOAL_FITNESS
	}
	
	static func workoutGoalType() -> GoalType {
		let mydefaults: UserDefaults = UserDefaults.standard
		let goalType = mydefaults.integer(forKey: PREF_NAME_WORKOUT_GOAL_TYPE)
		
		if goalType == GOAL_TYPE_COMPLETION.rawValue {
			return GOAL_TYPE_COMPLETION
		}
		return GOAL_TYPE_SPEED
	}
	
	static func workoutGoalDate() -> time_t {
		let mydefaults: UserDefaults = UserDefaults.standard
		
		// Default value.
		if mydefaults.object(forKey: PREF_NAME_WORKOUT_GOAL_DATE) == nil {
			return time_t(Date().timeIntervalSince1970)
		}
		return mydefaults.integer(forKey: PREF_NAME_WORKOUT_GOAL_DATE)
	}
	
	static func workoutLongRunDay() -> DayType {
		let mydefaults: UserDefaults = UserDefaults.standard
		
		// Default value.
		if mydefaults.object(forKey: PREF_NAME_WORKOUT_LONG_RUN_DAY) == nil {
			return DAY_TYPE_SUNDAY
		}

		let dayType = mydefaults.integer(forKey: PREF_NAME_WORKOUT_LONG_RUN_DAY)
		
		if dayType == DAY_TYPE_MONDAY.rawValue {
			return DAY_TYPE_MONDAY
		}
		if dayType == DAY_TYPE_TUESDAY.rawValue {
			return DAY_TYPE_TUESDAY
		}
		if dayType == DAY_TYPE_WEDNESDAY.rawValue {
			return DAY_TYPE_WEDNESDAY
		}
		if dayType == DAY_TYPE_THURSDAY.rawValue {
			return DAY_TYPE_THURSDAY
		}
		if dayType == DAY_TYPE_FRIDAY.rawValue {
			return DAY_TYPE_FRIDAY
		}
		if dayType == DAY_TYPE_SATURDAY.rawValue {
			return DAY_TYPE_SATURDAY
		}
		if dayType == DAY_TYPE_SUNDAY.rawValue {
			return DAY_TYPE_SUNDAY
		}
		return DAY_TYPE_SUNDAY
	}
	
	static func workoutsCanIncludePoolSwims() -> Bool {
		let mydefaults: UserDefaults = UserDefaults.standard
		return mydefaults.bool(forKey: PREF_NAME_WORKOUTS_CAN_INCLUDE_POOL_SWIMS)
	}
	
	static func workoutsCanIncludeOpenWaterSwims() -> Bool {
		let mydefaults: UserDefaults = UserDefaults.standard
		return mydefaults.bool(forKey: PREF_NAME_WORKOUTS_CAN_INCLUDE_OPEN_WATER_SWIMS)
	}
	
	static func workoutsCanIncludeBikeRides() -> Bool {
		let mydefaults: UserDefaults = UserDefaults.standard
		return mydefaults.bool(forKey: PREF_NAME_WORKOUTS_CAN_INCLUDE_BIKE_RIDES)
	}
	
	static func workoutsCanIncludeRunning() -> Bool {
		let mydefaults: UserDefaults = UserDefaults.standard
		return mydefaults.bool(forKey: PREF_NAME_WORKOUTS_CAN_INCLUDE_RUNNING)
	}
	
	static func poolLength() -> Int {
		let mydefaults: UserDefaults = UserDefaults.standard
		return mydefaults.integer(forKey: PREF_NAME_POOL_LENGTH)
	}
	
	static func poolLengthUnits() -> UnitSystem {
		let mydefaults: UserDefaults = UserDefaults.standard
		let poolLengthUnits = mydefaults.integer(forKey: PREF_NAME_POOL_LENGTH_UNITS)
		
		if poolLengthUnits == UNIT_SYSTEM_METRIC.rawValue {
			return UNIT_SYSTEM_METRIC
		}
		return UNIT_SYSTEM_US_CUSTOMARY
	}
	
	static func lastServerSyncTime() -> time_t {
		let mydefaults: UserDefaults = UserDefaults.standard
		return mydefaults.integer(forKey: PREF_NAME_LAST_SERVER_SYNC_TIME)
	}
	
	//
	// Set methods
	//
	
	static func setUuid(value: String) {
		let mydefaults: UserDefaults = UserDefaults.standard
		mydefaults.set(value, forKey: PREF_NAME_UUID)
	}
	
	static func setActivityLevel(value: ActivityLevel) {
		let mydefaults: UserDefaults = UserDefaults.standard
		mydefaults.set(value.rawValue, forKey: PREF_NAME_ACTIVITY_LEVEL)
	}

	static func setBiologicalGender(value: Gender) {
		let mydefaults: UserDefaults = UserDefaults.standard
		mydefaults.set(value.rawValue, forKey: PREF_NAME_GENDER)
	}
	
	static func setHeightCm(value: Double) {
		let mydefaults: UserDefaults = UserDefaults.standard
		mydefaults.set(value, forKey: PREF_NAME_HEIGHT_CM)
	}
	
	static func setWeightKg(value: Double) {
		let mydefaults: UserDefaults = UserDefaults.standard
		mydefaults.set(value, forKey: PREF_NAME_WEIGHT_KG)
	}
	
	static func setBirthDate(value: time_t) {
		let mydefaults: UserDefaults = UserDefaults.standard
		mydefaults.set(value, forKey: PREF_NAME_BIRTH_DATE)
	}

	static func setFtp(value: Double) {
		let mydefaults: UserDefaults = UserDefaults.standard
		mydefaults.set(value, forKey: PREF_NAME_FTP)
	}
	
	static func setPreferredUnitSystem(system: UnitSystem) {
		let mydefaults: UserDefaults = UserDefaults.standard
		switch (system) {
		case UNIT_SYSTEM_US_CUSTOMARY:
			mydefaults.set(PREF_NAME_US_CUSTOMARY, forKey: PREF_NAME_UNITS)
			break
		case UNIT_SYSTEM_METRIC:
			mydefaults.set(PREF_NAME_METRIC, forKey: PREF_NAME_UNITS)
			break
		default:
			break
		}
	}
	
	static func setAutoScaleMap(value: Bool) {
		let mydefaults: UserDefaults = UserDefaults.standard
		mydefaults.set(value, forKey: PREF_NAME_AUTOSCALE_MAP)
	}
	
	static func setScanForSensors(value: Bool) {
		let mydefaults: UserDefaults = UserDefaults.standard
		mydefaults.set(value, forKey: PREF_NAME_SCAN_FOR_SENSORS)
	}
	
	static func setBroadcastToServer(value: Bool) {
		let mydefaults: UserDefaults = UserDefaults.standard
		mydefaults.set(value, forKey: PREF_NAME_BROADCAST_TO_SERVER)
	}
	
	static func setBroadcastUserName(value: String) {
		let mydefaults: UserDefaults = UserDefaults.standard
		mydefaults.set(value, forKey: PREF_NAME_BROADCAST_USER_NAME)
	}
	
	static func setBroadcastRate(value: Int) {
		let mydefaults: UserDefaults = UserDefaults.standard
		if (value < MAX_BROADCAST_RATE) {
			return
		}
		if (value > MIN_BROADCAST_RATE) {
			return
		}
		mydefaults.set(value, forKey: PREF_NAME_BROADCAST_RATE)
	}
	
	static func setBroadcastProtocol(value: String) {
		let mydefaults: UserDefaults = UserDefaults.standard
		mydefaults.set(value, forKey: PREF_NAME_BROADCAST_PROTOCOL)
	}
	
	static func setBroadcastHostName(value: String) {
		let mydefaults: UserDefaults = UserDefaults.standard
		mydefaults.set(value, forKey: PREF_NAME_BROADCAST_HOST_NAME)
	}
	
	static func setBroadcastShowIcon(value: Bool) {
		let mydefaults: UserDefaults = UserDefaults.standard
		mydefaults.set(value, forKey: PREF_NAME_BROADCAST_SHOW_ICON)
	}
	
	static func setWillIntegrateHealthKitActivities(value: Bool) {
		let mydefaults: UserDefaults = UserDefaults.standard
		mydefaults.set(value, forKey: PREF_NAME_WILL_INTEGRATE_HEALTH_KIT_ACTIVITIES)
	}
	
	static func setHideHealthKitDuplicates(value: Bool) {
		let mydefaults: UserDefaults = UserDefaults.standard
		mydefaults.set(value, forKey: PREF_NAME_HIDE_HEALTH_KIT_DUPLICATES)
	}
	
	static func setAutoSaveToICloudDrive(value: Bool) {
		let mydefaults: UserDefaults = UserDefaults.standard
		mydefaults.set(value, forKey: PREF_NAME_AUTO_SAVE_TO_ICLOUD)
	}
	
	static func setHashShownFirstTimeUseMessage(value: Bool) {
		let mydefaults: UserDefaults = UserDefaults.standard
		mydefaults.set(value, forKey: PREF_NAME_HAS_SHOWN_FIRST_TIME_USE_MSG)
	}
	
	static func setHasShownPullUpHelp(value: Bool) {
		let mydefaults: UserDefaults = UserDefaults.standard
		mydefaults.set(value, forKey: PREF_NAME_HAS_SHOWN_PULL_UP_HELP)
	}
	
	static func setHasShownPushUpHelp(value: Bool) {
		let mydefaults: UserDefaults = UserDefaults.standard
		mydefaults.set(value, forKey: PREF_NAME_HAS_SHOWN_PUSH_UP_HELP)
	}
	
	static func setHasShownRunningHelp(value: Bool) {
		let mydefaults: UserDefaults = UserDefaults.standard
		mydefaults.set(value, forKey: PREF_NAME_HAS_SHOWN_RUNNING_HELP)
	}
	
	static func setHasShownCyclingHelp(value: Bool) {
		let mydefaults: UserDefaults = UserDefaults.standard
		mydefaults.set(value, forKey: PREF_NAME_HAS_SHOWN_CYCLING_HELP)
	}
	
	static func setHasShownSquatHelp(value: Bool) {
		let mydefaults: UserDefaults = UserDefaults.standard
		mydefaults.set(value, forKey: PREF_NAME_HAS_SHOWN_SQUAT_HELP)
	}
	
	static func setHasShownStationaryBikeHelp(value: Bool) {
		let mydefaults: UserDefaults = UserDefaults.standard
		mydefaults.set(value, forKey: PREF_NAME_HAS_SHOWN_STATIONARY_BIKE_HELP)
	}
	
	static func setHasShownTreadmillHelp(value: Bool) {
		let mydefaults: UserDefaults = UserDefaults.standard
		mydefaults.set(value, forKey: PREF_NAME_HAS_SHOWN_TREADMILL_HELP)
	}
	
	static func setUseWatchHeartRate(value: Bool) {
		let mydefaults: UserDefaults = UserDefaults.standard
		mydefaults.set(value, forKey: PREF_NAME_USE_WATCH_HEART_RATE)
	}

	static func setWatchRunSplitBeeps(value: Bool) {
		let mydefaults: UserDefaults = UserDefaults.standard
		mydefaults.set(value, forKey: PREF_NAME_USE_WATCH_RUN_SPLIT_BEEPS)
	}

	static func setWatchStartStopBeeps(value: Bool) {
		let mydefaults: UserDefaults = UserDefaults.standard
		mydefaults.set(value, forKey: PREF_NAME_WATCH_START_STOP_BEEPS)
	}
	
	static func setWatchAllowPressesDuringActivity(value: Bool) {
		let mydefaults: UserDefaults = UserDefaults.standard
		mydefaults.set(value, forKey: PREF_NAME_WATCH_ALLOW_PRESSES_DURING_ACTIVITY)
	}

	static func setWorkoutGoal(value: Goal) {
		let mydefaults: UserDefaults = UserDefaults.standard
		mydefaults.set(value.rawValue, forKey: PREF_NAME_WORKOUT_GOAL)
	}
	
	static func setWorkoutGoalType(value: GoalType) {
		let mydefaults: UserDefaults = UserDefaults.standard
		mydefaults.set(value.rawValue, forKey: PREF_NAME_WORKOUT_GOAL_TYPE)
	}
	
	static func setWorkoutGoalDate(value: time_t) {
		let mydefaults: UserDefaults = UserDefaults.standard
		mydefaults.set(value, forKey: PREF_NAME_WORKOUT_GOAL_DATE)
	}
	
	static func setWorkoutLongRunDay(value: DayType) {
		let mydefaults: UserDefaults = UserDefaults.standard
		mydefaults.set(value.rawValue, forKey: PREF_NAME_WORKOUT_LONG_RUN_DAY)
	}
	
	static func setWorkoutsCanIncludePoolSwims(value: Bool) {
		let mydefaults: UserDefaults = UserDefaults.standard
		mydefaults.set(value, forKey: PREF_NAME_WORKOUTS_CAN_INCLUDE_POOL_SWIMS)
	}
	
	static func setWorkoutsCanIncludeOpenWaterSwims(value: Bool) {
		let mydefaults: UserDefaults = UserDefaults.standard
		mydefaults.set(value, forKey: PREF_NAME_WORKOUTS_CAN_INCLUDE_OPEN_WATER_SWIMS)
	}
	
	static func setWorkoutsCanIncludeBikeRides(value: Bool) {
		let mydefaults: UserDefaults = UserDefaults.standard
		mydefaults.set(value, forKey: PREF_NAME_WORKOUTS_CAN_INCLUDE_BIKE_RIDES)
	}
	
	static func setWorkoutsCanIncludeRunning(value: Bool) {
		let mydefaults: UserDefaults = UserDefaults.standard
		mydefaults.set(value, forKey: PREF_NAME_WORKOUTS_CAN_INCLUDE_RUNNING)
	}
	
	static func setPoolLength(poolLength: Int) {
		let mydefaults: UserDefaults = UserDefaults.standard
		mydefaults.set(poolLength, forKey: PREF_NAME_POOL_LENGTH)
	}
	
	static func setPoolLengthUnits(poolLengthUnits: UnitSystem) {
		let mydefaults: UserDefaults = UserDefaults.standard
		mydefaults.set(poolLengthUnits.rawValue, forKey: PREF_NAME_POOL_LENGTH_UNITS)
	}
	
	static func setLastServerSyncTime(value: time_t) {
		let mydefaults: UserDefaults = UserDefaults.standard
		mydefaults.set(value, forKey: PREF_NAME_LAST_SERVER_SYNC_TIME)
	}
	
	//
	// Methods for managing the list of accessories
	//

	static func listPeripheralsToUse() -> Array<String> {
		let mydefaults: UserDefaults = UserDefaults.standard
		let peripheralList = mydefaults.string(forKey: PREF_NAME_ALWAYS_CONNECT)
		if peripheralList == nil {
			return []
		}
		return peripheralList!.components(separatedBy: ";")
	}

	static func addPeripheralToUse(uuid: String) {
		if !shouldUsePeripheral(uuid: uuid) {
			let mydefaults: UserDefaults = UserDefaults.standard
			let peripheralList = mydefaults.string(forKey: PREF_NAME_ALWAYS_CONNECT)
			
			if peripheralList != nil && peripheralList!.count > 0 {
				let newList = peripheralList! + ";" + uuid
				mydefaults.set(newList, forKey: PREF_NAME_ALWAYS_CONNECT)
			}
			else {
				mydefaults.set(uuid, forKey: PREF_NAME_ALWAYS_CONNECT)
			}
		}
	}

	static func removePeripheralFromUseList(uuid: String) {
		let mydefaults: UserDefaults = UserDefaults.standard
		var peripheralList = mydefaults.string(forKey: PREF_NAME_ALWAYS_CONNECT)

		if peripheralList != nil && peripheralList!.contains(uuid) {
			peripheralList?.replace(uuid, with: "")
			peripheralList?.replace(";;", with: ";")
			mydefaults.set(peripheralList, forKey: PREF_NAME_ALWAYS_CONNECT)
		}
	}

	static func shouldUsePeripheral(uuid: String) -> Bool {
		let mydefaults: UserDefaults = UserDefaults.standard
		let peripheralList = mydefaults.string(forKey: PREF_NAME_ALWAYS_CONNECT)
		
		if peripheralList != nil && peripheralList!.contains(uuid) {
			return true
		}
		return false
	}

	//
	// Import and export methods
	//

	static func exportPrefs() -> Dictionary<String, Any> {
		var prefs : Dictionary<String, Any> = [:]

		prefs[PREF_NAME_UNITS] = preferredUnitSystem()
		prefs[PREF_NAME_SCAN_FOR_SENSORS] = shouldScanForSensors()
		prefs[PREF_NAME_BROADCAST_TO_SERVER] = shouldBroadcastToServer()
		prefs[PREF_NAME_BROADCAST_USER_NAME] = broadcastUserName()
		prefs[PREF_NAME_BROADCAST_RATE] = broadcastRate()
		prefs[PREF_NAME_BROADCAST_PROTOCOL] = broadcastProtocol()
		prefs[PREF_NAME_BROADCAST_HOST_NAME] = broadcastHostName()
		prefs[PREF_NAME_HAS_SHOWN_FIRST_TIME_USE_MSG] = hasShownFirstTimeUseMessage()
		prefs[PREF_NAME_HAS_SHOWN_PULL_UP_HELP] = hasShownPullUpHelp()
		prefs[PREF_NAME_HAS_SHOWN_PUSH_UP_HELP] = hasShownPushUpHelp()
		prefs[PREF_NAME_HAS_SHOWN_RUNNING_HELP] = hasShownRunningHelp()
		prefs[PREF_NAME_HAS_SHOWN_CYCLING_HELP] = hasShownCyclingHelp()
		prefs[PREF_NAME_HAS_SHOWN_SQUAT_HELP] = hasShownSquatHelp()
		prefs[PREF_NAME_BROADCAST_HOST_NAME] = broadcastHostName()
		prefs[PREF_NAME_HAS_SHOWN_STATIONARY_BIKE_HELP] = hasShownStationaryBikeHelp()
		prefs[PREF_NAME_HAS_SHOWN_TREADMILL_HELP] = hasShownTreadmillHelp()
		return prefs
	}
	
	static func importPrefs(prefs: Dictionary<String, Any>) {
		for item in prefs {
			if item.key == PREF_NAME_UNITS {
				let tempValue = item.value as! Int
				if tempValue == UNIT_SYSTEM_METRIC.rawValue {
					setPreferredUnitSystem(system: UNIT_SYSTEM_METRIC)
				}
				else if tempValue == UNIT_SYSTEM_US_CUSTOMARY.rawValue {
					setPreferredUnitSystem(system: UNIT_SYSTEM_US_CUSTOMARY)
				}
			}
			else if item.key == PREF_NAME_SCAN_FOR_SENSORS {
				setScanForSensors(value: item.value as! Bool)
			}
			else if item.key == PREF_NAME_BROADCAST_TO_SERVER {
				setBroadcastToServer(value: item.value as! Bool)
			}
			else if item.key == PREF_NAME_BROADCAST_USER_NAME {
				setBroadcastUserName(value: item.value as! String)
			}
			else if item.key == PREF_NAME_BROADCAST_RATE {
				setBroadcastRate(value: item.value as! Int)
			}
			else if item.key == PREF_NAME_BROADCAST_PROTOCOL {
				setBroadcastProtocol(value: item.value as! String)
			}
			else if item.key == PREF_NAME_HAS_SHOWN_FIRST_TIME_USE_MSG {
				setHashShownFirstTimeUseMessage(value: item.value as! Bool)
			}
			else if item.key == PREF_NAME_HAS_SHOWN_PULL_UP_HELP {
				setHasShownPullUpHelp(value: item.value as! Bool)
			}
			else if item.key == PREF_NAME_HAS_SHOWN_PUSH_UP_HELP {
				setHasShownPushUpHelp(value: item.value as! Bool)
			}
			else if item.key == PREF_NAME_HAS_SHOWN_RUNNING_HELP {
				setHasShownRunningHelp(value: item.value as! Bool)
			}
			else if item.key == PREF_NAME_HAS_SHOWN_CYCLING_HELP {
				setHasShownCyclingHelp(value: item.value as! Bool)
			}
			else if item.key == PREF_NAME_HAS_SHOWN_SQUAT_HELP {
				setHasShownSquatHelp(value: item.value as! Bool)
			}
			else if item.key == PREF_NAME_HAS_SHOWN_STATIONARY_BIKE_HELP {
				setHasShownStationaryBikeHelp(value: item.value as! Bool)
			}
			else if item.key == PREF_NAME_HAS_SHOWN_TREADMILL_HELP {
				setHasShownTreadmillHelp(value: item.value as! Bool)
			}
		}
	}
}
