//
//  SensorsView.swift
//  Created by Michael Simms on 9/29/22.
//

import SwiftUI

struct SensorsView: View {
	@State private var shouldScan: Bool = Preferences.shouldScanForSensors()
	@State private var sensors = SensorMgr.shared.listSensors()

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
					ForEach(Array(zip(self.sensors.indices, self.sensors)), id: \.1) { index, sensor in
						Toggle(sensor.name, isOn: self.$sensors[index].enabled)
							.onChange(of: sensor.enabled) { value in
								Preferences.addPeripheralToUse(uuid: sensor.id)
							}
					}
				}
			}
			.padding(10)
		}
    }
}
