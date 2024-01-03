//
//  GearView.swift
//  Created by Michael Simms on 9/29/22.
//

import SwiftUI

struct GearView: View {
	@Environment(\.colorScheme) var colorScheme
	@StateObject var gearVM: GearVM = GearVM()
	@State private var showingAddSelection: Bool = false

	var body: some View {
		VStack(alignment: .center) {
			HStack() {
				Image(systemName: "questionmark.circle")
				Text("Keep track of your shoes and bicycles. Tag activities with the gear used.")
			}
			.padding(INFO_INSETS)

			let bikes = self.gearVM.listBikes()
			let shoes = self.gearVM.listShoes()

			Text("Bicycles")
				.bold()
			if bikes.count > 0 {
				List(bikes, id: \.self) { item in
					NavigationLink(destination: EditBikeView(gearId: item.gearId, name: item.name, description: item.description, serviceHistory: item.serviceHistory)) {
						let textColor = item.timeRetired.timeIntervalSince1970 > 0 ? Color.gray : (self.colorScheme == .dark ? Color.white : Color.black)
						Text(item.name)
							.foregroundColor(textColor)
					}
				}
				.listStyle(.plain)
			}
			else {
				Text("No Bicycles")
			}

			Spacer()
				.frame(minHeight: 10, idealHeight: 40, maxHeight: 80)
				.fixedSize()

			Text("Shoes")
				.bold()
			if shoes.count > 0 {
				List(self.gearVM.listShoes(), id: \.self) { item in
					NavigationLink(destination: EditShoesView(gearId: item.gearId, name: item.name, description: item.description)) {
						let textColor = item.timeRetired.timeIntervalSince1970 > 0 ? Color.gray : (self.colorScheme == .dark ? Color.white : Color.black)
						Text(item.name)
							.foregroundColor(textColor)
					}
				}
				.listStyle(.plain)
			}
			else {
				Text("No Shoes")
			}
		}
		.padding(10)
		.toolbar {
			ToolbarItem(placement: .bottomBar) {
				Spacer()
			}
			ToolbarItem(placement: .bottomBar) {
				HStack() {
					Button {
						self.showingAddSelection = true
					} label: {
						Text("+")
							.foregroundColor(self.colorScheme == .dark ? .white : .black)
					}
				}
				.confirmationDialog("What would you like to add?", isPresented: $showingAddSelection, titleVisibility: .visible) {
					NavigationLink("Bicycle", destination: EditBikeView())
					NavigationLink("Shoes", destination: EditShoesView())
				}
			}
		}
    }
}
