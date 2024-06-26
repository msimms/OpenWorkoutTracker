//
//  SensorMgr.swift
//  Created by Michael Simms on 9/29/22.
//

import Foundation
import CoreBluetooth
import SwiftUI

let HEART_RATE_SERVICE_ID = CBUUID(data: BT_SERVICE_HEART_RATE)
let POWER_SERVICE_ID = CBUUID(data: BT_SERVICE_CYCLING_POWER)
let CADENCE_SERVICE_ID = CBUUID(data: BT_SERVICE_CYCLING_SPEED_AND_CADENCE)
let RUNNING_POWER_SERVICE_ID = CBUUID(data: BT_SERVICE_RUNNING_SPEED_AND_CADENCE)
let RADAR_SERVICE_ID = CBUUID(data: CUSTOM_BT_SERVICE_VARIA_RADAR)

class PeripheralSummary : Identifiable {
	var id: UUID = UUID()
	var name: String = ""
	var peripheral: CBPeripheral! = nil
	var services: Array<CBUUID> = []
	var enabled: Bool = false
	var lastUpdatedTime: time_t = 0
}

class SensorMgr : ObservableObject {
	static let shared = SensorMgr()

	var scanner: BluetoothScanner = BluetoothScanner()
	var accelerometer: Accelerometer = Accelerometer()
	var location: LocationSensor = LocationSensor()
	@Published var peripherals: Array<PeripheralSummary> = []
	@Published var currentHeartRateBpm: UInt16 = 0
	@Published var currentPowerWatts: UInt16 = 0
	@Published var currentCadenceRpm: UInt16 = 0
	@Published var radarMeasurements: Array<RadarMeasurement> = []
	@Published var heartRateConnected: Bool = false
	@Published var powerConnected: Bool = false
	@Published var cadenceConnected: Bool = false
	@Published var runningPowerConnected: Bool = false
	@Published var radarConnected: Bool = false
	private var lastCrankCount: UInt16 = 0
	private var lastCrankCountTime: UInt64 = 0
	private var lastCadenceUpdateTimeMs: UInt64 = 0
	private var firstCadenceUpdate: Bool = true
	@Published var lastHrmUpdate: UInt64 = 0
	@Published var lastPowerUpdate: UInt64 = 0
	@Published var lastRadarUpdate: UInt64 = 0
	@Published var lastRunningPowerUpdate: UInt64 = 0

	/// Singleton constructor
	private init() {
	}

	func displayMessage(text: String) {
		var notificationData: Dictionary<String, String> = [:]
		notificationData[KEY_NAME_MESSAGE] = text
		let notification = Notification(name: Notification.Name(rawValue: NOTIFICATION_NAME_PRINT_MESSAGE), object: notificationData)
		NotificationCenter.default.post(notification)
	}

	/// Called when a peripheral is discovered.
	/// Returns true to indicate that we should connect to this peripheral and discover its services.
	func peripheralDiscovered(peripheral: CBPeripheral, name: String) -> Bool {
		var found: Bool = false
		var shouldDiscoverServices: Bool = false

		for existingPeripheral in self.peripherals {
			if existingPeripheral.name == name {
				found = true
				shouldDiscoverServices = existingPeripheral.enabled
				break
			}
		}

		if !found {
			let summary = PeripheralSummary()
			summary.id = peripheral.identifier
			summary.name = name
			summary.peripheral = peripheral
			summary.enabled = Preferences.shouldUsePeripheral(uuid: summary.id.uuidString)
			summary.lastUpdatedTime = time(nil)
			shouldDiscoverServices = summary.enabled
			self.peripherals.append(summary)
			self.displayMessage(text: name + (shouldDiscoverServices ? " connected" : " discovered"))
		}
		return shouldDiscoverServices
	}

	/// Called when a service is discovered.
	func serviceDiscovered(peripheral: CBPeripheral, serviceId: CBUUID) {
		var foundPeripheral: Bool = false
		var foundService: Bool = false

		for existingPeripheral in self.peripherals {
			if existingPeripheral.peripheral == peripheral && existingPeripheral.enabled {
				for existingServiceId in existingPeripheral.services {
					if existingServiceId == serviceId {
						foundService = true
					}
				}
				if !foundService {
					existingPeripheral.services.append(serviceId)
				}
				foundPeripheral = true
				break
			}
		}

		if foundPeripheral {
			if serviceId == HEART_RATE_SERVICE_ID {
				self.heartRateConnected = true
			}
			else if serviceId == POWER_SERVICE_ID {
				self.powerConnected = true
				self.cadenceConnected = true
			}
			else if serviceId == CADENCE_SERVICE_ID {
				self.cadenceConnected = true
			}
			else if serviceId == RUNNING_POWER_SERVICE_ID {
				self.runningPowerConnected = true
			}
			else if serviceId == RADAR_SERVICE_ID {
				self.radarConnected = true
			}
		}
	}

