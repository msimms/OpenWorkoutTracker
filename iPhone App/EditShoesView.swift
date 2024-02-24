//
//  EditShoesView.swift
//  Created by Michael Simms on 10/10/22.
//

import SwiftUI

struct EditShoesView: View {
	@Environment(\.colorScheme) var colorScheme
	@State var gearId: UUID = UUID()
	@State var name: String = ""
	@State var description: String = ""
	@State var showingSaveError: Bool = false
	@State var showingRetireError: Bool = false
	@State var showingDeleteError: Bool = false

	var body: some View {
		VStack(alignment: .center) {
			Group() {
				Text("Name")
					.font(.system(size: 24))
					.bold()
				TextField("Name", text: self.$name)
			}
			.padding(SIDE_INSETS)

			Group() {
				Text("Description")
					.font(.system(size: 24))
					.bold()
				TextField("Description", text: self.$description, axis: .vertical)
					.lineLimit(2...10)
			}
			.padding(SIDE_INSETS)

			Spacer()

			Group() {
				Button(action: {
					let item = GearSummary(gearId: self.gearId, name: self.name, description: self.description)
					self.showingSaveError = !GearVM.createShoes(item: item)
				}) {
					Text("Save")
						.frame(minWidth: 0, maxWidth: .infinity)
						.foregroundColor(self.colorScheme == .dark ? .black : .white)
						.padding()
				}
				.alert("Failed to save.", isPresented: self.$showingSaveError) {}
				.background(RoundedRectangle(cornerRadius: 10, style: .continuous))
				.opacity(0.8)
				.bold()

				Button(action: {
					let item = GearSummary(gearId: self.gearId, name: self.name, description: self.description)
					self.showingRetireError = !GearVM.retireShoes(item: item)
				}) {
					Text("Retire")
						.frame(minWidth: 0, maxWidth: .infinity)
						.foregroundColor(self.colorScheme == .dark ? .black : .white)
						.padding()
				}
				.alert("Failed to retire.", isPresented: self.$showingRetireError) {}
				.background(RoundedRectangle(cornerRadius: 10, style: .continuous))
				.opacity(0.8)
				.bold()

				Button(action: {
					self.showingDeleteError = !GearVM.deleteShoes(gearId: self.gearId)
				}) {
					HStack() {
						Image(systemName: "trash")
						Text("Delete")
					}
					.frame(minWidth: 0, maxWidth: .infinity)
					.foregroundColor(.red)
					.padding()
				}
				.alert("Failed to delete.", isPresented: self.$showingDeleteError) {}
				.background(RoundedRectangle(cornerRadius: 10, style: .continuous))
				.opacity(0.8)
				.bold()
			}
		}
		.padding(10)
    }
}
