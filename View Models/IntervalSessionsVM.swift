//
//  IntervalSessionsVM.swift
//  Created by Michael Simms on 9/29/22.
//

import Foundation
import SwiftUI

let NO_INTERVAL_SESSION_INDEX: Int = -1

let MODIFIER_ADD_SETS = "Add Sets"
let MODIFIER_EDIT_SETS = "Edit Sets"

let MODIFIER_ADD_REPS = "Add Reps"
let MODIFIER_EDIT_REPS = "Edit Reps"

let MODIFIER_ADD_DURATION = "Add Duration (seconds)"
let MODIFIER_EDIT_DURATION = "Edit Duration (seconds)"

let MODIFIER_ADD_DISTANCE_METERS = "Add Distance (meters)"
let MODIFIER_EDIT_DISTANCE_METERS = "Edit Distance (meters)"

let MODIFIER_ADD_DISTANCE_KILOMETERS = "Add Distance (kilometers)"
let MODIFIER_EDIT_DISTANCE_KILOMETERS = "Edit Distance (kilometers)"

let MODIFIER_ADD_DISTANCE_FEET = "Add Distance (feet)"
let MODIFIER_EDIT_DISTANCE_FEET = "Edit Distance (feet)"

let MODIFIER_ADD_DISTANCE_YARDS = "Add Distance (yards)"
let MODIFIER_EDIT_DISTANCE_YARDS = "Edit Distance (yards)"

let MODIFIER_ADD_DISTANCE_MILES = "Add Distance (miles)"
let MODIFIER_EDIT_DISTANCE_MILES = "Edit Distance (miles)"

let MODIFIER_ADD_PACE_US_CUSTOMARY = "Add Pace (mins/mile)"
let MODIFIER_EDIT_PACE_US_CUSTOMARY = "Edit Pace (mins/mile)"

let MODIFIER_ADD_PACE_METRIC = "Add Pace (mins/km)"
let MODIFIER_EDIT_PACE_METRIC = "Edit Pace (mins/km)"

let MODIFIER_ADD_SPEED_US_CUSTOMARY = "Add Speed (mph)"
let MODIFIER_EDIT_SPEED_US_CUSTOMARY = "Edit Speed (mph)"

let MODIFIER_ADD_SPEED_METRIC = "Add Speed (kph)"
let MODIFIER_EDIT_SPEED_METRIC = "Edit Speed (kph)"

let MODIFIER_ADD_POWER = "Add Power (watts)"
let MODIFIER_EDIT_POWER = "Edit Power (watts)"

// Mirrors the backend structure IntervalSessionSegment
class IntervalSegment : Identifiable, Hashable, Equatable {
	var id: UUID = UUID()
	var sets: UInt8 = 1
	var reps: UInt8 = 1
	var firstValue: Double = 0.0
	var secondValue: Double = 0.0
	var firstUnits: IntervalUnit = INTERVAL_UNIT_NOT_SET  // Units for the first part of the description (ex: X secs at Y pace)
	var secondUnits: IntervalUnit = INTERVAL_UNIT_NOT_SET // Units for the first second of the description (ex: X secs at Y pace)

	/// Constructor
	init() {
	}
	init(json: Decodable) {
	}
	init(backendStruct: IntervalSessionSegment) {
		self.sets = backendStruct.sets
		self.reps = backendStruct.reps
		self.firstValue = backendStruct.firstValue
		self.secondValue = backendStruct.secondValue
		self.firstUnits = backendStruct.firstUnits
		self.secondUnits = backendStruct.secondUnits
	}
	
	/// Hashable overrides
	func hash(into hasher: inout Hasher) {
		hasher.combine(self.id)
	}
	
	/// Equatable overrides
	static func == (lhs: IntervalSegment, rhs: IntervalSegment) -> Bool {
		return lhs.id == rhs.id
	}
	
	func toBackendStruct() -> IntervalSessionSegment {
		var result: IntervalSessionSegment = IntervalSessionSegment()
		result.sets = self.sets
		result.reps = self.reps
		result.firstValue = self.firstValue
		result.secondValue = self.secondValue
		result.firstUnits = self.firstUnits
		result.secondUnits = self.secondUnits
		result.position = 0
		return result
	}
	
