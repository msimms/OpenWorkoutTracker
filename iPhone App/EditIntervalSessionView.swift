//
//  EditIntervalSessionView.swift
//  Created by Michael Simms on 10/7/22.
//

import SwiftUI

struct EditIntervalSessionView: View {
	@Environment(\.dismiss) var dismiss
	@StateObject private var intervalSessionsVM = IntervalSessionsVM.shared

	@State private var tempSession: IntervalSession
	@State private var tempName: String
	@State private var tempSport: String
	@State private var tempDescription: String

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
	@State private var showingMoveSegmentUpAlert: Bool = false
	@State private var showingMoveSegmentDownAlert: Bool = false
	@State private var showingDeleteSegmentAlert: Bool = false

	init(session: IntervalSession) {
		_tempSession = State(initialValue: session)
		_tempName = State(initialValue: session.name)
		_tempSport = State(initialValue: session.sport)
		_tempDescription = State(initialValue: session.description)
	}

	var body: some View {
		VStack(alignment: .center) {

			Group() {
				Text("Name")
					.bold()
				TextField("Name", text: self.$tempName)
					.onChange(of: self.tempName) { value in
						self.tempSession.name = value
					}
			}
			.padding(5)

			Group() {
				Button(self.tempSession.sport) {
					self.showingSportSelection = true
				}
				.bold()
				.confirmationDialog("Select the workout to perform", isPresented: self.$showingSportSelection, titleVisibility: .visible) {
					ForEach(CommonApp.activityTypes, id: \.self) { item in
						Button(item) {
							self.tempSession.sport = item
						}
					}
				}
			}
			.padding(5)

			Group() {
				Text("Description")
					.bold()
				TextField("Description", text: self.$tempDescription, axis: .vertical)
					.lineLimit(2...10)
					.onChange(of: self.tempDescription) { value in
						self.tempSession.description = value
					}
			}
			.padding(5)

			Spacer()

			Group() {
				ScrollView() {
					VStack(alignment: .leading) {
						ForEach(self.tempSession.segments, id: \.self) { segment in
							HStack() {
								// Move up button
								Button(action: {
									self.showingMoveSegmentUpAlert = !self.intervalSessionsVM.moveSegmentUp(session: self.tempSession, segmentId: segment.id)
								}) {
									Image(systemName: "arrow.up.square")
								}
								.alert("Failed to move the segment up.", isPresented: self.$showingMoveSegmentUpAlert) {}

								Spacer()
								
								// Main button
								Button(action: {
									self.showingSegmentEditSelection = true
								}) {
									Text(segment.intervalDescription())
										.frame(minWidth: 0, maxWidth: .infinity)
										.foregroundColor(segment.color())
										.padding()
								}
								.background(RoundedRectangle(cornerRadius: 10, style: .continuous))
								.opacity(0.8)
								.confirmationDialog("Edit", isPresented: self.$showingSegmentEditSelection, titleVisibility: .visible) {
									VStack() {
										ForEach(self.tempSession.segments.last!.validModifiers(activityType: self.tempSport), id: \.self) { item in
											Button(item) {
												self.keyBeingEdited = item
												self.showingValueEditAlert = true
											}
										}
										Button("Delete") {
											self.showingDeleteSegmentAlert = !self.intervalSessionsVM.deleteSegment(session: self.tempSession, segmentId: segment.id)
										}
									}
								}
								.alert("Failed to delete the segment.", isPresented: self.$showingDeleteSegmentAlert) {}
								.alert(self.keyBeingEdited, isPresented: self.$showingValueEditAlert, actions: {
									TextField("10", text: self.$valueBeingEdited)
									Button("Ok", action: {
										var hours: Int = 0
										var mins: Int = 0
										var secs: Int = 0
										var value: Double = 0.0
										
										if StringUtils.parseHHMMSS(str: self.valueBeingEdited, hours: &hours, minutes: &mins, seconds: &secs) {
											value = Double(mins) + (Double(secs) / 60.0)
										}
										else {
											value = Double(self.valueBeingEdited) ?? 0.0
										}
										self.tempSession.segments.last!.applyModifier(key: self.keyBeingEdited, value: value)
									})
									Button("Cancel", role: .cancel, action: {})
								}, message: {
									Text("Enter the value")
								})

								Spacer()
								
								// Move down button
								Button(action: {
									self.showingMoveSegmentDownAlert = !self.intervalSessionsVM.moveSegmentDown(session: self.tempSession, segmentId: segment.id)
								}) {
									Image(systemName: "arrow.down.square")
								}
								.alert("Failed to move the segment down.", isPresented: self.$showingMoveSegmentDownAlert) {}
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
				.confirmationDialog("Which type of interval?", isPresented: self.$showingIntervalTypeSelection, titleVisibility: .visible) {
					Button("Time") {
						let newSegment = IntervalSegment()
						newSegment.firstValue = 60.0
						newSegment.firstUnits = INTERVAL_UNIT_SECONDS
						self.tempSession.segments.append(newSegment)
					}
					Button("Distance") {
						let newSegment = IntervalSegment()
						newSegment.firstValue = 1000.0
						newSegment.firstUnits = INTERVAL_UNIT_METERS
						self.tempSession.segments.append(newSegment)
					}
					Button("Sets") {
						let newSegment = IntervalSegment()
						newSegment.sets = 1
						self.tempSession.segments.append(newSegment)
					}
				}
				.bold()
			}

			Spacer()

			// Save
			Group() {
				Button(action: {
					if self.intervalSessionsVM.doesIntervalSessionExistInDatabase(sessionId: self.tempSession.id) {
						if self.intervalSessionsVM.updateIntervalSession(session: self.tempSession) {
							self.dismiss()
						}
						else {
							self.showingSaveFailedAlert = true
						}
					}
					else {
						if self.intervalSessionsVM.createIntervalSession(session: self.tempSession) {
							self.dismiss()
						}
						else {
							self.showingSaveFailedAlert = true
						}
					}
				}) {
					Text("Save")
						.frame(minWidth: 0, maxWidth: .infinity)
						.foregroundColor(.white)
						.padding()
				}
				.alert("Failed to create the interval session.", isPresented: self.$showingSaveFailedAlert) {}
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
				.alert("Are you sure you want to delete this workout? This cannot be undone.", isPresented: self.$showingDeleteConfirmation) {
					Button("Delete") {
						if self.intervalSessionsVM.deleteIntervalSession(intervalSessionId: self.tempSession.id) {
							self.dismiss()
						}
						else {
							self.showingDeleteFailedAlert = true
						}
					}
					Button("Cancel") {
					}
				}
				.alert("Failed to delete the interval session.", isPresented: self.$showingDeleteFailedAlert) {}
				.background(RoundedRectangle(cornerRadius: 10, style: .continuous))
				.opacity(0.8)
				.bold()
			}
		}
		.padding(10)
    }
}
