//
//  ActivitiesVM.swift
//  Created by Michael Simms on 9/23/22.
//

import Foundation

struct ActivityTypeCallbackType {
	var names: Array<String>
}

func activityTypeCallback(name: Optional<UnsafePointer<Int8>>, context: Optional<UnsafeMutableRawPointer>)
{
	let activityType = String(cString: UnsafeRawPointer(name!).assumingMemoryBound(to: CChar.self))
	let typedPointer = context!.bindMemory(to: ActivityTypeCallbackType.self, capacity: 1)
	typedPointer.pointee.names.append(activityType)
}

class ActivitySummary : Codable, Identifiable, Hashable, Equatable {
	enum CodingKeys: CodingKey {
		case index
		case id
		case name
		case type
		case startTime
		case endTime
	}

	var index: Int = ACTIVITY_INDEX_UNKNOWN
	var id: String = ""
	var name: String = ""
	var type: String = ""
	var startTime: Date = Date()
	var endTime: Date = Date()

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
	static func == (lhs: ActivitySummary, rhs: ActivitySummary) -> Bool {
		return lhs.id == rhs.id
	}
}

class ActivitiesVM : ObservableObject {
	@Published var historicalActivities: Array<ActivitySummary> = []

	init() {
		self.buildHistoricalActivitiesList()
	}

	static func getActivityTypes() -> Array<String> {
		let pointer = UnsafeMutablePointer<ActivityTypeCallbackType>.allocate(capacity: 1)

		defer {
			pointer.deinitialize(count: 1)
			pointer.deallocate()
		}

		pointer.pointee = ActivityTypeCallbackType(names: [])
		GetActivityTypes(activityTypeCallback, pointer, true, true, true)
		let activityTypes = pointer.pointee.names
		return activityTypes
	}

	func buildHistoricalActivitiesList() {
		InitializeHistoricalActivityList()
		CreateAllHistoricalActivityObjects()

		if LoadAllHistoricalActivitySummaryData() {

			var activityIndex = 0
			var done = false

			while !done {

				var startTime: time_t = 0
				var endTime: time_t = 0

				// Load all data.
				if GetHistoricalActivityStartAndEndTime(activityIndex, &startTime, &endTime) {

					if endTime == 0 {
						FixHistoricalActivityEndTime(activityIndex)
					}

					let activityIdPtr = UnsafeRawPointer(ConvertActivityIndexToActivityId(activityIndex))
					let activityTypePtr = UnsafeRawPointer(GetHistoricalActivityType(activityIndex))
					let activityNamePtr = UnsafeRawPointer(GetHistoricalActivityName(activityIndex))

					defer {
						activityTypePtr!.deallocate()
						activityNamePtr!.deallocate()
					}

					if activityTypePtr == nil  || activityNamePtr == nil {
						done = true
					}
					else {
						let summary = ActivitySummary()

						let activityId = String(cString: activityIdPtr!.assumingMemoryBound(to: CChar.self))
						let activityName = String(cString: activityNamePtr!.assumingMemoryBound(to: CChar.self))
						let activityType = String(cString: activityTypePtr!.assumingMemoryBound(to: CChar.self))

						for c in activityId {
							summary.id.append(c)
						}
						for c in activityName {
							summary.name.append(c)
						}
						for c in activityType {
							summary.type.append(c)
						}

						summary.index = activityIndex
						summary.startTime = Date(timeIntervalSince1970: TimeInterval(startTime))
						summary.endTime = Date(timeIntervalSince1970: TimeInterval(endTime))

						self.historicalActivities.append(summary)

						activityIndex += 1
					}
				}
				else {
					done = true
				}
			}
		}
	}

	static func imageNameForActivityType(activityType: String) -> String {
		if activityType == ACTIVITY_TYPE_BENCH_PRESS {
			return "scalemass"
		}
		if activityType == ACTIVITY_TYPE_CHINUP {
			return "scalemass"
		}
		if activityType == ACTIVITY_TYPE_CYCLING {
			return "bicycle"
		}
		if activityType == ACTIVITY_TYPE_HIKING {
			return "figure.walk"
		}
		if activityType == ACTIVITY_TYPE_MOUNTAIN_BIKING {
			return "bicycle"
		}
		if activityType == ACTIVITY_TYPE_RUNNING {
			return "figure.walk"
		}
		if activityType == ACTIVITY_TYPE_SQUAT {
			return "scalemass"
		}
		if activityType == ACTIVITY_TYPE_STATIONARY_BIKE {
			return "bicycle"
		}
		if activityType == ACTIVITY_TYPE_TREADMILL {
			return "figure.walk"
		}
		if activityType == ACTIVITY_TYPE_PULLUP {
			return "scalemass"
		}
		if activityType == ACTIVITY_TYPE_PUSHUP {
			return "scalemass"
		}
		if activityType == ACTIVITY_TYPE_WALKING {
			return "figure.walk"
		}
		if activityType == ACTIVITY_TYPE_OPEN_WATER_SWIMMING {
			return "stopwatch"
		}
		if activityType == ACTIVITY_TYPE_POOL_SWIMMING {
			return "stopwatch"
		}
		if activityType == ACTIVITY_TYPE_DUATHLON {
			return "2.circle"
		}
		if activityType == ACTIVITY_TYPE_TRIATHLON {
			return "3.circle"
		}
		return "stopwatch"
	}
}
