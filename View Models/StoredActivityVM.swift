//
//  StoredActivityVM.swift
//  Created by Michael Simms on 10/8/22.
//

import Foundation
import MapKit

struct TagsTypeCallbackType {
	var tags: Array<String>
}

func tagsTypeCallback(name: Optional<UnsafePointer<Int8>>, context: Optional<UnsafeMutableRawPointer>)
{
	let tag = String(cString: UnsafeRawPointer(name!).assumingMemoryBound(to: CChar.self))
	let typedPointer = context!.bindMemory(to: TagsTypeCallbackType.self, capacity: 1)
	typedPointer.pointee.tags.append(tag)
}

class StoredActivityVM : ObservableObject {
	var activityIndex: Int = ACTIVITY_INDEX_UNKNOWN // Index into the cache of loaded activities
	var activityId: String = ""                     // Unique identifier for the activity
	var name: String = ""                           // Name of the activity
	var description: String = ""                    // Description of the activity
	var locationTrack: Array<CLLocationCoordinate2D> = []
	var startingLat: Double = 0.0
	var startingLon: Double = 0.0
#if !os(watchOS)
	@Published var route: MKPolyline = MKPolyline()
#endif
	var heartRate: Array<(UInt64, Double)> = []
	var cadence: Array<(UInt64, Double)> = []
	var pace: Array<(UInt64, Double)> = []
	var power: Array<(UInt64, Double)> = []
	var speed: Array<(UInt64, Double)> = []

	init (activityIndex: Int, activityId: String, name: String, description: String) {

		// If a database index wasn't provided then we probably needed to load the activity summary from the database.
		// The activity index will be zero because it will be the only activity loaded.
		if activityIndex == ACTIVITY_INDEX_UNKNOWN {
			LoadHistoricalActivity(activityId)
			CreateHistoricalActivityObject(0)
			self.activityIndex = 0
		}
		else {
			CreateHistoricalActivityObject(activityIndex)
			self.activityIndex = activityIndex
		}
		self.activityId = activityId
		self.name = name
		self.description = description
		self.loadSensorData()
	}

	func loadSensorData() {
		if LoadAllHistoricalActivitySensorData(self.activityIndex) {
			
			// Location points
			let numLocationPoints = GetNumHistoricalActivityLocationPoints(self.activityIndex)
			if numLocationPoints > 0 {

				for pointIndex in 0...numLocationPoints - 1 {
					var coordinate = Coordinate( latitude: 0.0, longitude: 0.0, altitude: 0.0, horizontalAccuracy: 0.0, verticalAccuracy: 0.0, time: 0 )
					
					if GetHistoricalActivityPoint(self.activityIndex, pointIndex, &coordinate) {
						self.locationTrack.append(CLLocationCoordinate2D(latitude: coordinate.latitude, longitude: coordinate.longitude))
					}
				}
				
				if self.locationTrack.count > 0 {
					
					self.startingLat = locationTrack[0].latitude
					self.startingLon = locationTrack[0].longitude
#if !os(watchOS)
					self.route = MKPolyline(coordinates: self.locationTrack, count: self.locationTrack.count)
#endif
				}
			}
			
			// Heart rate points
			let numHeartRatePoints = GetNumHistoricalSensorPoints(self.activityIndex, SENSOR_TYPE_HEART_RATE)
			if numHeartRatePoints > 0 {

				for pointIndex in 0...numHeartRatePoints - 1 {
					var timestamp: time_t = 0
					var value: Double = 0.0

					if GetHistoricalActivitySensorPoint(self.activityIndex, SENSOR_TYPE_HEART_RATE, pointIndex, &timestamp, &value) {
						self.heartRate.append((UInt64(timestamp), value))
					}
				}
			}

			// Cadence points
			let numCadencePoints = GetNumHistoricalSensorPoints(self.activityIndex, SENSOR_TYPE_CADENCE)
			if numCadencePoints > 0 {

				for pointIndex in 0...numCadencePoints - 1 {
					var timestamp: time_t = 0
					var value: Double = 0.0
					
					if GetHistoricalActivitySensorPoint(self.activityIndex, SENSOR_TYPE_CADENCE, pointIndex, &timestamp, &value) {
						self.cadence.append((UInt64(timestamp), value))
					}
				}
			}

			// Pace and speed points
			let numPacePoints = GetNumHistoricalSensorPoints(self.activityIndex, SENSOR_TYPE_LOCATION)
			if numPacePoints > 0 {
				
				for pointIndex in 0...numPacePoints - 1 {
					let pace = QueryHistoricalActivityAttribute(self.activityIndex, ACTIVITY_ATTRIBUTE_CURRENT_PACE)
					let speed = QueryHistoricalActivityAttribute(self.activityIndex, ACTIVITY_ATTRIBUTE_CURRENT_SPEED)

					self.pace.append((UInt64(pointIndex), pace.value.doubleVal))
					self.speed.append((UInt64(pointIndex), speed.value.doubleVal))
				}
			}

			// Power points
			let numPowerPoints = GetNumHistoricalSensorPoints(self.activityIndex, SENSOR_TYPE_POWER)
			if numPowerPoints > 0 {

				for pointIndex in 0...numPowerPoints - 1 {
					var timestamp: time_t = 0
					var value: Double = 0.0
					
					if GetHistoricalActivitySensorPoint(self.activityIndex, SENSOR_TYPE_POWER, pointIndex, &timestamp, &value) {
						self.power.append((UInt64(timestamp), value))
					}
				}
			}
		}
	}

