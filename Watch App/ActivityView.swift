//
//  ActivityView.swift
//  Created by Michael Simms on 9/20/22.
//

import SwiftUI

let NUM_SCREENS: UInt = 4
let MIN_CROWN_VALUE: Double = 1.0
let MAX_CROWN_VALUE: Double = MIN_CROWN_VALUE + Double(NUM_SCREENS) + 1 // The number of screens, plus one for the start/stop
let MINOR_FONT_SIZE: CGFloat = 10.0

struct ActivityView: View {
	@Environment(\.dismiss) var dismiss
	@StateObject var activityVM: LiveActivityVM
	@StateObject private var pacePlansVM = PacePlansVM.shared
	@StateObject private var intervalSessionsVM = IntervalSessionsVM.shared
	@State private var stopping: Bool = false
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
	@State private var showingPoolLengthSelection: Bool = false
	@State private var poolLengths: Array<String> = ["25 Yards", "25 Meters", "50 Yards", "50 Meters"]
	@State private var poolLength = Preferences.poolLength()
	@State private var poolLengthUnits = Preferences.poolLengthUnits()
	@State private var allowScreenPressesDuringActivity = Preferences.watchAllowPressesDuringActivity()
	@State private var crownValue = MIN_CROWN_VALUE

	var activityType: String

	var items: [GridItem] {
		Array(repeating: .init(.adaptive(minimum: 120)), count: 2)
	}
	
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

	func canShowAttributeMenu() -> Bool {
		if !IsActivityInProgress() {
			return true
		}
		return self.allowScreenPressesDuringActivity
	}

	func stop() -> StoredActivityVM {
		self.stopping = true
		let summary = self.activityVM.stop()
		let storedActivityVM = StoredActivityVM(activitySummary: summary)
		storedActivityVM.load()
		return storedActivityVM
	}

	func handleStartStopPauseAction() {
		if self.activityVM.isPaused {
			self.activityVM.pause()
		}
		else if self.activityVM.isInProgress {
			self.showingStopSelection = true
		}
		else if !self.activityVM.start() {
			NSLog("Error starting when the Start button was manually pressed.")
		}
	}

