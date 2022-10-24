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

	var body: some View {
		VStack(alignment: .center) {
			Toggle("Broadcast", isOn: $broadcastEnabled)
				.onChange(of: broadcastEnabled) { value in
					Preferences.setBroadcastToServer(value: broadcastEnabled)
				}
			Toggle("Metric", isOn: $preferMetric)
				.onChange(of: preferMetric) { value in
					Preferences.setPreferredUnitSystem(system: value ? UNIT_SYSTEM_METRIC : UNIT_SYSTEM_US_CUSTOMARY)
				}
			Toggle("Heart Rate", isOn: $heartRateEnabled)
				.onChange(of: heartRateEnabled) { value in
					Preferences.setUseWatchHeartRate(value: heartRateEnabled)
				}
			Toggle("Bluetooth Sensors", isOn: $btSensorsEnabled)
				.onChange(of: btSensorsEnabled) { value in
					Preferences.setScanForSensors(value: btSensorsEnabled)
				}
			Button("Close") {
				self.dismiss()
			}
			.bold()
		}
		.padding(10)
    }
}
