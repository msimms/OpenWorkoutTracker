//
//  ContentView.swift
//  Created by Michael Simms on 9/20/22.
//

import SwiftUI

struct ContentView: View {
	@State private var showingActivitySelection: Bool = false

	var body: some View {
		NavigationStack() {
			ScrollView() {
				Group() {
					// Start button
					Button(action: {
						self.showingActivitySelection = true
					}) {
						HStack {
							Text("Start")
							Image(systemName: "play")
						}
					}
					.confirmationDialog("Select the workout to perform", isPresented: self.$showingActivitySelection, titleVisibility: .visible) {
						ForEach(CommonApp.activityTypes, id: \.self) { item in
							NavigationLink(item, destination: ActivityView(activityVM: LiveActivityVM(activityType: item, recreateOrphanedActivities: false), activityType: item))
						}
					}
					.frame(minWidth: 0, maxWidth: .infinity)
					
					// History button
					NavigationLink(destination: HistoryView()) {
						HStack {
							Text("History")
							Image(systemName: "list.bullet.clipboard")
						}
					}
					.frame(minWidth: 0, maxWidth: .infinity)
					
					// Settings and About buttons
					HStack() {
						NavigationLink(destination: SettingsView()) {
							ZStack {
								Image(systemName: "gear")
							}
						}
						.frame(minWidth: 0, maxWidth: .infinity)
						NavigationLink(destination: AboutView()) {
							ZStack {
								Image(systemName: "questionmark.circle")
							}
						}
						.frame(minWidth: 0, maxWidth: .infinity)
					}
				}
				.padding(.horizontal)

				// iPhone connectivity status
				Image(systemName: "iphone")
					.opacity(CommonApp.shared.watchSession.isConnected ? 1 : 0)
			}
		}
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
