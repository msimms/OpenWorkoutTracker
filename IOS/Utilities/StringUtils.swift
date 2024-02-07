//
//  StringUtils.swift
//  Created by Michael Simms on 8/27/23.
//

import Foundation

class StringUtils {
	
	/// @brief Parses the string for a time value in the format of HH:MM:SS where MM and SS ranges from 0 to 59.
	static func parseHHMMSS(str: String, hours: inout Int, minutes: inout Int, seconds: inout Int) -> Bool {
		let listItems = str.components(separatedBy: ":")
		let reversedList = Array(listItems.reversed())
		let numItems = reversedList.count
		
		if numItems == 0 {
			return false
		}
		
		if numItems >= 3 {
			let tempHours = Int(reversedList[2])
			
			if tempHours != nil {
				hours = tempHours!
				if hours < 0 {
					return false
				}
			}
			else {
				return false
			}
		}
		if numItems >= 2 {
			let tempMinutes = Int(reversedList[1])
			
			if tempMinutes != nil {
				minutes = tempMinutes!
				if minutes < 0 || minutes >= 60 {
					return false
				}
			}
		}
		if numItems >= 1 {
			let tempSeconds = Int(reversedList[0])
			
			if tempSeconds != nil {
				seconds = tempSeconds!
				if seconds < 0 || seconds >= 60 {
					return false
				}
			}
			else {
				return false
			}
		}
		
		return true
	}
	
	/// @brief Utility function for converting a number of seconds into HH:MMSS format
	static func formatAsHHMMSS(numSeconds: Double) -> String {
		let SECS_PER_DAY  = 86400
		let SECS_PER_HOUR = 3600
		let SECS_PER_MIN  = 60
		var tempSeconds   = Int(numSeconds)
		
		let days     = (tempSeconds / SECS_PER_DAY)
		tempSeconds -= (days * SECS_PER_DAY)
		let hours    = (tempSeconds / SECS_PER_HOUR)
		tempSeconds -= (hours * SECS_PER_HOUR)
		let minutes  = (tempSeconds / SECS_PER_MIN)
		tempSeconds -= (minutes * SECS_PER_MIN)
		let seconds  = (tempSeconds % SECS_PER_MIN)
		
		if days > 0 {
			return String(format: "%02d:%02d:%02d:%02d", days, hours, minutes, seconds)
		}
		else if hours > 0 {
			return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
		}
		return String(format: "%02d:%02d", minutes, seconds)
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

	static func formatDistanceInUserUnits(meters: Double) -> String {
		var attr: ActivityAttributeType = ActivityAttributeType()
		attr.value.doubleVal = meters / 1000.0
		attr.valueType = TYPE_DOUBLE
		attr.measureType = MEASURE_DISTANCE
		attr.unitSystem = UNIT_SYSTEM_METRIC
		attr.valid = true
		ConvertToPreferredUnits(&attr)
		return String(format: "%0.2f", attr.value.doubleVal)
	}

	/// @brief Utility function for converting an activity attribute structure to something human readable.
	static func formatActivityValue(attribute: ActivityAttributeType) -> String {
		if attribute.valid {
			switch attribute.valueType {
			case TYPE_NOT_SET:
				return VALUE_NOT_SET_STR
			case TYPE_TIME:
				return StringUtils.formatSeconds(numSeconds: attribute.value.timeVal)
			case TYPE_DOUBLE:
				if attribute.measureType == MEASURE_DISTANCE {
					return String(format: "%0.2f", attribute.value.doubleVal)
				}
				else if attribute.measureType == MEASURE_POOL_DISTANCE {
					return String(format: "%0.0f", attribute.value.doubleVal)
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
		case MEASURE_POOL_DISTANCE:
			let preferredUnits = Preferences.preferredUnitSystem()
			if preferredUnits == UNIT_SYSTEM_METRIC {
				return "meters"
			}
			else if preferredUnits == UNIT_SYSTEM_US_CUSTOMARY {
				return "yards"
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
		case MEASURE_POWER_TO_WEIGHT:
			return "watts/kg";
		default:
			return ""
		}
	}
}
