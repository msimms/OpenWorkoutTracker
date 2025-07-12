//
//  SettingsView.swift
//  Created by Michael Simms on 9/20/22.
//

import SwiftUI

struct SettingsView: View {
	@State private var broadcastEnabled: Bool = Preferences.shouldBroadcastToServer()
	@State private var preferMetric: Bool = Preferences.preferredUnitSystem() == UNIT_SYSTEM_METRIC
	@State private var heartRateEnabled: Bool = Preferences.useWatchHeartRate()
	@State private var btSensorsEnabled: Bool = Preferences.shouldScanForSensors()
	@State private var runSplitBeeps: Bool = Preferences.watchRunSplitBeeps()
	@State private var startStopBeeps: Bool = Preferences.watchStartStopBeeps()
	@State private var allowPressesDuringActivity: Bool = Preferences.watchAllowPressesDuringActivity()
	@State private var turnCrown: Bool = Preferences.watchTurnCrownToStartStopActivity()
	@State private var showingResetConfirmation: Bool = false
	@StateObject private var sensorMgr = SensorMgr.shared

	var body: some View {
		VStack(alignment: .center) {
			ScrollView() {
				Group() {
					Text("Units")
						.bold()
					Toggle("Metric", isOn: self.$preferMetric)
						.onChange(of: self.preferMetric) { _, value in
							Preferences.setPreferredUnitSystem(system: value ? UNIT_SYSTEM_METRIC : UNIT_SYSTEM_US_CUSTOMARY)
							SetPreferredUnitSystem(Preferences.preferredUnitSystem()) // Update the backend
						}
						.padding(5)
				}
				
				Group() {
					Text("Broadcast")
						.bold()
					Toggle("Broadcast", isOn: self.$broadcastEnabled)
						.onChange(of: self.broadcastEnabled) { _, value in
							Preferences.setBroadcastToServer(value: self.broadcastEnabled)
						}
						.padding(5)
				}
				
				Group() {
					Text("Sensors")
						.bold()
					Toggle("Heart Rate", isOn: self.$heartRateEnabled)
						.onChange(of: self.heartRateEnabled) { _, value in
							Preferences.setUseWatchHeartRate(value: self.heartRateEnabled)
							
							// If we are currently subscribed to the heart rate query, then unsubscribe.
							if value == false {
								HealthManager.shared.unsubscribeFromHeartRateUpdates()
							}
						}
						.padding(5)
					Toggle("Bluetooth Sensors", isOn: self.$btSensorsEnabled)
						.onChange(of: self.btSensorsEnabled) { _, value in
							Preferences.setScanForSensors(value: self.btSensorsEnabled)
							if self.btSensorsEnabled {
								SensorMgr.shared.startSensors(usableSensors: [])
							}
							else {
								SensorMgr.shared.stopSensors()
							}
						}
						.padding(5)
					ForEach(self.sensorMgr.peripherals) { sensor in
						HStack() {
							Text(sensor.name)
							Spacer()
							Button(sensor.enabled ? "Disconnect" : "Connect") {
								sensor.enabled = !sensor.enabled
								if sensor.enabled {
									Preferences.addPeripheralToUse(uuid: sensor.id.uuidString)
								}
								else {
									Preferences.removePeripheralFromUseList(uuid: sensor.id.uuidString)
								}
							}
						}
					}
				}
				
				Group() {
					Text("Sounds")
						.bold()
					Toggle("Run Split Beeps", isOn: self.$runSplitBeeps)
						.onChange(of: self.runSplitBeeps) { _, value in
							Preferences.setWatchRunSplitBeeps(value: self.runSplitBeeps)
						}
						.padding(5)
					Toggle("Start Stop Beeps", isOn: self.$startStopBeeps)
						.onChange(of: self.startStopBeeps) { _, value in
							Preferences.setWatchStartStopBeeps(value: self.startStopBeeps)
						}
						.padding(5)
				}
				
				Group() {
					Text("Screen")
						.bold()
					Toggle("Allow Presses During Activity", isOn: self.$allowPressesDuringActivity)
						.onChange(of: self.allowPressesDuringActivity) { _, value in
							Preferences.setWatchAllowPressesDuringActivity(value: self.allowPressesDuringActivity)
						}
						.padding(5)
					Toggle("Turn Crown To Start / Stop Activity", isOn: self.$turnCrown)
						.onChange(of: self.turnCrown) { _, value in
							Preferences.setWatchTurnCrownToStartStopActivity(value: self.turnCrown)
						}
						.padding(5)
				}
				
				Group() {
					Button("Reset") {
						self.showingResetConfirmation = true
					}
					.alert("This will delete all of your data. Do you wish to continue? This cannot be undone.", isPresented:$showingResetConfirmation) {
						Button("Delete") {
							ResetDatabase()
						}
						Button("Cancel") {
						}
					}
				}
			}
		}
		.onAppear() {
			self.broadcastEnabled = Preferences.shouldBroadcastToServer()
			self.preferMetric = Preferences.preferredUnitSystem() == UNIT_SYSTEM_METRIC
			self.heartRateEnabled = Preferences.useWatchHeartRate()
			self.btSensorsEnabled = Preferences.shouldScanForSensors()
			self.runSplitBeeps = Preferences.watchRunSplitBeeps()
			self.startStopBeeps = Preferences.watchStartStopBeeps()
			self.allowPressesDuringActivity = Preferences.watchAllowPressesDuringActivity()
			self.turnCrown = Preferences.watchTurnCrownToStartStopActivity()
		}
		.padding(10)
    }
}
