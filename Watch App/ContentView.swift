//
//  ContentView.swift
//  Created by Michael Simms on 9/20/22.
//

import SwiftUI

struct ContentView: View {
	@State private var showingActivitySelection: Bool = false
	@State private var showingResetConfirmation: Bool = false

	var body: some View {
		NavigationStack() {
			ScrollView() {
				Button("Start") {
					showingActivitySelection = true
				}
				.confirmationDialog("Select the workout to perform", isPresented: $showingActivitySelection, titleVisibility: .visible) {
					ForEach(CommonApp.activityTypes, id: \.self) { item in
						NavigationLink(item, destination: ActivityView(activityVM: LiveActivityVM(activityType: item), activityType: item))
					}
				}
				NavigationLink("History", destination: HistoryView())
				NavigationLink("Settings", destination: SettingsView())
				HStack() {
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
					NavigationLink("About", destination: AboutView())
				}
			}
		}
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
