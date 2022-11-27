//
//  WorkoutsVM.swift
//  Created by Michael Simms on 9/29/22.
//

import Foundation

let STR_FITNESS =                      "Fitness"
let STR_5K_RUN =                       "5K Run"
let STR_10K_RUN =                      "10K Run"
let STR_15K_RUN =                      "15K Run"
let STR_HALF_MARATHON_RUN =            "Half Marathon"
let STR_MARATHON_RUN =                 "Marathon"
let STR_50K_RUN =                      "50K Run"
let STR_50_MILE_RUN =                  "50 Mile Run"
let STR_SPRINT_TRIATHLON =             "Sprint Triathlon"
let STR_OLYMPIC_TRIATHLON =            "Olympic Triathlon"
let STR_HALF_IRON_DISTANCE_TRIATHLON = "Half Iron Distance Triathlon"
let STR_IRON_DISTANCE_TRIATHLON =      "Iron Distance Triathlon"

let STR_COMPLETION =                   "Completion"
let STR_SPEED =                        "Speed"

let STR_MONDAY =                       "Monday"
let STR_TUESDAY =                      "Tuesday"
let STR_WEDNESDAY =                    "Wednesday"
let STR_THURSDAY =                     "Thursday"
let STR_FRIDAY =                       "Friday"
let STR_SATURDAY =                     "Saturday"
let STR_SUNDAY =                       "Sunday"

class WorkoutSummary : Identifiable, Hashable, Equatable {
	var id: String = ""
	var sportType: String = ""
	var workoutType: String = ""
	var numIntervals: UInt = 0
	var duration: Double = 0.0
	var distance: Double = 0.0
	var scheduledTime: Date = Date()
	
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
	static func == (lhs: WorkoutSummary, rhs: WorkoutSummary) -> Bool {
		return lhs.id == rhs.id
	}
}

class WorkoutsVM : ObservableObject {
	@Published var workouts: Array<WorkoutSummary> = []
	
	/// Constructor
	init() {
		let _ = buildWorkoutsList()
	}
	
	func buildWorkoutsList() -> Bool {
		var result = false

		// Remove the old workout descriptions.
		self.workouts = []

		// Query the backend for the latest workouts.
		if InitializeWorkoutList() {
			
			var workoutIndex = 0
			var done = false
			
			while !done {
				if let workoutJsonStrPtr = UnsafeRawPointer(RetrieveWorkoutAsJSON(workoutIndex)) {
					let summaryObj = WorkoutSummary()

					let workoutJsonStr = String(cString: workoutJsonStrPtr.assumingMemoryBound(to: CChar.self))
					let summaryDict = try! JSONSerialization.jsonObject(with: Data(workoutJsonStr.utf8), options: []) as! [String:Any]

					if let workoutId = summaryDict[PARAM_WORKOUT_ID] as? String {
						summaryObj.id = workoutId
					}
					if let sportType = summaryDict[PARAM_WORKOUT_SPORT_TYPE] as? String {
						summaryObj.sportType = sportType
					}
					if let duration = summaryDict[PARAM_WORKOUT_DURATION] as? Double {
						summaryObj.duration = duration
					}
					if let distance = summaryDict[PARAM_WORKOUT_DISTANCE] as? Double {
						summaryObj.distance = distance
					}
					if let scheduledTime = summaryDict[PARAM_WORKOUT_SCHEDULED_TIME] as? UInt {
						summaryObj.scheduledTime = Date(timeIntervalSince1970: TimeInterval(scheduledTime))
					}

					defer {
						workoutJsonStrPtr.deallocate()
					}

					self.workouts.append(summaryObj)
					workoutIndex += 1
				}
				else {
					done = true
				}
			}
			
			result = true
		}

		return result
	}
	
	func updateWorkoutFromDict(dict: Dictionary<String, Any>) {
	}

	func generateWorkouts() -> Bool {
		var result = false

		if GenerateWorkouts(Preferences.workoutGoal(),
							Preferences.workoutGoalType(),
							Preferences.workoutGoalDate(),
							Preferences.workoutLongRunDay(),
							Preferences.workoutsCanIncludePoolSwims(),
							Preferences.workoutsCanIncludeOpenWaterSwims(),
							Preferences.workoutsCanIncludeBikeRides()) {
			result = buildWorkoutsList()
		}
		return result
	}
	
