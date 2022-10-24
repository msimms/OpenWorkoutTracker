//
//  PacePlansView.swift
//  Created by Michael Simms on 9/29/22.
//

import SwiftUI

struct PacePlansView: View {
	@Environment(\.colorScheme) var colorScheme
	@StateObject private var pacePlansVM = PacePlansVM()
	@State private var showingNewView: Bool = false

	var body: some View {
		VStack(alignment: .center) {
			if self.pacePlansVM.pacePlans.count > 0 {
				List(self.pacePlansVM.pacePlans, id: \.self) { item in
					Text(item.name)
				}
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
				NavigationLink("+", destination: NewPacePlanView())
					.foregroundColor(colorScheme == .dark ? .white : .black)
			}
		}
	}
}
