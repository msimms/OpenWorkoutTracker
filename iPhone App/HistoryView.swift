//
//  HistoryView.swift
//  Created by Michael Simms on 9/20/22.
//

import SwiftUI

struct HistoryView: View {
	@ObservedObject private var historyVM = HistoryVM()

	let dateFormatter: DateFormatter = {
		let df = DateFormatter()
		df.dateStyle = .medium
		df.timeStyle = .short
		return df
	}()

	private func loadHistory() {
		DispatchQueue.global(qos: .userInitiated).async {
			self.historyVM.buildHistoricalActivitiesList(createAllObjects: false)
		}
	}

	var body: some View {
		ZStack() {
			if self.historyVM.state == HistoryVM.VmState.empty {
				ProgressView("Loading...").onAppear(perform: self.loadHistory)
					.progressViewStyle(CircularProgressViewStyle(tint: .gray))
					.zIndex(1)
			}
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
		.refreshable {
			self.historyVM.state = HistoryVM.VmState.empty
		}
    }
}
