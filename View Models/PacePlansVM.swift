//
//  PacePlansVM.swift
//  Created by Michael Simms on 9/29/22.
//

import Foundation

class PacePlan : Codable, Identifiable, Hashable, Equatable {
	enum CodingKeys: CodingKey {
		case id
		case name
		case distance
		case splits
	}
	
	var id: UUID = UUID()
	var name: String = ""
	var distance: Double = 0.0
	var splits: Double = 0.0
	
	/// Constructor
	init() {
	}
	init(json: Decodable) {
	}
	
	/// Hashable overrides
	func hash(into hasher: inout Hasher) {
		hasher.combine(self.id)
	}
	
	/// Equatable overrides
	static func == (lhs: PacePlan, rhs: PacePlan) -> Bool {
		return lhs.id == rhs.id
	}
}

class PacePlansVM : ObservableObject {
	@Published var pacePlans: Array<PacePlan> = []
	
	/// Constructor
	init() {
		buildPacePlansList()
	}
	
	func buildPacePlansList() {
		if InitializePacePlanList() {
			var pacePlanIndex = 0
			var done = false
			
			while !done {
				let pacePlanDesc = RetrievePacePlanAsJSON(pacePlanIndex)
				
				if pacePlanDesc == nil {
					done = true
				}
				else {
					let ptr = UnsafeRawPointer(pacePlanDesc)
					let tempPacePlanDesc = String(cString: ptr!.assumingMemoryBound(to: CChar.self))
					
					defer {
						ptr!.deallocate()
					}
					
					pacePlanIndex += 1
				}
			}
		}
	}
	
	func createPacePlan(name: String, description: String, distanceInKms: Double, paceSeconds: UInt, splits: Double) -> Bool {
		let planId = UUID().uuidString
		if CreateNewPacePlan(name, planId) {
//			if UpdatePacePlanDetails(planId, name, description, double targetPaceInMinKm, distanceInKms, splits, UnitSystem targetDistanceUnits, UnitSystem targetPaceUnits, time_t lastUpdatedTime) { }
		}
		return false
	}
	
	func deletePacePlan(pacePlanId: String) -> Bool {
		return DeletePacePlan(pacePlanId)
	}

	func parseHHMMSS(str: String, hours: inout Int, minutes: inout Int, seconds: inout Int) -> Bool {
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
		}

		return true
	}
}
