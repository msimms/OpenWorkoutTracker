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

class StoredActivityVM : ObservableObject, Identifiable, Hashable, Equatable {
	enum State {
		case empty
		case loaded
	}
	
	@Published private(set) var state = State.empty
	var source: ActivitySummary.Source = ActivitySummary.Source.database
	var activityIndex: Int = ACTIVITY_INDEX_UNKNOWN // Index into the cache of loaded activities
	var activityId: String = ""                     // Unique identifier for the activity
	var userId: String = ""                         // Unique identifier for the activity owner
	@Published var name: String = ""                // Name of the activity
	@Published var description: String = ""         // Description of the activity
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
	@Published var photoIds: Array<String> = []     // Unique identifiers for any photos associated with this activity
	
	init(activitySummary: ActivitySummary) {
		NotificationCenter.default.addObserver(self, selector: #selector(self.activityMetadataUpdated), name: Notification.Name(rawValue: NOTIFICATION_NAME_ACTIVITY_METADATA_UPDATED), object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(self.activityPhotosListReceived), name: Notification.Name(rawValue: NOTIFICATION_NAME_ACTIVITY_PHOTOS_LIST), object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(self.activityPhotosUpdated), name: Notification.Name(rawValue: NOTIFICATION_NAME_ACTIVITY_PHOTOS_UPDATED), object: nil)
		
		self.state = State.empty
		self.source = activitySummary.source
		self.activityId = activitySummary.id
		self.userId = activitySummary.userId
		self.name = activitySummary.name
		self.description = activitySummary.description
		self.activityIndex = activitySummary.index
	}
	
	/// @brief Hashable overrides
	func hash(into hasher: inout Hasher) {
		hasher.combine(self.activityId)
		hasher.combine(self.state)
	}
	
	/// @brief Equatable overrides
	static func == (lhs: StoredActivityVM, rhs: StoredActivityVM) -> Bool {
		return lhs.activityId == rhs.activityId && lhs.state == rhs.state
	}
	
	func load() {
		// Activity is from the app database.
		if self.source == ActivitySummary.Source.database {
			
			// If a database index wasn't provided then we probably needed to load the activity summary from the database.
			// The activity index will be zero because it will be the only activity loaded.
			if self.activityIndex == ACTIVITY_INDEX_UNKNOWN {
				LoadHistoricalActivity(self.activityId)
				self.activityIndex = ConvertActivityIdToActivityIndex(self.activityId)
			}
			
			// Should never happen, but just in case.
			if self.activityIndex != ACTIVITY_INDEX_UNKNOWN {
				CreateHistoricalActivityObject(self.activityIndex)
				
				// Retrieve all the sensor and location data.
				self.loadSensorDataFromDb()
				
				// Make sure we have the latest name, description, etc.
				let _ = ApiClient.shared.requestActivityMetadata(activityId: self.activityId)
				
				// Retrieve photo URLs.
				let _ = ApiClient.shared.requestActivityPhotos(activityId: self.activityId)
			}
		}
		
		// Activity is from HealthKit.
		else if self.source == ActivitySummary.Source.healthkit {
			self.loadSensorDataFromHealthKit()
		}
		
		DispatchQueue.main.async {
			if self.state != State.loaded {
				self.state = State.loaded
			}
		}
	}
	
	/// @brief Loads sensor data (location, heart rate, power, etc.) for activities in HealthKit.
	func loadSensorDataFromHealthKit() {
		let healthKit = HealthManager.shared
		healthKit.readLocationPointsFromHealthStoreForActivityId(activityId: self.activityId)
		
		var currCoordinate: Coordinate = Coordinate()
		var prevCoordinate: Coordinate = Coordinate()
		var pointIndex: Int = 0
		
		self.locationTrack = []
		
		while healthKit.getHistoricalActivityLocationPoint(activityId: self.activityId, coordinate: &currCoordinate, pointIndex: pointIndex) {
			let currentCoordinate: Coordinate = Coordinate(latitude: currCoordinate.latitude, longitude: currCoordinate.longitude, altitude: 0.0, horizontalAccuracy: 0.0, verticalAccuracy: 0.0, time: 0)
			
			// Performance optimization. Don't add every point to the track.
			let distance = DistanceBetweenCoordinates(currentCoordinate, prevCoordinate)
			if distance > 10 {
				self.locationTrack.append(CLLocationCoordinate2D(latitude: currCoordinate.latitude, longitude: currCoordinate.longitude))
				prevCoordinate = currCoordinate
			}
			pointIndex += 1
		}
		
		if self.locationTrack.count > 0 {
			self.startingLat = self.locationTrack[0].latitude
			self.startingLon = self.locationTrack[0].longitude
#if !os(watchOS)
			self.trackLine = MKPolyline(coordinates: self.locationTrack, count: self.locationTrack.count)
#endif
		}
	}
	
	/// @brief Loads sensor data (location, heart rate, power, etc.) for activities in our own database.
	func loadSensorDataFromDb() {
		if LoadHistoricalActivityLapData(self.activityIndex) && LoadAllHistoricalActivitySensorData(self.activityIndex) {
			
			// Location points
			self.locationTrack = []
			self.pace = []
			self.speed = []
			let numLocationPoints = GetNumHistoricalActivityLocationPoints(self.activityIndex)
			if numLocationPoints > 0 {
				var prevCoordinate = Coordinate(latitude: 0.0, longitude: 0.0, altitude: 0.0, horizontalAccuracy: 0.0, verticalAccuracy: 0.0, time: 0)
				var speedConversion = 3.6
				
				if Preferences.preferredUnitSystem() == UNIT_SYSTEM_US_CUSTOMARY {
					speedConversion = 2.236936
				}
				
				for pointIndex in 0...numLocationPoints - 1 {
					var currentCoordinate = Coordinate(latitude: 0.0, longitude: 0.0, altitude: 0.0, horizontalAccuracy: 0.0, verticalAccuracy: 0.0, time: 0)
					
					if GetHistoricalActivityLocationPoint(self.activityIndex, pointIndex, &currentCoordinate) {
						
						if self.locationTrack.count > 0 {
							let distance = DistanceBetweenCoordinates(prevCoordinate, currentCoordinate)
							let elapsedTimeSec = Double(currentCoordinate.time - prevCoordinate.time) / 1000.0
							let metersPerSec = distance / elapsedTimeSec
							if elapsedTimeSec > 0.01 {
								let currentPace = metersPerSec * 60.0 // Convert to meters/min, chart view will handle the rest
								let currentSpeed = metersPerSec * speedConversion // Convert to kph
								
								self.pace.append((UInt64(pointIndex), currentPace))
								self.speed.append((UInt64(pointIndex), currentSpeed))
							}
						}
						
						self.locationTrack.append(CLLocationCoordinate2D(latitude: currentCoordinate.latitude, longitude: currentCoordinate.longitude))
					}
					prevCoordinate = currentCoordinate
				}
				
				if self.locationTrack.count > 0 {
					self.startingLat = self.locationTrack[0].latitude
					self.startingLon = self.locationTrack[0].longitude
#if !os(watchOS)
					self.trackLine = MKPolyline(coordinates: self.locationTrack, count: self.locationTrack.count)
#endif
				}
			}
			
			// Heart rate readings
			self.heartRate = []
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
			self.cadence = []
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
			
			// Power readings
			self.power = []
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
			self.x = []
			self.y = []
			self.z = []
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
	
	func isMovingActivity() -> Bool {
		return IsHistoricalActivityMovingActivity(self.activityIndex)
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
	
	func getKilometerSplits() -> Array<time_t> {
		var result: Array<time_t> = []
		var attributeName = ACTIVITY_ATTRIBUTE_SPLIT_TIME_KM + "1"
		var attribute = QueryHistoricalActivityAttribute(self.activityIndex, attributeName)
		var splitTotal: time_t = 0
		var splitIndex = 1
		
		while attribute.valid {
			let currentSplit = time_t(attribute.value.timeVal) - splitTotal
			result.append(currentSplit)
			
			splitIndex += 1
			attributeName = ACTIVITY_ATTRIBUTE_SPLIT_TIME_KM + String(splitIndex)
			attribute = QueryHistoricalActivityAttribute(self.activityIndex, attributeName)
			splitTotal += currentSplit
		}
		
		return result
	}
	
	func getMileSplits() -> Array<time_t> {
		var result: Array<time_t> = []
		var attributeName = ACTIVITY_ATTRIBUTE_SPLIT_TIME_MILE + "1"
		var attribute = QueryHistoricalActivityAttribute(self.activityIndex, attributeName)
		var splitTotal: time_t = 0
		var splitIndex = 1
		
		while attribute.valid {
			let currentSplit = time_t(attribute.value.timeVal) - splitTotal
			result.append(currentSplit)
			
			splitIndex += 1
			attributeName = ACTIVITY_ATTRIBUTE_SPLIT_TIME_MILE + String(splitIndex)
			attribute = QueryHistoricalActivityAttribute(self.activityIndex, attributeName)
			splitTotal += currentSplit
		}
		
		return result
	}
	
	func getLapSplits() -> Array<time_t> {
		var result: Array<time_t> = []
		var attributeName = ACTIVITY_ATTRIBUTE_LAP_TIME + "1"
		var attribute = QueryHistoricalActivityAttribute(self.activityIndex, attributeName)
		var splitIndex = 1
		
		while attribute.valid {
			if attribute.valid {
				result.append(attribute.value.timeVal)
			}
			
			splitIndex += 1
			attributeName = ACTIVITY_ATTRIBUTE_LAP_TIME + String(splitIndex)
			attribute = QueryHistoricalActivityAttribute(self.activityIndex, attributeName)
		}
		
		return result
	}
	
	private func formatActivityAttribute(attribute: ActivityAttributeType) -> String {
		let result = StringUtils.formatActivityValue(attribute: attribute)
		return result + " " + StringUtils.formatActivityMeasureType(measureType: attribute.measureType)
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
		
		if self.source == ActivitySummary.Source.database {
			GetHistoricalActivityStartAndEndTime(self.activityIndex, &startTime, &endTime)
		}
		else if self.source == ActivitySummary.Source.healthkit {
		}
		return startTime
	}
	
	func getActivityEndTime() -> time_t {
		var startTime: time_t = 0
		var endTime: time_t = 0
		
		if self.source == ActivitySummary.Source.database {
			GetHistoricalActivityStartAndEndTime(self.activityIndex, &startTime, &endTime)
		}
		else if self.source == ActivitySummary.Source.healthkit {
		}
		return endTime
	}
	
	func getFastestMile() -> time_t {
		let fastest = QueryHistoricalActivityAttribute(self.activityIndex, ACTIVITY_ATTRIBUTE_FASTEST_MILE)
		return fastest.value.timeVal
	}
	
	func getFastestKm() -> time_t {
		let fastest = QueryHistoricalActivityAttribute(self.activityIndex, ACTIVITY_ATTRIBUTE_FASTEST_KM)
		return fastest.value.timeVal
	}
	
	/// @brief Exports the activity to the specified directory, in the specified file format..
	func exportActivityToFile(fileFormat: FileFormat, dirName: String) throws -> String {
		var fileName: String = ""
		
		if self.source == ActivitySummary.Source.database {
			let fileNamePtr = UnsafeRawPointer(ExportActivityFromDatabase(self.activityId, fileFormat, dirName))
			guard fileNamePtr != nil else {
				throw ActivityExportException.runtimeError("Export failed!")
			}
			
			fileName = String(cString: fileNamePtr!.assumingMemoryBound(to: CChar.self))
			fileNamePtr!.deallocate()
		}
		else if self.source == ActivitySummary.Source.healthkit {
			let healthKit = HealthManager.shared
			fileName = try healthKit.exportActivityToFile(activityId: self.activityId, fileFormat: fileFormat, dirName: dirName)
		}
		return fileName
	}
	
	/// @brief Exports the activity to the temp directory, in the specified file format..
	func exportActivityToTempFile(fileFormat: FileFormat) throws -> String {
		let directory = NSTemporaryDirectory()
		return try self.exportActivityToFile(fileFormat: fileFormat, dirName: directory)
	}
	
	/// @brief Exports the activity to the iCloud drive, in the specified file format..
	func exportActivityToICloudFile(fileFormat: FileFormat) throws -> String {
		
		// Build the URL for the application's directory.
		var exportDirUrl = FileManager.default.url(forUbiquityContainerIdentifier: nil)
		guard exportDirUrl != nil else {
			throw ActivityExportException.runtimeError("iCloud storage is disabled.")
		}
		exportDirUrl = exportDirUrl?.appendingPathComponent("Documents")
		try FileManager.default.createDirectory(at: exportDirUrl!, withIntermediateDirectories: true, attributes: nil)
		
		// Export the file.
		return try self.exportActivityToFile(fileFormat: fileFormat, dirName: exportDirUrl!.path(percentEncoded: false))
	}
	
	func updateActivityType(newActivityType: String) {
		UpdateActivityType(self.activityId, newActivityType)
		self.load()
	}
	
	func trimActivityData(newTime: UInt64, fromStart: Bool) {
		TrimActivityData(self.activityId, newTime, fromStart)
		self.load()
	}

	/// @brief Updates the activity name in our database and also the server, if applicable.
	func updateActivityName() -> Bool {
		// Only applicable to activities in our own database.
		if self.source == ActivitySummary.Source.database {
			if UpdateActivityName(self.activityId, self.name) {
				return ApiClient.shared.setActivityName(activityId: self.activityId, name: self.name)
			}
		}
		return false
	}
	
	/// @brief Updates the activity description in our database and also the server, if applicable.
	func updateActivityDescription() -> Bool {
		// Only applicable to activities in our own database.
		if self.source == ActivitySummary.Source.database {
			if UpdateActivityDescription(self.activityId, self.description) {
				return ApiClient.shared.setActivityDescription(activityId: self.activityId, description: self.description)
			}
		}
		return false
	}
	
	/// @brief Deletes this activity from our database and also the server, if applicable.
	func deleteActivity() -> Bool {
		// Only applicable to activities in our own database.
		if self.source == ActivitySummary.Source.database {
			if DeleteActivityFromDatabase(self.activityId) {
				return ApiClient.shared.deleteActivity(activityId: self.activityId)
			}
			else {
				NSLog("Delete activity failed.")
			}
		}
		return false
	}
	
	func uploadPhoto(image: UIImage) -> Bool {
		let imageData = image.jpegData(compressionQuality: 0.5)
		if imageData != nil {
			return ApiClient.shared.uploadActivityPhoto(activityId: self.activityId, imageData: imageData!)
		}
		return false
	}
	
	func deletePhoto(photoId: String) -> Bool {
		return ApiClient.shared.deleteActivityPhoto(activityId: self.activityId, photoId: photoId)
	}

	func createTag(tag: String) -> Bool {
		if CreateTag(self.activityId, tag) {
			return ApiClient.shared.createTag(tag: tag, activityId: self.activityId)
		}
		return false
	}
	
	func deleteTag(tag: String) -> Bool {
		if DeleteTag(self.activityId, tag) {
			return ApiClient.shared.deleteTag(tag: tag, activityId: self.activityId)
		}
		return false
	}
	
	/// @brief Returns any tags that were applied to this activity.
	func listTags() -> Array<String> {
		var tags: Array<String> = []
		
		// Only applicable to activities in our own database.
		if self.source == ActivitySummary.Source.database {
			let pointer = UnsafeMutablePointer<TagsCallbackType>.allocate(capacity: 1)
			
			defer {
				pointer.deinitialize(count: 1)
				pointer.deallocate()
			}
			
			pointer.pointee = TagsCallbackType(tags: [])
			if RetrieveTags(self.activityId, tagsCallback, pointer) == false {
				NSLog("Retrieve tags failed.")
			}
			tags = pointer.pointee.tags
		}
		return tags
	}
	
	func listValidGearNames() -> Array<String> {
		var names: Array<String> = []
		
		if IsHistoricalActivityMovingActivity(self.activityIndex) {
			if IsHistoricalActivityFootBased(self.activityIndex) {
				let gearVM: GearVM = GearVM()
				let shoes = gearVM.listShoes()
				for shoe in shoes {
					if shoe.timeRetired.timeIntervalSince1970 == 0 {
						names.append(shoe.name)
					}
				}
			}
			else {
				let gearVM: GearVM = GearVM()
				let bikes = gearVM.listBikes()
				for bike in bikes {
					if bike.timeRetired.timeIntervalSince1970 == 0 {
						names.append(bike.name)
					}
				}
			}
		}
		return names
	}

	@objc func activityMetadataUpdated(notification: NSNotification) {
		if let data = notification.object as? Dictionary<String, AnyObject> {
			let requestUrl = data[KEY_NAME_URL] as? URL
			guard requestUrl != nil else {
				return
			}

			let activityId = ApiClient.shared.extractActivityIdParamFromUrl(requestUrl: requestUrl!)
			guard activityId != nil && activityId == self.activityId else {
				return
			}

			let activityName = data[PARAM_ACTIVITY_NAME]
			if activityName != nil {
				DispatchQueue.main.async {
					self.name = (activityName as? String)!
				}
			}

			let activityDesc = data[PARAM_ACTIVITY_DESCRIPTION]
			if activityDesc != nil {
				DispatchQueue.main.async {
					self.description = (activityDesc as? String)!
				}
			}
		}
	}

	@objc func activityPhotosListReceived(notification: NSNotification) {
		do {
			if let data = notification.object as? Dictionary<String, AnyObject> {
				let requestUrl = data[KEY_NAME_URL] as? URL
				guard requestUrl != nil else {
					return
				}
				
				let activityId = ApiClient.shared.extractActivityIdParamFromUrl(requestUrl: requestUrl!)
				guard activityId != nil && activityId == self.activityId else {
					return
				}

				if let responseData = data[KEY_NAME_RESPONSE_DATA] as? Data {
					if let responseDict = try JSONSerialization.jsonObject(with: responseData, options: []) as? Dictionary<String, Any> {
						if let photoIds = responseDict[PARAM_ACTIVITY_PHOTO_IDS] as? Array<String> {
							DispatchQueue.main.async {
								self.photoIds = photoIds
							}
						}
					}
				}
			}
		}
		catch {
		}
	}
	
	@objc func activityPhotosUpdated(notification: NSNotification) {
		// Retrieve photo URLs.
		let _ = ApiClient.shared.requestActivityPhotos(activityId: self.activityId)
	}
}
