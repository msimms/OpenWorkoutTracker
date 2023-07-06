//
//  GearVM.swift
//  Created by Michael Simms on 9/29/22.
//

import Foundation

class GearServiceItem : Identifiable, Hashable, Equatable {
	var serviceId: String = ""
	var servicedTime: Date = Date()
	var description: String = ""

	/// Constructor
	init() {
	}
	init(serviceId: String, servicedTime: time_t, description: String) {
		self.serviceId = serviceId
		self.servicedTime = Date(timeIntervalSince1970: TimeInterval(servicedTime))
		self.description = description
	}
	init(servicedTime: time_t, description: String) {
		self.servicedTime = Date(timeIntervalSince1970: TimeInterval(servicedTime))
		self.description = description
	}
	init(json: Decodable) {
	}
	
	/// Hashable overrides
	func hash(into hasher: inout Hasher) {
		hasher.combine(self.serviceId)
	}
	
	/// Equatable overrides
	static func == (lhs: GearServiceItem, rhs: GearServiceItem) -> Bool {
		return lhs.serviceId == rhs.serviceId
	}
}

class GearSummary : Identifiable, Hashable, Equatable {
	var gearId: UUID = UUID()
	var name: String = ""
	var description: String = ""
	var weightKg: Double = 0.0
	var wheelCircumferenceMm = 0.0
	var timeAdded: Date = Date()
	var timeRetired: Date = Date()
	var serviceHistory: Array<GearServiceItem> = []
	var lastUpdatedTime: Date = Date()

	/// Constructor
	init() {
	}
	init(json: Decodable) {
	}
	init(gearId: UUID, name: String, description: String) {
		self.gearId = gearId
		self.name = name
		self.description = description
	}

	/// Hashable overrides
	func hash(into hasher: inout Hasher) {
		hasher.combine(self.gearId)
	}
	
	/// Equatable overrides
	static func == (lhs: GearSummary, rhs: GearSummary) -> Bool {
		return lhs.gearId == rhs.gearId
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
			var bikeWeight: Double = 0.0
			var wheelCircumference: Double = 0.0
			var timeAdded: time_t = 0
			var timeRetired: time_t = 0
			var lastUpdatedTime: time_t = 0
			
			let gearIdPtr = UnsafeRawPointer(GetBikeIdFromIndex(bikeIndex))
			if gearIdPtr != nil {
				let gearId = String(cString: gearIdPtr!.assumingMemoryBound(to: CChar.self))

				if RetrieveBikeProfileById(gearId, &namePtr, &descriptionPtr, &bikeWeight, &wheelCircumference, &timeAdded, &timeRetired, &lastUpdatedTime) {
					let summary: GearSummary = GearSummary()
					
					summary.gearId = UUID(uuidString: gearId)!
					summary.name = String.init(cString: namePtr)
					summary.description = String.init(cString: descriptionPtr)
					summary.weightKg = bikeWeight
					summary.wheelCircumferenceMm = wheelCircumference
					summary.timeAdded = Date(timeIntervalSince1970: TimeInterval(timeAdded))
					summary.timeRetired = Date(timeIntervalSince1970: TimeInterval(timeRetired))
					summary.lastUpdatedTime = Date(timeIntervalSince1970: TimeInterval(lastUpdatedTime))

					var serviceIndex: Int = 0
					var timeServiced: time_t = 0
					var serviceIdPtr: UnsafeMutablePointer<CChar>!
					var descriptionPtr: UnsafeMutablePointer<CChar>!

					while RetrieveServiceHistoryByIndex(gearId, serviceIndex, &serviceIdPtr, &timeServiced, &descriptionPtr) {
						let serviceId = String.init(cString: serviceIdPtr)
						let description = String.init(cString: descriptionPtr)
						let serviceItem = GearServiceItem(serviceId: serviceId, servicedTime: timeServiced, description: description)
						summary.serviceHistory.append(serviceItem)
						serviceIndex += 1
						serviceIdPtr.deallocate()
						descriptionPtr.deallocate()
					}

					bikes.append(summary)
					bikeIndex += 1
				}
				else {
					done = true
				}
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
			var timeAdded: time_t = 0
			var timeRetired: time_t = 0
			var lastUpdatedTime: time_t = 0
			
			let gearIdPtr = UnsafeRawPointer(GetShoeIdFromIndex(shoeIndex))
			if gearIdPtr != nil {
				let gearId = String(cString: gearIdPtr!.assumingMemoryBound(to: CChar.self))

				if RetrieveShoeProfileById(gearId, &namePtr, &descriptionPtr, &timeAdded, &timeRetired, &lastUpdatedTime) {
					let summary: GearSummary = GearSummary()
					
					summary.gearId = UUID(uuidString: gearId)!
					summary.name = String.init(cString: namePtr)
					summary.description = String.init(cString: descriptionPtr)
					summary.timeAdded = Date(timeIntervalSince1970: TimeInterval(timeAdded))
					summary.timeRetired = Date(timeIntervalSince1970: TimeInterval(timeRetired))
					summary.lastUpdatedTime = Date(timeIntervalSince1970: TimeInterval(lastUpdatedTime))
					
					shoes.append(summary)
					shoeIndex += 1
					
					descriptionPtr.deallocate()
				}
				else {
					done = true
				}
			}
			else {
				done = true
			}
		}
		
		return shoes
	}
	
