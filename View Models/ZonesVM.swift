//
//  ZonesVM.swift
//  Created by Michael Simms on 1/24/23.
//

import Foundation

class ZonesVM : ObservableObject {
	var hrZonesDescription: String = ""
	var powerZonesDescription: String = ""

	func hasHrData() -> Bool {
		return Preferences.estimatedMaxHr() > 1.0 || Preferences.userDefinedMaxHr() > 1.0
	}

	func hasPowerData() -> Bool {
		return Preferences.estimatedFtp() > 1.0 || Preferences.userDefinedFtp() > 1.0
	}

	func hasRunData() -> Bool {
		return Preferences.bestRecent5KSecs() > 0
	}

	func listHrZones() -> Array<Bar> {
		var zoneBars: Array<Bar> = []
		let descriptions = ["Very Light (Recovery)", "Light (Endurance)", "Moderate", "Hard (Speed Endurance)", "Maximum"]
		var lastValue = 1
		
		self.hrZonesDescription = ""
		for zoneNum in 0...4 {
			let zoneMaxValue = GetHrZone(UInt8(zoneNum))
			let printableValue = Int(zoneMaxValue)
			let zoneLabel = "\(lastValue) to \(printableValue) BPM"
			zoneBars.append(Bar(value: zoneMaxValue, label: zoneLabel, description: descriptions[zoneNum]))
			
			self.hrZonesDescription += "Zone "
			self.hrZonesDescription += String(zoneNum + 1)
			self.hrZonesDescription += " : "
			self.hrZonesDescription += descriptions[zoneNum]
			self.hrZonesDescription += "\n"
			
			lastValue = printableValue
		}
		return zoneBars
	}

	func listPowerZones() -> Array<Bar> {
		var zoneBars: Array<Bar> = []
		let descriptions = ["Recovery", "Endurance", "Tempo", "Lactate Threshold", "VO2 Max", "Anaerobic Capacity", "Neuromuscular Power"]
		var lastValue = 1
		
		self.powerZonesDescription = ""
		for zoneNum in 0...5 {
			let zoneValue = GetPowerZone(UInt8(zoneNum))
			let printableValue = Int(zoneValue)
			var zoneLabel = ""
			
			if zoneNum == 5 {
				zoneLabel = "> \(lastValue) Watts"
			}
			else {
				zoneLabel = "\(lastValue) to \(printableValue) Watts"
			}
			zoneBars.append(Bar(value: zoneValue, label: zoneLabel, description: descriptions[zoneNum]))
			
			self.powerZonesDescription += "Zone "
			self.powerZonesDescription += String(zoneNum + 1)
			self.powerZonesDescription += " : "
			self.powerZonesDescription += descriptions[zoneNum]
			self.powerZonesDescription += "\n"
			
			lastValue = printableValue
		}
		return zoneBars
	}

	func listRunTrainingPaces() -> Dictionary<String, Double> {
		var result: Dictionary<String, Double> = [:]
		
		result[WORKOUT_INPUT_LONG_RUN_PACE] = GetRunTrainingPace(LONG_RUN_PACE)
		result[WORKOUT_INPUT_EASY_RUN_PACE] = GetRunTrainingPace(EASY_RUN_PACE)
		result[WORKOUT_INPUT_TEMPO_RUN_PACE] = GetRunTrainingPace(TEMPO_RUN_PACE)
		result[WORKOUT_INPUT_FUNCTIONAL_THRESHOLD_PACE] = GetRunTrainingPace(FUNCTIONAL_THRESHOLD_PACE)
		return result
	}
}
