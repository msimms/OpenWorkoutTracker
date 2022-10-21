//
//  ContentView.swift
//  Created by Michael Simms on 9/20/22.
//

import SwiftUI

struct ContentView: View {
	@State private var showingActivitySelection: Bool = false
	@State var pushed: Bool = true

	var body: some View {
		ScrollView() {
			NavigationStack() {
				Button("Start") {
					showingActivitySelection = true
				}
				.confirmationDialog("Select the workout to perform", isPresented: $showingActivitySelection, titleVisibility: .visible) {
					ForEach(ActivitiesVM.getActivityTypes(), id: \.self) { item in
						NavigationLink(item, destination: ActivityView(activity: LiveActivityVM(activityType: item), activityType: item))
					}
				}
				NavigationLink("History", destination: HistoryView())
				HStack() {
					NavigationLink("Settings", destination: SettingsView())
					NavigationLink("About", destination: AboutView())
				}
			}
			.frame(height: 350)
		}
		.frame(height: 350)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
