//
//  ActivityView.swift
//  Created by Michael Simms on 9/20/22.
//

import SwiftUI
import MapKit

let MAX_THREAT_DISTANCE_METERS = 160.0
var selectedItem: Int = 0

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

struct WeightDetails: Identifiable {
	var weight: Double
	let id = UUID()
}

struct ActivityView: View {
	@Environment(\.colorScheme) var colorScheme
	@Environment(\.dismiss) var dismiss
	@StateObject var activityVM: LiveActivityVM
	@StateObject private var pacePlansVM = PacePlansVM.shared
	@StateObject private var intervalSessionsVM = IntervalSessionsVM.shared
	@StateObject private var routesVM: RoutesVM = RoutesVM()
	@State private var selectedRoute: RouteSummary = RouteSummary()
	@State private var region = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 0.0, longitude: 0.0), span: MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5))
	@State private var stopping: Bool = false
	@State private var showingStopSelection: Bool = false
	@State private var showingIntervalSessionSelection: Bool = false
	@State private var intervalSessionIsSelected: Bool = false
	@State private var showingPacePlanSelection: Bool = false
	@State private var showingRouteSelection: Bool = false
	@State private var showingActivityAttributeSelection: Bool = false
	@State private var showingStartError: Bool = false
	@State private var showingExtraWeightAlert: Bool = false
	@State private var additionalWeight: NumbersOnly = NumbersOnly(initialDoubleValue: 0.0)
	@State private var tappedAttr: RenderedActivityAttribute = RenderedActivityAttribute()
	var sensorMgr = SensorMgr.shared
	var broadcastMgr = BroadcastManager.shared
	var activityType: String = ""
	var font: String = "DBLCDTempBlack"

	var items: [GridItem] {
		Array(repeating: .init(.adaptive(minimum: 120)), count: 2)
	}

	func selectAttributeToDisplay() -> some View {
		return VStack(content: {
			ForEach(self.activityVM.getActivityAttributeNames(), id: \.self) { item in
				Button(action: {
					self.activityVM.setDisplayedActivityAttributeName(position: self.tappedAttr.position, attributeName: item)
				}) {
					Text(item)
				}
			}
		})
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

	func renderItem(attr: RenderedActivityAttribute, labelColor: Color, textColor: Color) -> some View {
		VStack(alignment: .center) {
			Text(attr.title)
				.font(.system(size: 16))
				.foregroundColor(labelColor)
			Text(attr.value)
				.font(.custom(self.font, fixedSize: 28))
				.foregroundColor(self.colorScheme == .dark ? .white : textColor)
				.onTapGesture {
					self.showingActivityAttributeSelection = self.canShowAttributeMenu()
					self.tappedAttr = attr
				}
				.confirmationDialog("Select the attribute to display", isPresented: self.$showingActivityAttributeSelection, titleVisibility: .visible) {
					self.selectAttributeToDisplay()
				}
				.allowsTightening(true)
				.lineLimit(1)
				.minimumScaleFactor(0.75)
				.padding(1)
			Text(attr.units)
				.font(.system(size: 16))
				.foregroundColor(labelColor)
		}
	}

	func renderLargeItem(attr: RenderedActivityAttribute, labelColor: Color, textColor: Color) -> some View {
		VStack(alignment: .center, content: {
			Text(attr.title)
				.font(.system(size: 16))
				.foregroundColor(labelColor)
			Text(attr.value)
				.font(.custom(self.font, fixedSize: 72))
				.foregroundColor(self.colorScheme == .dark ? .white : textColor)
				.onTapGesture {
					self.showingActivityAttributeSelection = self.canShowAttributeMenu()
					self.tappedAttr = attr
				}
				.confirmationDialog("Select the attribute to display", isPresented: self.$showingActivityAttributeSelection, titleVisibility: .visible, actions: {
					self.selectAttributeToDisplay()
				})
				.allowsTightening(true)
				.lineLimit(1)
				.minimumScaleFactor(0.75)
				.padding(1)
			Text(attr.units)
				.font(.system(size: 16))
				.foregroundColor(labelColor)
		})
	}

	var body: some View {
		ZStack {
			let bkgndColor = self.colorScheme == .dark ? Color.black : ActivityPreferences.getBackgroundColor(activityType: self.activityType)
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
							let labelColor = ActivityPreferences.getLabelColor(activityType: self.activityType)
							let textColor = ActivityPreferences.getTextColor(activityType: self.activityType)

							// Messages
							Text(self.activityVM.currentMessage)
							
							// Main value
							VStack(alignment: .center) {
								self.renderLargeItem(attr: self.activityVM.attr1, labelColor: labelColor, textColor: textColor)
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
								ScrollView(.vertical, showsIndicators: false) {
									LazyVGrid(columns: self.items, spacing: 20) {
										self.renderItem(attr: self.activityVM.attr2, labelColor: labelColor, textColor: textColor)
										self.renderItem(attr: self.activityVM.attr3, labelColor: labelColor, textColor: textColor)
										self.renderItem(attr: self.activityVM.attr4, labelColor: labelColor, textColor: textColor)
										self.renderItem(attr: self.activityVM.attr5, labelColor: labelColor, textColor: textColor)
										self.renderItem(attr: self.activityVM.attr6, labelColor: labelColor, textColor: textColor)
										self.renderItem(attr: self.activityVM.attr7, labelColor: labelColor, textColor: textColor)
										self.renderItem(attr: self.activityVM.attr8, labelColor: labelColor, textColor: textColor)
										self.renderItem(attr: self.activityVM.attr9, labelColor: labelColor, textColor: textColor)
									}
									.padding(.horizontal)
								}
							}
							
							// Simple view
							else if self.activityVM.viewType == ACTIVITY_VIEW_SIMPLE {
								ScrollView(.vertical, showsIndicators: false) {
									VStack(alignment: .center) {
										self.renderLargeItem(attr: self.activityVM.attr2, labelColor: labelColor, textColor: textColor)
										self.renderLargeItem(attr: self.activityVM.attr3, labelColor: labelColor, textColor: textColor)
										self.renderLargeItem(attr: self.activityVM.attr4, labelColor: labelColor, textColor: textColor)
									}
									.padding(.horizontal)
									Spacer()
								}
							}
							
							// Mapped view
							else if self.activityVM.viewType == ACTIVITY_VIEW_MAPPED {
								ScrollView(.vertical, showsIndicators: false) {
									LazyVGrid(columns: self.items, spacing: 20) {
										self.renderItem(attr: self.activityVM.attr2, labelColor: labelColor, textColor: textColor)
										self.renderItem(attr: self.activityVM.attr3, labelColor: labelColor, textColor: textColor)
										self.renderItem(attr: self.activityVM.attr4, labelColor: labelColor, textColor: textColor)
										self.renderItem(attr: self.activityVM.attr5, labelColor: labelColor, textColor: textColor)
									}
									.padding(.horizontal)
									Spacer()
									
									GeometryReader { reader in
										MapWithPolyline(region: MKCoordinateRegion(
											center: CLLocationCoordinate2D(latitude: SensorMgr.shared.location.currentLocation.coordinate.latitude,
																		   longitude: SensorMgr.shared.location.currentLocation.coordinate.longitude),
											span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
										), trackUser: true, updates: true, overlays: [self.activityVM.trackLine, self.selectedRoute.trackLine])
										.ignoresSafeArea()
										.frame(height: 300)
										.padding(.horizontal)
									}
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
								.opacity(self.sensorMgr.radarConnected ? (time(nil) - Int(self.sensorMgr.lastRadarUpdate) < 60 ? 1.0 : 0.5) : 0.0)
						}
						if self.sensorMgr.powerConnected {
							Image(systemName: "bolt.circle")
								.resizable()
								.frame(width: 32.0, height: 32.0)
								.opacity(self.sensorMgr.powerConnected ? (time(nil) - Int(self.sensorMgr.lastPowerUpdate) < 60 ? 1.0 : 0.5) : 0.0)
						}
						if self.sensorMgr.heartRateConnected {
							Image(systemName: "heart.circle")
								.resizable()
								.frame(width: 32.0, height: 32.0)
								.opacity(self.sensorMgr.heartRateConnected ? (time(nil) - Int(self.sensorMgr.lastHrmUpdate) < 60 ? 1.0 : 0.5) : 0.0)
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
								.opacity(self.sensorMgr.runningPowerConnected ? (time(nil) - Int(self.sensorMgr.lastRunningPowerUpdate) < 60 ? 1.0 : 0.5) : 0.0)
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
						.foregroundColor(self.colorScheme == .dark ? .white : .black)
						.opacity(self.activityVM.isInProgress ? 0 : 1)
						.help("View preferences")
						
						// Interval Session selection button
						if self.intervalSessionsVM.intervalSessions.count > 0 {
							Button {
								self.showingIntervalSessionSelection = true
							} label: {
								Label("Intervals", systemImage: "i.circle")
							}
							.confirmationDialog("Select the interval session to perform", isPresented: self.$showingIntervalSessionSelection, titleVisibility: .visible) {
								ForEach(self.intervalSessionsVM.intervalSessions, id: \.self) { item in
									Button {
										SetCurrentIntervalSession(item.id.uuidString)
										self.intervalSessionIsSelected = true
									} label: {
										Text(item.name)
									}
								}
							}
							.foregroundColor(self.intervalSessionIsSelected ? .green : (self.colorScheme == .dark ? .white : .black))
							.opacity(self.activityVM.isInProgress ? 0 : 1)
							.help("Interval session selection.")
						}
						
						// Pace Plan selection button
						if self.pacePlansVM.pacePlans.count > 0 && self.activityVM.isMovingActivity {
							Button {
								self.showingPacePlanSelection = true
							} label: {
								Label("Pace Plan", systemImage: "p.circle")
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
							.foregroundColor(self.colorScheme == .dark ? .white : .black)
							.opacity(self.activityVM.isInProgress ? 0 : 1)
							.help("Pace plan selection.")
						}

						// Route button
						if self.routesVM.routes.count > 0 && self.activityVM.isMovingActivity {
							Button {
								self.showingRouteSelection = true
							} label: {
								if self.selectedRoute.trackLine.pointCount  == 0 {
									Label("Route", systemImage: "mappin.circle")
								}
								else {
									Label("Route", systemImage: "mappin.circle.fill")
								}
							}
							.confirmationDialog("Select the route to use", isPresented: self.$showingRouteSelection, titleVisibility: .visible) {
								ForEach(self.routesVM.routes, id: \.self) { item in
									Button {
										self.selectedRoute = item
									} label: {
										Text(item.name)
									}
								}
							}
							.foregroundColor(self.colorScheme == .dark ? .white : .black)
							.opacity(self.activityVM.isInProgress ? 0 : 1)
							.help("Route")
						}
						
						// Additional weight button
						if !self.activityVM.isMovingActivity {
							Button {
								self.showingExtraWeightAlert = true
							} label: {
								Label("Weight", systemImage: "scalemass")
							}
							.foregroundColor(self.colorScheme == .dark ? .white : .black)
							.opacity(self.activityVM.isInProgress ? 0 : 1)
							.help("Additional Weight")
							.alert("Weight.", isPresented: self.$showingExtraWeightAlert) {
								VStack() {
									TextField("Weight", text: self.$additionalWeight.value)
										.keyboardType(.decimalPad)
										.multilineTextAlignment(.trailing)
										.fixedSize()
										.onChange(of: self.additionalWeight.value) {
										}

									HStack() {
										Button("OK") {
											var value: ActivityAttributeType = ActivityAttributeType()
											value.value.doubleVal = self.additionalWeight.asDouble()
											value.valueType = TYPE_DOUBLE
											value.measureType = MEASURE_WEIGHT
											value.unitSystem = Preferences.preferredUnitSystem()
											
											SetLiveActivityAttribute(ACTIVITY_ATTRIBUTE_ADDITIONAL_WEIGHT, value)
										}
										Button("Cancel") {
										}
									}
								}
							} message: {
								Text("Enter additional weight used during this activity.")
							}
						}
					}
					else if self.activityVM.isMovingActivity {

						// Lap button
						Button {
							self.activityVM.lap()
							displayMessage(text: "New lap started")
						} label: {
							Label("Lap", systemImage: "point.forward.to.point.capsulepath")
						}
						.foregroundColor(self.colorScheme == .dark ? .white : .black)
						.disabled(!(self.activityVM.isInProgress && !self.activityVM.isPaused))
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
					.foregroundColor(self.colorScheme == .dark ? .white : .black)
					.help("Will switch between different views/pages.")

					if !self.activityVM.isInProgress {

						// AutoStart button
						Button {
							if self.activityVM.setAutoStart() {
							}
						} label: {
							Label("Autostart", systemImage: "play.circle")
						}
						.foregroundColor(self.activityVM.autoStartEnabled ? .red : (self.colorScheme == .dark ? .white : .black))
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
					.foregroundColor(self.colorScheme == .dark ? .white : .black)
					.confirmationDialog("What would you like to do?", isPresented: self.$showingStopSelection, titleVisibility: .visible) {
						NavigationLink(destination: HistoryDetailsView(activityVM: self.stop())) {
							Text("Stop")
						}
						Button {
							self.activityVM.pause()
						} label: {
							Text("Pause")
						}
					}
					.alert("There was an unspecified error while trying to start the activity.", isPresented: self.$showingStartError) { }
				}
			}
		}
		.navigationBarBackButtonHidden(self.activityVM.isInProgress)
		.navigationTitle(self.activityType)
		.navigationBarTitleDisplayMode(.inline)
		.opacity(self.activityVM.isPaused ? 0.5 : 1)
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