	static func workoutGoalToString(goal: Goal) -> String {
		switch goal {
		case GOAL_FITNESS:
			return STR_FITNESS
		case GOAL_5K_RUN:
			return STR_5K_RUN
		case GOAL_10K_RUN:
			return STR_10K_RUN
		case GOAL_15K_RUN:
			return STR_15K_RUN
		case GOAL_HALF_MARATHON_RUN:
			return STR_HALF_MARATHON_RUN
		case GOAL_MARATHON_RUN:
			return STR_MARATHON_RUN
		case GOAL_50K_RUN:
			return STR_50K_RUN
		case GOAL_50_MILE_RUN:
			return STR_50_MILE_RUN
		case GOAL_SPRINT_TRIATHLON:
			return STR_SPRINT_TRIATHLON
		case GOAL_OLYMPIC_TRIATHLON:
			return STR_OLYMPIC_TRIATHLON
		case GOAL_HALF_IRON_DISTANCE_TRIATHLON:
			return STR_HALF_IRON_DISTANCE_TRIATHLON
		case GOAL_IRON_DISTANCE_TRIATHLON:
			return STR_IRON_DISTANCE_TRIATHLON
		default:
			break
		}
		return STR_FITNESS
	}
	
	static func workoutStringToGoal(goalStr: String) -> Goal {
		if goalStr == STR_FITNESS {
			return GOAL_FITNESS
		}
		if goalStr == STR_5K_RUN {
			return GOAL_5K_RUN
		}
		if goalStr == STR_10K_RUN {
			return GOAL_10K_RUN
		}
		if goalStr == STR_15K_RUN {
			return GOAL_15K_RUN
		}
		if goalStr == STR_HALF_MARATHON_RUN {
			return GOAL_HALF_MARATHON_RUN
		}
		if goalStr == STR_MARATHON_RUN {
			return GOAL_MARATHON_RUN
		}
		if goalStr == STR_50K_RUN {
			return GOAL_50K_RUN
		}
		if goalStr == STR_50_MILE_RUN {
			return GOAL_50_MILE_RUN
		}
		if goalStr == STR_SPRINT_TRIATHLON {
			return GOAL_SPRINT_TRIATHLON
		}
		if goalStr == STR_OLYMPIC_TRIATHLON {
			return GOAL_OLYMPIC_TRIATHLON
		}
		if goalStr == STR_HALF_IRON_DISTANCE_TRIATHLON {
			return GOAL_HALF_IRON_DISTANCE_TRIATHLON
		}
		if goalStr == STR_IRON_DISTANCE_TRIATHLON {
			return GOAL_IRON_DISTANCE_TRIATHLON
		}
		return GOAL_FITNESS
	}
	
	static func workoutGoalTypeToString(goalType: GoalType) -> String {
		switch goalType {
		case GOAL_TYPE_SPEED:
			return STR_SPEED
		case GOAL_TYPE_COMPLETION:
			return STR_COMPLETION
		default:
			break
		}
		return STR_COMPLETION
	}
	
	static func workoutStringToGoalType(goalStr: String) -> GoalType {
		if goalStr == STR_SPEED {
			return GOAL_TYPE_SPEED
		}
		if goalStr == STR_COMPLETION {
			return GOAL_TYPE_COMPLETION
		}
		return GOAL_TYPE_COMPLETION
	}
	
	static func dayTypeToString(day: DayType) -> String {
		switch day {
		case DAY_TYPE_MONDAY:
			return STR_MONDAY
		case DAY_TYPE_TUESDAY:
			return STR_TUESDAY
		case DAY_TYPE_WEDNESDAY:
			return STR_WEDNESDAY
		case DAY_TYPE_THURSDAY:
			return STR_THURSDAY
		case DAY_TYPE_FRIDAY:
			return STR_FRIDAY
		case DAY_TYPE_SATURDAY:
			return STR_SATURDAY
		case DAY_TYPE_SUNDAY:
			return STR_SUNDAY
		default:
			break
		}
		return STR_SUNDAY
	}
	
	static func dayStringToType(dayStr: String) -> DayType {
		if dayStr == STR_MONDAY {
			return DAY_TYPE_MONDAY
		}
		if dayStr == STR_TUESDAY {
			return DAY_TYPE_TUESDAY
		}
		if dayStr == STR_WEDNESDAY {
			return DAY_TYPE_WEDNESDAY
		}
		if dayStr == STR_THURSDAY {
			return DAY_TYPE_THURSDAY
		}
		if dayStr == STR_FRIDAY {
			return DAY_TYPE_FRIDAY
		}
		if dayStr == STR_SATURDAY {
			return DAY_TYPE_SATURDAY
		}
		if dayStr == STR_SUNDAY {
			return DAY_TYPE_SUNDAY
		}
		return DAY_TYPE_SUNDAY
	}
}
