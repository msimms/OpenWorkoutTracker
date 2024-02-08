//
//  GearVM.swift
//  Created by Michael Simms on 9/29/22.
//

import Foundation

class GearServiceItem : Identifiable, Hashable, Equatable, Encodable {
	enum CodingKeys: CodingKey {
		case serviceId
		case timeServiced
		case description
	}

	var serviceId: String = ""
	var timeServiced: Date = Date()
	var description: String = ""

	/// Constructor
	init() {
	}
	init(serviceId: UUID, timeServiced: Date, description: String) {
		self.serviceId = serviceId.uuidString
		self.timeServiced = timeServiced
		self.description = description
	}
	init(serviceId: String, timeServiced: time_t, description: String) {
		self.serviceId = serviceId
		self.timeServiced = Date(timeIntervalSince1970: TimeInterval(timeServiced))
		self.description = description
	}
	init(timeServiced: time_t, description: String) {
		self.timeServiced = Date(timeIntervalSince1970: TimeInterval(timeServiced))
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

class GearSummary : Identifiable, Hashable, Equatable, Encodable {
	enum CodingKeys: String, CodingKey {
		case gearId
		case name
		case description
		case weightKg
		case wheelCircumferenceMm
		case timeAdded
		case timeRetired
		case serviceHistory
		case lastUpdatedTime
	}

	var gearId: UUID = UUID()
	var name: String = ""
	var description: String = ""
	var weightKg: Double = 0.0
	var wheelCircumferenceMm = 0.0
	var timeAdded: Date = Date()
	var timeRetired: Date = Date(timeIntervalSince1970: 0)
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
	
	var dict : [String: Any]? {
		guard let data = try? JSONEncoder().encode(self) else { return nil }
		guard let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String:Any] else { return nil }
		return json
	}
}

class GearVM : ObservableObject {
	@Published var gear: Array<GearSummary> = []
	
	init() {
		self.buildGearList()
	}
	
	func buildGearList() {
		if InitializeBikeProfileList() == false {
			NSLog("Failed to initialize the bike profile list.")
		}
		if InitializeShoeProfileList() == false {
			NSLog("Failed to initialize the shoe profile list.")
		}
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
						let serviceItem = GearServiceItem(serviceId: serviceId, timeServiced: timeServiced, description: description)

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
		// Does this already exist?
		if GetBikeIdFromName(item.name) == nil {

			// Create in the local database.
			if CreateBikeProfile(item.gearId.uuidString,
								 item.name,
								 item.description,
								 item.weightKg,
								 item.wheelCircumferenceMm,
								 time_t(item.timeAdded.timeIntervalSince1970),
								 time_t(item.timeRetired.timeIntervalSince1970),
								 time_t(item.lastUpdatedTime.timeIntervalSince1970)) {

				// Add the service history.
				for serviceItem in item.serviceHistory {
					if CreateServiceHistory(item.gearId.uuidString,
											serviceItem.serviceId,
											time_t(serviceItem.timeServiced.timeIntervalSince1970),
											serviceItem.description) == false {
						return false
					}
				}

				do {
					return try ApiClient.shared.createGear(item: item)
				}
				catch { }
			}
		}
		else {
			// Update in the local database.
			if UpdateBikeProfile(item.gearId.uuidString,
								 item.name,
								 item.description,
								 item.weightKg,
								 item.wheelCircumferenceMm,
								 time_t(item.timeAdded.timeIntervalSince1970),
								 time_t(item.timeRetired.timeIntervalSince1970),
								 time_t(item.lastUpdatedTime.timeIntervalSince1970)) {
				
				// Add the service history.
				for serviceItem in item.serviceHistory {
					if CreateServiceHistory(item.gearId.uuidString,
											serviceItem.serviceId,
											time_t(serviceItem.timeServiced.timeIntervalSince1970),
											serviceItem.description) == false {
						return false
					}
				}

				// Update the optional server.
				do {
					return try ApiClient.shared.updateGear(item: item)
				}
				catch { }
			}
			else {
				NSLog("Failed to update the bike profile.")
			}
		}
		return false
	}

