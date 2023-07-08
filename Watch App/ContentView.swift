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
				// Start button
				Button("Start") {
					self.showingActivitySelection = true
				}
				.confirmationDialog("Select the workout to perform", isPresented: self.$showingActivitySelection, titleVisibility: .visible) {
					ForEach(CommonApp.activityTypes, id: \.self) { item in
						NavigationLink(item, destination: ActivityView(activityVM: LiveActivityVM(activityType: item, recreateOrphanedActivities: false), activityType: item))
					}
				}

				// History button
				NavigationLink("History", destination: HistoryView())

				// Settings and About buttons
				HStack() {
					NavigationLink(destination: SettingsView()) {
						ZStack {
							Image(systemName: "gear")
						}
					}
					NavigationLink(destination: AboutView()) {
						ZStack {
							Image(systemName: "questionmark.circle")
						}
					}
				}

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
