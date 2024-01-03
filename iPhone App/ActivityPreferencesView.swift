//
//  ActivityPreferencesView.swift
//  Created by Michael Simms on 10/13/22.
//

import SwiftUI

let PREFS_INSET = EdgeInsets(top: 0, leading: 0, bottom: 10, trailing: 0)

struct ActivityPreferencesView: View {
	var activityType: String = ""
	var colorNames: Array<String> = [COLOR_NAME_WHITE, COLOR_NAME_GRAY, COLOR_NAME_BLACK, COLOR_NAME_RED, COLOR_NAME_GREEN, COLOR_NAME_BLUE, COLOR_NAME_YELLOW]

	@State private var screenAutoLocking: Bool
	@State private var allowScreenPresses: Bool
	@State private var countdownTimer: Bool
	@State private var showHeartRateAsPercentage: Bool
	@State private var backgroundColorName = ""
	@State private var labelColorName = ""
	@State private var textColorName = ""
	@State private var startStopBeep: Bool
	@State private var splitBeep: Bool
	@State private var horizontalAccuracy: NumbersOnly
	@State private var verticalAccuracy: NumbersOnly
	@State private var showThreatSpeed: Bool
	@State private var showingBackgroundColorSelection: Bool = false
	@State private var showingLabelColorSelection: Bool = false
	@State private var showingTextColorSelection: Bool = false
	@State private var showingBadLocationFilter: Bool = false

	init(activityType: String) {
		self.activityType = activityType

		self.screenAutoLocking = ActivityPreferences.getScreenAutoLocking(activityType: activityType)
		self.allowScreenPresses = ActivityPreferences.getAllowScreenPressesDuringActivity(activityType: activityType)
		self.countdownTimer = ActivityPreferences.getCountdown(activityType: activityType)
		self.showHeartRateAsPercentage = ActivityPreferences.getShowHeartRatePercent(activityType: activityType)

		self.backgroundColorName = ActivityPreferences.getBackgroundColorName(activityType: activityType)
		self.labelColorName = ActivityPreferences.getLabelColorName(activityType: activityType)
		self.textColorName = ActivityPreferences.getTextColorName(activityType: activityType)

		self.startStopBeep = ActivityPreferences.getStartStopBeepEnabled(activityType: activityType)
		self.splitBeep = ActivityPreferences.getSplitBeepEnabled(activityType: activityType)

		self.horizontalAccuracy = NumbersOnly(initialValue: ActivityPreferences.getMinLocationHorizontalAccuracy(activityType: activityType))
		self.verticalAccuracy = NumbersOnly(initialValue: ActivityPreferences.getMinLocationVerticalAccuracy(activityType: activityType))

		self.showThreatSpeed = ActivityPreferences.getShowThreatSpeed(activityType: activityType)
	}