	func validModifiers(activityType: String) -> Array<String> {
		var modifiers: Array<String> = []

		switch self.firstUnits {
		case INTERVAL_UNIT_NOT_SET:
			modifiers.append(MODIFIER_EDIT_SETS)
			modifiers.append(MODIFIER_EDIT_REPS)
			modifiers.append(MODIFIER_ADD_DURATION)
			modifiers.append(MODIFIER_ADD_DISTANCE_METERS)
			modifiers.append(MODIFIER_ADD_DISTANCE_KILOMETERS)
			modifiers.append(MODIFIER_ADD_DISTANCE_FEET)
			modifiers.append(MODIFIER_ADD_DISTANCE_YARDS)
			modifiers.append(MODIFIER_ADD_DISTANCE_MILES)
			break
		case INTERVAL_UNIT_SETS:
			modifiers.append(MODIFIER_EDIT_SETS)
			modifiers.append(MODIFIER_EDIT_REPS)
			break;
		case INTERVAL_UNIT_REPS:
			modifiers.append(MODIFIER_EDIT_SETS)
			modifiers.append(MODIFIER_EDIT_REPS)
			break
		case INTERVAL_UNIT_SECONDS:
			modifiers.append(MODIFIER_EDIT_DURATION)
			if self.secondUnits == INTERVAL_UNIT_NOT_SET {
				modifiers.append(MODIFIER_ADD_PACE_US_CUSTOMARY)
				modifiers.append(MODIFIER_ADD_PACE_METRIC)
				modifiers.append(MODIFIER_ADD_SPEED_US_CUSTOMARY)
				modifiers.append(MODIFIER_ADD_SPEED_METRIC)
				modifiers.append(MODIFIER_ADD_POWER)
			}
			break
		case INTERVAL_UNIT_METERS:
			modifiers.append(MODIFIER_EDIT_DISTANCE_METERS)
			if self.secondUnits == INTERVAL_UNIT_NOT_SET {
				modifiers.append(MODIFIER_ADD_PACE_US_CUSTOMARY)
				modifiers.append(MODIFIER_ADD_PACE_METRIC)
				modifiers.append(MODIFIER_ADD_SPEED_US_CUSTOMARY)
				modifiers.append(MODIFIER_ADD_SPEED_METRIC)
				modifiers.append(MODIFIER_ADD_POWER)
			}
			break
		case INTERVAL_UNIT_KILOMETERS:
			modifiers.append(MODIFIER_EDIT_DISTANCE_KILOMETERS)
			if self.secondUnits == INTERVAL_UNIT_NOT_SET {
				modifiers.append(MODIFIER_ADD_PACE_US_CUSTOMARY)
				modifiers.append(MODIFIER_ADD_PACE_METRIC)
				modifiers.append(MODIFIER_ADD_SPEED_US_CUSTOMARY)
				modifiers.append(MODIFIER_ADD_SPEED_METRIC)
				modifiers.append(MODIFIER_ADD_POWER)
			}
			break
		case INTERVAL_UNIT_FEET:
			modifiers.append(MODIFIER_EDIT_DISTANCE_FEET)
			if self.secondUnits == INTERVAL_UNIT_NOT_SET {
				modifiers.append(MODIFIER_ADD_PACE_US_CUSTOMARY)
				modifiers.append(MODIFIER_ADD_PACE_METRIC)
				modifiers.append(MODIFIER_ADD_SPEED_US_CUSTOMARY)
				modifiers.append(MODIFIER_ADD_SPEED_METRIC)
				modifiers.append(MODIFIER_ADD_POWER)
			}
			break
		case INTERVAL_UNIT_YARDS:
			modifiers.append(MODIFIER_EDIT_DISTANCE_YARDS)
			if self.secondUnits == INTERVAL_UNIT_NOT_SET {
				modifiers.append(MODIFIER_ADD_PACE_US_CUSTOMARY)
				modifiers.append(MODIFIER_ADD_PACE_METRIC)
				modifiers.append(MODIFIER_ADD_SPEED_US_CUSTOMARY)
				modifiers.append(MODIFIER_ADD_SPEED_METRIC)
				modifiers.append(MODIFIER_ADD_POWER)
			}
			break
		case INTERVAL_UNIT_MILES:
			modifiers.append(MODIFIER_EDIT_DISTANCE_MILES)
			if self.secondUnits == INTERVAL_UNIT_NOT_SET {
				modifiers.append(MODIFIER_ADD_PACE_US_CUSTOMARY)
				modifiers.append(MODIFIER_ADD_PACE_METRIC)
				modifiers.append(MODIFIER_ADD_SPEED_US_CUSTOMARY)
				modifiers.append(MODIFIER_ADD_SPEED_METRIC)
				modifiers.append(MODIFIER_ADD_POWER)
			}
			break
		case INTERVAL_UNIT_PACE_US_CUSTOMARY:
			modifiers.append(MODIFIER_EDIT_PACE_US_CUSTOMARY)
			break
		case INTERVAL_UNIT_PACE_METRIC:
			modifiers.append(MODIFIER_EDIT_PACE_METRIC)
			break
		case INTERVAL_UNIT_SPEED_US_CUSTOMARY:
			modifiers.append(MODIFIER_EDIT_SPEED_US_CUSTOMARY)
			break
		case INTERVAL_UNIT_SPEED_METRIC:
			modifiers.append(MODIFIER_EDIT_SPEED_METRIC)
			break
		case INTERVAL_UNIT_WATTS:
			modifiers.append(MODIFIER_EDIT_POWER)
			break
		default:
			break
		}
		return modifiers
	}
	
