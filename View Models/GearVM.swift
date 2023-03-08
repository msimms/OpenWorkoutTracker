//
//  GearVM.swift
//  Created by Michael Simms on 9/29/22.
//

import Foundation

class GearSummary : Identifiable, Hashable, Equatable {
	var id: UInt64 = UInt64.max
	var name: String = ""
	var description: String = ""
	var weightKg: Double = 0.0
	var wheelCircumferenceMm = 0.0
	var timeAdded: Date = Date()
	var timeRetired: Date = Date()
	var lastUpdatedTime: Date = Date()

	/// Constructor
	init() {
	}
	init(json: Decodable) {
	}
	init(id: UInt64, name: String, description: String) {
		self.id = id
		self.name = name
		self.description = description
	}

	/// Hashable overrides
	func hash(into hasher: inout Hasher) {
		hasher.combine(self.id)
	}
	
	/// Equatable overrides
	static func == (lhs: GearSummary, rhs: GearSummary) -> Bool {
		return lhs.id == rhs.id
	}
}

class GearVM : ObservableObject {
	@Published var gear: Array<GearSummary> = []
	
	init() {
		self.buildGearList()
	}
	
	func buildGearList() {
		InitializeBikeProfileList()
		InitializeShoeProfileList()
	}
	
	func listBikes() -> Array<GearSummary> {
		var bikes: Array<GearSummary> = []
		var bikeIndex: size_t = 0
		var done: Bool = false
		
		while !done {
			var namePtr: UnsafeMutablePointer<CChar>!
			var descriptionPtr: UnsafeMutablePointer<CChar>!
			var bikeId: UInt64 = 0
			var bikeWeight: Double = 0.0
			var wheelCircumference: Double = 0.0
			var timeAdded: time_t = 0
			var timeRetired: time_t = 0
			var lastUpdatedTime: time_t = 0
			
			if GetBikeProfileByIndex(bikeIndex, &bikeId, &namePtr, &descriptionPtr, &bikeWeight, &wheelCircumference, &timeAdded, &timeRetired, &lastUpdatedTime) {
				let summary: GearSummary = GearSummary()
				
				summary.id = bikeId
				summary.name = String.init(cString: namePtr)
				summary.description = String.init(cString: descriptionPtr)
				summary.weightKg = bikeWeight
				summary.wheelCircumferenceMm = wheelCircumference
				summary.timeAdded = Date(timeIntervalSince1970: TimeInterval(timeAdded))
				summary.timeRetired = Date(timeIntervalSince1970: TimeInterval(timeRetired))
				summary.lastUpdatedTime = Date(timeIntervalSince1970: TimeInterval(lastUpdatedTime))
				
				bikes.append(summary)
				bikeIndex += 1
			}
			else {
				done = true
			}
		}
		
		return bikes
	}
	
	func listShoes() -> Array<GearSummary> {
		var shoes: Array<GearSummary> = []
		var shoeIndex: size_t = 0
		var done: Bool = false
		
		while !done {
			var namePtr: UnsafeMutablePointer<CChar>!
			var descriptionPtr: UnsafeMutablePointer<CChar>!
			var shoeId: UInt64 = 0
			var timeAdded: time_t = 0
			var timeRetired: time_t = 0
			var lastUpdatedTime: time_t = 0
			
			if GetShoeProfileByIndex(shoeIndex, &shoeId, &namePtr, &descriptionPtr, &timeAdded, &timeRetired, &lastUpdatedTime) {
				let summary: GearSummary = GearSummary()
				
				summary.id = shoeId
				summary.name = String.init(cString: namePtr)
				summary.description = String.init(cString: descriptionPtr)
				summary.timeAdded = Date(timeIntervalSince1970: TimeInterval(timeAdded))
				summary.timeRetired = Date(timeIntervalSince1970: TimeInterval(timeRetired))
				summary.lastUpdatedTime = Date(timeIntervalSince1970: TimeInterval(lastUpdatedTime))
				
				shoes.append(summary)
				shoeIndex += 1
			}
			else {
				done = true
			}
		}
		
		return shoes
	}
	
	static func createBike(item: GearSummary) -> Bool {
		if item.id == UInt64.max { // New item
			return CreateBikeProfile(item.name, item.description, item.weightKg, item.wheelCircumferenceMm, time_t(item.timeAdded.timeIntervalSince1970), time_t(item.timeRetired.timeIntervalSince1970), time_t(item.lastUpdatedTime.timeIntervalSince1970))
		}
		return UpdateBikeProfile(item.id, item.name, item.description, item.weightKg, item.wheelCircumferenceMm, time_t(item.timeAdded.timeIntervalSince1970), time_t(item.timeRetired.timeIntervalSince1970), time_t(item.lastUpdatedTime.timeIntervalSince1970))
	}
	
	static func createShoes(item: GearSummary) -> Bool {
		if item.id == UInt64.max { // New item
			return CreateShoeProfile(item.name, item.description, time_t(item.timeAdded.timeIntervalSince1970), time_t(item.timeRetired.timeIntervalSince1970), time_t(item.lastUpdatedTime.timeIntervalSince1970))
		}
		return UpdateShoeProfile(item.id, item.name, item.description, time_t(item.timeAdded.timeIntervalSince1970), time_t(item.timeRetired.timeIntervalSince1970), time_t(item.lastUpdatedTime.timeIntervalSince1970))
	}
	
	func updateGearFromDict(dict: Dictionary<String, AnyObject>) {
		let summary: GearSummary = GearSummary()
		
		if let name = dict[PARAM_GEAR_NAME] as? String {
			summary.name = name
		}
		if let description = dict[PARAM_GEAR_DESCRIPTION] as? String {
			summary.description = description
		}
		if let addTime = dict[PARAM_GEAR_ADD_TIME] as? UInt {
			summary.timeAdded = Date(timeIntervalSince1970: TimeInterval(addTime))
		}
		if let retireTime = dict[PARAM_GEAR_RETIRE_TIME] as? UInt {
			summary.timeRetired = Date(timeIntervalSince1970: TimeInterval(retireTime))
		}
		if let lastUpdatedTime = dict[PARAM_GEAR_LAST_UPDATED_TIME] as? UInt {
			summary.lastUpdatedTime = Date(timeIntervalSince1970: TimeInterval(lastUpdatedTime))
		}
		
		if let type = dict[PARAM_GEAR_TYPE] as? String {
			if type == "bike" {
				summary.id = GetBikeIdFromName(summary.name)
				let _ = GearVM.createBike(item: summary)
			}
			else if type == "shoes" {
				summary.id = GetShoeIdFromName(summary.name)
				let _ = GearVM.createShoes(item: summary)
			}
		}
	}

	static func deleteBike(id: UInt64) -> Bool {
		return DeleteBikeProfile(id)
	}
	
	static func deleteShoes(id: UInt64) -> Bool {
		return DeleteShoeProfile(id)
	}
}