	var body: some View {
		VStack(alignment: .center) {
			// Top item
			VStack(alignment: .center) {
				HStack() {
					Text("Stopping...")
						.foregroundColor(.red)
						.bold()
				}
				.opacity(self.stopping ? 1 : 0)

				VStack(alignment: .center) {
					Text(self.activityVM.attr1.title).font(.system(size: MINOR_FONT_SIZE)).multilineTextAlignment(.center)
					Text(self.activityVM.attr1.value).font(.system(size: 48))
						.onTapGesture {
							self.showingActivityAttributeSelection1 = self.canShowAttributeMenu()
						}
						.onLongPressGesture(minimumDuration: 2) {
							self.showingActivityColorSelection1 = self.canShowAttributeMenu()
						}
						.confirmationDialog("Select the attribute to display", isPresented: self.$showingActivityAttributeSelection1, titleVisibility: .visible) {
							self.selectAttributeToDisplay(position: 0)
						}
						.confirmationDialog("Select the color to use", isPresented: self.$showingActivityColorSelection1, titleVisibility: .visible) {
							self.selectColorToUse(attributeName: self.activityVM.attr1.title)
						}
						.foregroundColor(self.getColorToUse(attributeName: self.activityVM.attr1.title))
						.allowsTightening(true)
						.lineLimit(1)
						.minimumScaleFactor(0.75)
				}
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
					if self.crownValue >= MIN_CROWN_VALUE && self.crownValue < MIN_CROWN_VALUE + 1.0 {
						VStack(alignment: .center) {
							Text(self.activityVM.attr2.title).font(.system(size: MINOR_FONT_SIZE)).multilineTextAlignment(.center)
							Text(self.activityVM.attr2.value).font(.system(size: 24))
								.onTapGesture {
									self.showingActivityAttributeSelection2 = self.canShowAttributeMenu()
								}
								.onLongPressGesture(minimumDuration: 2) {
									self.showingActivityColorSelection2 = self.canShowAttributeMenu()
								}
								.confirmationDialog("Select the attribute to display", isPresented: self.$showingActivityAttributeSelection2, titleVisibility: .visible) {
									self.selectAttributeToDisplay(position: 1)
								}
								.confirmationDialog("Select the color to use", isPresented: self.$showingActivityColorSelection2, titleVisibility: .visible) {
									self.selectColorToUse(attributeName: self.activityVM.attr2.title)
								}
								.foregroundColor(self.getColorToUse(attributeName: self.activityVM.attr2.title))
								.allowsTightening(true)
								.lineLimit(1)
								.minimumScaleFactor(0.75)
							Text(self.activityVM.attr2.units).font(.system(size: MINOR_FONT_SIZE))
						}
						VStack(alignment: .center) {
							Text(self.activityVM.attr3.title).font(.system(size: MINOR_FONT_SIZE)).multilineTextAlignment(.center)
							Text(self.activityVM.attr3.value).font(.system(size: 24))
								.onTapGesture {
									self.showingActivityAttributeSelection3 = self.canShowAttributeMenu()
								}
								.onLongPressGesture(minimumDuration: 2) {
									self.showingActivityColorSelection3 = self.canShowAttributeMenu()
								}
								.confirmationDialog("Select the attribute to display", isPresented: self.$showingActivityAttributeSelection3, titleVisibility: .visible) {
									self.selectAttributeToDisplay(position: 2)
								}
								.confirmationDialog("Select the color to use", isPresented: self.$showingActivityColorSelection3, titleVisibility: .visible) {
									self.selectColorToUse(attributeName: self.activityVM.attr3.title)
								}
								.foregroundColor(self.getColorToUse(attributeName: self.activityVM.attr3.title))
								.allowsTightening(true)
								.lineLimit(1)
								.minimumScaleFactor(0.75)
							Text(self.activityVM.attr3.units).font(.system(size: MINOR_FONT_SIZE))
						}
					}

					// Screen 2
					else if self.crownValue >= MIN_CROWN_VALUE + 1.0 && self.crownValue < MIN_CROWN_VALUE + 2.0 {
						VStack(alignment: .center) {
							Text(self.activityVM.attr4.title).font(.system(size: MINOR_FONT_SIZE)).multilineTextAlignment(.center)
							Text(self.activityVM.attr4.value).font(.system(size: 24))
								.onTapGesture {
									self.showingActivityAttributeSelection4 = self.canShowAttributeMenu()
								}
								.onLongPressGesture(minimumDuration: 2) {
									self.showingActivityColorSelection4 = self.canShowAttributeMenu()
								}
								.confirmationDialog("Select the attribute to display", isPresented: self.$showingActivityAttributeSelection4, titleVisibility: .visible) {
									self.selectAttributeToDisplay(position: 3)
								}
								.confirmationDialog("Select the color to use", isPresented: self.$showingActivityColorSelection4, titleVisibility: .visible) {
									self.selectColorToUse(attributeName: self.activityVM.attr4.title)
								}
								.foregroundColor(self.getColorToUse(attributeName: self.activityVM.attr4.title))
								.allowsTightening(true)
								.lineLimit(1)
								.minimumScaleFactor(0.75)
							Text(self.activityVM.attr4.units).font(.system(size: MINOR_FONT_SIZE))
						}
						VStack(alignment: .center) {
							Text(self.activityVM.attr5.title).font(.system(size: MINOR_FONT_SIZE)).multilineTextAlignment(.center)
							Text(self.activityVM.attr5.value).font(.system(size: 24))
								.onTapGesture {
									self.showingActivityAttributeSelection5 = self.canShowAttributeMenu()
								}
								.onLongPressGesture(minimumDuration: 2) {
									self.showingActivityColorSelection5 = self.canShowAttributeMenu()
								}
								.confirmationDialog("Select the attribute to display", isPresented: self.$showingActivityAttributeSelection5, titleVisibility: .visible) {
									self.selectAttributeToDisplay(position: 4)
								}
								.confirmationDialog("Select the color to use", isPresented: self.$showingActivityColorSelection5, titleVisibility: .visible) {
									self.selectColorToUse(attributeName: self.activityVM.attr5.title)
								}
								.foregroundColor(self.getColorToUse(attributeName: self.activityVM.attr5.title))
								.allowsTightening(true)
								.lineLimit(1)
								.minimumScaleFactor(0.75)
							Text(self.activityVM.attr5.units).font(.system(size: MINOR_FONT_SIZE))
						}
					}

					// Screen 3
					else if self.crownValue >= MIN_CROWN_VALUE + 2.0 && self.crownValue < MIN_CROWN_VALUE + 3.0 {
						VStack(alignment: .center) {
							Text(self.activityVM.attr6.title).font(.system(size: MINOR_FONT_SIZE)).multilineTextAlignment(.center)
							Text(self.activityVM.attr6.value).font(.system(size: 24))
								.onTapGesture {
									self.showingActivityAttributeSelection6 = self.canShowAttributeMenu()
								}
								.onLongPressGesture(minimumDuration: 2) {
									self.showingActivityColorSelection6 = self.canShowAttributeMenu()
								}
								.confirmationDialog("Select the attribute to display", isPresented: self.$showingActivityAttributeSelection6, titleVisibility: .visible) {
									self.selectAttributeToDisplay(position: 5)
								}
								.confirmationDialog("Select the color to use", isPresented: self.$showingActivityColorSelection6, titleVisibility: .visible) {
									self.selectColorToUse(attributeName: self.activityVM.attr6.title)
								}
								.foregroundColor(self.getColorToUse(attributeName: self.activityVM.attr6.title))
								.allowsTightening(true)
								.lineLimit(1)
								.minimumScaleFactor(0.75)
							Text(self.activityVM.attr6.units).font(.system(size: MINOR_FONT_SIZE))
						}
						VStack(alignment: .center) {
							Text(self.activityVM.attr7.title).font(.system(size: MINOR_FONT_SIZE)).multilineTextAlignment(.center)
							Text(self.activityVM.attr7.value).font(.system(size: 24))
								.onTapGesture {
									self.showingActivityAttributeSelection7 = self.canShowAttributeMenu()
								}
								.onLongPressGesture(minimumDuration: 2) {
									self.showingActivityColorSelection7 = self.canShowAttributeMenu()
								}
								.confirmationDialog("Select the attribute to display", isPresented: self.$showingActivityAttributeSelection7, titleVisibility: .visible) {
									self.selectAttributeToDisplay(position: 6)
								}
								.confirmationDialog("Select the color to use", isPresented: self.$showingActivityColorSelection7, titleVisibility: .visible) {
									self.selectColorToUse(attributeName: self.activityVM.attr7.title)
								}
								.foregroundColor(self.getColorToUse(attributeName: self.activityVM.attr7.title))
								.allowsTightening(true)
								.lineLimit(1)
								.minimumScaleFactor(0.75)
							Text(self.activityVM.attr7.units).font(.system(size: MINOR_FONT_SIZE))
						}
					}
					
					// Screen 4
					else if self.crownValue >= MIN_CROWN_VALUE + 3.0 && self.crownValue < MIN_CROWN_VALUE + 4.0 {

						// Interval sessions
						if self.intervalSessionsVM.intervalSessions.count == 0 {
							Button {
								self.showingIntervalSessionSelection = true
							} label: {
								Label("Intervals", systemImage: "stopwatch")
							}
							.confirmationDialog("Select the interval session to perform", isPresented: self.$showingIntervalSessionSelection, titleVisibility: .visible) {
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
						if self.pacePlansVM.pacePlans.count == 0 {
							Button {
								self.showingPacePlanSelection = true
							} label: {
								Label("Pace Plan", systemImage: "book.closed")
							}
							.confirmationDialog("Select the pace plan to use", isPresented: self.$showingPacePlanSelection, titleVisibility: .visible) {
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
				
				HStack() {

					// Start/Stop/Cancel
					// If we're using the crown to start and stop the activity then hide the button.
					// This is useful for activities like swimming, to prevent accidental presses.
					if !Preferences.watchTurnCrownToStartStopActivity() {
						VStack() {
							HStack() {
								
								// Start/Stop/Pause button
								Button {
									self.handleStartStopPauseAction()
								} label: {
									Label(self.activityVM.isInProgress ? "Stop" : "Start", systemImage: self.activityVM.isInProgress ? (self.activityVM.isPaused ? "pause" : "stop") : "play")
								}
								.foregroundColor(self.activityVM.isInProgress ? .red : .green)
								.confirmationDialog("What would you like to do?", isPresented: self.$showingStopSelection, titleVisibility: .visible) {
									NavigationLink(destination: HistoryDetailsView(activityVM: self.stop())) {
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
								
								// Lap button
								if self.allowScreenPressesDuringActivity && self.activityVM.isInProgress && self.activityVM.isMovingActivity {
									Button {
										self.activityVM.lap()
									} label: {
										Label("Lap", systemImage: "stopwatch")
									}
									.help("Lap")
								}
							}

							HStack() {

								// Pool Length button
								if !self.activityVM.isInProgress && self.activityType == ACTIVITY_TYPE_POOL_SWIMMING {
									Button {
										self.showingPoolLengthSelection = true
									} label: {
										Label("Pool Length", systemImage: "ruler")
									}
									.confirmationDialog("Set the pool length", isPresented: self.$showingPoolLengthSelection, titleVisibility: .visible) {
										ForEach(self.poolLengths, id: \.self) { item in
											Button {
												Preferences.setPoolLength(poolLengthDescription: item)
											} label: {
												Text(item)
											}
										}
									}
									.help("Set the pool length")
								}
							}
						}
					}
				}
			}
		}
		.focusable()
		.digitalCrownRotation(self.$crownValue, from: MIN_CROWN_VALUE, through: MAX_CROWN_VALUE, by: -1, sensitivity: .low, isContinuous: true, isHapticFeedbackEnabled: true)
		.onChange(of: self.crownValue) {
			if Preferences.watchTurnCrownToStartStopActivity() {
				if self.crownValue >= MIN_CROWN_VALUE + 4.0 && self.crownValue < MIN_CROWN_VALUE + 5.0 {
					self.handleStartStopPauseAction()
				}
			}
		}
		.confirmationDialog("What would you like to do?", isPresented: self.$showingStopSelection, titleVisibility: .visible) {
			NavigationLink(destination: HistoryDetailsView(activityVM: self.stop())) {
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
		.navigationBarBackButtonHidden(self.activityVM.isInProgress)
		.navigationBarTitleDisplayMode(.inline)
		.opacity(self.activityVM.isPaused ? 0.5 : 1)
		.onAppear() {
			if self.activityVM.isStopped {
				self.dismiss()
			}
		}
    }
}
