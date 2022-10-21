//
//  ActivityView.swift
//  Created by Michael Simms on 9/20/22.
//

import SwiftUI

struct ActivityView: View {
	@Environment(\.dismiss) var dismiss
	@StateObject var activity: LiveActivityVM
	@StateObject private var pacePlansVM = PacePlansVM()
	@StateObject private var intervalSessionsVM = IntervalSessionsVM()
	@State private var showingStopSelection: Bool = false
	@State private var showingIntervalSessionSelection: Bool = false
	@State private var showingPacePlanSelection: Bool = false

	var activityType: String

	var body: some View {
		VStack(alignment: .center) {
			// Top item
			HStack() {
				Text(activity.value1).font(.system(size: 48))
			}

			// Minor items
			HStack() {
				Text(activity.value2).font(.system(size: 24))
				VStack() {
					Text(activity.title2).font(.system(size: 12))
					Text(activity.units2).font(.system(size: 12))
				}
			}
			HStack() {
				Text(activity.value3).font(.system(size: 24))
				VStack() {
					Text(activity.title3).font(.system(size: 12))
					Text(activity.units3).font(.system(size: 12))
				}
			}

			// Start/Stop/Cancel
			HStack() {
				Button {
					self.dismiss()
				} label: {
					Text("Cancel")
				}
				Button {
					if self.activity.isPaused {
						self.activity.pause()
					}
					else if self.activity.isInProgress {
						self.showingStopSelection = true
					}
					else {
						self.activity.start()
					}
				} label: {
					Label(self.activity.isInProgress ? "Stop" : "Start", systemImage: self.activity.isInProgress ? "stop" : "play")
				}
				.confirmationDialog("What would you like to do?", isPresented: $showingStopSelection, titleVisibility: .visible) {
					NavigationLink(destination: HistoryDetailsView(activityVM: StoredActivityVM(activityIndex: ACTIVITY_INDEX_UNKNOWN, activityId: self.activity.stop()))) {
						Text("Stop")
					}
					Button {
						self.activity.pause()
					} label: {
						Label("Pause", systemImage: "pause")
					}
				}
			}
			
			HStack() {
				// Interval sessions
				Button {
					self.showingIntervalSessionSelection = true
				} label: {
					Text("Intervals")
				}
				.confirmationDialog("Select the interval session to perform", isPresented: $showingIntervalSessionSelection, titleVisibility: .visible) {
					ForEach(self.intervalSessionsVM.intervalSessions, id: \.self) { item in
						Button {
							SetCurrentIntervalWorkout(item.id.uuidString)
						} label: {
							Text(item.name)
						}
					}
				}
				.opacity(self.activity.isInProgress ? 0 : 1)

				// Pace plans
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
				.opacity(self.activity.isInProgress ? 0 : 1)
			}
		}
		.navigationTitle(activityType)
    }
}
