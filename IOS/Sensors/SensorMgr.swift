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

class ThreatSummary : Codable, Identifiable, Hashable, Equatable {
	enum CodingKeys: CodingKey {
		case id
		case distance
	}
	
	var id: String = ""
	var distance: Double = 0.0
	
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
	static func == (lhs: ThreatSummary, rhs: ThreatSummary) -> Bool {
		return lhs.id == rhs.id
	}
}

class SensorSummary : Codable, Identifiable, Hashable, Equatable {
	enum CodingKeys: CodingKey {
		case id
		case name
		case enabled
	}
	
	var id: String = ""
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
	@Published var currentHeartRateBpm: UInt16 = 0
	@Published var currentPowerWatts: UInt16 = 0
	@Published var currentCadenceRpm: UInt16 = 0
	@Published var threatSummary: Array<ThreatSummary> = []
	@Published var heartRateConnected: Bool = false
	@Published var powerConnected: Bool = false
	@Published var cadenceConnected: Bool = false
	@Published var radarConnected: Bool = false

	/// Singleton constructor
	private init() {
	}

	/// Called when a peripheral is discovered.
	/// Returns true to indicate that we should connect to this peripheral and discover its services.
	func peripheralDiscovered(description: String) -> Bool {
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

	/// Called when a sensor characteristic is updated.
	func valueUpdated(peripheral: CBPeripheral, serviceId: CBUUID, value: Data) {
		if serviceId == HEART_RATE_SERVICE_ID {
			self.currentHeartRateBpm = decodeHeartRateReading(data: value)
		}
		else if serviceId == POWER_SERVICE_ID {
			self.currentPowerWatts = decodeCyclingPowerReading(data: value)
		}
		else if serviceId == CADENCE_SERVICE_ID {
			let cadenceData = decodeCyclingCadenceReading(data: value)
		}
		else if serviceId == RADAR_SERVICE_ID {
		}
	}

	func startSensors() {
		let interestingServices = [ CBUUID(data: BT_SERVICE_HEART_RATE),
									CBUUID(data: BT_SERVICE_CYCLING_POWER),
									CBUUID(data: BT_SERVICE_CYCLING_SPEED_AND_CADENCE),
									CBUUID(data: CUSTOM_BT_SERVICE_VARIA_RADAR) ]
		
		self.scanner.startScanningForServices(serviceIdsToScanFor: interestingServices,
											  peripheralCallbacks: [peripheralDiscovered],
											  serviceCallbacks: [serviceDiscovered],
											  valueUpdatedCallbacks: [valueUpdated])

		self.location.start()
		self.accelerometer.start()
	}

	func stopSensors() {
		self.scanner.stopScanning()
		self.location.stop()
		self.accelerometer.stop()
	}
	
	func listSensors() -> Array<SensorSummary> {
		return []
	}
}
