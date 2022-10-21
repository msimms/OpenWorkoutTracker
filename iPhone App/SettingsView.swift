//
//  SettingsView.swift
//  Created by Michael Simms on 9/20/22.
//

import SwiftUI

struct SettingsView: View {
	private var apiClient = ApiClient.shared
	@State private var preferMetric: Bool = false
	@State private var readActivitiesFromHealthKit: Bool = Preferences.willIntegrateHealthKitActivities()
	@State private var autoSaveActivitiesToICloudDrive: Bool = false
	@State private var hideDuplicateActivities: Bool = Preferences.hideHealthKitDuplicates()
	@State private var broadcastEnabled: Bool = Preferences.shouldBroadcastToServer()
	@State private var useHttps: Bool = true
	@State private var showBroadcastIcon: Bool = Preferences.broadcastShowIcon()
	@State private var broadcastServer: String = Preferences.broadcastHostName()
	@ObservedObject var updateRate = NumbersOnly(initialValue: Preferences.broadcastRate())

	var body: some View {
		VStack(alignment: .center) {
			Text("Units")
				.bold()
			VStack(alignment: .center) {
				Toggle("Metric", isOn: $preferMetric)
					.onChange(of: preferMetric) { value in
						Preferences.setPreferredUnitSystem(system: value ? UNIT_SYSTEM_METRIC : UNIT_SYSTEM_US_CUSTOMARY)
					}
			}
			.padding(5)

			Text("HealthKit")
				.bold()
			VStack(alignment: .center) {
				Toggle("Read Activities From HealthKit", isOn: $readActivitiesFromHealthKit)
					.onChange(of: readActivitiesFromHealthKit) { value in
						Preferences.setWillIntegrateHealthKitActivities(value: readActivitiesFromHealthKit)
					}
				Toggle("Hide Duplicate Activities", isOn: $hideDuplicateActivities)
					.onChange(of: hideDuplicateActivities) { value in
						Preferences.setHideHealthKitDuplicates(value: hideDuplicateActivities)
					}
			}
			.padding(5)

			Text("Cloud Services")
				.bold()
			VStack(alignment: .center) {
				Toggle("Auto Save Files to iCloud Drive", isOn: $autoSaveActivitiesToICloudDrive)
			}
			.padding(5)

			Text("Broadcast")
				.bold()
			VStack(alignment: .center) {
				Toggle("Enabled", isOn: $broadcastEnabled)
					.onChange(of: broadcastEnabled) { value in
						Preferences.setBroadcastToServer(value: broadcastEnabled)
					}
				HStack() {
					Text("Update Rate")
					Spacer()
					TextField("Seconds", text: $updateRate.value)
						.keyboardType(.decimalPad)
						.multilineTextAlignment(.trailing)
						.fixedSize()
						.onChange(of: updateRate.value) { value in
							if let value = Int(updateRate.value) {
								Preferences.setBroadcastRate(value: value)
							} else {
							}
						}
					Text(" seconds")
				}
				Toggle("Use HTTPS", isOn: $useHttps)
					.onChange(of: useHttps) { value in
						Preferences.setBroadcastProtocol(value: value ? "https" : "http")
					}
				HStack() {
					Text("Broadcast Server")
					Spacer()
					TextField("Server", text: $broadcastServer)
						.keyboardType(.URL)
						.multilineTextAlignment(.trailing)
						.onChange(of: broadcastServer) { value in
							Preferences.setBroadcastHostName(value: broadcastServer)
						}
				}
				Toggle("Show Broadcast Icon", isOn: $showBroadcastIcon)
					.onChange(of: showBroadcastIcon) { value in
						Preferences.setBroadcastShowIcon(value: showBroadcastIcon)
					}
			}
			.padding(5)

			Spacer()
		}
		.padding(10)
		.toolbar {
			ToolbarItem(placement: .bottomBar) {
				HStack() {
					Button {
						//self.apiClient.login()
					} label: {
						Text("Login")
					}
				}
			}
		}
    }
}
