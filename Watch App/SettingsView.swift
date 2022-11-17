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

	var body: some View {
		VStack(alignment: .center) {
			ScrollView() {
				Group() {
					Text("Units")
						.bold()
					Toggle("Metric", isOn: $preferMetric)
						.onChange(of: preferMetric) { value in
							Preferences.setPreferredUnitSystem(system: value ? UNIT_SYSTEM_METRIC : UNIT_SYSTEM_US_CUSTOMARY)
							SetPreferredUnitSystem(Preferences.preferredUnitSystem()) // Update the backend
						}
						.padding(5)
				}
				
				Group() {
					Text("Broadcast")
						.bold()
					Toggle("Broadcast", isOn: $broadcastEnabled)
						.onChange(of: broadcastEnabled) { value in
							Preferences.setBroadcastToServer(value: broadcastEnabled)
						}
						.padding(5)
				}
				
				Group() {
					Text("Sensors")
						.bold()
					Toggle("Heart Rate", isOn: $heartRateEnabled)
						.onChange(of: heartRateEnabled) { value in
							Preferences.setUseWatchHeartRate(value: heartRateEnabled)
						}
						.padding(5)
					Toggle("Bluetooth Sensors", isOn: $btSensorsEnabled)
						.onChange(of: btSensorsEnabled) { value in
							Preferences.setScanForSensors(value: btSensorsEnabled)
						}
						.padding(5)
				}
				
				Group() {
					Text("Sounds")
						.bold()
					Toggle("Run Split Beeps", isOn: $runSplitBeeps)
						.onChange(of: runSplitBeeps) { value in
							Preferences.setWatchRunSplitBeeps(value: runSplitBeeps)
						}
						.padding(5)
					Toggle("Start Stop Beeps", isOn: $startStopBeeps)
						.onChange(of: startStopBeeps) { value in
							Preferences.setWatchStartStopBeeps(value: startStopBeeps)
						}
						.padding(5)
				}
				
				Group() {
					Text("Screen")
						.bold()
					Toggle("Allow Presses During Activity", isOn: $allowPressesDuringActivity)
						.onChange(of: allowPressesDuringActivity) { value in
							Preferences.setWatchAllowPressesDuringActivity(value: allowPressesDuringActivity)
						}
						.padding(5)
				}
			}
		}
		.padding(10)
    }
}
