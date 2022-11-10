//
//  EditIntervalSessionView.swift
//  Created by Michael Simms on 10/7/22.
//

import SwiftUI

struct EditIntervalSessionView: View {
	@Environment(\.colorScheme) var colorScheme
	@Environment(\.dismiss) var dismiss
	@StateObject private var intervalSessionsVM = IntervalSessionsVM.shared
	@State private var newSession: IntervalSession = IntervalSession()
	@State private var name: String = ""
	@State private var sport: String = ""
	@State private var description: String = ""
	@State private var keyBeingEdited: String = ""
	@State private var valueBeingEdited: String = ""
	@State private var showingIntervalTypeSelection: Bool = false
	@State private var showingIntervalTimeValueSelection: Bool = false
	@State private var showingIntervalDistanceValueSelection: Bool = false
	@State private var showingIntervalRepsValueSelection: Bool = false
	@State private var showingSegmentEditSelection: Bool = false
	@State private var showingDeleteConfirmation: Bool = false
	@State private var showingSportSelection: Bool = false
	@State private var showingSaveFailedAlert: Bool = false
	@State private var showingDeleteFailedAlert: Bool = false
	@State private var showingValueEditAlert: Bool = false

	init(sessionid: UUID) {
	}

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
				Button(self.newSession.sport) {
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
							self.showingSegmentEditSelection = true
						}) {
							Text(segment.description())
								.frame(minWidth: 0, maxWidth: .infinity)
								.foregroundColor(segment.color())
								.padding()
						}
						.background(RoundedRectangle(cornerRadius: 10, style: .continuous))
						.opacity(0.8)
						.confirmationDialog("Edit", isPresented: $showingSegmentEditSelection, titleVisibility: .visible) {
							ForEach(self.newSession.segments.last!.validModifiers(activityType: self.sport), id: \.self) { item in
								Button(item) {
									self.keyBeingEdited = item
									self.showingValueEditAlert = true
								}
							}
						}
						.alert(self.keyBeingEdited, isPresented: self.$showingValueEditAlert, actions: {
							TextField("10", text: self.$valueBeingEdited)
							Button("Ok", action: {
								self.newSession.segments.last!.applyModifier(key: self.keyBeingEdited, value: Double(self.valueBeingEdited)!)
							})
							Button("Cancel", role: .cancel, action: {})
						}, message: {
							Text("Enter the value")
						})
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
						newSegment.firstValue = 60.0
						newSegment.firstUnits = INTERVAL_UNIT_SECONDS
						self.newSession.segments.append(newSegment)
					}
					Button("Distance") {
						let newSegment = IntervalSegment()
						newSegment.firstValue = 1000.0
						newSegment.firstUnits = INTERVAL_UNIT_METERS
						self.newSession.segments.append(newSegment)
					}
					Button("Sets") {
						let newSegment = IntervalSegment()
						newSegment.firstValue = 3.0
						newSegment.firstUnits = INTERVAL_UNIT_SETS
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
				.alert("Failed to create the interval session.", isPresented: $showingSaveFailedAlert) {}
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
				.alert("Failed to delete the interval session.", isPresented: $showingDeleteFailedAlert) {}
				.opacity(0.8)
				.bold()
			}
		}
		.padding(10)
		.onAppear() {
			//self.intervalSessionsVM.retrieveIntervalSession(sessionid: self.planId)
		}
    }
}
