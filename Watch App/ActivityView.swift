//
//  ActivityView.swift
//  Created by Michael Simms on 9/20/22.
//

import SwiftUI

let MIN_CROWN_VALUE: Double = 1.0
let MAX_CROWN_VALUE: Double = MIN_CROWN_VALUE + 2.0

struct ActivityView: View {
	@Environment(\.dismiss) var dismiss
	@StateObject var activityVM: LiveActivityVM
	@StateObject private var pacePlansVM = PacePlansVM.shared
	@StateObject private var intervalSessionsVM = IntervalSessionsVM.shared
	@State private var showingStopSelection: Bool = false
	@State private var showingIntervalSessionSelection: Bool = false
	@State private var showingPacePlanSelection: Bool = false
	@State private var showingActivityAttributeSelection1: Bool = false
	@State private var showingActivityAttributeSelection2: Bool = false
	@State private var showingActivityAttributeSelection3: Bool = false
	@State private var showingActivityAttributeSelection4: Bool = false
	@State private var showingActivityAttributeSelection5: Bool = false
	@State private var showingActivityAttributeSelection6: Bool = false
	@State private var showingActivityAttributeSelection7: Bool = false
	@State private var showingActivityColorSelection1: Bool = false
	@State private var showingActivityColorSelection2: Bool = false
	@State private var showingActivityColorSelection3: Bool = false
	@State private var showingActivityColorSelection4: Bool = false
	@State private var showingActivityColorSelection5: Bool = false
	@State private var showingActivityColorSelection6: Bool = false
	@State private var showingActivityColorSelection7: Bool = false
	@State private var crownValue = MIN_CROWN_VALUE

	var activityType: String

	func selectAttributeToDisplay(position: Int) -> some View {
		return VStack() {
			Button("Cancel") {}
			ForEach(self.activityVM.getActivityAttributeNames(), id: \.self) { item in
				Button {
					self.activityVM.setDisplayedActivityAttributeName(position: position, attributeName: item)
				} label: {
					Text(item)
				}
			}
		}
	}
	
	func selectColorToUse(attributeName: String) -> some View {
		let colorNames: Array<String> = [COLOR_NAME_WHITE, COLOR_NAME_GRAY, COLOR_NAME_BLACK, COLOR_NAME_RED, COLOR_NAME_GREEN, COLOR_NAME_BLUE, COLOR_NAME_YELLOW]
		return VStack() {
			Button("Cancel") {}
			ForEach(colorNames, id: \.self) { colorName in
				Button {
					self.activityVM.setWatchActivityAttributeColor(attributeName: attributeName, colorName: colorName)
				} label: {
					Text(colorName)
				}
			}
		}
	}

	func getColorToUse(attributeName: String) -> Color {
		return self.activityVM.getWatchActivityAttributeColor(attributeName: attributeName)
	}

	var items: [GridItem] {
		Array(repeating: .init(.adaptive(minimum: 120)), count: 2)
	}

