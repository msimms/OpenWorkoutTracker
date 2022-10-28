//
//  NewIntervalSessionView.swift
//  Created by Michael Simms on 10/7/22.
//

import SwiftUI

struct NewIntervalSessionView: View {
	@Environment(\.colorScheme) var colorScheme
	@Environment(\.dismiss) var dismiss
	@StateObject private var intervalSessionsVM = IntervalSessionsVM()
	@State private var newSession: IntervalSession = IntervalSession()
	@State private var name: String = ""
	@State private var sport: String = ""
	@State private var description: String = ""
	@State private var showingIntervalTypeSelection: Bool = false
	@State private var showingIntervalTimeValueSelection: Bool = false
	@State private var showingIntervalDistanceValueSelection: Bool = false
	@State private var showingIntervalRepsValueSelection: Bool = false
	@State private var showingSegmentDetailsSelection: Bool = false
	@State private var showingDeleteConfirmation: Bool = false
	@State private var showingSportSelection: Bool = false
	@State private var showingSaveFailedAlert: Bool = false
	@State private var showingDeleteFailedAlert: Bool = false
	@State private var showingValueEntryAlert: Bool = false
	@State private var valueEntry: String = ""

	var body: some View {
		VStack(alignment: .center) {

			Group() {
				Text("Name")
					.bold()
				TextField("Name", text: $name)
					.onChange(of: self.name) { value in
						self.newSession.name = value
					}
			}
			.padding(5)
				
			Group() {
				Button("Sport") {
					self.showingSportSelection = true
				}
				.bold()
				.confirmationDialog("Select the workout to perform", isPresented: $showingSportSelection, titleVisibility: .visible) {
					ForEach(CommonApp.activityTypes, id: \.self) { item in
						Button(item) {
							self.newSession.sport = item
						}
					}
				}
				Text(self.newSession.sport)
			}
			.padding(5)

			Group() {
				Text("Description")
					.bold()
				TextField("Description", text: $description, axis: .vertical)
					.lineLimit(2...10)
			}
			.padding(5)

			Spacer()

			Group() {
				VStack(alignment: .leading) {
					ForEach(self.newSession.segments, id: \.self) { segment in
						Button(action: {
							self.showingSegmentDetailsSelection = true
						}) {
							Text(segment.description())
								.frame(minWidth: 0, maxWidth: .infinity)
								.foregroundColor(segment.color())
								.padding()
						}
						.background(RoundedRectangle(cornerRadius: 10, style: .continuous))
						.opacity(0.8)
						.confirmationDialog("Which type of interval?", isPresented: $showingSegmentDetailsSelection, titleVisibility: .visible) {
							ForEach(self.newSession.segments.last!.validModifiers(activityType: self.sport), id: \.self) { item in
								Button(item) {
									self.showingValueEntryAlert = true
								}
								.alert(item, isPresented: self.$showingValueEntryAlert, actions: {
									TextField("10", text: self.$valueEntry)
									Button("Ok", action: {
									})
									Button("Cancel", role: .cancel, action: {})
								}, message: {
									Text("Enter the number")
								})
							}
						}
					}
				}
			}

			Spacer()

			Group() {
				Button(action: { self.showingIntervalTypeSelection = true }) {
					Text("Append")
						.frame(minWidth: 0, maxWidth: .infinity)
						.foregroundColor(.white)
						.padding()
				}
				.background(RoundedRectangle(cornerRadius: 10, style: .continuous))
				.confirmationDialog("Which type of interval?", isPresented: $showingIntervalTypeSelection, titleVisibility: .visible) {
					Button("Time") {
						let newSegment = IntervalSegment()
						newSegment.duration = 60
						newSegment.units = INTERVAL_UNIT_SECONDS
						self.newSession.segments.append(newSegment)
					}
					Button("Distance") {
						let newSegment = IntervalSegment()
						newSegment.distance = 1000
						newSegment.units = INTERVAL_UNIT_METERS
						self.newSession.segments.append(newSegment)
					}
					Button("Sets") {
						let newSegment = IntervalSegment()
						newSegment.sets = 3
						newSegment.units = INTERVAL_UNIT_NOT_SET
						self.newSession.segments.append(newSegment)
					}
				}
				.bold()
			}

			Spacer()

			// Save
			Group() {
				Button(action: {
					if !self.intervalSessionsVM.createIntervalSession(session: self.newSession) {
						self.showingSaveFailedAlert = true
					}
				}) {
					Text("Save")
						.frame(minWidth: 0, maxWidth: .infinity)
						.foregroundColor(.white)
						.padding()
				}
				.background(RoundedRectangle(cornerRadius: 10, style: .continuous))
				.opacity(0.8)
				.bold()
			}

			// Delete
			Group() {
				Button(action: { self.showingDeleteConfirmation = true }) {
					Text("Delete")
						.frame(minWidth: 0, maxWidth: .infinity)
						.foregroundColor(.red)
						.padding()
				}
				.background(RoundedRectangle(cornerRadius: 10, style: .continuous))
				.alert("Are you sure you want to delete this workout? This cannot be undone.", isPresented: $showingDeleteConfirmation) {
					Button("Delete") {
						if self.intervalSessionsVM.deleteIntervalSession(intervalSessionId: self.newSession.id) {
							self.dismiss()
						}
						else {
							self.showingDeleteFailedAlert = true
						}
					}
					Button("Cancel") {
					}
				}
				.opacity(0.8)
				.bold()
			}
		}
		.padding(10)
    }
}
