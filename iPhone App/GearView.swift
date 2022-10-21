//
//  GearView.swift
//  Created by Michael Simms on 9/29/22.
//

import SwiftUI

struct GearView: View {
	@StateObject var gearVM: GearVM = GearVM()
	@State private var showingAddSelection: Bool = false

	var body: some View {
		VStack(alignment: .center) {
			VStack() {
				let bikes = self.gearVM.listBikes()

				Text("Bicycles")
					.bold()
				if bikes.count > 0 {
					List(bikes, id: \.self) { item in
						NavigationLink(destination: EditBikeView(id: item.id, name: item.name, description: item.description)) {
							Text(item.name)
						}
					}
					.listStyle(.plain)
				}
				else {
					Text("No Bicycles")
				}
			}
			.padding(10)
			VStack() {
				let shoes = self.gearVM.listShoes()

				Text("Shoes")
					.bold()
				if shoes.count > 0 {
					List(self.gearVM.listShoes(), id: \.self) { item in
						NavigationLink(destination: EditShoesView(id: item.id, name: item.name, description: item.description)) {
							Text(item.name)
						}
					}
					.listStyle(.plain)
				}
				else {
					Text("No Shoes")
				}
			}
			.padding(10)
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
						Label("+", systemImage: "plus")
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
