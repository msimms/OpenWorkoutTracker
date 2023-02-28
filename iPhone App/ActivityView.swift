//
//  ActivityView.swift
//  Created by Michael Simms on 9/20/22.
//

import SwiftUI
import MapKit

let MAX_THREAT_DISTANCE_METERS = 160.0

struct ActivityIndicator: UIViewRepresentable {
	typealias UIView = UIActivityIndicatorView
	var isAnimating: Bool
	fileprivate var configuration = { (indicator: UIView) in }
	
	func makeUIView(context: UIViewRepresentableContext<Self>) -> UIView { UIView() }
	func updateUIView(_ view: UIView, context: UIViewRepresentableContext<Self>) {
		self.isAnimating ? view.startAnimating() : view.stopAnimating()
		self.configuration(view)
	}
}

func displayMessage(text: String) {
	var notificationData: Dictionary<String, String> = [:]
	notificationData[KEY_NAME_MESSAGE] = text
	let notification = Notification(name: Notification.Name(rawValue: NOTIFICATION_NAME_PRINT_MESSAGE), object: notificationData)
	NotificationCenter.default.post(notification)
}

struct ActivityView: View {
	@Environment(\.colorScheme) var colorScheme
	@Environment(\.dismiss) var dismiss
	@StateObject var activityVM: LiveActivityVM
	@StateObject private var pacePlansVM = PacePlansVM.shared
	@StateObject private var intervalSessionsVM = IntervalSessionsVM.shared
	@State private var region = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 0.0, longitude: 0.0), span: MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5))
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
	@State private var showingActivityAttributeSelection8: Bool = false
	@State private var showingActivityAttributeSelection9: Bool = false
	@State private var showingStartError: Bool = false
	var sensorMgr = SensorMgr.shared
	var broadcastMgr = BroadcastManager.shared
	var activityType: String = ""
	var font: String = "DBLCDTempBlack"

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
	
	func canShowAttributeMenu() -> Bool {
		if !IsActivityInProgress() {
			return true
		}
		return ActivityPreferences.getAllowScreenPressesDuringActivity(activityType: self.activityType)
	}
	
	func stop() -> StoredActivityVM {
		self.stopping = true
		let summary = self.activityVM.stop()
		let storedActivityVM = StoredActivityVM(activitySummary: summary)
		storedActivityVM.load()
		return storedActivityVM
	}

	var body: some View {
		ZStack {
			let bkgndColor = colorScheme == .dark ? Color.black : ActivityPreferences.getBackgroundColor(activityType: self.activityType)
			bkgndColor
				.ignoresSafeArea()

			ZStack() {

				ActivityIndicator(isAnimating: self.stopping)
					.frame(width: self.stopping ? 64 : 0, height: self.stopping ? 64 : 0)

				VStack() {
					
					HStack() {
						// Radar threat display.
						VStack(alignment: .leading) {
							GeometryReader { (geometry) in
								ForEach(self.sensorMgr.radarMeasurements, id: \.self) { measurement in
									let imageY = (Double(measurement.threatMeters) / MAX_THREAT_DISTANCE_METERS) * geometry.size.height
									
									Image(systemName: "car.fill")
										.resizable()
										.frame(width: 28.0, height: 28.0)
										.offset(x: 2, y: imageY)
								}
							}
						}
						.frame(width: self.sensorMgr.radarConnected ? 24 : 0)
						
						// Main display.
						VStack(alignment: .center) {
							
							// Messages
							Text(self.activityVM.currentMessage)
							
							// Main value
							VStack(alignment: .center) {
								Text(self.activityVM.title1)
									.font(.system(size: 16))
									.foregroundColor(ActivityPreferences.getLabelColor(activityType: self.activityType))
									.padding(5)
								Text(self.activityVM.value1)
									.font(.custom(self.font, fixedSize: 72))
									.foregroundColor(colorScheme == .dark ? .white : ActivityPreferences.getTextColor(activityType: self.activityType))
									.onTapGesture {
										self.showingActivityAttributeSelection1 = self.canShowAttributeMenu()
									}
									.confirmationDialog("Select the attribute to display", isPresented: $showingActivityAttributeSelection1, titleVisibility: .visible) {
										selectAttributeToDisplay(position: 0)
									}
									.allowsTightening(true)
									.lineLimit(1)
									.minimumScaleFactor(0.75)
								Text(self.activityVM.units1)
									.font(.system(size: 16))
									.foregroundColor(ActivityPreferences.getLabelColor(activityType: self.activityType))
							}
							.padding(20)
							
							// Countdown timer
							if self.activityVM.countdownSecsRemaining > 0 {
								Image(systemName: String(format: "%u.circle.fill", self.activityVM.countdownSecsRemaining))
									.resizable()
									.frame(width: 256.0, height: 256.0)
							}
							
							// Complex view
							else if self.activityVM.viewType == ACTIVITY_VIEW_COMPLEX {
								let labelColor = ActivityPreferences.getLabelColor(activityType: self.activityType)
								let textColor = ActivityPreferences.getTextColor(activityType: self.activityType)
								
								ScrollView(.vertical, showsIndicators: false) {
									LazyVGrid(columns: self.items, spacing: 20) {
										VStack(alignment: .center) {
											Text(self.activityVM.title2)
												.font(.system(size: 16))
												.foregroundColor(labelColor)
											Text(self.activityVM.value2)
												.font(.custom(self.font, fixedSize: 28))
												.foregroundColor(colorScheme == .dark ? .white : textColor)
												.onTapGesture {
													self.showingActivityAttributeSelection2 = self.canShowAttributeMenu()
												}
												.confirmationDialog("Select the attribute to display", isPresented: $showingActivityAttributeSelection2, titleVisibility: .visible) {
													selectAttributeToDisplay(position: 1)
												}
												.padding(1)
											Text(self.activityVM.units2)
												.font(.system(size: 16))
												.foregroundColor(labelColor)
										}
										VStack(alignment: .center) {
											Text(self.activityVM.title3)
												.font(.system(size: 16))
												.foregroundColor(labelColor)
											Text(self.activityVM.value3)
												.font(.custom(self.font, fixedSize: 28))
												.foregroundColor(colorScheme == .dark ? .white : textColor)
												.onTapGesture {
													self.showingActivityAttributeSelection3 = self.canShowAttributeMenu()
												}
												.confirmationDialog("Select the attribute to display", isPresented: $showingActivityAttributeSelection3, titleVisibility: .visible) {
													selectAttributeToDisplay(position: 2)
												}
												.padding(1)
											Text(self.activityVM.units3)
												.font(.system(size: 16))
												.foregroundColor(labelColor)
										}
										VStack(alignment: .center) {
											Text(self.activityVM.title4)
												.font(.system(size: 16))
												.foregroundColor(labelColor)
											Text(self.activityVM.value4)
												.font(.custom(self.font, fixedSize: 28))
												.foregroundColor(colorScheme == .dark ? .white : textColor)
												.onTapGesture {
													self.showingActivityAttributeSelection4 = self.canShowAttributeMenu()
												}
												.confirmationDialog("Select the attribute to display", isPresented: $showingActivityAttributeSelection4, titleVisibility: .visible) {
													selectAttributeToDisplay(position: 3)
												}
												.padding(1)
											Text(self.activityVM.units4)
												.font(.system(size: 16))
												.foregroundColor(labelColor)
										}
										VStack(alignment: .center) {
											Text(self.activityVM.title5)
												.font(.system(size: 16))
												.foregroundColor(labelColor)
											Text(self.activityVM.value5)
												.font(.custom(self.font, fixedSize: 28))
												.foregroundColor(colorScheme == .dark ? .white : textColor)
												.onTapGesture {
													self.showingActivityAttributeSelection5 = self.canShowAttributeMenu()
												}
												.confirmationDialog("Select the attribute to display", isPresented: $showingActivityAttributeSelection5, titleVisibility: .visible) {
													selectAttributeToDisplay(position: 4)
												}
												.padding(1)
											Text(self.activityVM.units5)
												.font(.system(size: 16))
												.foregroundColor(labelColor)
										}
										VStack(alignment: .center) {
											Text(self.activityVM.title6)
												.font(.system(size: 16))
												.foregroundColor(labelColor)
											Text(self.activityVM.value6)
												.font(.custom(self.font, fixedSize: 28))
												.foregroundColor(colorScheme == .dark ? .white : textColor)
												.onTapGesture {
													self.showingActivityAttributeSelection6 = self.canShowAttributeMenu()
												}
												.confirmationDialog("Select the attribute to display", isPresented: $showingActivityAttributeSelection6, titleVisibility: .visible) {
													selectAttributeToDisplay(position: 5)
												}
												.padding(1)
											Text(self.activityVM.units6)
												.font(.system(size: 16))
												.foregroundColor(labelColor)
										}
										VStack(alignment: .center) {
											Text(self.activityVM.title7)
												.font(.system(size: 16))
												.foregroundColor(labelColor)
											Text(self.activityVM.value7)
												.font(.custom(self.font, fixedSize: 28))
												.foregroundColor(colorScheme == .dark ? .white : textColor)
												.onTapGesture {
													self.showingActivityAttributeSelection7 = self.canShowAttributeMenu()
												}
												.padding(1)
												.confirmationDialog("Select the attribute to display", isPresented: $showingActivityAttributeSelection7, titleVisibility: .visible) {
													selectAttributeToDisplay(position: 6)
												}
											Text(self.activityVM.units7)
												.font(.system(size: 16))
												.foregroundColor(labelColor)
										}
										VStack(alignment: .center) {
											Text(self.activityVM.title8)
												.font(.system(size: 16))
												.foregroundColor(labelColor)
											Text(self.activityVM.value8)
												.font(.custom(self.font, fixedSize: 28))
												.foregroundColor(colorScheme == .dark ? .white : textColor)
												.onTapGesture {
													self.showingActivityAttributeSelection8 = self.canShowAttributeMenu()
												}
												.confirmationDialog("Select the attribute to display", isPresented: $showingActivityAttributeSelection8, titleVisibility: .visible) {
													selectAttributeToDisplay(position: 7)
												}
												.padding(1)
											Text(self.activityVM.units8)
												.font(.system(size: 16))
												.foregroundColor(labelColor)
										}
										VStack(alignment: .center) {
											Text(self.activityVM.title9)
												.font(.system(size: 16))
												.foregroundColor(labelColor)
											Text(self.activityVM.value9)
												.font(.custom(self.font, fixedSize: 28))
												.foregroundColor(colorScheme == .dark ? .white : textColor)
												.onTapGesture {
													self.showingActivityAttributeSelection9 = self.canShowAttributeMenu()
												}
												.confirmationDialog("Select the attribute to display", isPresented: $showingActivityAttributeSelection9, titleVisibility: .visible) {
													selectAttributeToDisplay(position: 8)
												}
												.padding(1)
											Text(self.activityVM.units9)
												.font(.system(size: 16))
												.foregroundColor(labelColor)
										}
									}
									.padding(.horizontal)
								}
							}
							
							// Simple view
							else if self.activityVM.viewType == ACTIVITY_VIEW_SIMPLE {
								let labelColor = ActivityPreferences.getLabelColor(activityType: self.activityType)
								let textColor = ActivityPreferences.getTextColor(activityType: self.activityType)
								
								ScrollView(.vertical, showsIndicators: false) {
									VStack(alignment: .center) {
										VStack(alignment: .center) {
											Text(self.activityVM.title2)
												.font(.system(size: 16))
												.foregroundColor(labelColor)
												.padding(5)
											Text(self.activityVM.value2)
												.font(.custom(self.font, fixedSize: 64))
												.foregroundColor(colorScheme == .dark ? .white : textColor)
												.onTapGesture {
													self.showingActivityAttributeSelection2 = self.canShowAttributeMenu()
												}
												.confirmationDialog("Select the attribute to display", isPresented: $showingActivityAttributeSelection2, titleVisibility: .visible) {
													selectAttributeToDisplay(position: 1)
												}
												.allowsTightening(true)
												.lineLimit(1)
												.minimumScaleFactor(0.75)
											Text(self.activityVM.units2)
												.font(.system(size: 16))
												.foregroundColor(labelColor)
										}
										.padding(5)
										VStack(alignment: .center) {
											Text(self.activityVM.title3)
												.font(.system(size: 16))
												.foregroundColor(labelColor)
												.padding(5)
											Text(self.activityVM.value3)
												.font(.custom(self.font, fixedSize: 64))
												.foregroundColor(colorScheme == .dark ? .white : textColor)
												.onTapGesture {
													self.showingActivityAttributeSelection3 = self.canShowAttributeMenu()
												}
												.confirmationDialog("Select the attribute to display", isPresented: $showingActivityAttributeSelection3, titleVisibility: .visible) {
													selectAttributeToDisplay(position: 2)
												}
												.allowsTightening(true)
												.lineLimit(1)
												.minimumScaleFactor(0.75)
											Text(self.activityVM.units3)
												.font(.system(size: 16))
												.foregroundColor(labelColor)
										}
										.padding(5)
									}
									.padding(.horizontal)
								}
							}
							
							// Mapped view
							else if self.activityVM.viewType == ACTIVITY_VIEW_MAPPED {
								let labelColor = ActivityPreferences.getLabelColor(activityType: self.activityType)
								let textColor = ActivityPreferences.getTextColor(activityType: self.activityType)
								
								ScrollView(.vertical, showsIndicators: false) {
									LazyVGrid(columns: self.items, spacing: 20) {
										VStack(alignment: .center) {
											Text(self.activityVM.title2)
												.font(.system(size: 16))
												.foregroundColor(labelColor)
											Text(self.activityVM.value2)
												.font(.custom(self.font, fixedSize: 48))
												.foregroundColor(colorScheme == .dark ? .white : textColor)
												.onTapGesture {
													self.showingActivityAttributeSelection2 = self.canShowAttributeMenu()
												}
												.confirmationDialog("Select the attribute to display", isPresented: $showingActivityAttributeSelection2, titleVisibility: .visible) {
													selectAttributeToDisplay(position: 1)
												}
												.allowsTightening(true)
												.lineLimit(1)
												.minimumScaleFactor(0.75)
												.padding(1)
											Text(self.activityVM.units2)
												.font(.system(size: 16))
												.foregroundColor(labelColor)
										}
										VStack(alignment: .center) {
											Text(self.activityVM.title3)
												.font(.system(size: 16))
												.foregroundColor(labelColor)
											Text(self.activityVM.value3)
												.font(.custom(self.font, fixedSize: 48))
												.foregroundColor(colorScheme == .dark ? .white : textColor)
												.onTapGesture {
													self.showingActivityAttributeSelection3 = self.canShowAttributeMenu()
												}
												.confirmationDialog("Select the attribute to display", isPresented: $showingActivityAttributeSelection3, titleVisibility: .visible) {
													selectAttributeToDisplay(position: 2)
												}
												.allowsTightening(true)
												.lineLimit(1)
												.minimumScaleFactor(0.75)
												.padding(1)
											Text(self.activityVM.units3)
												.font(.system(size: 16))
												.foregroundColor(labelColor)
										}
									}
									.padding(.horizontal)
									Spacer()
									
									MapWithPolyline(region: MKCoordinateRegion(
										center: CLLocationCoordinate2D(latitude: self.activityVM.currentLat, longitude: self.activityVM.currentLon),
										span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
									), lineCoordinates: self.activityVM.locationTrack)
									.addOverlay(self.activityVM.trackLine)
									.ignoresSafeArea()
									.frame(width: 400, height: 300)
									.padding(10)
								}
								.padding(10)
							}
						}
					}
					
					// Connectivity icons
					HStack() {
						if self.sensorMgr.radarConnected {
							Image(systemName: "car.circle")
								.resizable()
								.frame(width: 32.0, height: 32.0)
								.opacity(self.sensorMgr.radarConnected ? 1 : 0)
						}
						if self.sensorMgr.powerConnected {
							Image(systemName: "bolt.circle")
								.resizable()
								.frame(width: 32.0, height: 32.0)
								.opacity(self.sensorMgr.powerConnected ? 1 : 0)
						}
						if self.sensorMgr.heartRateConnected {
							Image(systemName: "heart.circle")
								.resizable()
								.frame(width: 32.0, height: 32.0)
								.opacity(self.sensorMgr.heartRateConnected ? 1 : 0)
						}
						if self.sensorMgr.cadenceConnected {
							Image(systemName: "c.circle")
								.resizable()
								.frame(width: 32.0, height: 32.0)
								.opacity(self.sensorMgr.cadenceConnected ? 1 : 0)
						}
						if self.sensorMgr.runningPowerConnected {
							Image(systemName: "figure.run")
								.resizable()
								.frame(width: 32.0, height: 32.0)
								.opacity(self.sensorMgr.runningPowerConnected ? 1 : 0)
						}
						let showBroadcastIcon = self.broadcastMgr.lastSendTime > 0 && Preferences.broadcastShowIcon()
						if showBroadcastIcon {
							Image(systemName: "antenna.radiowaves.left.and.right.circle")
								.resizable()
								.frame(width: 32.0, height: 32.0)
								.opacity(showBroadcastIcon ? 1 : 0)
						}
					}
					
					Spacer()
				}
			}
		}
		.toolbar {
			ToolbarItem(placement: .bottomBar) {
				HStack() {
					if !self.activityVM.isInProgress {

						// Preferences Edit button
						NavigationLink(destination: ActivityPreferencesView(activityType: self.activityType)) {
							ZStack {
								Image(systemName: "line.3.horizontal.decrease.circle")
							}
						}
						.foregroundColor(colorScheme == .dark ? .white : .black)
						.opacity(self.activityVM.isInProgress ? 0 : 1)
						.help("View preferences")
						
						// Interval Session selection button
						if self.intervalSessionsVM.intervalSessions.count > 0 {
							Button {
								self.showingIntervalSessionSelection = true
							} label: {
								Label("Intervals", systemImage: "stopwatch")
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
							.foregroundColor(colorScheme == .dark ? .white : .black)
							.opacity(self.activityVM.isInProgress ? 0 : 1)
							.help("Interval session selection.")
						}
						
						// Pace Plan selection button
						if self.pacePlansVM.pacePlans.count > 0 && self.activityVM.isMovingActivity {
							Button {
								self.showingPacePlanSelection = true
							} label: {
								Label("Pace Plan", systemImage: "book.closed")
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
							.foregroundColor(colorScheme == .dark ? .white : .black)
							.opacity(self.activityVM.isInProgress ? 0 : 1)
							.help("Pace plan selection.")
						}
					}
					else if self.activityVM.isMovingActivity {

						// Lap button
						Button {
							self.activityVM.lap()
							displayMessage(text: "New lap started")
						} label: {
							Label("Lap", systemImage: "stopwatch")
						}
						.foregroundColor(colorScheme == .dark ? .white : .black)
						.opacity(self.activityVM.isInProgress ? 1 : 0)
						.help("Lap")
					}

					// Page button
					Button {
						if self.activityVM.viewType == ACTIVITY_VIEW_COMPLEX {
							self.activityVM.viewType = ACTIVITY_VIEW_SIMPLE
						}
						else if self.activityVM.viewType == ACTIVITY_VIEW_SIMPLE {
							self.activityVM.viewType = ACTIVITY_VIEW_MAPPED
						}
						else if self.activityVM.viewType == ACTIVITY_VIEW_MAPPED {
							self.activityVM.viewType = ACTIVITY_VIEW_COMPLEX
						}
					} label: {
						Label("Page", systemImage: "book")
					}
					.foregroundColor(colorScheme == .dark ? .white : .black)
					.help("Will switch between different views/pages.")

					if !self.activityVM.isInProgress {

						// AutoStart button
						Button {
							if self.activityVM.setAutoStart() {
							}
						} label: {
							Label("Autostart", systemImage: "play.circle")
						}
						.foregroundColor(self.activityVM.autoStartEnabled ? .red : (colorScheme == .dark ? .white : .black))
						.help("Autostart. Will start when movement is detected.")
					}

					// Start/Stop/Pause button
					Button {
						if self.activityVM.isPaused {
							self.activityVM.pause()
						}
						else if self.activityVM.isInProgress {
							self.showingStopSelection = true
						}
						else {
							if !self.activityVM.start() {
								self.showingStartError = true
							}
						}
					} label: {
						Label(self.activityVM.isInProgress ? "Stop" : "Start", systemImage: self.activityVM.isInProgress ? (self.activityVM.isPaused ? "pause" : "stop") : "play")
					}
					.foregroundColor(colorScheme == .dark ? .white : .black)
					.confirmationDialog("What would you like to do?", isPresented: $showingStopSelection, titleVisibility: .visible) {
						NavigationLink(destination: HistoryDetailsView(activityVM: self.stop())) {
							Text("Stop")
						}
						Button {
							self.activityVM.pause()
						} label: {
							Text("Pause")
						}
					}
					.alert("There was an unspecified error while trying to start the activity.", isPresented: $showingStartError) { }
				}
			}
		}
		.navigationBarBackButtonHidden(self.activityVM.isInProgress)
		.onAppear() {
			if self.activityVM.isStopped {
				self.dismiss()
			}

			PhoneApp.shared.setScreenLockingForActivity(activityType: self.activityType)
		}
		.onDisappear() {
			PhoneApp.shared.enableScreenLocking()
		}
	}
}
