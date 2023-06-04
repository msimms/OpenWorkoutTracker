//
//  ContentView.swift
//  Created by Michael Simms on 9/27/22.
//

import SwiftUI

struct ContentView: View {
	@State private var showingActivitySelection: Bool = false
	@State private var showingViewSelection: Bool = false
	@State private var showingEditSelection: Bool = false
	@State private var isBusy: Bool = false
	private var backgroundImageIndex: Int = Int.random(in: 1..<4)

	var body: some View {
		NavigationStack() {
			
			VStack() {
				
				// Filthy hack to move the Start button down a bit.
				Text(" ")
					.padding(6)
				
				// Workout start button
				Button("Start a\nWorkout") {
					self.showingActivitySelection = true
				}
				.confirmationDialog("Select the workout to perform", isPresented: self.$showingActivitySelection, titleVisibility: .visible) {
					ForEach(CommonApp.activityTypes, id: \.self) { item in
						NavigationLink(item, destination: ActivityView(activityVM: LiveActivityVM(activityType: item, recreateOrphanedActivities: false), activityType: item))
					}
				}
				.foregroundColor(.black)
				.font(.custom("HelveticaNeue-CondensedBlack", fixedSize: 64))
				.padding(10)

				Spacer()

				// View history and statistics button
				Button("View") {
					self.showingViewSelection = true
				}
				.confirmationDialog("What would you like to view?", isPresented: self.$showingViewSelection, titleVisibility: .visible) {
					NavigationLink("History", destination: HistoryView())
					NavigationLink("Statistics", destination: StatisticsView())
					NavigationLink("Workouts", destination: WorkoutsView())
					NavigationLink("Zones", destination: ZonesView())
				}
				.foregroundColor(.black)
				.font(.custom("HelveticaNeue-CondensedBlack", fixedSize: 64))
				.padding(10)

				// Edit settings button
				Button("Edit") {
					self.showingEditSelection = true
				}
				.confirmationDialog("What would you like to edit?", isPresented: self.$showingEditSelection, titleVisibility: .visible) {
					NavigationLink("Profile", destination: ProfileView())
					NavigationLink("Settings", destination: SettingsView())
					NavigationLink("Sensors", destination: SensorsView())
					NavigationLink("Interval Sessions", destination: IntervalSessionsView())
					NavigationLink("Pace Plans", destination: PacePlansView())
					NavigationLink("Gear", destination: GearView())
				}
				.foregroundColor(.black)
				.font(.custom("HelveticaNeue-CondensedBlack", fixedSize: 64))
				.padding(10)
				
				// About button
				NavigationLink("About", destination: AboutView())
					.foregroundColor(.black)
					.font(.custom("HelveticaNeue-CondensedBlack", fixedSize: 64))
					.padding(10)
					.toolbar {
						ToolbarItem(placement: .bottomBar) {
							Image(systemName: "applewatch")
								.opacity(CommonApp.shared.watchSession.isConnected ? 1 : 0)
					}
				}
			}
			.opacity(0.7)
			.background(
				Image("Background" + String(backgroundImageIndex))
					.resizable()
					.edgesIgnoringSafeArea(.all)
					.aspectRatio(contentMode: .fill)
					.opacity(0.7)
			)
		}
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
