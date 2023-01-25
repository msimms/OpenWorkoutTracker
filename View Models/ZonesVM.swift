//
//  ZonesVM.swift
//  Created by Michael Simms on 1/24/23.
//

import Foundation

class ZonesVM {
	static func listHrZones() -> Array<Bar> {
		var result: Array<Bar> = []

		for zoneNum in 0...4 {
			let zoneValue = GetHrZone(UInt8(zoneNum))
			result.append(Bar(value: zoneValue, label: String(Int(zoneValue))))
		}
		return result
	}
	
	static func listPowerZones() -> Array<Bar> {
		var result: Array<Bar> = []

		for zoneNum in 0...4 {
			let zoneValue = GetPowerZone(UInt8(zoneNum))
			result.append(Bar(value: zoneValue, label: String(Int(zoneValue))))
		}
		return result
	}
	
	static func listRunTrainingPaces() -> Dictionary<String, String> {
		var result: Dictionary<String, String> = [:]
		
		return result
	}
}
