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
}
