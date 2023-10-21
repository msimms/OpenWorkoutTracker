//
//  RoutesView.swift
//  Created by Michael Simms on 10/12/23.
//

import SwiftUI

struct RoutesView: View {
	@Environment(\.colorScheme) var colorScheme
	@StateObject var routesVM: RoutesVM = RoutesVM()
	@State private var showingAddSelection: Bool = false

	var body: some View {
		VStack(alignment: .center) {
			Group() {
				let routes = self.routesVM.listRoutes()
				
				if routes.count > 0 {
					List(routes, id: \.self) { item in
						NavigationLink(destination: RoutesView()) {
							Text(item.name)
						}
					}
					.listStyle(.plain)
				}
				else {
					Text("No Routes")
				}
			}
		}
		.padding(10)
		.toolbar {
			ToolbarItem(placement: .bottomBar) {
				Spacer()
			}
			ToolbarItem(placement: .bottomBar) {
				NavigationLink("+", destination: ImportRouteView())
					.foregroundColor(self.colorScheme == .dark ? .white : .black)
			}
		}
	}
}
