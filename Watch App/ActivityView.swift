//
//  ActivityView.swift
//  Created by Michael Simms on 9/20/22.
//

import SwiftUI

struct ActivityView: View {
	@Environment(\.dismiss) var dismiss
	@StateObject var activityVM: LiveActivityVM
	@StateObject private var pacePlansVM = PacePlansVM()
	@StateObject private var intervalSessionsVM = IntervalSessionsVM()
	@State private var showingStopSelection: Bool = false
	@State private var showingIntervalSessionSelection: Bool = false
	@State private var showingPacePlanSelection: Bool = false

	var activityType: String

	var body: some View {
		ScrollView() {
			VStack(alignment: .center) {
				// Top item
				HStack() {
					Text(self.activityVM.value1).font(.system(size: 48))
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
					HStack() {
						Text(self.activityVM.value2).font(.system(size: 24))
						VStack() {
							Text(self.activityVM.title2).font(.system(size: 12))
							Text(self.activityVM.units2).font(.system(size: 12))
						}
					}
					HStack() {
						Text(self.activityVM.value3).font(.system(size: 24))
						VStack() {
							Text(self.activityVM.title3).font(.system(size: 12))
							Text(self.activityVM.units3).font(.system(size: 12))
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
							if self.activityVM.isPaused {
								self.activityVM.pause()
							}
							else if self.activityVM.isInProgress {
								self.showingStopSelection = true
							}
							else if !self.activityVM.start() {
								NSLog("Error starting when the Start button was manually pressed.")
							}
						} label: {
							Label(self.activityVM.isInProgress ? "Stop" : "Start", systemImage: self.activityVM.isInProgress ? "stop" : "play")
						}
						.confirmationDialog("What would you like to do?", isPresented: $showingStopSelection, titleVisibility: .visible) {
							NavigationLink(destination: HistoryDetailsView(activityVM: StoredActivityVM(activityIndex: ACTIVITY_INDEX_UNKNOWN, activityId: self.activityVM.stop(), name: "", description: ""))) {
								Text("Stop")
							}
							Button {
								self.activityVM.pause()
							} label: {
								Label("Pause", systemImage: "pause")
							}
						}
					}
					
					HStack() {
						// Interval sessions
						if self.intervalSessionsVM.intervalSessions.count > 0 {
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
							.opacity(self.activityVM.isInProgress ? 0 : 1)
						}
						
						// Pace plans
						if self.pacePlansVM.pacePlans.count > 0 {
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
							.opacity(self.activityVM.isInProgress ? 0 : 1)
						}
					}
				}
			}
		}
		.navigationTitle(self.activityType)
    }
}
