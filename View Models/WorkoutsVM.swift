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

enum WorkoutException : Error {
	case runtimeError(String)
}

class WorkoutSummary : Identifiable, Hashable, Equatable {
	var id: String = ""
	var sportType: String = ""
	var workoutType: String = ""
	var description: String = ""
	var duration: Double = 0.0
	var distance: Double = 0.0
	var scheduledTime: Date = Date()
	var intervals: Array<Dictionary<String, Any>> = []
	
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
	var inputs: Dictionary<String, Any> = [:]

	/// Constructor
	init() {
		self.buildWorkoutsList()
	}
	
	func buildWorkoutsList() {
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
					if let workoutType = summaryDict[PARAM_WORKOUT_WORKOUT_TYPE] as? UInt32 {
						let workoutTypeEnum = WorkoutType(rawValue: workoutType)
						summaryObj.workoutType = WorkoutsVM.workoutTypeEnumToString(typeEnum: workoutTypeEnum)
						summaryObj.description = WorkoutsVM.workoutDescription(typeEnum: workoutTypeEnum)
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
					if let intervals = summaryDict[PARAM_WORKOUT_INTERVALS] as? Array<Dictionary<String, Any>> {
						summaryObj.intervals = intervals
					}

					self.workouts.append(summaryObj)
					workoutIndex += 1

					workoutJsonStrPtr.deallocate()
				}
				else {
					done = true
				}
			}
		}
	}

	func sendPlannedWorkoutsToServer() {
		if InitializeWorkoutList() {
			var workoutListJsonStr: String = "["
			var workoutIndex = 0
			var done = false
			var first = true

			while !done {
				if let workoutJsonStrPtr = UnsafeRawPointer(RetrieveWorkoutAsJSON(workoutIndex)) {
					if !first {
						workoutListJsonStr += ","
					}
					let workoutJsonStr = String(cString: workoutJsonStrPtr.assumingMemoryBound(to: CChar.self))
					workoutListJsonStr += workoutJsonStr
					workoutIndex += 1
					workoutJsonStrPtr.deallocate()
					first = false
				}
				else {
					done = true
				}
			}

			workoutListJsonStr += "]"

			let _ = ApiClient.shared.sendPlannedWorkouts(workoutsJson: workoutListJsonStr)
		}
	}

	func importWorkoutFromDict(dict: Dictionary<String, Any>) throws {
		if  let workoutId = dict[PARAM_WORKOUT_ID] as? String,
			let workoutTypeStr = dict[PARAM_WORKOUT_WORKOUT_TYPE] as? String,
			let sportType = dict[PARAM_WORKOUT_SPORT_TYPE] as? String,
			let scheduledTime = dict[PARAM_WORKOUT_SCHEDULED_TIME] as? time_t {

			let estimatedIntensityScore = dict[PARAM_WORKOUT_ESTIMATED_INTENSITY] as? Double ?? 0.0
			let workoutType = try WorkoutsVM.workoutTypeStringToEnum(typeStr: workoutTypeStr)

			CreateWorkout(workoutId, workoutType, sportType, estimatedIntensityScore, scheduledTime)
		}
	}

	func deleteAllWorkouts() -> Bool {
		workouts.removeAll()
		return DeleteAllWorkouts()
	}

	func regenerateWorkouts() throws {
		// Add HealthKit activities as inputs to the workout generation algorithm.
		// We'll de-dupe the list to make sure we're not double-counting anything.
		let healthMgr = HealthManager.shared
		healthMgr.readAllActivitiesFromHealthStore()
		healthMgr.removeDuplicateActivities()
		if healthMgr.workouts.count > 0 {
			for i in 0...healthMgr.workouts.count - 1 {
				let activityId = healthMgr.convertIndexToActivityId(index: i)
				let activityType = healthMgr.getHistoricalActivityType(activityId: activityId)
				let currentWorkout = healthMgr.workouts[activityId]
				
				if currentWorkout != nil {
					let startTime: time_t = Int(currentWorkout!.startDate.timeIntervalSince1970)
					let endTime: time_t = Int(currentWorkout!.endDate.timeIntervalSince1970)
					
					let distanceAttr = healthMgr.getWorkoutAttribute(attributeName: ACTIVITY_ATTRIBUTE_DISTANCE_TRAVELED, activityId: activityId)
					let elapsedTimeAttr = healthMgr.getWorkoutAttribute(attributeName: ACTIVITY_ATTRIBUTE_ELAPSED_TIME, activityId: activityId)
					let movingTimeAttr = healthMgr.getWorkoutAttribute(attributeName: ACTIVITY_ATTRIBUTE_MOVING_TIME, activityId: activityId)
					let caloriesBurnedAttr = healthMgr.getWorkoutAttribute(attributeName: ACTIVITY_ATTRIBUTE_CALORIES_BURNED, activityId: activityId)
					
					InsertAdditionalAttributesForWorkoutGeneration(activityId, activityType, startTime, endTime, distanceAttr)
					InsertAdditionalAttributesForWorkoutGeneration(activityId, activityType, startTime, endTime, elapsedTimeAttr)
					InsertAdditionalAttributesForWorkoutGeneration(activityId, activityType, startTime, endTime, movingTimeAttr)
					InsertAdditionalAttributesForWorkoutGeneration(activityId, activityType, startTime, endTime, caloriesBurnedAttr)
				}
			}
		}

		// This will remove existing workouts and generate new ones.
		if let workoutGenResultsPtr = UnsafeRawPointer(GenerateWorkouts(Preferences.workoutGoal(),
																		Preferences.workoutGoalType(),
																		Preferences.workoutGoalDate(),
																		Preferences.workoutLongRunDay(),
																		Preferences.workoutsCanIncludePoolSwims(),
																		Preferences.workoutsCanIncludeOpenWaterSwims(),
																		Preferences.workoutsCanIncludeBikeRides())) {
			let resultsJsonStr = String(cString: workoutGenResultsPtr.assumingMemoryBound(to: CChar.self))
			if resultsJsonStr.count > 0 {
				do {
					self.inputs = try JSONSerialization.jsonObject(with: Data(resultsJsonStr.utf8), options: []) as! [String:Any]
					self.buildWorkoutsList()
					self.sendPlannedWorkoutsToServer()
				}
				catch {
					throw WorkoutException.runtimeError(resultsJsonStr)
				}
			}
			else {
				throw WorkoutException.runtimeError("Unspecified error when generating workouts.")
			}

			workoutGenResultsPtr.deallocate()
		}
		else {
			throw WorkoutException.runtimeError("Unspecified error when generating workouts.")
		}
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
	
	static func workoutTypeEnumToString(typeEnum: WorkoutType) -> String {
		switch typeEnum {
		case WORKOUT_TYPE_REST:
			return WORKOUT_TYPE_STR_REST
		case WORKOUT_TYPE_EVENT:
			return WORKOUT_TYPE_STR_EVENT
		case WORKOUT_TYPE_SPEED_RUN:
			return WORKOUT_TYPE_STR_SPEED_RUN
		case WORKOUT_TYPE_THRESHOLD_RUN:
			return WORKOUT_TYPE_STR_THRESHOLD_RUN
		case WORKOUT_TYPE_TEMPO_RUN:
			return WORKOUT_TYPE_STR_TEMPO_RUN
		case WORKOUT_TYPE_EASY_RUN:
			return WORKOUT_TYPE_STR_EASY_RUN
		case WORKOUT_TYPE_LONG_RUN:
			return WORKOUT_TYPE_STR_LONG_RUN
		case WORKOUT_TYPE_FREE_RUN:
			return WORKOUT_TYPE_STR_FREE_RUN
		case WORKOUT_TYPE_HILL_REPEATS:
			return WORKOUT_TYPE_STR_HILL_REPEATS
		case WORKOUT_TYPE_PROGRESSION_RUN:
			return WORKOUT_TYPE_STR_PROGRESSION_RUN
		case WORKOUT_TYPE_FARTLEK_RUN:
			return WORKOUT_TYPE_STR_FARTLEK_RUN
		case WORKOUT_TYPE_MIDDLE_DISTANCE_RUN:
			return WORKOUT_TYPE_STR_MIDDLE_DISTANCE_RUN
		case WORKOUT_TYPE_HILL_RIDE:
			return WORKOUT_TYPE_STR_HILL_RIDE
		case WORKOUT_TYPE_CADENCE_DRILLS:
			return WORKOUT_TYPE_STR_CADENCE_DRILLS
		case WORKOUT_TYPE_SPEED_INTERVAL_RIDE:
			return WORKOUT_TYPE_STR_SPEED_INTERVAL_RIDE
		case WORKOUT_TYPE_TEMPO_RIDE:
			return WORKOUT_TYPE_STR_TEMPO_RIDE
		case WORKOUT_TYPE_EASY_RIDE:
			return WORKOUT_TYPE_STR_EASY_RIDE
		case WORKOUT_TYPE_SWEET_SPOT_RIDE:
			return WORKOUT_TYPE_STR_SWEET_SPOT_RIDE
		case WORKOUT_TYPE_OPEN_WATER_SWIM:
			return WORKOUT_TYPE_STR_OPEN_WATER_SWIM
		case WORKOUT_TYPE_POOL_SWIM:
			return WORKOUT_TYPE_STR_POOL_SWIM
		case WORKOUT_TYPE_TECHNIQUE_SWIM:
			return WORKOUT_TYPE_STR_TECHNIQUE_SWIM
		default:
			return ""
		}
	}

	static func workoutTypeStringToEnum(typeStr: String) throws -> WorkoutType {
		if typeStr == WORKOUT_TYPE_STR_REST {
			return WORKOUT_TYPE_REST
		}
		if typeStr == WORKOUT_TYPE_STR_EVENT {
			return WORKOUT_TYPE_EVENT
		}
		if typeStr == WORKOUT_TYPE_STR_SPEED_RUN {
			return WORKOUT_TYPE_SPEED_RUN
		}
		if typeStr == WORKOUT_TYPE_STR_THRESHOLD_RUN {
			return WORKOUT_TYPE_THRESHOLD_RUN
		}
		if typeStr == WORKOUT_TYPE_STR_TEMPO_RUN {
			return WORKOUT_TYPE_TEMPO_RUN
		}
		if typeStr == WORKOUT_TYPE_STR_EASY_RUN {
			return WORKOUT_TYPE_EASY_RUN
		}
		if typeStr == WORKOUT_TYPE_STR_LONG_RUN {
			return WORKOUT_TYPE_LONG_RUN
		}
		if typeStr == WORKOUT_TYPE_STR_FREE_RUN {
			return WORKOUT_TYPE_FREE_RUN
		}
		if typeStr == WORKOUT_TYPE_STR_HILL_REPEATS {
			return WORKOUT_TYPE_HILL_REPEATS
		}
		if typeStr == WORKOUT_TYPE_STR_PROGRESSION_RUN {
			return WORKOUT_TYPE_PROGRESSION_RUN
		}
		if typeStr == WORKOUT_TYPE_STR_FARTLEK_RUN {
			return WORKOUT_TYPE_FARTLEK_RUN
		}
		if typeStr == WORKOUT_TYPE_STR_MIDDLE_DISTANCE_RUN {
			return WORKOUT_TYPE_MIDDLE_DISTANCE_RUN
		}
		if typeStr == WORKOUT_TYPE_STR_HILL_RIDE {
			return WORKOUT_TYPE_HILL_RIDE
		}
		if typeStr == WORKOUT_TYPE_STR_CADENCE_DRILLS {
			return WORKOUT_TYPE_CADENCE_DRILLS
		}
		if typeStr == WORKOUT_TYPE_STR_SPEED_INTERVAL_RIDE {
			return WORKOUT_TYPE_SPEED_INTERVAL_RIDE
		}
		if typeStr == WORKOUT_TYPE_STR_TEMPO_RIDE {
			return WORKOUT_TYPE_TEMPO_RIDE
		}
		if typeStr == WORKOUT_TYPE_STR_EASY_RIDE {
			return WORKOUT_TYPE_EASY_RIDE
		}
		if typeStr == WORKOUT_TYPE_STR_SWEET_SPOT_RIDE {
			return WORKOUT_TYPE_SWEET_SPOT_RIDE
		}
		if typeStr == WORKOUT_TYPE_STR_OPEN_WATER_SWIM {
			return WORKOUT_TYPE_OPEN_WATER_SWIM
		}
		if typeStr == WORKOUT_TYPE_STR_POOL_SWIM {
			return WORKOUT_TYPE_POOL_SWIM
		}
		if typeStr == WORKOUT_TYPE_STR_TECHNIQUE_SWIM {
			return WORKOUT_TYPE_TECHNIQUE_SWIM
		}
		throw WorkoutException.runtimeError("Invalid workout type string.")
	}
	
	static func workoutDescription(typeEnum: WorkoutType) -> String {
		switch typeEnum {
		case WORKOUT_TYPE_REST:
			return ""
		case WORKOUT_TYPE_EVENT:
			return "Goal Event!\n"
		case WORKOUT_TYPE_SPEED_RUN:
			return "Purpose: Speed sessions get you used to running at faster paces.\n"
		case WORKOUT_TYPE_THRESHOLD_RUN:
			return "Purpose: Tempo runs build a combination of speed and endurance. They should be performed at a pace you can hold for roughly one hour.\n"
		case WORKOUT_TYPE_TEMPO_RUN:
			return "Purpose: Tempo runs build a combination of speed and endurance. They should be performed at a pace slightly slower than your pace for a 5K race.\n"
		case WORKOUT_TYPE_EASY_RUN:
			return "Purpose: Easy runs build aerobic capacity while keeping the wear and tear on the body to a minimum. Pacing should be slow enough to stay at or near Heart Rate Zone 2, i.e. conversational pace.\n"
		case WORKOUT_TYPE_LONG_RUN:
			return "Purpose: Long runs build and develop endurance.\n"
		case WORKOUT_TYPE_FREE_RUN:
			return "Purpose: You should run this at a pace that feels comfortable for you.\n"
		case WORKOUT_TYPE_HILL_REPEATS:
			return "Purpose: Hill repeats build strength and improve speed.\n"
		case WORKOUT_TYPE_PROGRESSION_RUN:
			return "Purpose: Progression runs teach you to run fast on tired legs.\n"
		case WORKOUT_TYPE_FARTLEK_RUN:
			return "Purpose: Fartlek sessions combine speed and endurance without the formal structure of a traditional interval workout.\n"
		case WORKOUT_TYPE_MIDDLE_DISTANCE_RUN:
			return ""
		case WORKOUT_TYPE_HILL_RIDE:
			return "Purpose: Hill workouts build the strength needed to tackle hills in a race. This can be done on the indoor trainer or replaced with low gear work if hills are not available.\n"
		case WORKOUT_TYPE_CADENCE_DRILLS:
			return WORKOUT_TYPE_STR_CADENCE_DRILLS
		case WORKOUT_TYPE_SPEED_INTERVAL_RIDE:
			return "Purpose: Speed interval sessions get you used to riding at faster paces.\n"
		case WORKOUT_TYPE_TEMPO_RIDE:
			return "Purpose: Tempo rides build a combination of speed and endurance. They should be performed at a pace you can hold for roughly one hour.\n"
		case WORKOUT_TYPE_EASY_RIDE:
			return "Purpose: Easy rides build aerobic capacity while keeping the wear and tear on the body to a minimum.\n"
		case WORKOUT_TYPE_SWEET_SPOT_RIDE:
			return "Purpose: Sweet spot rides are hard enough to improve fitness while being easy enough to do frequently.\n"
		case WORKOUT_TYPE_OPEN_WATER_SWIM:
			return "Purpose: Open water swims get you used to race day conditions.\n"
		case WORKOUT_TYPE_POOL_SWIM:
			return "Purpose: Most training is done in the swimming pool.\n"
		case WORKOUT_TYPE_TECHNIQUE_SWIM:
			return "Purpose: Develop proper swimming technique.\n"
		default:
			return ""
		}
	}
}
