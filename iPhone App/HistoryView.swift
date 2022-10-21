//
//  HistoryView.swift
//  Created by Michael Simms on 9/20/22.
//

import SwiftUI

struct HistoryView: View {
	@Environment(\.colorScheme) var colorScheme
	@Environment(\.dismiss) var dismiss
	@StateObject private var activitiesVM = ActivitiesVM()

	let dateFormatter: DateFormatter = {
		let df = DateFormatter()
		df.dateStyle = .medium
		df.timeStyle = .short
		return df
	}()

	var body: some View {
		VStack(alignment: .center) {
			if self.activitiesVM.historicalActivities.count > 0 {
				List(self.activitiesVM.historicalActivities, id: \.self) { item in
					NavigationLink(destination: HistoryDetailsView(activityVM: StoredActivityVM(activityIndex: item.index, activityId: item.id))) {
						VStack() {
							Text(item.name)
								.bold()
							HStack() {
								Image(systemName: ActivitiesVM.imageNameForActivityType(activityType: item.type))
								Text(item.type)
									.bold()
								Spacer()
								Text("\(self.dateFormatter.string(from: item.startTime))")
							}
						}
					}
				}
				.listStyle(.plain)
			}
			else {
				Text("Ho History")
			}
		}
    }
}
