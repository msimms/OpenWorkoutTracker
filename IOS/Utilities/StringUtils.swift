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
}
