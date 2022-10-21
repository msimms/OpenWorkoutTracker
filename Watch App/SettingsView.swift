//
//  SettingsView.swift
//  Created by Michael Simms on 9/20/22.
//

import SwiftUI

struct SettingsView: View {
	@Environment(\.dismiss) var dismiss
	@State private var broadcastEnabled: Bool = false
	@State private var preferMetric: Bool = false
	@State private var heartRateEnabled: Bool = false
	@State private var btSensorsEnabled: Bool = false

	var body: some View {
		VStack(alignment: .center) {
			Toggle("Broadcast", isOn: $broadcastEnabled)
			Toggle("Metric", isOn: $preferMetric)
			Toggle("Heart Rate", isOn: $heartRateEnabled)
			Toggle("Bluetooth Sensors", isOn: $btSensorsEnabled)
			Button("Close") {
				self.dismiss()
			}
			.bold()
		}
		.padding(10)
    }
}
