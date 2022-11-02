//
//  SensorsView.swift
//  Created by Michael Simms on 9/29/22.
//

import SwiftUI

struct SensorsView: View {
	@State private var shouldScan: Bool = Preferences.shouldScanForSensors()
	@State private var enabledSensors: Array<Bool> = []
	@ObservedObject var sensorMgr = SensorMgr.shared

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
						Toggle(sensor.name, isOn: sensor.$enabled)
							.onChange(of: sensor.enabled) { value in
//								Preferences.addPeripheralToUse(uuid: sensor.id)
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