	private func isDistanceUnit(unit: IntervalUnit) -> Bool {
		switch unit {
		case INTERVAL_UNIT_METERS:
			return true
		case INTERVAL_UNIT_KILOMETERS:
			return true
		case INTERVAL_UNIT_FEET:
			return true
		case INTERVAL_UNIT_YARDS:
			return true
		case INTERVAL_UNIT_MILES:
			return true
		default:
			return false
		}
	}
	
	private func isPaceOrSpeedUnit(unit: IntervalUnit) -> Bool {
		switch unit {
		case INTERVAL_UNIT_PACE_METRIC:
			return true
		case INTERVAL_UNIT_PACE_US_CUSTOMARY:
			return true
		case INTERVAL_UNIT_SPEED_METRIC:
			return true
		case INTERVAL_UNIT_SPEED_US_CUSTOMARY:
			return true
		default:
			return false
		}
	}
	
	func applyModifier(key: String, value: Double) {

		if key.contains(MODIFIER_ADD_SETS) || key.contains(MODIFIER_EDIT_SETS) {
			self.sets = UInt8(value)
		}
		if key.contains(MODIFIER_ADD_REPS) || key.contains(MODIFIER_EDIT_REPS) {
			self.reps = UInt8(value)
		}

		else if key.contains(MODIFIER_ADD_DURATION) {
			self.firstValue = value
			self.firstUnits = INTERVAL_UNIT_SECONDS
		}
		else if key.contains(MODIFIER_ADD_DISTANCE_METERS) {
			if self.isPaceOrSpeedUnit(unit: self.firstUnits) {
				self.secondValue = self.firstValue
				self.secondUnits = self.firstUnits
			}
			self.firstValue = value
			self.firstUnits = INTERVAL_UNIT_METERS
		}
		else if key.contains(MODIFIER_ADD_DISTANCE_KILOMETERS) {
			if self.isPaceOrSpeedUnit(unit: self.firstUnits) {
				self.secondValue = self.firstValue
				self.secondUnits = self.firstUnits
			}
			self.firstValue = value
			self.firstUnits = INTERVAL_UNIT_KILOMETERS
		}
		else if key.contains(MODIFIER_ADD_DISTANCE_FEET) {
			if self.isPaceOrSpeedUnit(unit: self.firstUnits) {
				self.secondValue = self.firstValue
				self.secondUnits = self.firstUnits
			}
			self.firstValue = value
			self.firstUnits = INTERVAL_UNIT_FEET
		}
		else if key.contains(MODIFIER_ADD_DISTANCE_YARDS) {
			if self.isPaceOrSpeedUnit(unit: self.firstUnits) {
				self.secondValue = self.firstValue
				self.secondUnits = self.firstUnits
			}
			self.firstValue = value
			self.firstUnits = INTERVAL_UNIT_YARDS
		}
		else if key.contains(MODIFIER_ADD_DISTANCE_MILES) {
			if self.isPaceOrSpeedUnit(unit: self.firstUnits) {
				self.secondValue = self.firstValue
				self.secondUnits = self.firstUnits
			}
			self.firstValue = value
			self.firstUnits = INTERVAL_UNIT_MILES
		}
		else if key.contains(MODIFIER_ADD_PACE_US_CUSTOMARY) {
			if self.isDistanceUnit(unit: self.firstUnits) || self.firstUnits == INTERVAL_UNIT_SECONDS {
				self.secondValue = value
				self.secondUnits = INTERVAL_UNIT_PACE_US_CUSTOMARY
			}
			else {
				self.firstValue = value
				self.firstUnits = INTERVAL_UNIT_PACE_US_CUSTOMARY
			}
		}
		else if key.contains(MODIFIER_ADD_PACE_METRIC) {
			if self.isDistanceUnit(unit: self.firstUnits) || self.firstUnits == INTERVAL_UNIT_SECONDS {
				self.secondValue = value
				self.secondUnits = INTERVAL_UNIT_PACE_METRIC
			}
			else {
				self.firstValue = value
				self.firstUnits = INTERVAL_UNIT_PACE_METRIC
			}
		}
		else if key.contains(MODIFIER_ADD_SPEED_US_CUSTOMARY) {
			if self.isDistanceUnit(unit: self.firstUnits) || self.firstUnits == INTERVAL_UNIT_SECONDS {
				self.secondValue = value
				self.secondUnits = INTERVAL_UNIT_SPEED_US_CUSTOMARY
			}
			else {
				self.firstValue = value
				self.firstUnits = INTERVAL_UNIT_SPEED_US_CUSTOMARY
			}
		}
		else if key.contains(MODIFIER_ADD_SPEED_METRIC) {
			if self.isDistanceUnit(unit: self.firstUnits) || self.firstUnits == INTERVAL_UNIT_SECONDS {
				self.secondValue = value
				self.secondUnits = INTERVAL_UNIT_PACE_METRIC
			}
			else {
				self.firstValue = value
				self.firstUnits = INTERVAL_UNIT_PACE_METRIC
			}
		}
		else if key.contains(MODIFIER_ADD_POWER) {
			if self.isDistanceUnit(unit: self.firstUnits) || self.firstUnits == INTERVAL_UNIT_SECONDS {
				self.secondValue = value
				self.secondUnits = INTERVAL_UNIT_WATTS
			}
			else {
				self.firstValue = value
				self.firstUnits = INTERVAL_UNIT_WATTS
			}
		}

		else if key.contains(MODIFIER_EDIT_DURATION) {
			if self.firstUnits == INTERVAL_UNIT_SECONDS {
				self.firstValue = value
			}
			else {
				self.secondValue = value
			}
		}
		else if key.contains(MODIFIER_EDIT_DISTANCE_METERS) {
			if self.firstUnits == INTERVAL_UNIT_METERS {
				self.firstValue = value
			}
			else {
				self.secondValue = value
			}
		}
		else if key.contains(MODIFIER_EDIT_DISTANCE_KILOMETERS) {
			if self.firstUnits == INTERVAL_UNIT_KILOMETERS {
				self.firstValue = value
			}
			else {
				self.secondValue = value
			}
		}
		else if key.contains(MODIFIER_EDIT_DISTANCE_FEET) {
			if self.firstUnits == INTERVAL_UNIT_FEET {
				self.firstValue = value
			}
			else {
				self.secondValue = value
			}
		}
		else if key.contains(MODIFIER_EDIT_DISTANCE_YARDS) {
			if self.firstUnits == INTERVAL_UNIT_YARDS {
				self.firstValue = value
			}
			else {
				self.secondValue = value
			}
		}
		else if key.contains(MODIFIER_EDIT_DISTANCE_MILES) {
			if self.firstUnits == INTERVAL_UNIT_MILES {
				self.firstValue = value
			}
			else {
				self.secondValue = value
			}
		}
	}

