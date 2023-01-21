//
//  SettingsView.swift
//  Created by Michael Simms on 9/20/22.
//

import SwiftUI

struct SettingsView: View {
	private var apiClient = ApiClient.shared
	private var app = CommonApp.shared
	@State private var preferMetric: Bool = Preferences.preferredUnitSystem() == UNIT_SYSTEM_METRIC
	@State private var readActivitiesFromHealthKit: Bool = Preferences.willIntegrateHealthKitActivities()
	@State private var autoSaveActivitiesToICloudDrive: Bool = Preferences.autoSaveToICloudDrive()
	@State private var hideDuplicateActivities: Bool = Preferences.hideHealthKitDuplicates()
	@State private var broadcastEnabled: Bool = Preferences.shouldBroadcastToServer()
	@State private var useHttps: Bool = Preferences.broadcastProtocol() == "https"
	@State private var showBroadcastIcon: Bool = Preferences.broadcastShowIcon()
	@State private var broadcastServer: String = Preferences.broadcastHostName()
	@State private var showingLogoutError: Bool = false
	@ObservedObject var updateRate = NumbersOnly(initialValue: Preferences.broadcastRate())

	var body: some View {
		VStack(alignment: .center) {
			Text("Units")
				.bold()
			VStack(alignment: .center) {
				Toggle("Metric", isOn: self.$preferMetric)
					.onChange(of: self.preferMetric) { value in
						Preferences.setPreferredUnitSystem(system: value ? UNIT_SYSTEM_METRIC : UNIT_SYSTEM_US_CUSTOMARY)
						SetPreferredUnitSystem(Preferences.preferredUnitSystem()) // Update the backend
					}
			}
			.padding(5)

			Text("HealthKit")
				.bold()
			VStack(alignment: .center) {
				Toggle("Read Activities From HealthKit", isOn: self.$readActivitiesFromHealthKit)
					.onChange(of: self.readActivitiesFromHealthKit) { value in
						Preferences.setWillIntegrateHealthKitActivities(value: self.readActivitiesFromHealthKit)
					}
				Toggle("Hide Duplicate Activities", isOn: self.$hideDuplicateActivities)
					.onChange(of: self.hideDuplicateActivities) { value in
						Preferences.setHideHealthKitDuplicates(value: self.hideDuplicateActivities)
					}
			}
			.padding(5)

			Text("Cloud Services")
				.bold()
			VStack(alignment: .center) {
				Toggle("Auto Save Files to iCloud Drive", isOn: self.$autoSaveActivitiesToICloudDrive)
					.onChange(of: self.autoSaveActivitiesToICloudDrive) { value in
						Preferences.setAutoSaveToICloudDrive(value: self.autoSaveActivitiesToICloudDrive)
					}
			}
			.padding(5)

			Text("Broadcast")
				.bold()
			VStack(alignment: .center) {
				Toggle("Enabled", isOn: self.$broadcastEnabled)
					.onChange(of: self.broadcastEnabled) { value in
						Preferences.setBroadcastToServer(value: self.broadcastEnabled)
						let _ = self.apiClient.isLoggedIn()
					}
				HStack() {
					Text("Update Rate")
					Spacer()
					TextField("Seconds", text: self.$updateRate.value)
						.keyboardType(.decimalPad)
						.multilineTextAlignment(.trailing)
						.fixedSize()
						.onChange(of: self.updateRate.value) { value in
							if let value = Int(self.updateRate.value) {
								Preferences.setBroadcastRate(value: value)
							} else {
							}
						}
					Text(" seconds")
				}
				Toggle("Use HTTPS", isOn: self.$useHttps)
					.onChange(of: self.useHttps) { value in
						Preferences.setBroadcastProtocol(value: value ? "https" : "http")
					}
				HStack() {
					Text("Broadcast Server")
					Spacer()
					TextField("Server", text: self.$broadcastServer)
						.keyboardType(.URL)
						.multilineTextAlignment(.trailing)
						.onChange(of: self.broadcastServer) { value in
							Preferences.setBroadcastHostName(value: self.broadcastServer)
						}
				}
				Toggle("Show Broadcast Icon", isOn: self.$showBroadcastIcon)
					.onChange(of: self.showBroadcastIcon) { value in
						Preferences.setBroadcastShowIcon(value: self.showBroadcastIcon)
					}
			}
			.padding(5)

			Spacer()

			HStack() {
				if Preferences.shouldBroadcastToServer() {
					if self.apiClient.loggedIn {
						Button {
							if !self.apiClient.logout() {
								self.showingLogoutError = true
							}
						} label: {
							Text("Logout")
								.foregroundColor(.white)
								.fontWeight(Font.Weight.heavy)
								.frame(minWidth: 0, maxWidth: .infinity)
								.padding()
						}
						.alert("Failed to logout.", isPresented: self.$showingLogoutError) {}
						.background(RoundedRectangle(cornerRadius: 10, style: .continuous))
						.opacity(0.8)
						.bold()
					}
					else {
						NavigationLink(destination: LoginView()) {
							Text("Login")
								.foregroundColor(.white)
								.fontWeight(Font.Weight.heavy)
								.frame(minWidth: 0, maxWidth: .infinity)
								.padding()
						}
						.background(RoundedRectangle(cornerRadius: 10, style: .continuous))
						.opacity(0.8)
						.bold()
					}
				}
			}
		}
		.padding(10)
    }
}
