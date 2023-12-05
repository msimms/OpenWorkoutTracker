//
//  IntervalSessionsView.swift
//  Created by Michael Simms on 9/29/22.
//

import SwiftUI

struct IntervalSessionsView: View {
	@Environment(\.colorScheme) var colorScheme
	@StateObject private var intervalSessionsVM = IntervalSessionsVM.shared
	
	let dateFormatter: DateFormatter = {
		let df = DateFormatter()
		df.dateStyle = .medium
		df.timeZone = .current
		return df
	}()

	var body: some View {
		VStack(alignment: .center) {
			HStack() {
				Image(systemName: "questionmark.circle")
				Text("This view is for managing interval sessions. You'll receive messages on the activity screen when it's time to perform the next interval.")
			}
			.padding(EdgeInsets.init(top: 5, leading: 0, bottom: 20, trailing: 0))

			if self.intervalSessionsVM.intervalSessions.count > 0 {
				List(self.intervalSessionsVM.intervalSessions, id: \.self) { item in
					NavigationLink(destination: EditIntervalSessionView(session: item)) {
						VStack(alignment: .leading) {
							Text(item.name)
								.bold()
							Text("Last Updated: \(self.dateFormatter.string(from: item.lastUpdatedTime))")
								.italic()
						}
					}
				}
				.listStyle(.plain)
			}
			else {
				Text("No Interval Sessions\n(Click the + sign to create one)")
					.multilineTextAlignment(.center)
			}
		}
		.padding(10)
		.toolbar {
			ToolbarItem(placement: .bottomBar) {
				Spacer()
			}
			ToolbarItem(placement: .bottomBar) {
				NavigationLink("+", destination: EditIntervalSessionView(session: IntervalSession()))
					.foregroundColor(self.colorScheme == .dark ? .white : .black)
			}
		}
	}
}