	func calculateCadence(curTimeMs: UInt64, currentCrankCount: UInt16, currentCrankTime: UInt64) {
		let msSinceLastUpdate = curTimeMs - self.lastCadenceUpdateTimeMs
		var elapsedSecs: Double = 0.0

		// Sensor has reset
		if currentCrankCount == 0 || currentCrankTime == 0 {
			self.firstCadenceUpdate = true
		}
	
		// Handle wrap-around
		if currentCrankTime >= self.lastCrankCountTime { // normal case
			elapsedSecs = Double(currentCrankTime - self.lastCrankCountTime) / 1024.0
		}
		else {
			let temp: UInt32 = 0x0000ffff + (UInt32(currentCrankTime) << 16)
			elapsedSecs = Double(temp - UInt32(self.lastCrankCountTime)) / 1024.0
		}
		
		// Compute the cadence (zero on the first iteration).
		if self.firstCadenceUpdate {
			self.currentCadenceRpm = 0
		}
		else if elapsedSecs > 0.1 {
			var newCrankCount: UInt16 = 0

			// Check for rollover.
			if currentCrankCount >= self.lastCrankCount {
				newCrankCount = currentCrankCount - self.lastCrankCount
			}
			else {
				newCrankCount = currentCrankCount
			}
			self.currentCadenceRpm = UInt16((Double(newCrankCount) / elapsedSecs) * 60.0)
			self.lastCadenceUpdateTimeMs = curTimeMs
		}
		
		// Handle cases where it has been a while since our last update (i.e. the crank is either not
		// turning or is turning very slowly).
		if msSinceLastUpdate >= 3000 {
			self.currentCadenceRpm = 0
		}
		
		self.firstCadenceUpdate = false
		self.lastCrankCount = currentCrankCount
		self.lastCrankCountTime = currentCrankTime
	}

	/// Called when a sensor characteristic is updated.
	func valueUpdated(peripheral: CBPeripheral, serviceId: CBUUID, value: Data) {
		if Preferences.shouldUsePeripheral(uuid: peripheral.identifier.uuidString) {
			let now = UInt64(Date().timeIntervalSince1970)
			let hrTimeDiff = now - self.lastHrmUpdate
			let powerTimeDiff = now - self.lastPowerUpdate
			let radarTimeDiff = now - self.lastRadarUpdate

			do {
				if serviceId == HEART_RATE_SERVICE_ID {
					if hrTimeDiff >= 1 {
						let currentReading = decodeHeartRateReading(data: value)
						self.heartRateConnected = true

						// Filthy hack to deal with some heart rate monitors that don't comply with the spec
						if currentReading > 10 {
							self.lastHrmUpdate = now
							self.currentHeartRateBpm = currentReading
							ProcessHrmReading(Double(self.currentHeartRateBpm), self.lastHrmUpdate)
						}
					}
				}
				else if serviceId == POWER_SERVICE_ID {
					if powerTimeDiff >= 1 {
						let powerDict = try decodeCyclingPowerReadingAsDict(data: value)

						if  let currentPower = powerDict[KEY_NAME_CYCLING_POWER_WATTS] {
							self.currentPowerWatts = UInt16(currentPower)
							self.lastPowerUpdate = now
							self.powerConnected = true
							ProcessPowerMeterReading(Double(self.currentPowerWatts), self.lastPowerUpdate)
						}
						
						// Power meters often send cadence data as well.
						if  let currentCrankCount = powerDict[KEY_NAME_CYCLING_POWER_CRANK_REVS],
							let currentCrankTime = powerDict[KEY_NAME_CYCLING_POWER_LAST_CRANK_TIME] {
							let timestamp = now * 1000

							self.calculateCadence(curTimeMs: UInt64(timestamp), currentCrankCount: UInt16(currentCrankCount), currentCrankTime: UInt64(currentCrankTime))
							ProcessCadenceReading(Double(self.currentCadenceRpm), now)
						}
					}
				}
				else if serviceId == CADENCE_SERVICE_ID {
					let cadenceData = try decodeCyclingCadenceReading(data: value)

					if  let currentCrankCount = cadenceData[KEY_NAME_WHEEL_CRANK_COUNT],
						let currentCrankTime = cadenceData[KEY_NAME_WHEEL_CRANK_TIME] {
						let timestamp = now * 1000

						self.calculateCadence(curTimeMs: UInt64(timestamp), currentCrankCount: UInt16(currentCrankCount), currentCrankTime: UInt64(currentCrankTime))
						ProcessCadenceReading(Double(self.currentCadenceRpm), now)
					}
				}
				else if serviceId == RUNNING_POWER_SERVICE_ID {
					self.lastRunningPowerUpdate = now
				}
				else if serviceId == RADAR_SERVICE_ID {
					if radarTimeDiff >= 1 {
						self.radarMeasurements = decodeCyclingRadarReading(data: value)
						self.lastRadarUpdate = now
						self.radarConnected = true
						ProcessRadarReading(UInt(self.radarMeasurements.count), self.lastRadarUpdate)
					}
				}
				
				// Look for lost sensors, perhaps ones that didn't disconnect properly.
				if hrTimeDiff > 30 {
					self.heartRateConnected = false
				}
				if powerTimeDiff > 30 {
					self.powerConnected = false
				}
				if radarTimeDiff > 30 {
					self.radarConnected = false
				}
			}
			catch {
				NSLog(error.localizedDescription)
			}
		}
	}

