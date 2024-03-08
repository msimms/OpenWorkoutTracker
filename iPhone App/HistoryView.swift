//
//  HistoryView.swift
//  Created by Michael Simms on 9/20/22.
//

import SwiftUI

struct HistoryView: View {
	@ObservedObject private var historyVM = HistoryVM()
	@State var displayedDates : Set<Date> = []

	let dateFormatter: DateFormatter = {
		let df = DateFormatter()
		df.dateStyle = .medium
		df.timeStyle = .short
		return df
	}()

	private func loadHistory() {
		DispatchQueue.global(qos: .userInitiated).async {
			if let updatesSince = self.displayedDates.min() {
				let _ = ApiClient.shared.requestUpdatesSince(timestamp: updatesSince)
			}
			self.historyVM.buildHistoricalActivitiesList(createAllObjects: false)
		}
	}

	var body: some View {
		ZStack() {
			// The user has connected the app to the server, but we don't have a valid session, move to the login screen.
			if Preferences.shouldBroadcastToServer () && !ApiClient.shared.isCurrentlyLoggedIn() {
				LoginView()
			}
			
			// User is either logged in or has chosen not to connect the app.
			else {

				// If we're loading data then display the progress indicator.
				if self.historyVM.state == HistoryVM.VmState.empty {
					ProgressView("Loading...").onAppear(perform: self.loadHistory)
						.progressViewStyle(CircularProgressViewStyle(tint: .gray))
						.zIndex(1)
				}
				
				// The list of stored activities.
				VStack(alignment: .center) {
					if self.historyVM.historicalActivities.count > 0 {
						List(self.historyVM.historicalActivities, id: \.self) { item in
							NavigationLink(destination: HistoryDetailsView(activityVM: StoredActivityVM(activitySummary: item))) {
								HStack() {
									Image(systemName: HistoryVM.imageNameForActivityType(activityType: item.type))
										.frame(width: 32)
									VStack(alignment: .leading) {
										if item.name.count > 0 {
											Text(item.name)
												.bold()
												.font(Font.headline)
										}
										Text("\(self.dateFormatter.string(from: item.startTime))")
										if item.source == ActivitySummary.Source.healthkit {
											Text("HealthKit")
												.bold()
												.foregroundColor(.gray)
												.font(Font.subheadline)
										}
									}
									.onAppear() {
										item.requestMetadata()
										self.displayedDates.insert(item.startTime)
									}
									.onDisappear {
										self.displayedDates.remove(item.startTime)
									}
								}
							}
						}
						.listStyle(.plain)
						.gesture(
							DragGesture().onChanged { value in
								if value.translation.height > 0 {
								} else {
								}
							})
					}
					else if self.historyVM.state == HistoryVM.VmState.loaded {
						Text("No History")
					}
				}
			}
		}
		.refreshable {
			self.historyVM.state = HistoryVM.VmState.empty
		}
    }
}
