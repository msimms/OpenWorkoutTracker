//
//  RoutesView.swift
//  Created by Michael Simms on 10/12/23.
//

import SwiftUI

struct RoutesView: View {
	@Environment(\.colorScheme) var colorScheme
	@StateObject var routesVM: RoutesVM = RoutesVM()

	var body: some View {
		VStack(alignment: .center) {
			HStack() {
				Image(systemName: "questionmark.circle")
				Text("Manage routes. Routes can be overlayed on the maps for bike rides, runs, hikes, etc.")
			}
			.padding(INFO_INSETS)

			if self.routesVM.routes.count > 0 {
				List(self.routesVM.routes, id: \.self) { item in
					NavigationLink(destination: EditRouteView(route: item)) {
						Text(item.name)
							.bold()
					}
				}
				.listStyle(.plain)
			}
			else {
				Text("No Routes")
			}
		}
		.padding(10)
		.toolbar {
			ToolbarItem(placement: .bottomBar) {
				Spacer()
			}
			ToolbarItem(placement: .bottomBar) {
				NavigationLink("+", destination: EditRouteView(route: RouteSummary()))
					.foregroundColor(self.colorScheme == .dark ? .white : .black)
			}
		}
	}
}
