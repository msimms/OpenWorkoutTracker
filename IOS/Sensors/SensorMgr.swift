//
//  SensorMgr.swift
//  Created by Michael Simms on 9/29/22.
//

import Foundation
import CoreBluetooth

let HEART_RATE_SERVICE_ID = CBUUID(data: BT_SERVICE_HEART_RATE)
let POWER_SERVICE_ID = CBUUID(data: BT_SERVICE_CYCLING_POWER)
let CADENCE_SERVICE_ID = CBUUID(data: BT_SERVICE_CYCLING_SPEED_AND_CADENCE)
let RADAR_SERVICE_ID = CBUUID(data: CUSTOM_BT_SERVICE_VARIA_RADAR)

class SensorSummary : Codable, Identifiable, Hashable, Equatable {
	enum CodingKeys: CodingKey {
		case id
		case name
		case enabled
	}
	
	var id: String = UUID().uuidString
	var name: String = ""
	var enabled: Bool = false

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
	static func == (lhs: SensorSummary, rhs: SensorSummary) -> Bool {
		return lhs.id == rhs.id
	}
}

class SensorMgr : ObservableObject {
	static let shared = SensorMgr()

	var scanner: BluetoothScanner = BluetoothScanner()
	var accelerometer: Accelerometer = Accelerometer()
	var location: LocationSensor = LocationSensor()
	@Published var sensors: Array<SensorSummary> = []
	@Published var currentHeartRateBpm: UInt16 = 0
	@Published var currentPowerWatts: UInt16 = 0
	@Published var currentCadenceRpm: UInt16 = 0
	@Published var radarMeasurements: Array<RadarMeasurement> = []
	@Published var heartRateConnected: Bool = false
	@Published var powerConnected: Bool = false
	@Published var cadenceConnected: Bool = false
	@Published var radarConnected: Bool = false
	private var lastCrankCount: UInt16 = 0
	private var lastCrankCountTime: UInt64 = 0
	private var lastCadenceUpdateTimeMs: UInt64 = 0
	private var firstCadenceUpdate: Bool = true

	/// Singleton constructor
	private init() {
	}

	/// Called when a peripheral is discovered.
	/// Returns true to indicate that we should connect to this peripheral and discover its services.
	func peripheralDiscovered(description: String) -> Bool {
		let summary = SensorSummary()
		summary.name = description
		self.sensors.append(summary)
		return true
	}

	/// Called when a service is discovered.
	func serviceDiscovered(serviceId: CBUUID) {
		if serviceId == HEART_RATE_SERVICE_ID {
			self.heartRateConnected = true
		}
		else if serviceId == POWER_SERVICE_ID {
			self.powerConnected = true
		}
		else if serviceId == CADENCE_SERVICE_ID {
			self.cadenceConnected = true
		}
		else if serviceId == RADAR_SERVICE_ID {
			self.radarConnected = true
		}
	}

	func calculateCadence(curTimeMs: UInt64, currentCrankCount: UInt16, currentCrankTime: UInt64) {
		let msSinceLastUpdate = curTimeMs - self.lastCadenceUpdateTimeMs
		var elapsedSecs: Double = 0.0
		
		if currentCrankTime >= self.lastCrankCountTime { // handle wrap-around
			elapsedSecs = Double(currentCrankTime - self.lastCrankCountTime) / 1024.0
		}
		else {
			let temp: UInt32 = 0x0000ffff + UInt32(currentCrankTime)
			elapsedSecs = Double(temp - UInt32(self.lastCrankCountTime)) / 1024.0
		}
		
		// Compute the cadence (zero on the first iteration).
		if self.firstCadenceUpdate {
			self.currentCadenceRpm = 0
		}
		else if elapsedSecs > 0.0 {
			let newCrankCount = currentCrankCount - self.lastCrankCount
			self.currentCadenceRpm = UInt16((Double(newCrankCount) / elapsedSecs) * 60.0)
		}
		
		// Handle cases where it has been a while since our last update (i.e. the crank is either not
		// turning or is turning very slowly).
		if msSinceLastUpdate >= 3000 {
			self.currentCadenceRpm = 0
		}
		
		self.lastCadenceUpdateTimeMs = curTimeMs
		self.firstCadenceUpdate = false
		self.lastCrankCount = currentCrankCount
		self.lastCrankCountTime = currentCrankTime
	}

	/// Called when a sensor characteristic is updated.
	func valueUpdated(peripheral: CBPeripheral, serviceId: CBUUID, value: Data) {
		do {
			if serviceId == HEART_RATE_SERVICE_ID {
				self.currentHeartRateBpm = decodeHeartRateReading(data: value)
				ProcessHrmReading(Double(self.currentHeartRateBpm), UInt64(Date().timeIntervalSince1970))
			}
			else if serviceId == POWER_SERVICE_ID {
				self.currentPowerWatts = try decodeCyclingPowerReading(data: value)
				ProcessPowerMeterReading(Double(self.currentPowerWatts), UInt64(Date().timeIntervalSince1970))
			}
			else if serviceId == CADENCE_SERVICE_ID {
				let cadenceData = try decodeCyclingCadenceReading(data: value)
				//let currentWheelRevCount = reading[KEY_NAME_WHEEL_REV_COUNT]
				let currentCrankCount = cadenceData[KEY_NAME_WHEEL_CRANK_COUNT]
				let currentCrankTime = cadenceData[KEY_NAME_WHEEL_CRANK_TIME]
				let timestamp = NSDate().timeIntervalSince1970
				self.calculateCadence(curTimeMs: UInt64(timestamp), currentCrankCount: UInt16(currentCrankCount!), currentCrankTime: UInt64(currentCrankTime!))
				ProcessCadenceReading(Double(self.currentCadenceRpm), UInt64(Date().timeIntervalSince1970))
			}
			else if serviceId == RADAR_SERVICE_ID {
				self.radarMeasurements = decodeCyclingRadarReading(data: value)
				ProcessRadarReading(UInt(self.radarMeasurements.count), UInt64(Date().timeIntervalSince1970))
			}
		} catch {
			print(error.localizedDescription)
		}
	}

	func startSensors() {
		if Preferences.shouldScanForSensors() {
			let interestingServices = [ CBUUID(data: BT_SERVICE_HEART_RATE),
										CBUUID(data: BT_SERVICE_CYCLING_POWER),
										CBUUID(data: BT_SERVICE_CYCLING_SPEED_AND_CADENCE),
										CBUUID(data: CUSTOM_BT_SERVICE_VARIA_RADAR) ]
			
			self.scanner.startScanningForServices(serviceIdsToScanFor: interestingServices,
												  peripheralCallbacks: [peripheralDiscovered],
												  serviceCallbacks: [serviceDiscovered],
												  valueUpdatedCallbacks: [valueUpdated])
		}

		self.location.start()
		self.accelerometer.start()
	}

	func stopSensors() {
		self.scanner.stopScanning()
		self.location.stop()
		self.accelerometer.stop()
	}
	
	func listSensors() -> Array<SensorSummary> {
		return self.sensors
	}
}
