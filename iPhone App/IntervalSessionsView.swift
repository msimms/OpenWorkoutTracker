//
//  IntervalSessionsView.swift
//  Created by Michael Simms on 9/29/22.
//

import SwiftUI

struct IntervalSessionsView: View {
	@StateObject private var intervalSessionsVM = IntervalSessionsVM()
	
	var body: some View {
		VStack(alignment: .center) {
			if self.intervalSessionsVM.intervalSessions.count > 0 {
				List(self.intervalSessionsVM.intervalSessions, id: \.self) { item in
					Text(item.name)
				}
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
				NavigationLink("+", destination: NewIntervalSessionView())
			}
		}
	}
}