	var body: some View {
		ScrollView() {
			VStack(alignment: .center) {
				// Top item
				HStack() {
					Text(self.activityVM.value1).font(.system(size: 48))
						.onTapGesture {
							self.showingActivityAttributeSelection1 = Preferences.watchAllowPressesDuringActivity()
						}
						.onLongPressGesture(minimumDuration: 2) {
							self.showingActivityColorSelection1 = Preferences.watchAllowPressesDuringActivity()
						}
						.confirmationDialog("Select the attribute to display", isPresented: $showingActivityAttributeSelection1, titleVisibility: .visible) {
							selectAttributeToDisplay(position: 0)
						}
						.confirmationDialog("Select the color to use", isPresented: $showingActivityColorSelection1, titleVisibility: .visible) {
							selectColorToUse(attributeName: self.activityVM.title1)
						}
						.foregroundColor(getColorToUse(attributeName: self.activityVM.title1))
						.allowsTightening(true)
						.lineLimit(1)
						.minimumScaleFactor(0.75)
				}

				// Countdown timer
				if self.activityVM.countdownSecsRemaining > 0 {
					Image(systemName: String(format: "%u.circle.fill", self.activityVM.countdownSecsRemaining))
						.resizable()
						.frame(width: 128.0, height: 128.0)
				}
				
				// Normal view
				else {
					// Minor items
					LazyVGrid(columns: self.items, spacing: 20) {
						
						// Screen 1
						if self.crownValue < MIN_CROWN_VALUE + 1.0 {
							VStack() {
								Text(self.activityVM.title2).font(.system(size: 12))
								Text(self.activityVM.value2).font(.system(size: 24))
									.onTapGesture {
										self.showingActivityAttributeSelection2 = Preferences.watchAllowPressesDuringActivity()
									}
									.onLongPressGesture(minimumDuration: 2) {
										self.showingActivityColorSelection2 = Preferences.watchAllowPressesDuringActivity()
									}
									.confirmationDialog("Select the attribute to display", isPresented: $showingActivityAttributeSelection2, titleVisibility: .visible) {
										selectAttributeToDisplay(position: 1)
									}
									.confirmationDialog("Select the color to use", isPresented: $showingActivityColorSelection2, titleVisibility: .visible) {
										selectColorToUse(attributeName: self.activityVM.title2)
									}
									.foregroundColor(getColorToUse(attributeName: self.activityVM.title2))
									.allowsTightening(true)
									.lineLimit(1)
									.minimumScaleFactor(0.75)
								Text(self.activityVM.units2).font(.system(size: 12))
							}
							VStack() {
								Text(self.activityVM.title3).font(.system(size: 12))
								Text(self.activityVM.value3).font(.system(size: 24))
									.onTapGesture {
										self.showingActivityAttributeSelection3 = Preferences.watchAllowPressesDuringActivity()
									}
									.onLongPressGesture(minimumDuration: 2) {
										self.showingActivityColorSelection3 = Preferences.watchAllowPressesDuringActivity()
									}
									.confirmationDialog("Select the attribute to display", isPresented: $showingActivityAttributeSelection3, titleVisibility: .visible) {
										selectAttributeToDisplay(position: 2)
									}
									.confirmationDialog("Select the color to use", isPresented: $showingActivityColorSelection3, titleVisibility: .visible) {
										selectColorToUse(attributeName: self.activityVM.title3)
									}
									.foregroundColor(getColorToUse(attributeName: self.activityVM.title3))
									.allowsTightening(true)
									.lineLimit(1)
									.minimumScaleFactor(0.75)
								Text(self.activityVM.units3).font(.system(size: 12))
							}
						}

						// Screen 2
						else if self.crownValue >= MIN_CROWN_VALUE + 1.0 && self.crownValue < MIN_CROWN_VALUE + 2.0 {
							VStack() {
								Text(self.activityVM.title4).font(.system(size: 12))
								Text(self.activityVM.value4).font(.system(size: 24))
									.onTapGesture {
										self.showingActivityAttributeSelection4 = Preferences.watchAllowPressesDuringActivity()
									}
									.onLongPressGesture(minimumDuration: 2) {
										self.showingActivityColorSelection4 = Preferences.watchAllowPressesDuringActivity()
									}
									.confirmationDialog("Select the attribute to display", isPresented: $showingActivityAttributeSelection4, titleVisibility: .visible) {
										selectAttributeToDisplay(position: 3)
									}
									.confirmationDialog("Select the color to use", isPresented: $showingActivityColorSelection4, titleVisibility: .visible) {
										selectColorToUse(attributeName: self.activityVM.title4)
									}
									.foregroundColor(getColorToUse(attributeName: self.activityVM.title4))
									.allowsTightening(true)
									.lineLimit(1)
									.minimumScaleFactor(0.75)
								Text(self.activityVM.units4).font(.system(size: 12))
							}
							VStack() {
								Text(self.activityVM.title5).font(.system(size: 12))
								Text(self.activityVM.value5).font(.system(size: 24))
									.onTapGesture {
										self.showingActivityAttributeSelection5 = Preferences.watchAllowPressesDuringActivity()
									}
									.onLongPressGesture(minimumDuration: 2) {
										self.showingActivityColorSelection5 = Preferences.watchAllowPressesDuringActivity()
									}
									.confirmationDialog("Select the attribute to display", isPresented: $showingActivityAttributeSelection5, titleVisibility: .visible) {
										selectAttributeToDisplay(position: 4)
									}
									.confirmationDialog("Select the color to use", isPresented: $showingActivityColorSelection5, titleVisibility: .visible) {
										selectColorToUse(attributeName: self.activityVM.title5)
									}
									.foregroundColor(getColorToUse(attributeName: self.activityVM.title5))
									.allowsTightening(true)
									.lineLimit(1)
									.minimumScaleFactor(0.75)
								Text(self.activityVM.units5).font(.system(size: 12))
							}
						}

						// Screen 3
						else if self.crownValue >= MIN_CROWN_VALUE + 2.0 && self.crownValue < MIN_CROWN_VALUE + 3.0 {
							VStack() {
								Text(self.activityVM.title6).font(.system(size: 12))
								Text(self.activityVM.value6).font(.system(size: 24))
									.onTapGesture {
										self.showingActivityAttributeSelection6 = Preferences.watchAllowPressesDuringActivity()
									}
									.onLongPressGesture(minimumDuration: 2) {
										self.showingActivityColorSelection6 = Preferences.watchAllowPressesDuringActivity()
									}
									.confirmationDialog("Select the attribute to display", isPresented: $showingActivityAttributeSelection6, titleVisibility: .visible) {
										selectAttributeToDisplay(position: 5)
									}
									.confirmationDialog("Select the color to use", isPresented: $showingActivityColorSelection6, titleVisibility: .visible) {
										selectColorToUse(attributeName: self.activityVM.title6)
									}
									.foregroundColor(getColorToUse(attributeName: self.activityVM.title6))
									.allowsTightening(true)
									.lineLimit(1)
									.minimumScaleFactor(0.75)
								Text(self.activityVM.units6).font(.system(size: 12))
							}
							VStack() {
								Text(self.activityVM.title7).font(.system(size: 12))
								Text(self.activityVM.value7).font(.system(size: 24))
									.onTapGesture {
										self.showingActivityAttributeSelection7 = Preferences.watchAllowPressesDuringActivity()
									}
									.onLongPressGesture(minimumDuration: 2) {
										self.showingActivityColorSelection7 = Preferences.watchAllowPressesDuringActivity()
									}
									.confirmationDialog("Select the attribute to display", isPresented: $showingActivityAttributeSelection7, titleVisibility: .visible) {
										selectAttributeToDisplay(position: 6)
									}
									.confirmationDialog("Select the color to use", isPresented: $showingActivityColorSelection7, titleVisibility: .visible) {
										selectColorToUse(attributeName: self.activityVM.title5)
									}
									.foregroundColor(getColorToUse(attributeName: self.activityVM.title7))
									.allowsTightening(true)
									.lineLimit(1)
									.minimumScaleFactor(0.75)
								Text(self.activityVM.units7).font(.system(size: 12))
							}
						}
					}
					
					// Start/Stop/Cancel
					HStack() {
						Button {
							if self.activityVM.isPaused {
								self.activityVM.pause()
							}
							else if self.activityVM.isInProgress {
								self.showingStopSelection = true
							}
							else if !self.activityVM.start() {
								NSLog("Error starting when the Start button was manually pressed.")
							}
						} label: {
							Label(self.activityVM.isInProgress ? "Stop" : "Start", systemImage: self.activityVM.isInProgress ? (self.activityVM.isPaused ? "pause" : "stop") : "play")
						}
						.foregroundColor(self.activityVM.isInProgress ? .red : .green)
						.confirmationDialog("What would you like to do?", isPresented: $showingStopSelection, titleVisibility: .visible) {
							NavigationLink(destination: HistoryDetailsView(activityVM: StoredActivityVM(activitySummary: self.activityVM.stop()))) {
								Text("Stop")
							}
							Button {
								self.activityVM.pause()
							} label: {
								Label("Pause", systemImage: "pause")
							}
							Button {
							} label: {
								Text("Cancel")
							}
						}
					}
					
					HStack() {
						// Interval sessions
						if self.intervalSessionsVM.intervalSessions.count > 0 {
							Button {
								self.showingIntervalSessionSelection = true
							} label: {
								Text("Intervals")
							}
							.confirmationDialog("Select the interval session to perform", isPresented: $showingIntervalSessionSelection, titleVisibility: .visible) {
								ForEach(self.intervalSessionsVM.intervalSessions, id: \.self) { item in
									Button {
										SetCurrentIntervalSession(item.id.uuidString)
									} label: {
										Text(item.name)
									}
								}
							}
							.opacity(self.activityVM.isInProgress ? 0 : 1)
						}
						
						// Pace plans
						if self.pacePlansVM.pacePlans.count > 0 {
							Button {
								self.showingPacePlanSelection = true
							} label: {
								Text("Pace Plan")
							}
							.confirmationDialog("Select the pace plan to use", isPresented: $showingPacePlanSelection, titleVisibility: .visible) {
								ForEach(self.pacePlansVM.pacePlans, id: \.self) { item in
									Button {
										SetCurrentPacePlan(item.id.uuidString)
									} label: {
										Text(item.name)
									}
								}
							}
							.opacity(self.activityVM.isInProgress ? 0 : 1)
						}
					}
				}
			}
		}
		.digitalCrownRotation(self.$crownValue, from: MIN_CROWN_VALUE, through: MAX_CROWN_VALUE, by: 1, sensitivity: .low, isContinuous: true, isHapticFeedbackEnabled: true)
		.onChange(of: self.crownValue) { output in
		}
		.navigationTitle(self.activityType)
		.onAppear() {
			if self.activityVM.isStopped {
				self.dismiss()
			}
		}
    }
}
