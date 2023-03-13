//
//  SettingsView.swift
//  Created by Michael Simms on 9/20/22.
//

import SwiftUI

struct SettingsView: View {
	@Environment(\.dismiss) var dismiss
	@State private var broadcastEnabled: Bool = Preferences.shouldBroadcastToServer()
	@State private var preferMetric: Bool = Preferences.preferredUnitSystem() == UNIT_SYSTEM_METRIC
	@State private var heartRateEnabled: Bool = Preferences.useWatchHeartRate()
	@State private var btSensorsEnabled: Bool = Preferences.shouldScanForSensors()
	@State private var runSplitBeeps: Bool = Preferences.watchRunSplitBeeps()
	@State private var startStopBeeps: Bool = Preferences.watchStartStopBeeps()
	@State private var allowPressesDuringActivity: Bool = Preferences.watchAllowPressesDuringActivity()
	@State private var turnCrown: Bool = Preferences.watchTurnCrownToStartStopActivity()
	@State private var showingResetConfirmation: Bool = false

	var body: some View {
		VStack(alignment: .center) {
			ScrollView() {
				Group() {
					Text("Units")
						.bold()
					Toggle("Metric", isOn: self.$preferMetric)
						.onChange(of: self.preferMetric) { value in
							Preferences.setPreferredUnitSystem(system: value ? UNIT_SYSTEM_METRIC : UNIT_SYSTEM_US_CUSTOMARY)
							SetPreferredUnitSystem(Preferences.preferredUnitSystem()) // Update the backend
						}
						.padding(5)
				}
				
				Group() {
					Text("Broadcast")
						.bold()
					Toggle("Broadcast", isOn: self.$broadcastEnabled)
						.onChange(of: self.broadcastEnabled) { value in
							Preferences.setBroadcastToServer(value: self.broadcastEnabled)
						}
						.padding(5)
				}
				
				Group() {
					Text("Sensors")
						.bold()
					Toggle("Heart Rate", isOn: self.$heartRateEnabled)
						.onChange(of: self.heartRateEnabled) { value in
							Preferences.setUseWatchHeartRate(value: self.heartRateEnabled)
							
							// If we are currently subscribed to the heart rate query, then unsubscribe.
							if value == false {
								HealthManager.shared.unsubscribeFromHeartRateUpdates()
							}
						}
						.padding(5)
					Toggle("Bluetooth Sensors", isOn: self.$btSensorsEnabled)
						.onChange(of: self.btSensorsEnabled) { value in
							Preferences.setScanForSensors(value: self.btSensorsEnabled)
						}
						.padding(5)
				}
				
				Group() {
					Text("Sounds")
						.bold()
					Toggle("Run Split Beeps", isOn: self.$runSplitBeeps)
						.onChange(of: self.runSplitBeeps) { value in
							Preferences.setWatchRunSplitBeeps(value: self.runSplitBeeps)
						}
						.padding(5)
					Toggle("Start Stop Beeps", isOn: self.$startStopBeeps)
						.onChange(of: self.startStopBeeps) { value in
							Preferences.setWatchStartStopBeeps(value: self.startStopBeeps)
						}
						.padding(5)
				}
				
				Group() {
					Text("Screen")
						.bold()
					Toggle("Allow Presses During Activity", isOn: self.$allowPressesDuringActivity)
						.onChange(of: self.allowPressesDuringActivity) { value in
							Preferences.setWatchAllowPressesDuringActivity(value: self.allowPressesDuringActivity)
						}
						.padding(5)
					Toggle("Turn Crown To Start / Stop Activity", isOn: self.$turnCrown)
						.onChange(of: self.turnCrown) { value in
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
		.padding(10)
    }
}
