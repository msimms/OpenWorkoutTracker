//
//  IntervalSessionsVM.swift
//  Created by Michael Simms on 9/29/22.
//

import Foundation
import SwiftUI

class IntervalSegment : Identifiable, Hashable, Equatable {
	var id: UUID = UUID()
	var sets: UInt = 0         // Number of sets
	var reps: UInt = 0         // Number of repititions
	var duration: UInt = 0     // Duration, if applicable, in seconds
	var distance: Double = 0.0
	var pace: Double = 0.0
	var power: Double = 0.0
	var units: IntervalUnit = INTERVAL_UNIT_NOT_SET
	
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
	static func == (lhs: IntervalSegment, rhs: IntervalSegment) -> Bool {
		return lhs.id == rhs.id
	}
	
	func description() -> String {
		var description: String = ""

		switch self.units {
		case INTERVAL_UNIT_NOT_SET:
			description = String(format: "%u sets of %u reps", self.sets, self.reps)
			break
		case INTERVAL_UNIT_SECONDS:
			description = String(format: "%u seconds", self.duration)
			break
		case INTERVAL_UNIT_METERS:
			description = String(format: "%d meters", self.distance)
			break
		case INTERVAL_UNIT_KILOMETERS:
			description = String(format: "%d kilometers", self.distance)
			break
		case INTERVAL_UNIT_FEET:
			description = String(format: "%d feet", self.distance)
			break
		case INTERVAL_UNIT_YARDS:
			description = String(format: "%d yards", self.distance)
			break
		case INTERVAL_UNIT_MILES:
			description = String(format: "%d miles", self.distance)
			break
		case INTERVAL_UNIT_PACE_US_CUSTOMARY:
			description = " min/mile"
			break
		case INTERVAL_UNIT_PACE_METRIC:
			description = " km/mile"
			break
		case INTERVAL_UNIT_SPEED_US_CUSTOMARY:
			description = " mph"
			break
		case INTERVAL_UNIT_SPEED_METRIC:
			description = " kph"
			break
		case INTERVAL_UNIT_TIME_AND_POWER:
			description = String(format: "%.1f watts for %u seconds", self.power, self.duration)
			break
		default:
			break
		}
		return description
	}
	
	func color() -> Color {
		switch self.units {
		case INTERVAL_UNIT_NOT_SET:
			break
		case INTERVAL_UNIT_SECONDS:
			return .red
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
		case INTERVAL_UNIT_TIME_AND_POWER:
			return .blue
		default:
			break
		}
		return .white
	}
}

class IntervalSession : Identifiable, Hashable, Equatable {
	var id: UUID = UUID()
	var name: String = ""
	var sport: String = ""
	var segments: Array<IntervalSegment> = []

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
	@Published var intervalSessions: Array<IntervalSession> = []
	@Published var newSession: Array<IntervalSegment> = []

	/// Constructor
	init() {
		buildIntervalSessionList()
	}

	func buildIntervalSessionList() {
		if InitializeIntervalWorkoutList() {
			var workoutIndex = 0
			var done = false
			
			while !done {
				let workoutDesc = RetrieveIntervalWorkoutAsJSON(workoutIndex)
				
				if workoutDesc == nil {
					done = true
				}
				else {
					let ptr = UnsafeRawPointer(workoutDesc)
					let tempWorkoutDesc = String(cString: ptr!.assumingMemoryBound(to: CChar.self))
					
					defer {
						ptr!.deallocate()
					}

					workoutIndex += 1
				}
			}
		}
	}
	
	func createIntervalSession() -> Bool {
		return false
	}
	
	func deleteIntervalSession(intervalSessionId: String) -> Bool {
		return DeleteIntervalWorkout(intervalSessionId)
	}
}