	var body: some View {
		VStack(alignment: .center) {
			Group() {
				Text("Default Layout")
					.bold()
				Toggle("Screen Auto-Locking", isOn: self.$screenAutoLocking)
					.onChange(of: screenAutoLocking) { value in
						ActivityPreferences.setScreenAutoLocking(activityType: self.activityType, value: value)
					}
				Toggle("Allow Screen Presses During Activity", isOn: self.$allowScreenPresses)
					.onChange(of: allowScreenPresses) { value in
						ActivityPreferences.setAllowScreenPressesDuringActivity(activityType: self.activityType, value: value)
					}
				Toggle("Countdown Timer", isOn: self.$countdownTimer)
					.onChange(of: countdownTimer) { value in
						ActivityPreferences.setCountdown(activityType: self.activityType, value: value)
					}
				Toggle("Show Heart Rate as Percentage", isOn: self.$showHeartRateAsPercentage)
					.onChange(of: showHeartRateAsPercentage) { value in
						ActivityPreferences.setShowHeartRatePercent(activityType: self.activityType, value: value)
					}
			}
			Group() {
				Text("Colors")
					.bold()
				HStack() {
					Text("Background Color")
					Spacer()
					Button(ActivityPreferences.getBackgroundColorName(activityType: self.activityType)) {
						self.showingBackgroundColorSelection = true
					}
					.confirmationDialog("Which color?", isPresented: self.$showingBackgroundColorSelection, titleVisibility: .visible) {
						ForEach(self.colorNames, id: \.self) { item in
							Button(item) {
								ActivityPreferences.setBackgroundColor(activityType: self.activityType, colorName: item)
							}
						}
					}
					.padding(PREFS_INSET)
				}
				HStack() {
					Text("Label Color")
					Spacer()
					Button(ActivityPreferences.getLabelColorName(activityType: self.activityType)) {
						self.showingLabelColorSelection = true
					}
					.confirmationDialog("Which color?", isPresented: self.$showingLabelColorSelection, titleVisibility: .visible) {
						ForEach(self.colorNames, id: \.self) { item in
							Button(item) {
								ActivityPreferences.setLabelColor(activityType: self.activityType, colorName: item)
							}
						}
					}
					.padding(PREFS_INSET)
				}
				HStack() {
					Text("Text Color")
					Spacer()
					Button(ActivityPreferences.getTextColorName(activityType: self.activityType)) {
						self.showingTextColorSelection = true
					}
					.confirmationDialog("Which color?", isPresented: self.$showingTextColorSelection, titleVisibility: .visible) {
						ForEach(self.colorNames, id: \.self) { item in
							Button(item) {
								ActivityPreferences.setTextColor(activityType: self.activityType, colorName: item)
							}
						}
					}
					.padding(PREFS_INSET)
				}
			}
			Group() {
				Text("Sounds")
					.bold()
				Toggle("Start/Stop Beep", isOn: self.$startStopBeep)
					.onChange(of: startStopBeep) { value in
						ActivityPreferences.setStartStopBeepEnabled(activityType: self.activityType, value: value)
					}
				Toggle("Split Beep", isOn: self.$splitBeep)
					.onChange(of: splitBeep) { value in
						ActivityPreferences.setSplitBeepEnabled(activityType: self.activityType, value: value)
					}
			}
			Group() {
				Text("Location")
					.bold()
				HStack() {
					Text("Horizontal Accuracy")
					Spacer()
					TextField("Distance", text: self.$horizontalAccuracy.value)
						.keyboardType(.decimalPad)
						.multilineTextAlignment(.trailing)
						.fixedSize()
						.onChange(of: self.horizontalAccuracy.value) { value in
						}
					Text("Meters")
				}
				HStack() {
					Text("Vertical Accuracy")
					Spacer()
					TextField("Distance", text: self.$verticalAccuracy.value)
						.keyboardType(.decimalPad)
						.multilineTextAlignment(.trailing)
						.fixedSize()
						.onChange(of: self.verticalAccuracy.value) { value in
						}
					Text("Meters")
				}
				HStack() {
					Text("Bad Location Filter")
					Spacer()
					Button(ActivityPreferences.getLocationFilterOption(activityType: self.activityType) == LocationFilterOption.LOCATION_FILTER_WARN ? "Warn" : "Discard") {
						self.showingBadLocationFilter = true
					}
					.confirmationDialog("What should be done with bad location points?", isPresented: $showingBadLocationFilter, titleVisibility: .visible) {
						Button("Warn") {
							ActivityPreferences.setLocationFilterOption(activityType: self.activityType, option: LocationFilterOption.LOCATION_FILTER_WARN)
						}
						Button("Discard") {
							ActivityPreferences.setLocationFilterOption(activityType: self.activityType, option: LocationFilterOption.LOCATION_FILTER_DROP)
						}
					}
				}
			}
		/*	Group() {
				Text("Radar")
					.bold()
				Toggle("Show Threat Speed", isOn: self.$showThreatSpeed)
					.onChange(of: showThreatSpeed) { value in
						ActivityPreferences.setShowThreatSpeed(activityType: self.activityType, value: value)
					}
			} */
		}
		.padding(10)
    }
}
