//
//  PacePlansVM.swift
//  Created by Michael Simms on 9/29/22.
//

import Foundation

class PacePlan : Identifiable, Hashable, Equatable {
	var id: UUID = UUID()
	var name: String = ""
	var description: String = ""
	var distance: Double = 0.0
	var distanceUnits: UnitSystem = UNIT_SYSTEM_METRIC
	var time: Int = 0 // The time (seconds) in which the user wishes to complete the pace plan
	var splits: Int = 0 // The splits (seconds, can be negative)
	var splitsUnits: UnitSystem = UNIT_SYSTEM_METRIC
	var route: String = ""
	var lastUpdatedTime: Date = Date()

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
	static let shared = PacePlansVM()
	@Published var pacePlans: Array<PacePlan> = []
	
	/// Singleton Constructor
	private init() {
		let _ = buildPacePlansList()
	}
	
	func buildPacePlansList() -> Bool {
		var result = false

		// Remove any old ones.
		self.pacePlans = []

		// Query the backend for the latest pace plans.
		if InitializePacePlanList() {

			var pacePlanIndex = 0
			var done = false

			while !done {
				if let rawPacePlanDescPtr = RetrievePacePlanAsJSON(pacePlanIndex) {
					let summaryObj = PacePlan()
					let pacePlanDescPtr = UnsafeRawPointer(rawPacePlanDescPtr)

					let pacePlanDesc = String(cString: pacePlanDescPtr.assumingMemoryBound(to: CChar.self))
					let summaryDict = try! JSONSerialization.jsonObject(with: Data(pacePlanDesc.utf8), options: []) as! [String:Any]

					if let pacePlanId = summaryDict[PARAM_PACE_PLAN_ID] as? String {
						summaryObj.id = UUID(uuidString: pacePlanId)!
					}
					if let pacePlanName = summaryDict[PARAM_PACE_PLAN_NAME] as? String {
						summaryObj.name = pacePlanName
					}
					if let pacePlanDescription = summaryDict[PARAM_PACE_PLAN_DESCRIPTION] as? String {
						summaryObj.description = pacePlanDescription
					}
					if let pacePlanDistance = summaryDict[PARAM_PACE_PLAN_TARGET_DISTANCE] as? Double {
						summaryObj.distance = pacePlanDistance
					}
					if let pacePlanDistanceUnits = summaryDict[PARAM_PACE_PLAN_TARGET_DISTANCE_UNITS] as? Int {
						if pacePlanDistanceUnits == UNIT_SYSTEM_US_CUSTOMARY.rawValue {
							summaryObj.distanceUnits = UNIT_SYSTEM_US_CUSTOMARY
						}
						else {
							summaryObj.distanceUnits = UNIT_SYSTEM_METRIC
						}
					}
					if let pacePlanTime = summaryDict[PARAM_PACE_PLAN_TARGET_TIME] as? Int {
						summaryObj.time = pacePlanTime
					}
					if let pacePlanSplits = summaryDict[PARAM_PACE_PLAN_TARGET_SPLITS] as? Int {
						summaryObj.splits = pacePlanSplits
					}
					if let pacePlanSplitsUnits = summaryDict[PARAM_PACE_PLAN_TARGET_SPLITS_UNITS] as? Int {
						if pacePlanSplitsUnits == UNIT_SYSTEM_US_CUSTOMARY.rawValue {
							summaryObj.splitsUnits = UNIT_SYSTEM_US_CUSTOMARY
						}
						else {
							summaryObj.splitsUnits = UNIT_SYSTEM_METRIC
						}
					}
					if let pacePlanRoute = summaryDict[PARAM_PACE_PLAN_ROUTE] as? String {
						summaryObj.route = pacePlanRoute
					}
					if let lastModifiedTime = summaryDict[PARAM_PACE_PLAN_LAST_UPDATED_TIME] as? UInt {
						summaryObj.lastUpdatedTime = Date(timeIntervalSince1970: TimeInterval(lastModifiedTime))
					}

					defer {
						pacePlanDescPtr.deallocate()
					}

					self.pacePlans.append(summaryObj)
					pacePlanIndex += 1
				}
				else {
					done = true
				}
			}

			result = true
		}
		
		return result
	}
	
	func updatePacePlanFromDict(dict: Dictionary<String, AnyObject>) {
	}

	func createPacePlan(plan: PacePlan) -> Bool {
		if CreateNewPacePlan(plan.name, plan.id.uuidString) {
			let lastUpdatedTime = time(nil)

			if UpdatePacePlan(plan.id.uuidString, plan.name, plan.description, plan.distance, plan.time, plan.splits, plan.distanceUnits, plan.splitsUnits, lastUpdatedTime) {
				return buildPacePlansList()
			}

			// Creation failed, clean up our mess.
			DeletePacePlan(plan.id.uuidString)
		}
		return false
	}

	func doesPacePlanExist(planId: UUID) -> Bool {
		for existingPlan in self.pacePlans {
			if existingPlan.id == planId {
				return true
			}
		}
		return false
	}

	func updatePacePlan(plan: PacePlan) -> Bool {
		let lastUpdatedTime = time(nil)
		
		if UpdatePacePlan(plan.id.uuidString, plan.name, plan.description, plan.distance, plan.time, plan.splits, plan.distanceUnits, plan.splitsUnits, lastUpdatedTime) {
			return buildPacePlansList()
		}
		return false
	}

	func deletePacePlan(planId: UUID) -> Bool {
		if DeletePacePlan(planId.uuidString) {
			return buildPacePlansList()
		}
		return false
	}

	/// @brief Parses the string for a time value in the format of HH:MM:SS where MM and SS ranges from 0 to 59.
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
