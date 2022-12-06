//
//  StoredActivityVM.swift
//  Created by Michael Simms on 10/8/22.
//

import Foundation
import MapKit

enum ActivityExportException: Error {
	case runtimeError(String)
}

struct TagsCallbackType {
	var tags: Array<String>
}

func tagsCallback(name: Optional<UnsafePointer<Int8>>, context: Optional<UnsafeMutableRawPointer>) {
	let tag = String(cString: UnsafeRawPointer(name!).assumingMemoryBound(to: CChar.self))
	let typedPointer = context!.bindMemory(to: TagsCallbackType.self, capacity: 1)
	typedPointer.pointee.tags.append(tag)
}

class StoredActivityVM : ObservableObject {
	var source: ActivitySummary.Source = ActivitySummary.Source.database
	var activityIndex: Int = ACTIVITY_INDEX_UNKNOWN // Index into the cache of loaded activities
	var activityId: String = ""                     // Unique identifier for the activity
	var name: String = ""                           // Name of the activity
	var description: String = ""                    // Description of the activity
	var locationTrack: Array<CLLocationCoordinate2D> = []
	var startingLat: Double = 0.0
	var startingLon: Double = 0.0
#if !os(watchOS)
	var trackLine: MKPolyline = MKPolyline()
#endif
	var heartRate: Array<(UInt64, Double)> = []     // Heart rate readings vs time
	var cadence: Array<(UInt64, Double)> = []       // Cadence readings vs time
	var pace: Array<(UInt64, Double)> = []          // Pace calculations vs time
	var power: Array<(UInt64, Double)> = []         // Power readings vs time
	var speed: Array<(UInt64, Double)> = []         // Speed calculations vs time
	var x: Array<(UInt64, Double)> = []             // X-axis accelerometer readings vs time
	var y: Array<(UInt64, Double)> = []             // Y-axis accelerometer readings vs time
	var z: Array<(UInt64, Double)> = []             // Z-axis accelerometer readings vs time

	init(activitySummary: ActivitySummary) {

		self.source = activitySummary.source
		self.activityId = activitySummary.id
		self.name = activitySummary.name
		self.description = activitySummary.description

		// Activity is from the app database.
		if activitySummary.source == ActivitySummary.Source.database {

			// If a database index wasn't provided then we probably needed to load the activity summary from the database.
			// The activity index will be zero because it will be the only activity loaded.
			if activitySummary.index == ACTIVITY_INDEX_UNKNOWN {
				LoadHistoricalActivity(activitySummary.id)
				CreateHistoricalActivityObject(0)
				self.activityIndex = 0
			}
			else {
				CreateHistoricalActivityObject(activitySummary.index)
				self.activityIndex = activitySummary.index
			}

			self.loadSensorDataFromDb()
		}
		
		// Activity is from HealthKit.
		else if activitySummary.source == ActivitySummary.Source.healthkit {
			self.loadSensorDataFromHealthKit()
		}
	}

	func loadSensorDataFromHealthKit() {
		let healthKit = HealthManager.shared
		healthKit.readLocationPointsFromHealthStoreForActivityId(activityId: self.activityId)
	}

	func loadSensorDataFromDb() {
		if LoadAllHistoricalActivitySensorData(self.activityIndex) {
			
			// Location points
			let numLocationPoints = GetNumHistoricalActivityLocationPoints(self.activityIndex)
			if numLocationPoints > 0 {

				for pointIndex in 0...numLocationPoints - 1 {
					var coordinate = Coordinate( latitude: 0.0, longitude: 0.0, altitude: 0.0, horizontalAccuracy: 0.0, verticalAccuracy: 0.0, time: 0 )
					
					if GetHistoricalActivityLocationPoint(self.activityIndex, pointIndex, &coordinate) {
						self.locationTrack.append(CLLocationCoordinate2D(latitude: coordinate.latitude, longitude: coordinate.longitude))
					}
				}
				
				if self.locationTrack.count > 0 {
					self.startingLat = locationTrack[0].latitude
					self.startingLon = locationTrack[0].longitude
#if !os(watchOS)
					self.trackLine = MKPolyline(coordinates: self.locationTrack, count: self.locationTrack.count)
#endif
				}
			}
			
			// Heart rate readings
			let numHeartRateReadings = GetNumHistoricalSensorReadings(self.activityIndex, SENSOR_TYPE_HEART_RATE)
			if numHeartRateReadings > 0 {

				for pointIndex in 0...numHeartRateReadings - 1 {
					var timestamp: time_t = 0
					var value: Double = 0.0

					if GetHistoricalActivitySensorReading(self.activityIndex, SENSOR_TYPE_HEART_RATE, pointIndex, &timestamp, &value) {
						self.heartRate.append((UInt64(timestamp), value))
					}
				}
			}

			// Cadence readings
			let numCadenceReadings = GetNumHistoricalSensorReadings(self.activityIndex, SENSOR_TYPE_CADENCE)
			if numCadenceReadings > 0 {

				for pointIndex in 0...numCadenceReadings - 1 {
					var timestamp: time_t = 0
					var value: Double = 0.0
					
					if GetHistoricalActivitySensorReading(self.activityIndex, SENSOR_TYPE_CADENCE, pointIndex, &timestamp, &value) {
						self.cadence.append((UInt64(timestamp), value))
					}
				}
			}

			// Pace and speed readings
			let numPaceReadings = GetNumHistoricalSensorReadings(self.activityIndex, SENSOR_TYPE_LOCATION)
			if numPaceReadings > 0 {
				
				for pointIndex in 0...numPaceReadings - 1 {
					let pace = QueryHistoricalActivityAttribute(self.activityIndex, ACTIVITY_ATTRIBUTE_CURRENT_PACE)
					let speed = QueryHistoricalActivityAttribute(self.activityIndex, ACTIVITY_ATTRIBUTE_CURRENT_SPEED)

					self.pace.append((UInt64(pointIndex), pace.value.doubleVal))
					self.speed.append((UInt64(pointIndex), speed.value.doubleVal))
				}
			}

			// Power readings
			let numPowerReadings = GetNumHistoricalSensorReadings(self.activityIndex, SENSOR_TYPE_POWER)
			if numPowerReadings > 0 {

				for pointIndex in 0...numPowerReadings - 1 {
					var timestamp: time_t = 0
					var value: Double = 0.0
					
					if GetHistoricalActivitySensorReading(self.activityIndex, SENSOR_TYPE_POWER, pointIndex, &timestamp, &value) {
						self.power.append((UInt64(timestamp), value))
					}
				}
			}
			
			// Accelerometer readings
			let numAccelPoints = GetNumHistoricalActivityAccelerometerReadings(self.activityIndex)
			if numAccelPoints > 0 {

				for pointIndex in 0...numAccelPoints - 1 {
					var timestamp: time_t = 0
					var xValue: Double = 0.0
					var yValue: Double = 0.0
					var zValue: Double = 0.0

					if GetHistoricalActivityAccelerometerReading(self.activityIndex, pointIndex, &timestamp, &xValue, &yValue, &zValue) {
						self.x.append((UInt64(timestamp), xValue))
						self.y.append((UInt64(timestamp), xValue))
						self.z.append((UInt64(timestamp), xValue))
					}
				}
			}
		}
	}