	static func createBike(item: GearSummary) -> Bool {
		if GetBikeIdFromName(item.name) == nil {
			if CreateBikeProfile(item.gearId.uuidString, item.name, item.description, item.weightKg, item.wheelCircumferenceMm,
								 time_t(item.timeAdded.timeIntervalSince1970),
								 time_t(item.timeRetired.timeIntervalSince1970),
								 time_t(item.lastUpdatedTime.timeIntervalSince1970)) {
				for serviceItem in item.serviceHistory {
					if CreateServiceHistory(item.gearId.uuidString,
											serviceItem.serviceId,
											time_t(serviceItem.servicedTime.timeIntervalSince1970),
											serviceItem.description) == false {
						return false
					}
				}
				return true
			}
		}
		else {
			if UpdateBikeProfile(item.gearId.uuidString, item.name, item.description, item.weightKg, item.wheelCircumferenceMm,
								 time_t(item.timeAdded.timeIntervalSince1970),
								 time_t(item.timeRetired.timeIntervalSince1970),
								 time_t(item.lastUpdatedTime.timeIntervalSince1970)) {
				for serviceItem in item.serviceHistory {
					if CreateServiceHistory(item.gearId.uuidString,
											serviceItem.serviceId,
											time_t(serviceItem.servicedTime.timeIntervalSince1970),
											serviceItem.description) == false {
						return false
					}
				}
				return true
			}
		}
		return false
	}

	static func createShoes(item: GearSummary) -> Bool {
		if GetShoeIdFromName(item.name) == nil {
			return CreateShoeProfile(item.gearId.uuidString, item.name, item.description,
									 time_t(item.timeAdded.timeIntervalSince1970),
									 time_t(item.timeRetired.timeIntervalSince1970),
									 time_t(item.lastUpdatedTime.timeIntervalSince1970))
		}
		return UpdateShoeProfile(item.gearId.uuidString, item.name, item.description,
								 time_t(item.timeAdded.timeIntervalSince1970),
								 time_t(item.timeRetired.timeIntervalSince1970),
								 time_t(item.lastUpdatedTime.timeIntervalSince1970))
	}

	func updateGearFromDict(dict: Dictionary<String, AnyObject>) {
		let summary: GearSummary = GearSummary()
		
		if let gearId = dict[PARAM_GEAR_ID] as? String {
			summary.gearId = UUID(uuidString: gearId)!
		}
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
		if let serviceHistory = dict[PARAM_GEAR_SERVICE_HISTORY] as? Array<Dictionary<String, AnyObject>> {
			for serviceItem in serviceHistory {
				if let tempServiceId = serviceItem[PARAM_GEAR_SERVICE_ID] as? String,
				   let tempServicedTime = serviceItem[PARAM_GEAR_SERVICE_TIME] as? time_t,
				   let tempDescription = serviceItem[PARAM_GEAR_DESCRIPTION] as? String {
					let tempServiceItem = GearServiceItem(serviceId: tempServiceId, servicedTime: tempServicedTime, description: tempDescription)
					summary.serviceHistory.append(tempServiceItem)
				}
			}
		}
		
		if let type = dict[PARAM_GEAR_TYPE] as? String {
			if type == "bike" {
				let _ = GearVM.createBike(item: summary)
			}
			else if type == "shoes" {
				let _ = GearVM.createShoes(item: summary)
			}
		}
	}

	static func deleteBike(gearId: UUID) -> Bool {
		return DeleteBikeProfile(gearId.uuidString)
	}
	
	static func deleteShoes(gearId: UUID) -> Bool {
		return DeleteShoeProfile(gearId.uuidString)
	}
}
