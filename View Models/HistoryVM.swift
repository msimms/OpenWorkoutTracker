//
//  HistoryVM.swift
//  Created by Michael Simms on 9/23/22.
//

import Foundation

extension RandomAccessCollection where Element : Comparable {
	func insertionIndex(of value: Element) -> Index {
		var slice : SubSequence = self[...]
		
		while !slice.isEmpty {
			let middle = slice.index(slice.startIndex, offsetBy: slice.count / 2)
			if value < slice[middle] {
				slice = slice[..<middle]
			} else {
				slice = slice[index(after: middle)...]
			}
		}
		return slice.startIndex
	}
}

class HistoryVM : ObservableObject {
	enum VmState {
		case empty
		case loaded
	}
	
	@Published var state = VmState.empty
	@Published var historicalActivities: Array<ActivitySummary> = []
	
	init() {
		NotificationCenter.default.addObserver(self, selector: #selector(self.activityMetadataUpdated), name: Notification.Name(rawValue: NOTIFICATION_NAME_ACTIVITY_METADATA_UPDATED), object: nil)

		self.state = VmState.empty
		self.historicalActivities = []
	}
	
	/// @brief Loads the activity list from HealthKit (if enabled).
	private func loadActivitiesFromHealthKit() {
		if Preferences.willIntegrateHealthKitActivities() {
			
			// Read all relevant activities from HealthKit.
			HealthManager.shared.readAllActivitiesFromHealthStore()
			
			// De-duplicate the list against itself as well as the activities in our database.
			if Preferences.hideHealthKitDuplicates() {
				
				// Remove duplicate activities from within the HealthKit list.
				HealthManager.shared.removeDuplicateActivities()
				
				// Remove activities that overlap with ones in our database.
				let numDbActivities = GetNumHistoricalActivities()
				for activityIndex in 0..<numDbActivities {
					var startTime: time_t = 0
					var endTime: time_t = 0
					
					if GetHistoricalActivityStartAndEndTime(activityIndex, &startTime, &endTime) {
						HealthManager.shared.removeActivitiesThatOverlapWithStartTime(startTime: startTime, endTime:endTime)
					}
				}
			}
			
			// Incorporate HealthKit's list into the master list of activities.
			for workout in HealthManager.shared.workouts {
				let summary = ActivitySummary()

				summary.id = workout.key
				summary.name = ""
				summary.type = HealthManager.healthKitWorkoutToActivityType(workout: workout.value)
				summary.index = ACTIVITY_INDEX_UNKNOWN
				summary.startTime = workout.value.startDate
				summary.endTime = workout.value.endDate
				summary.source = ActivitySummary.Source.healthkit
				
				DispatchQueue.main.async {
					let index = self.historicalActivities.insertionIndex(of: summary)
					self.historicalActivities.insert(summary, at: index)
				}
			}
		}
	}
	
	/// @brief Loads the activity list from our database.
	private func loadActivitiesFromDatabase() {
		InitializeHistoricalActivityList()
		
		if LoadAllHistoricalActivitySummaryData() {
			
			// Whenever we reload the history we should re-evaluate the user's recent performances.
			let estimatedFtp = EstimateFtp()
			let estimatedMaxHr = EstimateMaxHr()
			let best5KAttr = QueryBestActivityAttributeByActivityType(ACTIVITY_TYPE_RUNNING, ACTIVITY_ATTRIBUTE_FASTEST_5K, true, nil)
			Preferences.setEstimatedFtp(value: estimatedFtp)
			Preferences.setEstimatedMaxHr(value: estimatedMaxHr)
			if best5KAttr.valid {
				Preferences.setBestRecent5KSecs(value: UInt32(best5KAttr.value.intVal))
			}
			CommonApp.shared.setUserProfile()
			
			// Minor performance optimization, since we know how many items will be in the list.
			let numActivities = GetNumHistoricalActivities()
			self.historicalActivities.reserveCapacity(numActivities)
			
			// Build our local summary cache.
			var activityIndex = 0
			var done = false
			while !done {
				
				// Load all data.
				var startTime: time_t = 0
				var endTime: time_t = 0
				if GetHistoricalActivityStartAndEndTime(activityIndex, &startTime, &endTime) {
					
					if endTime == 0 {
						FixHistoricalActivityEndTime(activityIndex)
					}
					
					let activityIdPtr = UnsafeRawPointer(ConvertActivityIndexToActivityId(activityIndex)) // this one is a const char*, so don't dealloc it
					
					let activityTypePtr = UnsafeRawPointer(GetHistoricalActivityType(activityIndex))
					let activityNamePtr = UnsafeRawPointer(GetHistoricalActivityName(activityIndex))
					let activityDescPtr = UnsafeRawPointer(GetHistoricalActivityDescription(activityIndex))
					
					defer {
						activityTypePtr!.deallocate()
						activityNamePtr!.deallocate()
						activityDescPtr!.deallocate()
					}
					
					if activityTypePtr == nil || activityNamePtr == nil || activityDescPtr == nil {
						done = true
					}
					else {
						let summary = ActivitySummary()
						
						let activityId = String(cString: activityIdPtr!.assumingMemoryBound(to: CChar.self))
						let activityName = String(cString: activityNamePtr!.assumingMemoryBound(to: CChar.self))
						let activityType = String(cString: activityTypePtr!.assumingMemoryBound(to: CChar.self))
						let activityDesc = String(cString: activityDescPtr!.assumingMemoryBound(to: CChar.self))
						
						summary.id = activityId
						summary.name = activityName
						summary.type = activityType
						summary.description = activityDesc
						summary.index = activityIndex
						summary.startTime = Date(timeIntervalSince1970: TimeInterval(startTime))
						summary.endTime = Date(timeIntervalSince1970: TimeInterval(endTime))
						summary.source = ActivitySummary.Source.database
						
						DispatchQueue.main.async {
							self.historicalActivities.insert(summary, at: 0)
						}

						activityIndex += 1
					}
				}
				else {
					done = true
				}
			}
		}
	}
	
	/// @brief Loads the activity list from our database as well as HealthKit (if enabled).
	func buildHistoricalActivitiesList(createAllObjects: Bool) {
		DispatchQueue.main.async {
			self.state = VmState.empty
			self.historicalActivities = []
		}

		self.loadActivitiesFromDatabase()
		self.loadActivitiesFromHealthKit()

		if createAllObjects {
			CreateAllHistoricalActivityObjects()
		}

		DispatchQueue.main.async {
			if self.state != VmState.loaded {
				self.state = VmState.loaded
			}
		}
	}
	
	func getFormattedTotalActivityAttribute(activityType: String, attributeName: String) -> String {
		let attr = QueryActivityAttributeTotalByActivityType(attributeName, activityType)
		return LiveActivityVM.formatActivityValue(attribute: attr)
	}
	
	func getFormattedBestActivityAttribute(activityType: String, attributeName: String, smallestIsBest: Bool) -> String {
		let attr = QueryBestActivityAttributeByActivityType(attributeName, activityType, smallestIsBest, nil)
		return LiveActivityVM.formatActivityValue(attribute: attr)
	}
	
	/// @brief Utility function for getting the image name that corresponds to an activity, such as running, cycling, etc.
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
			return "figure.hiking"
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
		if activityType == ACTIVITY_TYPE_STATIONARY_CYCLING {
			return "bicycle"
		}
		if activityType == ACTIVITY_TYPE_VIRTUAL_CYCLING {
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
			return "figure.open.water.swim"
		}
		if activityType == ACTIVITY_TYPE_POOL_SWIMMING {
			return "figure.pool.swim"
		}
		if activityType == ACTIVITY_TYPE_DUATHLON {
			return "2.circle"
		}
		if activityType == ACTIVITY_TYPE_TRIATHLON {
			return "3.circle"
		}
		return "stopwatch"
	}
	
	@objc func activityMetadataUpdated(notification: NSNotification) {
		if let data = notification.object as? Dictionary<String, AnyObject> {
			let activityId = data[PARAM_ACTIVITY_ID] as? String

			if activityId != nil {
				DispatchQueue.main.async {
					for item in self.historicalActivities {
						if item.id == activityId {
							item.name = data[PARAM_ACTIVITY_NAME] as? String ?? ""
							item.description = data[PARAM_ACTIVITY_DESCRIPTION] as? String ?? ""
						}
					}
				}
			}
		}
	}
}
