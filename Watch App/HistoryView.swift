//
//  HistoryView.swift
//  Created by Michael Simms on 9/20/22.
//

import SwiftUI

struct HistoryView: View {
	@Environment(\.dismiss) var dismiss
	@StateObject private var historyVM = HistoryVM()

	let dateFormatter: DateFormatter = {
		let df = DateFormatter()
		df.dateStyle = .short
		df.timeStyle = .short
		return df
	}()

	var body: some View {
		VStack(alignment: .leading) {
			List(self.historyVM.historicalActivities, id: \.self) { item in
				NavigationLink(destination: HistoryDetailsView(activityVM: StoredActivityVM(activityIndex: item.index, activityId: item.id, name: item.name, description: item.description))) {
					VStack(alignment: .leading) {
						if item.name.count > 0 {
							Text(item.name)
								.bold()
						}
						HStack() {
							Image(systemName: HistoryVM.imageNameForActivityType(activityType: item.type))
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