	/// @brief Returns a list of attributes attribute names that are applicable to this activity.
	func getActivityAttributes() -> Array<String> {
		var attributeList: Array<String> = []

		if self.source == ActivitySummary.Source.database {
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
		}
		else if self.source == ActivitySummary.Source.healthkit {
			attributeList.append(ACTIVITY_ATTRIBUTE_DISTANCE_TRAVELED)
			attributeList.append(ACTIVITY_ATTRIBUTE_ELAPSED_TIME)
			attributeList.append(ACTIVITY_ATTRIBUTE_CALORIES_BURNED)
//			attributeList.append(ACTIVITY_ATTRIBUTE_STARTING_LATITUDE)
//			attributeList.append(ACTIVITY_ATTRIBUTE_STARTING_LONGITUDE)
		}
		return attributeList
	}

	func getActivityAttributesAndCharts() -> Array<String> {
		var attributeList = self.getActivityAttributes()

		if self.heartRate.count > 0 {
			attributeList.append("Heart Rate")
		}
		if IsHistoricalActivityMovingActivity(self.activityIndex) {
			if self.cadence.count > 0 {
				attributeList.append("Cadence")
			}
			if self.pace.count > 0 {
				attributeList.append("Pace")
			}
			if self.power.count > 0 {
				attributeList.append("Power")
			}
			if self.speed.count > 0 {
				attributeList.append("Speed")
			}
		}
		else if IsHistoricalActivityLiftingActivity(self.activityIndex) {
			if self.x.count > 0 {
				attributeList.append("X Axis")
			}
			if self.y.count > 0 {
				attributeList.append("Y Axis")
			}
			if self.z.count > 0 {
				attributeList.append("Z Axis")
			}
		}
		return attributeList
	}

	private func formatActivityAttribute(attribute: ActivityAttributeType) -> String {
		let result = LiveActivityVM.formatActivityValue(attribute: attribute)
		return result + " " + LiveActivityVM.formatActivityMeasureType(measureType: attribute.measureType)
	}

	func getActivityAttributeValueStr(attributeName: String) -> String {
		if self.source == ActivitySummary.Source.database {
			let attribute = QueryHistoricalActivityAttribute(self.activityIndex, attributeName)

			if attribute.valid {
				return self.formatActivityAttribute(attribute: attribute)
			}
		}
		else if self.source == ActivitySummary.Source.healthkit {
			let healthKit = HealthManager.shared
			let attribute = healthKit.getWorkoutAttribute(attributeName: attributeName, activityId: self.activityId)

			if attribute.valid {
				return self.formatActivityAttribute(attribute: attribute)
			}
		}
		return ""
	}
	
	func getActivityStartTime() -> time_t {
		var startTime: time_t = 0
		var endTime: time_t = 0

		GetHistoricalActivityStartAndEndTime(self.activityIndex, &startTime, &endTime)
		return startTime
	}

	func exportActivityToFile(fileFormat: FileFormat) throws {

		// Build the URL for the application's directory.
		var exportDirUrl = FileManager.default.url(forUbiquityContainerIdentifier: nil)
		if exportDirUrl == nil {
			throw ActivityExportException.runtimeError("iCloud storage is disabled.")
		}
		exportDirUrl = exportDirUrl?.appendingPathComponent("Documents")
		try FileManager.default.createDirectory(at: exportDirUrl!, withIntermediateDirectories: true, attributes: nil)

		// Export the file.
		let fileNamePtr = UnsafeRawPointer(ExportActivityFromDatabase(self.activityId, fileFormat, exportDirUrl?.absoluteString))

		guard fileNamePtr != nil else {
			throw ActivityExportException.runtimeError("Export failed!")
		}

		do {
			fileNamePtr!.deallocate()
		}
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
		let pointer = UnsafeMutablePointer<TagsCallbackType>.allocate(capacity: 1)
		
		defer {
			pointer.deinitialize(count: 1)
			pointer.deallocate()
		}
		
		pointer.pointee = TagsCallbackType(tags: [])
		RetrieveTags(self.activityId, tagsCallback, pointer)
		let tags = pointer.pointee.tags
		return tags
	}
}