	func getActivityAttributes() -> Array<String> {
		var attributeList: Array<String> = []
		let numAttributes = GetNumHistoricalActivityAttributes(self.activityIndex)
		
		if numAttributes > 0 {
			for attributeIndex in 0...numAttributes - 1 {
				let attributeNamePtr = UnsafeRawPointer(GetHistoricalActivityAttributeName(self.activityIndex, attributeIndex))
				
				if attributeNamePtr != nil {
					defer {
						attributeNamePtr!.deallocate()
					}
					
					let attributeName = String(cString: attributeNamePtr!.assumingMemoryBound(to: CChar.self))
					attributeList.append(attributeName)
				}
			}
		}
		return attributeList
	}

	func getActivityAttributeValueStr(attributeName: String) -> String {
		let attribute = QueryHistoricalActivityAttribute(self.activityIndex, attributeName)

		if attribute.valid {
			let result = LiveActivityVM.formatActivityValue(attribute: attribute)
			return result + " " + LiveActivityVM.formatActivityMeasureType(measureType: attribute.measureType)
		}
		return ""
	}
	
	func getActivityStartTime() -> time_t {
		var startTime: time_t = 0
		var endTime: time_t = 0

		GetHistoricalActivityStartAndEndTime(self.activityIndex, &startTime, &endTime)
		return startTime
	}

	func exportActivity(format: FileFormat) {
	}

	func updateActivityName() -> Bool {
		if UpdateActivityName(self.activityId, self.name) {
			return ApiClient.shared.setActivityName(activityId: self.activityId, name: self.name)
		}
		return false
	}

	func updateActivityDescription() -> Bool {
		if UpdateActivityDescription(self.activityId, self.description) {
			return ApiClient.shared.setActivityDescription(activityId: self.activityId, description: self.description)
		}
		return false
	}

	func deleteActivity() -> Bool {
		if DeleteActivityFromDatabase(self.activityId) {
			return ApiClient.shared.deleteActivity(activityId: self.activityId)
		}
		return false
	}
	
	func listTags() -> Array<String> {
		let pointer = UnsafeMutablePointer<TagsTypeCallbackType>.allocate(capacity: 1)
		
		defer {
			pointer.deinitialize(count: 1)
			pointer.deallocate()
		}
		
		pointer.pointee = TagsTypeCallbackType(tags: [])
		RetrieveTags(self.activityId, tagsTypeCallback, pointer)
		let tags = pointer.pointee.tags
		return tags
	}
}