	private func unitsStr(units: IntervalUnit) -> String {
		switch units {
		case INTERVAL_UNIT_NOT_SET:
			return ""
		case INTERVAL_UNIT_SETS:
			return "sets"
		case INTERVAL_UNIT_REPS:
			return "repetitions"
		case INTERVAL_UNIT_SECONDS:
			return "seconds"
		case INTERVAL_UNIT_METERS:
			return "meters"
		case INTERVAL_UNIT_KILOMETERS:
			return "kms"
		case INTERVAL_UNIT_FEET:
			return "feet"
		case INTERVAL_UNIT_YARDS:
			return "yards"
		case INTERVAL_UNIT_MILES:
			return "miles"
		case INTERVAL_UNIT_PACE_US_CUSTOMARY:
			return "min/mile"
		case INTERVAL_UNIT_PACE_METRIC:
			return "km/mile"
		case INTERVAL_UNIT_SPEED_US_CUSTOMARY:
			return "mph"
		case INTERVAL_UNIT_SPEED_METRIC:
			return "kph"
		case INTERVAL_UNIT_WATTS:
			return "watts"
		default:
			break
		}
		return ""
	}

	private func formatDescriptionFragment(value: Double, units: IntervalUnit) -> String {
		return String(format: "%0.1lf %@", value, self.unitsStr(units: units))
	}

