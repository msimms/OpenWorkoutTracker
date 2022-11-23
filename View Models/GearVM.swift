//
//  GearVM.swift
//  Created by Michael Simms on 9/29/22.
//

import Foundation

class GearSummary : Codable, Identifiable, Hashable, Equatable {
	enum CodingKeys: CodingKey {
		case id
		case name
		case description
	}
	
	var id: UInt64 = 0
	var name: String = ""
	var description: String = ""
	var timeAdded: Date = Date()
	var timeRetired: Date = Date()

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
		var bikeId: UInt64 = 0
		var bikeWeight: Double = 0.0
		var wheelCircumference: Double = 0.0
		var timeAdded: time_t = 0
		var timeRetired: time_t = 0
		var done: Bool = false
		
		while !done {
			var namePtr: UnsafeMutablePointer<CChar>!
			var descriptionPtr: UnsafeMutablePointer<CChar>!
			
			if GetBikeProfileByIndex(bikeIndex, &bikeId, &namePtr, &descriptionPtr, &bikeWeight, &wheelCircumference, &timeAdded, &timeRetired) {
				let summary: GearSummary = GearSummary()
				
				summary.id = bikeId
				summary.name = String.init(cString: namePtr)
				summary.description = String.init(cString: descriptionPtr)
				summary.timeAdded = Date(timeIntervalSince1970: TimeInterval(timeAdded))
				summary.timeRetired = Date(timeIntervalSince1970: TimeInterval(timeRetired))
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
		var shoeId: UInt64 = 0
		var done: Bool = false
		
		while !done {
			var namePtr: UnsafeMutablePointer<CChar>!
			var descriptionPtr: UnsafeMutablePointer<CChar>!
			var timeAdded: time_t = 0
			var timeRetired: time_t = 0
			
			if GetShoeProfileByIndex(shoeIndex, &shoeId, &namePtr, &descriptionPtr, &timeAdded, &timeRetired) {
				let summary: GearSummary = GearSummary()
				
				summary.id = shoeId
				summary.name = String.init(cString: namePtr)
				summary.description = String.init(cString: descriptionPtr)
				summary.timeAdded = Date(timeIntervalSince1970: TimeInterval(timeAdded))
				summary.timeRetired = Date(timeIntervalSince1970: TimeInterval(timeRetired))
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
		if item.id == 0 { // New item
		}
		else {
		}
		return false
	}
	
	static func createShoes(item: GearSummary) -> Bool {
		if item.id == 0 { // New item
			return AddShoeProfile(item.name, item.description, time(nil), 0)
		}
		else {
		}
		return false
	}

	static func updateBike() -> Bool {
		return false
	}

	static func updateShoe() -> Bool {
		return false
	}
	
	static func updateGearFromDict(dict: Dictionary<String, AnyObject>) -> Bool {
		return false
	}
}
