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

	var body: some View {
		VStack(alignment: .center) {
			// Map
			if IsHistoricalActivityMovingActivity(self.activityVM.activityIndex) {
				Map(coordinateRegion: .constant(
					MKCoordinateRegion(
						center: CLLocationCoordinate2D(latitude: self.activityVM.startingLat, longitude: self.activityVM.startingLon),
						span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
					)
				)
				)
				.addOverlay(self.activityVM.route)
				.ignoresSafeArea()
				.frame(width: 400, height: 200)
			}
			
			// Name and Description
			VStack(alignment: .leading) {
				Text("Name")
					.bold()
				TextField("Name", text: self.$activityVM.name)
					.onChange(of: self.activityVM.name) { value in
						showingUpdateNameError = !self.activityVM.updateActivityName()
					}
				Text("Description")
					.bold()
				TextField("Description", text: self.$activityVM.description, axis: .vertical)
					.onChange(of: self.activityVM.description) { value in
						showingUpdateDescriptionError = !self.activityVM.updateActivityDescription()
					}
					.lineLimit(2...10)
			}
			.padding(10)

			// Attributes Summary
			VStack(alignment: .leading) {
				Text("Details")
					.bold()
					.padding(10)
				List(self.activityVM.getActivityAttributes(), id: \.self) { item in
					HStack() {
						Text(item)
						Spacer()
						Text(self.activityVM.getActivityAttributeValueStr(attributeName: item))
					}
				}
				.listStyle(.plain)
			}
			
			// Charts and Graphs
			VStack(alignment: .leading) {
				Text("Charts")
					.bold()
					.padding(10)
				List() {
					NavigationLink("Heart Rate", destination: SensorChartView(activityId: self.activityVM.activityId, title: "Heart Rate", data: self.activityVM.heartRate))
					if IsHistoricalActivityMovingActivity(self.activityVM.activityIndex) {
						NavigationLink("Cadence", destination: SensorChartView(activityId: self.activityVM.activityId, title: "Cadence", data: self.activityVM.cadence))
						NavigationLink("Pace", destination: SensorChartView(activityId: self.activityVM.activityId, title: "Pace", data: self.activityVM.pace))
						NavigationLink("Power", destination: SensorChartView(activityId: self.activityVM.activityId, title: "Power", data: self.activityVM.power))
						NavigationLink("Speed", destination: SensorChartView(activityId: self.activityVM.activityId, title: "Speed", data: self.activityVM.speed))
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
						ForEach(HistoryVM.getActivityTypes(), id: \.self) { item in
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
								self.activityVM.exportActivity(format: FILE_GPX)
							}
							Button("TCX") {
								self.activityVM.exportActivity(format: FILE_TCX)
							}
							Button("FIT") {
								self.activityVM.exportActivity(format: FILE_FIT)
							}
						}
						Button("CSV") {
							self.activityVM.exportActivity(format: FILE_CSV)
						}
					}
					.foregroundColor(colorScheme == .dark ? .white : .black)
					.help("Export this activity")
				}
			}
		}
		.padding(10)
	}
}