	func intervalDescription() -> String {
		var description: String = ""
		
		if self.firstUnits == INTERVAL_UNIT_NOT_SET {
			if self.sets == 1 && self.reps == 1 {
				description = "1 set of 1 rep"
			}
			else {
				if self.sets > 1 {
					description = String(self.sets) + " sets of "
				}
				if self.reps > 1 {
					description += String(self.reps) + " reps "
				}
			}
		}
		else {
			if self.reps > 1 {
				description += String(self.reps) + " reps of "
			}
			
			description += self.formatDescriptionFragment(value: self.firstValue, units: self.firstUnits)
			
			if self.secondUnits != INTERVAL_UNIT_NOT_SET {
				if  self.secondUnits == INTERVAL_UNIT_PACE_US_CUSTOMARY ||
					self.secondUnits == INTERVAL_UNIT_PACE_METRIC ||
					self.secondUnits == INTERVAL_UNIT_SPEED_US_CUSTOMARY ||
					self.secondUnits == INTERVAL_UNIT_SPEED_METRIC ||
					self.secondUnits == INTERVAL_UNIT_WATTS {
					description += " at "
				}
				else if self.secondUnits == INTERVAL_UNIT_REPS {
					description += " of "
				}
				description += self.formatDescriptionFragment(value: self.secondValue, units: self.secondUnits)
			}
		}
		return description
	}
	
	func intervalProgressDescription() -> String {
		return ""
	}

	func color() -> Color {
		switch self.firstUnits {
		case INTERVAL_UNIT_NOT_SET:
			break
		case INTERVAL_UNIT_SECONDS:
			return .red
		case INTERVAL_UNIT_SETS:
			return .white
		case INTERVAL_UNIT_REPS:
			return .white
		case INTERVAL_UNIT_METERS:
			return .blue
		case INTERVAL_UNIT_KILOMETERS:
			return .blue
		case INTERVAL_UNIT_FEET:
			return .blue
		case INTERVAL_UNIT_YARDS:
			return .blue
		case INTERVAL_UNIT_MILES:
			return .blue
		case INTERVAL_UNIT_PACE_US_CUSTOMARY:
			return .green
		case INTERVAL_UNIT_PACE_METRIC:
			return .green
		case INTERVAL_UNIT_SPEED_US_CUSTOMARY:
			return .cyan
		case INTERVAL_UNIT_SPEED_METRIC:
			return .cyan
		case INTERVAL_UNIT_WATTS:
			return .blue
		default:
			break
		}
		return .white
	}
}

class IntervalSession : Identifiable, Hashable, Equatable {
	var id: UUID = UUID()
	var name: String = "Untitled"
	var sport: String = ACTIVITY_TYPE_RUNNING
	var description: String = ""
	var segments: Array<IntervalSegment> = []
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
	static func == (lhs: IntervalSession, rhs: IntervalSession) -> Bool {
		return lhs.id == rhs.id
	}
}

class IntervalSessionsVM : ObservableObject {
	static let shared = IntervalSessionsVM()
	@Published var intervalSessions: Array<IntervalSession> = []
	
	/// Singleton Constructor
	private init() {
		let _ = buildIntervalSessionList()
	}

