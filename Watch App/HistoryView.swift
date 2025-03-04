//
//  HistoryView.swift
//  Created by Michael Simms on 9/20/22.
//

import SwiftUI

struct HistoryView: View {
	@StateObject private var historyVM = HistoryVM()

	let dateFormatter: DateFormatter = {
		let df = DateFormatter()
		df.dateStyle = .short
		df.timeStyle = .short
		return df
	}()

	private func loadHistory() {
		DispatchQueue.global(qos: .userInitiated).async {
			self.historyVM.buildHistoricalActivitiesList(createAllObjects: false)
		}
	}

	private func delete(at offsets: IndexSet) {
		for offset in offsets {
			let item = self.historyVM.historicalActivities[offset]
			let activityVM = StoredActivityVM(activitySummary: item)
			let _ = activityVM.deleteActivity()
		}
	}

	var body: some View {
		switch self.historyVM.state {
		case HistoryVM.VmState.loaded:
			VStack(alignment: .leading) {
				if self.historyVM.historicalActivities.count > 0 {
					List {
						ForEach(self.historyVM.historicalActivities) { item in
							NavigationLink(destination: HistoryDetailsView(activityVM: StoredActivityVM(activitySummary: item))) {
								VStack(alignment: .leading) {
									if item.name.count > 0 {
										Text(item.name)
											.bold()
									}
									HStack() {
										Image(systemName: HistoryVM.imageNameForActivityType(activityType: item.type))
										Text(item.type)
											.font(.system(size: 16))
											.bold()
										Spacer()
										Text("\(self.dateFormatter.string(from: item.startTime))")
											.font(.system(size: 12))
									}
								}
							}
						}
						.onDelete(perform: delete)
					}
					.listStyle(.plain)
				}
				else {
					Text("No History")
				}
			}
		case HistoryVM.VmState.empty:
			VStack(alignment: .center) {
				ProgressView("Loading...").onAppear(perform: self.loadHistory)
					.progressViewStyle(CircularProgressViewStyle(tint: .gray))
			}
		}
    }
}
