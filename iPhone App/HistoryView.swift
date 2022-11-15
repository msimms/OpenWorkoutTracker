//
//  HistoryView.swift
//  Created by Michael Simms on 9/20/22.
//

import SwiftUI

struct HistoryView: View {
	@Environment(\.colorScheme) var colorScheme
	@ObservedObject private var historyVM = HistoryVM()

	let dateFormatter: DateFormatter = {
		let df = DateFormatter()
		df.dateStyle = .medium
		df.timeStyle = .short
		return df
	}()

	private func loadHistory() {
		self.historyVM.buildHistoricalActivitiesList()
	}

	var body: some View {
		switch self.historyVM.state {
		case HistoryVM.State.empty:
			VStack(alignment: .center) {
				ProgressView("Loading...").onAppear(perform: self.loadHistory)
					.progressViewStyle(CircularProgressViewStyle(tint: .black))
			}
		case HistoryVM.State.loaded:
			VStack(alignment: .center) {
				if self.historyVM.historicalActivities.count > 0 {
					List(self.historyVM.historicalActivities, id: \.self) { item in
						NavigationLink(destination: HistoryDetailsView(activityVM: StoredActivityVM(activitySummary: item))) {
							HStack() {
								Image(systemName: HistoryVM.imageNameForActivityType(activityType: item.type))
									.frame(width: 48)
								VStack(alignment: .leading) {
									if item.name.count > 0 {
										Text(item.name)
											.bold()
									}
									Text("\(self.dateFormatter.string(from: item.startTime))")
								}
							}
						}
					}
					.listStyle(.plain)
				}
				else {
					Text("No History")
				}
			}
		}
    }
}
