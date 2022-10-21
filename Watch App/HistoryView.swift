//
//  HistoryView.swift
//  Created by Michael Simms on 9/20/22.
//

import SwiftUI

struct HistoryView: View {
	@Environment(\.dismiss) var dismiss
	@StateObject private var activitiesVM = ActivitiesVM()

	let dateFormatter: DateFormatter = {
		let df = DateFormatter()
		df.dateStyle = .medium
		df.timeStyle = .short
		return df
	}()

	var body: some View {
		VStack(alignment: .leading) {
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

			Button("Close") {
				self.dismiss()
			}
			.bold()
		}
    }
}
