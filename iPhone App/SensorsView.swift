//
//  SensorsView.swift
//  Created by Michael Simms on 9/29/22.
//

import SwiftUI

struct SensorsView: View {
	@State private var shouldScan: Bool = Preferences.shouldScanForSensors()
	@StateObject private var sensorMgr = SensorMgr.shared

	var body: some View {
		ScrollView() {
			VStack() {
				Toggle("Scan for compatible sensors", isOn: $shouldScan)
					.onChange(of: shouldScan) { value in
						Preferences.setScanForSensors(value: shouldScan)
					}
				Group() {
					Text("Sensors")
						.bold()
					ForEach(self.sensorMgr.sensors) { sensor in
						HStack() {
							Text(sensor.name)
							Spacer()
							Button(sensor.enabled ? "Disconnect" : "Connect") {
								sensor.enabled = !sensor.enabled
//								Preferences.shouldUsePeripheral(uuid: sensor.id)
							}
							.padding(5)
						}
					}
				}
			}
			.padding(10)
		}
		.onAppear() {
			SensorMgr.shared.startSensors()
		}
		.onDisappear() {
			SensorMgr.shared.stopSensors()
		}
    }
}
