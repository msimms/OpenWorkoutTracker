//
//  HistoryDetailsView.swift
//  Created by Michael Simms on 9/21/22.
//

import SwiftUI
import MapKit

extension Map {
	func addOverlay(_ overlay: MKOverlay) -> some View {
		MKMapView.appearance().addOverlay(overlay)
		return self
	}
}

struct HistoryDetailsView: View {
	@Environment(\.colorScheme) var colorScheme
	@Environment(\.dismiss) var dismiss
	@StateObject var activityVM: StoredActivityVM
	@State private var showingDeleteConfirmation: Bool = false
	@State private var showingTrimSelection: Bool = false
	@State private var showingActivityTypeSelection: Bool = false
	@State private var showingExportSelection: Bool = false
	@State private var showingFormatSelection: Bool = false
	@State private var showingUpdateNameError: Bool = false
	@State private var showingUpdateDescriptionError: Bool = false
	@State private var showingExportFailedError: Bool = false

	var body: some View {
		VStack(alignment: .center) {
			// Map
			if self.activityVM.isMovingActivity() {
				let region = MKCoordinateRegion(
					center: CLLocationCoordinate2D(latitude: self.activityVM.startingLat, longitude: self.activityVM.startingLon),
					span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
				)

				MapWithPolyline(region: region, lineCoordinates: self.activityVM.locationTrack)
					.addOverlay(self.activityVM.trackLine)
					.ignoresSafeArea()
					.frame(width: 400, height: 300)
			}

			// Name
			Section(header: Text("Name")) {
				TextField("Name", text: self.$activityVM.name)
					.onChange(of: self.activityVM.name) { value in
						showingUpdateNameError = !self.activityVM.updateActivityName()
					}
					.alert("Failed to update the name!", isPresented: self.$showingUpdateNameError) { }
			}

			// Description
			Section(header: Text("Description")) {
				TextField("Description", text: self.$activityVM.description, axis: .vertical)
					.onChange(of: self.activityVM.description) { value in
						showingUpdateDescriptionError = !self.activityVM.updateActivityDescription()
					}
					.lineLimit(2...10)
					.alert("Failed to update the description!", isPresented: self.$showingUpdateDescriptionError) { }
			}

			// Attributes Summary
			Section(header: Text("Attributes")) {
				List(self.activityVM.getActivityAttributesAndCharts(), id: \.self) { item in
					if item == "Heart Rate" {
						NavigationLink("Heart Rate", destination: SensorChartView(title: "Heart Rate", yLabel: "Heart Rate (bpm)", data: self.activityVM.heartRate, color: .red))
					}
					else if item == "Cadence" {
						NavigationLink("Cadence", destination: SensorChartView(title: "Cadence", yLabel: "Cadence (rpm)", data: self.activityVM.cadence, color: .green))
					}
					else if item == "Pace" {
						NavigationLink("Pace", destination: SensorChartView(title: "Pace", yLabel: "Pace", data: self.activityVM.pace, color: .purple))
					}
					else if item == "Power" {
						NavigationLink("Power", destination: SensorChartView(title: "Power", yLabel: "Power (watts)", data: self.activityVM.power, color: .blue))
					}
					else if item == "Speed" {
						NavigationLink("Speed", destination: SensorChartView(title: "Speed", yLabel: "Speed", data: self.activityVM.speed, color: .teal))
					}
					else if item == "X Axis" {
						NavigationLink("X Axis", destination: SensorChartView(title: "X Axis", yLabel: "Movement (g)", data: self.activityVM.x, color: .red))
					}
					else if item == "Y Axis" {
						NavigationLink("Y Axis", destination: SensorChartView(title: "Y Axis", yLabel: "Movement (g)", data: self.activityVM.y, color: .green))
					}
					else if item == "Z Axis" {
						NavigationLink("Z Axis", destination: SensorChartView(title: "Z Axis", yLabel: "Movement (g)", data: self.activityVM.z, color: .blue))
					}
					else {
						HStack() {
							Text(item)
							Spacer()
							Text(self.activityVM.getActivityAttributeValueStr(attributeName: item))
						}
					}
				}
				.listStyle(.plain)
			}
		}
		.padding(10)
		.toolbar {
			ToolbarItem(placement: .bottomBar) {
				HStack() {
					// Delete button
					Button {
						self.showingDeleteConfirmation = true
					} label: {
						Label("Delete", systemImage: "trash")
					}
					.alert("Are you sure you want to delete this activity? This cannot be undone.", isPresented: $showingDeleteConfirmation) {
						Button("Delete") {
							if self.activityVM.deleteActivity() {
								self.dismiss()
							}
						}
						Button("Cancel") {
						}
					}
					.foregroundColor(colorScheme == .dark ? .white : .black)
					.help("Delete this activity")
					
					// Trim button
					Button {
						self.showingTrimSelection = true
					} label: {
						Label("Trim / Correct", systemImage: "pencil")
					}
					.confirmationDialog("Trim / Correct", isPresented: $showingTrimSelection, titleVisibility: .visible) {
						Button("Delete 1st Second") {
							let newTime: UInt64 = UInt64((self.activityVM.getActivityStartTime() + 1) * 1000)
							TrimActivityData(self.activityVM.activityId, newTime, true)
						}
						Button("Delete 1st Five Seconds") {
							let newTime: UInt64 = UInt64((self.activityVM.getActivityStartTime() + 5) * 1000)
							TrimActivityData(self.activityVM.activityId, newTime, true)
						}
						Button("Delete 1st Thirty Seconds") {
							let newTime: UInt64 = UInt64((self.activityVM.getActivityStartTime() + 30) * 1000)
							TrimActivityData(self.activityVM.activityId, newTime, true)
						}
						Button("Delete Last Second") {
							let newTime: UInt64 = UInt64((self.activityVM.getActivityStartTime() + 1) * 1000)
							TrimActivityData(self.activityVM.activityId, newTime, false)
						}
						Button("Delete Last Five Seconds") {
							let newTime: UInt64 = UInt64((self.activityVM.getActivityStartTime() + 5) * 1000)
							TrimActivityData(self.activityVM.activityId, newTime, false)
						}
						Button("Delete Last Thirty Seconds") {
							let newTime: UInt64 = UInt64((self.activityVM.getActivityStartTime() + 30) * 1000)
							TrimActivityData(self.activityVM.activityId, newTime, false)
						}
						if IsHistoricalActivityLiftingActivity(self.activityVM.activityIndex) {
							Button("Fix Repetition Count") {
								let newValue = InitializeActivityAttribute(TYPE_INTEGER, MEASURE_COUNT, UNIT_SYSTEM_METRIC)
								SetHistoricalActivityAttribute(self.activityVM.activityIndex, ACTIVITY_ATTRIBUTE_REPS_CORRECTED, newValue)
								SaveHistoricalActivitySummaryData(self.activityVM.activityIndex)
							}
						}
						Button("Change Activity Type") {
							self.showingActivityTypeSelection = true
						}
					}
					.confirmationDialog("New Activity Type", isPresented: $showingActivityTypeSelection, titleVisibility: .visible) {
						ForEach(CommonApp.activityTypes, id: \.self) { item in
							Button(item) {
								UpdateActivityType(self.activityVM.activityId, item)
							}
						}
					}
					.foregroundColor(colorScheme == .dark ? .white : .black)
					.help("Trim/correct this activity")
					
					Spacer()

					// Tags button
					NavigationLink(destination: TagsView(activityVM: self.activityVM)) {
						ZStack {
							Image(systemName: "tag")
						}
					}
					.foregroundColor(colorScheme == .dark ? .white : .black)
					.help("Apply a tag to the activity")

					// Share/Export button
					Button {
						self.showingExportSelection = true
					} label: {
						Label("Export", systemImage: "square.and.arrow.up")
					}
					.confirmationDialog("Export", isPresented: $showingExportSelection, titleVisibility: .visible) {
						Button("Export via Email") {
							self.showingFormatSelection = true
						}
						Button("Save to Your iCloud Drive") {
							self.showingFormatSelection = true
						}
					}
					.confirmationDialog("Export", isPresented: $showingFormatSelection, titleVisibility: .visible) {
						if IsHistoricalActivityMovingActivity(self.activityVM.activityIndex) {
							Button("GPX") {
								do { let _ = try self.activityVM.exportActivityToICloudFile(fileFormat: FILE_GPX) } catch { self.showingExportFailedError = true }
							}
							Button("TCX") {
								do { let _ = try self.activityVM.exportActivityToICloudFile(fileFormat: FILE_TCX) } catch { self.showingExportFailedError = true }
							}
							Button("FIT") {
								do { let _ = try self.activityVM.exportActivityToICloudFile(fileFormat: FILE_FIT) } catch { self.showingExportFailedError = true }
							}
						}
						Button("CSV") {
							do { let _ = try self.activityVM.exportActivityToICloudFile(fileFormat: FILE_CSV) } catch { self.showingExportFailedError = true }
						}
					}
					.foregroundColor(colorScheme == .dark ? .white : .black)
					.help("Export this activity")
					.alert("Export failed!", isPresented: self.$showingExportFailedError) { }
				}
			}
		}
		.padding(10)
	}
}
