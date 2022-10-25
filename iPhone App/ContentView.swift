//
//  ContentView.swift
//  OpenWorkoutTracker
//
//  Created by Michael Simms on 9/27/22.
//

import SwiftUI

struct ContentView: View {
	@Environment(\.colorScheme) var colorScheme
	@State private var showingActivitySelection: Bool = false
	@State private var showingViewSelection: Bool = false
	@State private var showingEditSelection: Bool = false
	@State private var showingResetConfirmation: Bool = false
	@State private var isBusy: Bool = false

	var body: some View {
		NavigationStack() {
			
			VStack() {
				
				// Filthy hack to move the Start button down a bit.
				Text(" ")
					.padding(10)
				
				// Workout start button
				Button("Start a Workout") {
					self.showingActivitySelection = true
				}
				.confirmationDialog("Select the workout to perform", isPresented: $showingActivitySelection, titleVisibility: .visible) {
					ForEach(CommonApp.getActivityTypes(), id: \.self) { item in
						NavigationLink(item, destination: ActivityView(activityVM: LiveActivityVM(activityType: item), activityType: item))
					}
				}
				.foregroundColor(.black)
				.font(.custom("HelveticaNeue-CondensedBlack", fixedSize: 48))
				.padding(10)
				
				// View history and statistics button
				Button("View") {
					self.showingViewSelection = true
				}
				.confirmationDialog("What would you like to view?", isPresented: $showingViewSelection, titleVisibility: .visible) {
					NavigationLink(destination: HistoryView()) {
						Text("History")
					}.simultaneousGesture(TapGesture().onEnded{
						self.isBusy = true
					})

					//NavigationLink("History", destination: HistoryView())
					NavigationLink("Statistics", destination: StatisticsView())
					NavigationLink("Workouts", destination: WorkoutsView())
				}
				.foregroundColor(.black)
				.font(.custom("HelveticaNeue-CondensedBlack", fixedSize: 48))
				.padding(10)
				.sheet(isPresented: $isBusy) {
					ProgressView("Loading...")
				}

				Spacer()
				
				// Edit settings button
				Button("Edit") {
					self.showingEditSelection = true
				}
				.confirmationDialog("What would you like to edit?", isPresented: $showingEditSelection, titleVisibility: .visible) {
					NavigationLink("Profile", destination: ProfileView())
					NavigationLink("Settings", destination: SettingsView())
					NavigationLink("Sensors", destination: SensorsView())
					NavigationLink("Interval Sessions", destination: IntervalSessionsView())
					NavigationLink("Pace Plans", destination: PacePlansView())
					NavigationLink("Gear", destination: GearView())
				}
				.foregroundColor(.black)
				.font(.custom("HelveticaNeue-CondensedBlack", fixedSize: 48))
				.padding(10)
				
				// About button
				NavigationLink("About", destination: AboutView())
					.foregroundColor(.black)
					.font(.custom("HelveticaNeue-CondensedBlack", fixedSize: 48))
					.padding(10)
				
				Button("Reset") {
					self.showingResetConfirmation = true
				}
				.alert("This will delete all of your data. Do you wish to continue? This cannot be undone.", isPresented:$showingResetConfirmation) {
					Button("Delete") {
						ResetDatabase()
					}
					Button("Cancel") {
					}
				}
				.foregroundColor(.black)
				.font(.custom("HelveticaNeue", fixedSize: 24))
				.padding(10)
			}
			.opacity(0.5)
			.background(
				Image("Background")
					.resizable()
					.edgesIgnoringSafeArea(.all)
					.frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
			)
		}
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