	/// Called when a peripheral disconnects.
	func peripheralDisconnected(peripheral: CBPeripheral) {
		var removed: Bool = false
		
		for (index, existingPeripheral) in self.peripherals.enumerated() {
			if existingPeripheral.peripheral == peripheral && existingPeripheral.enabled {
				self.peripherals.remove(at: index)
				self.displayMessage(text: existingPeripheral.name + " disconnected")
				removed = true
				break
			}
		}
		
		if removed {
			var tempHeartRateConnected: Bool = false
			var tempPowerConnected: Bool = false
			var tempCadenceConnected: Bool = false
			var tempRunningPowerConnected: Bool = false
			var tempRadarConnected: Bool = false

			// Rebuild the list of connected and enabled services.
			for existingPeripheral in self.peripherals {
				for serviceId in existingPeripheral.services {
					if serviceId == HEART_RATE_SERVICE_ID {
						tempHeartRateConnected = true
					}
					else if serviceId == POWER_SERVICE_ID {
						tempPowerConnected = true
					}
					else if serviceId == CADENCE_SERVICE_ID {
						tempCadenceConnected = true
					}
					else if serviceId == RUNNING_POWER_SERVICE_ID {
						tempRunningPowerConnected = true
					}
					else if serviceId == RADAR_SERVICE_ID {
						tempRadarConnected = true
					}
				}
			}

			self.heartRateConnected = tempHeartRateConnected
			self.powerConnected = tempPowerConnected
			self.cadenceConnected = tempCadenceConnected
			self.runningPowerConnected = tempRunningPowerConnected
			self.radarConnected = tempRadarConnected
		}
	}

	func startSensors(usableSensors: Array<SensorType>) {
		if Preferences.shouldScanForSensors() {
			let interestingServices = [ HEART_RATE_SERVICE_ID,
										POWER_SERVICE_ID,
										CADENCE_SERVICE_ID,
										RUNNING_POWER_SERVICE_ID,
										RADAR_SERVICE_ID ]

			self.scanner.startScanningForServices(serviceIdsToScanFor: interestingServices,
												  peripheralDiscoveredCallbacks: [peripheralDiscovered],
												  serviceCallbacks: [serviceDiscovered],
												  valueUpdatedCallbacks: [valueUpdated],
												  peripheralDisconnectedCallbacks: [peripheralDisconnected])
		}
		
		let useLocation = usableSensors.count == 0 || usableSensors.contains(SENSOR_TYPE_LOCATION)
		let useAccelerometer = usableSensors.count == 0 || usableSensors.contains(SENSOR_TYPE_ACCELEROMETER)

		if useLocation {
			self.location.start()
		}
		if useAccelerometer {
			self.accelerometer.start()
		}

#if os(watchOS)
		if Preferences.useWatchHeartRate() {
			let healthMgr = HealthManager.shared
			healthMgr.subscribeToHeartRateUpdates()
		}
#endif
	}

	func stopSensors() {
		self.scanner.stopScanning()
		self.location.stop()
		self.accelerometer.stop()

#if os(watchOS)
		let healthMgr = HealthManager.shared
		healthMgr.unsubscribeFromHeartRateUpdates()
#endif
	}
}
