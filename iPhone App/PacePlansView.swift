//
//  PacePlansView.swift
//  Created by Michael Simms on 9/29/22.
//

import SwiftUI

struct PacePlansView: View {
	@Environment(\.colorScheme) var colorScheme
	@StateObject private var pacePlansVM = PacePlansVM.shared

	let dateFormatter: DateFormatter = {
		let df = DateFormatter()
		df.dateStyle = .medium
		df.timeZone = .gmt
		return df
	}()

	var body: some View {
		VStack(alignment: .center) {
			if self.pacePlansVM.pacePlans.count > 0 {
				List(self.pacePlansVM.pacePlans, id: \.self) { item in
					NavigationLink(destination: EditPacePlanView(pacePlan: item)) {
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
				Text("No Pace Plans")
			}
		}
		.padding(10)
		.toolbar {
			ToolbarItem(placement: .bottomBar) {
				Spacer()
			}
			ToolbarItem(placement: .bottomBar) {
				NavigationLink("+", destination: EditPacePlanView(pacePlan: PacePlan()))
					.foregroundColor(colorScheme == .dark ? .white : .black)
			}
		}
	}
}