	func buildIntervalSessionList() -> Bool {
		var result = false
		
		// Remove any old ones.
		self.intervalSessions = []
		
		// Query the backend for the latest interval sessions.
		if InitializeIntervalSessionList() {
			
			var sessionIndex = 0
			var done = false
			
			while !done {
				if let rawSessionDescPtr = RetrieveIntervalSessionAsJSON(sessionIndex) {
					let summaryObj = IntervalSession()
					let sessionDescPtr = UnsafeRawPointer(rawSessionDescPtr)
					
					let sessionDesc = String(cString: sessionDescPtr.assumingMemoryBound(to: CChar.self))
					let summaryDict = try! JSONSerialization.jsonObject(with: Data(sessionDesc.utf8), options: []) as! [String:Any]
					
					if let sessionId = summaryDict[PARAM_INTERVAL_ID] as? String {
						summaryObj.id = UUID(uuidString: sessionId)!
					}
					if let sessionName = summaryDict[PARAM_INTERVAL_NAME] as? String {
						summaryObj.name = sessionName
					}
					if let sessionDescription = summaryDict[PARAM_INTERVAL_DESCRIPTION] as? String {
						summaryObj.description = sessionDescription
					}
					if let sessionSegments = summaryDict[PARAM_INTERVAL_SEGMENTS] as? Array<Dictionary<String, Any>> {
						for sessionSegment in sessionSegments {
							if let sets = sessionSegment[PARAM_INTERVAL_SEGMENT_NUM_SETS] as? UInt8,
							   let reps = sessionSegment[PARAM_INTERVAL_SEGMENT_NUM_REPS] as? UInt8,
							   let firstValue = sessionSegment[PARAM_INTERVAL_SEGMENT_FIRST_VALUE] as? Double,
							   let firstUnits = sessionSegment[PARAM_INTERVAL_SEGMENT_FIRST_UNITS] as? UInt32,
							   let secondValue = sessionSegment[PARAM_INTERVAL_SEGMENT_SECOND_VALUE] as? Double,
							   let secondUnits = sessionSegment[PARAM_INTERVAL_SEGMENT_SECOND_UNITS] as? UInt32 {

								let segmentObj = IntervalSegment()
								segmentObj.sets = sets
								segmentObj.reps = reps
								segmentObj.firstValue = firstValue
								segmentObj.firstUnits = IntervalUnit(firstUnits)
								segmentObj.secondValue = secondValue
								segmentObj.secondUnits = IntervalUnit(secondUnits)

								summaryObj.segments.append(segmentObj)
							}
						}
					}

					defer {
						sessionDescPtr.deallocate()
					}
					
					self.intervalSessions.append(summaryObj)
					sessionIndex += 1
				}
				else {
					done = true
				}
			}
			
			result = true
		}
		
		return result
	}

	func updateIntervalSessionFromDict(dict: Dictionary<String, Any>) {
	}

	func createIntervalSession(session: IntervalSession) -> Bool {
		if CreateNewIntervalSession(session.id.uuidString, session.name, session.sport, session.description) {
			
			if InitializeIntervalSessionList() {
				
				var position: UInt8 = 0
				
				for segment in session.segments {
					var tempSegment = segment.toBackendStruct()
					
					tempSegment.position = position
					position += 1
					
					if !CreateNewIntervalSessionSegment(session.id.uuidString, tempSegment) {
						return false
					}
				}
				return buildIntervalSessionList()
			}
		}
		return false
	}
	
	func doesIntervalSessionExistInDatabase(sessionId: UUID) -> Bool {
		for existingSession in self.intervalSessions {
			if existingSession.id == sessionId {
				return true
			}
		}
		return false
	}
	
	func updateIntervalSession(session: IntervalSession) -> Bool {
		if self.deleteIntervalSession(intervalSessionId: session.id) {
			return self.createIntervalSession(session: session)
		}
		return false
	}
	
	func deleteIntervalSession(intervalSessionId: UUID) -> Bool {
		if DeleteIntervalSession(intervalSessionId.uuidString) {
			return buildIntervalSessionList()
		}
		return false
	}
	
	func moveSegmentUp(session: IntervalSession, segmentId: UUID) -> Bool {
		var position = 0

		for segment in session.segments {
			if segment.id == segmentId {
				if position > 0 {
					session.segments.swapAt(position, position - 1)
					break
				}
				return false
			}
			position += 1
		}
		if self.doesIntervalSessionExistInDatabase(sessionId: session.id) {
			return updateIntervalSession(session: session)
		}
		return true
	}
	
	func moveSegmentDown(session: IntervalSession, segmentId: UUID) -> Bool  {
		var position = 0

		for segment in session.segments {
			if segment.id == segmentId {
				if position < (session.segments.count - 1) {
					session.segments.swapAt(position, position + 1)
					break
				}
				return false
			}
			position += 1
		}
		if self.doesIntervalSessionExistInDatabase(sessionId: session.id) {
			return updateIntervalSession(session: session)
		}
		return true
	}
	
	func deleteSegment(session: IntervalSession, segmentId: UUID) -> Bool  {
		var position = 0

		for segment in session.segments {
			if segment.id == segmentId {
				session.segments.remove(at: position)
			}
			position += 1
		}
		if self.doesIntervalSessionExistInDatabase(sessionId: session.id) {
			return updateIntervalSession(session: session)
		}
		return true
	}
}
