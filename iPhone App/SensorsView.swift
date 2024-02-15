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
			VStack(alignment: .center) {
				HStack() {
					Image(systemName: "questionmark.circle")
					Text("Bluetooth heart rate monitors, cycling power meters, and cadence sensors can all be connected.")
				}
				.padding(INFO_INSETS)

				Toggle("Scan for compatible sensors", isOn: self.$shouldScan)
					.onChange(of: self.shouldScan) { value in
						Preferences.setScanForSensors(value: self.shouldScan)
						if self.shouldScan {
							SensorMgr.shared.startSensors(usableSensors: [])
						}
						else {
							SensorMgr.shared.stopSensors()
						}
					}
				Group() {
					Text("Sensors")
						.bold()
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
							.padding(5)
						}
					}
				}
			}
			.padding(10)
		}
		.onAppear() {
			self.shouldScan = Preferences.shouldScanForSensors()
			if self.shouldScan {
				SensorMgr.shared.startSensors(usableSensors: [])
			}
		}
		.onDisappear() {
			SensorMgr.shared.stopSensors()
		}
    }
}
