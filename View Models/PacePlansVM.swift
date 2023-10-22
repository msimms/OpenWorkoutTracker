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

	private func dictToObj(summaryDict: Dictionary<String, AnyObject>) -> PacePlan {
		let summaryObj = PacePlan()
		
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
		else if let pacePlanDistanceUnits = summaryDict[PARAM_PACE_PLAN_TARGET_DISTANCE_UNITS] as? String {
			if pacePlanDistanceUnits == "standard" {
				summaryObj.distanceUnits = UNIT_SYSTEM_US_CUSTOMARY
			}
			else {
				summaryObj.distanceUnits = UNIT_SYSTEM_METRIC
			}
		}
		if let pacePlanTime = summaryDict[PARAM_PACE_PLAN_TARGET_TIME] as? Int {
			summaryObj.time = pacePlanTime
		}
		else if let pacePlanTime = summaryDict[PARAM_PACE_PLAN_TARGET_TIME] as? String {
			var hours: Int = 0, minutes: Int = 0, seconds: Int = 0

			if StringUtils.parseHHMMSS(str: pacePlanTime, hours: &hours, minutes: &minutes, seconds: &seconds) {
				summaryObj.time = (hours * 60 * 60) + (minutes * 60) + seconds
			}
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
		else if let pacePlanSplitsUnits = summaryDict[PARAM_PACE_PLAN_TARGET_SPLITS_UNITS] as? String {
			if pacePlanSplitsUnits == "standard" {
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

		return summaryObj
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
					let pacePlanDescPtr = UnsafeRawPointer(rawPacePlanDescPtr)
					let pacePlanDesc = String(cString: pacePlanDescPtr.assumingMemoryBound(to: CChar.self))
					let summaryDict = try! JSONSerialization.jsonObject(with: Data(pacePlanDesc.utf8), options: []) as! [String:AnyObject]
					let summaryObj = self.dictToObj(summaryDict: summaryDict)

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
	
	func createPacePlan(plan: PacePlan) -> Bool {
		if CreateNewPacePlan(plan.id.uuidString, plan.name) {
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

	func updatePacePlanFromDict(summaryDict: Dictionary<String, AnyObject>) -> Bool {
		let summaryObj = self.dictToObj(summaryDict: summaryDict)

		if self.doesPacePlanExist(planId: summaryObj.id) {
			if UpdatePacePlan(summaryObj.id.uuidString, summaryObj.name, summaryObj.description, summaryObj.distance, summaryObj.time, summaryObj.splits, summaryObj.distanceUnits, summaryObj.splitsUnits, time_t(summaryObj.lastUpdatedTime.timeIntervalSince1970)) {
				return buildPacePlansList()
			}
		}
		else {
			if CreateNewPacePlan(summaryObj.id.uuidString, summaryObj.name) {
				if UpdatePacePlan(summaryObj.id.uuidString, summaryObj.name, summaryObj.description, summaryObj.distance, summaryObj.time, summaryObj.splits, summaryObj.distanceUnits, summaryObj.splitsUnits, time_t(summaryObj.lastUpdatedTime.timeIntervalSince1970)) {
					return buildPacePlansList()
				}
			}
		}
		return false
	}
	
	func deletePacePlan(planId: UUID) -> Bool {
		if DeletePacePlan(planId.uuidString) {
			return buildPacePlansList()
		}
		return false
	}
}
