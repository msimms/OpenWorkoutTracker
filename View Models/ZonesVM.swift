//
//  ZonesVM.swift
//  Created by Michael Simms on 1/24/23.
//

import Foundation

class ZonesVM {
	static func hasHrData() -> Bool {
		return Preferences.estimatedMaxHr() > 1.0 || Preferences.userDefinedMaxHr() > 1.0
	}

	static func hasPowerData() -> Bool {
		return Preferences.estimatedFtp() > 1.0 || Preferences.userDefinedFtp() > 1.0
	}

	static func hasRunData() -> Bool {
		return Preferences.bestRecent5KSecs() > 0
	}

	static func listHrZones() -> Array<Bar> {
		var result: Array<Bar> = []
		let descriptions = ["Very Light (Recovery)", "Light (Endurance)", "Moderate", "Hard (Speed Endurance)", "Maximum"]

		for zoneNum in 0...4 {
			let zoneValue = GetHrZone(UInt8(zoneNum))
			result.append(Bar(value: zoneValue, label: String(Int(zoneValue)), description: descriptions[zoneNum]))
		}
		return result
	}

	static func listPowerZones() -> Array<Bar> {
		var result: Array<Bar> = []
		let descriptions = ["Recovery", "Endurance", "Tempo", "Lactate Threshold", "VO2 Max", "Anaerobic Capacity", "Neuromuscular Power"]

		for zoneNum in 0...4 {
			let zoneValue = GetPowerZone(UInt8(zoneNum))
			result.append(Bar(value: zoneValue, label: String(Int(zoneValue)), description: descriptions[zoneNum]))
		}
		return result
	}
	
	static func listRunTrainingPaces() -> Dictionary<String, Double> {
		var result: Dictionary<String, Double> = [:]
		
		result[WORKOUT_INPUT_LONG_RUN_PACE] = GetRunTrainingPace(LONG_RUN_PACE)
		result[WORKOUT_INPUT_EASY_RUN_PACE] = GetRunTrainingPace(EASY_RUN_PACE)
		result[WORKOUT_INPUT_TEMPO_RUN_PACE] = GetRunTrainingPace(TEMPO_RUN_PACE)
		result[WORKOUT_INPUT_FUNCTIONAL_THRESHOLD_PACE] = GetRunTrainingPace(FUNCTIONAL_THRESHOLD_PACE)
		return result
	}
}