	static func createShoes(item: GearSummary) -> Bool {
		// Does this already exist?
		if GetShoeIdFromName(item.name) == nil {

			// Create in the local database.
			if CreateShoeProfile(item.gearId.uuidString,
								 item.name,
								 item.description,
								 time_t(item.timeAdded.timeIntervalSince1970),
								 time_t(item.timeRetired.timeIntervalSince1970),
								 time_t(item.lastUpdatedTime.timeIntervalSince1970)) {

				// Update the optional server.
				do {
					return try ApiClient.shared.createGear(item: item)
				}
				catch { }
			}
			else {
				NSLog("Failed to update the shoe profile.")
			}
			return false
		}

		// Update in the local database.
		if UpdateShoeProfile(item.gearId.uuidString,
							 item.name,
							 item.description,
							 time_t(item.timeAdded.timeIntervalSince1970),
							 time_t(item.timeRetired.timeIntervalSince1970),
							 time_t(item.lastUpdatedTime.timeIntervalSince1970)) {

			// Update the optional server.
			do {
				return try ApiClient.shared.updateGear(item: item)
			}
			catch { }
		}
		else {
			NSLog("Failed to update the shoe profile.")
		}
		return false
	}
	
	static func createServiceRecord(gearId: UUID, item: GearServiceItem) -> Bool {
		return CreateServiceHistory(gearId.uuidString, item.serviceId, Int(item.timeServiced.timeIntervalSince1970), item.description)
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
				   let tempTimeServiced = serviceItem[PARAM_GEAR_SERVICE_TIME] as? time_t,
				   let tempDescription = serviceItem[PARAM_GEAR_DESCRIPTION] as? String {
					let tempServiceItem = GearServiceItem(serviceId: tempServiceId, timeServiced: tempTimeServiced, description: tempDescription)
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

	static func retireBike(item: GearSummary) -> Bool {
		// Update in the local database.
		item.timeRetired = Date()

		// Update in the local database.
		if UpdateBikeProfile(item.gearId.uuidString,
							 item.name,
							 item.description,
							 item.weightKg,
							 item.wheelCircumferenceMm,
							 time_t(item.timeAdded.timeIntervalSince1970),
							 time_t(item.timeRetired.timeIntervalSince1970),
							 time_t(item.lastUpdatedTime.timeIntervalSince1970)) {

			// Update the optional server.
			do {
				return try ApiClient.shared.updateGear(item: item)
			}
			catch { }
		}
		else {
			NSLog("Failed to update the bike profile.")
		}
		return false
	}
	
	static func retireShoes(item: GearSummary) -> Bool {
		// Set the retired date to now.
		item.timeRetired = Date()

		// Update in the local database.
		if UpdateShoeProfile(item.gearId.uuidString,
							 item.name,
							 item.description,
							 time_t(item.timeAdded.timeIntervalSince1970),
							 time_t(item.timeRetired.timeIntervalSince1970),
							 time_t(item.lastUpdatedTime.timeIntervalSince1970)) {

			// Update the optional server.
			do {
				return try ApiClient.shared.updateGear(item: item)
			}
			catch { }
		}
		return false
	}

	static func deleteBike(gearId: UUID) -> Bool {
		// Delete from the database and then from the optional server.
		if DeleteBikeProfile(gearId.uuidString) {
			return ApiClient.shared.deleteGear(gearId: gearId)
		}
		else {
			NSLog("Failed to delete the bike profile.")
		}
		return false
	}
	
	static func deleteShoes(gearId: UUID) -> Bool {
		// Delete from the database and then from the optional server.
		if DeleteShoeProfile(gearId.uuidString) {
			return ApiClient.shared.deleteGear(gearId: gearId)
		}
		else {
			NSLog("Failed to delete the shoe profile.")
		}
		return false
	}
}
