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
		df.timeZone = .gmt
		return df
	}()

	var body: some View {
		VStack(alignment: .center) {
			if self.intervalSessionsVM.intervalSessions.count > 0 {
				List(self.intervalSessionsVM.intervalSessions, id: \.self) { item in
					NavigationLink(destination: EditIntervalSessionView(sessionid: item.id)) {
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
				Text("No Interval Sessions")
			}
		}
		.padding(10)
		.toolbar {
			ToolbarItem(placement: .bottomBar) {
				Spacer()
			}
			ToolbarItem(placement: .bottomBar) {
				NavigationLink("+", destination: EditIntervalSessionView(sessionid: UUID()))
					.foregroundColor(colorScheme == .dark ? .white : .black)
			}
		}
	}
}
