//
//  NewIntervalSessionView.swift
//  Created by Michael Simms on 10/7/22.
//

import SwiftUI

struct NewIntervalSessionView: View {
	@StateObject private var intervalSessionsVM = IntervalSessionsVM()
	@State private var session: IntervalSession = IntervalSession()
	@State private var name: String = ""
	@State private var sport: String = ""
	@State private var description: String = ""
	@State private var showingIntervalTypeSelection: Bool = false
	@State private var showingIntervalTimeValueSelection: Bool = false
	@State private var showingIntervalDistanceValueSelection: Bool = false
	@State private var showingIntervalRepsValueSelection: Bool = false
	@State private var showingSegmentDetailsSelection: Bool = false
	@State private var showingDeleteConfirmation: Bool = false

	var body: some View {
		VStack(alignment: .center) {

			// Metadata: name, description, etc.
			Group() {
				Text("Name")
					.bold()
				TextField("Name", text: $name)
					.onChange(of: self.name) { value in
						self.session.name = value
					}
				
				Text("Sport")
					.bold()
				Button("") {
				}

				Text("Description")
					.bold()
				TextField("Description", text: $description, axis: .vertical)
					.lineLimit(2...10)
			}

			Spacer()

			Group() {
				VStack(alignment: .leading) {
					ForEach(self.intervalSessionsVM.newSession, id: \.self) { segment in
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
							Button("Time") {
								segment.duration = 100
							}
							Button("Distance") {
								segment.distance = 1000
							}
							Button("Power") {
								segment.power = 100
							}
							Button("Repititions") {
								segment.reps = 8
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
						self.intervalSessionsVM.newSession.append(newSegment)
					}
					Button("Distance") {
						let newSegment = IntervalSegment()
						newSegment.distance = 1000
						newSegment.units = INTERVAL_UNIT_METERS
						self.intervalSessionsVM.newSession.append(newSegment)
					}
					Button("Sets") {
						let newSegment = IntervalSegment()
						newSegment.sets = 3
						newSegment.units = INTERVAL_UNIT_NOT_SET
						self.intervalSessionsVM.newSession.append(newSegment)
					}
				}
				.bold()
			}

			Spacer()

			// Save and Delete
			Group() {
				Button(action: {
					
				}) {
					Text("Save")
						.frame(minWidth: 0, maxWidth: .infinity)
						.foregroundColor(.white)
						.padding()
				}
				.background(RoundedRectangle(cornerRadius: 10, style: .continuous))
				.opacity(0.8)
				.bold()

				Button(action: { self.showingDeleteConfirmation = true }) {
					Text("Delete")
						.frame(minWidth: 0, maxWidth: .infinity)
						.foregroundColor(.red)
						.padding()
				}
				.background(RoundedRectangle(cornerRadius: 10, style: .continuous))
				.alert("Are you sure you want to delete this workout? This cannot be undone.", isPresented: $showingDeleteConfirmation) {
					Button("Delete") {
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
