//
//  EditBikeView.swift
//  Created by Michael Simms on 10/10/22.
//

import SwiftUI

struct EditBikeView: View {
	@Environment(\.colorScheme) var colorScheme
	@State var gearId: UUID = UUID()
	@State var name: String = ""
	@State var description: String = ""
	@State var serviceHistory: Array<GearServiceItem> = []
	@State var showingSaveError: Bool = false
	@State var showingRetireError: Bool = false
	@State var showingDeleteError: Bool = false

	let dateFormatter: DateFormatter = {
		let df = DateFormatter()
		df.dateStyle = .medium
		df.timeStyle = .none
		return df
	}()

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
				Text("Service History")
					.font(.system(size: 24))
					.bold()
				if self.serviceHistory.count > 0 {
					List(self.serviceHistory, id: \.self) { item in
						VStack(alignment: .leading) {
							Text("\(self.dateFormatter.string(from: item.timeServiced))")
								.italic()
							Text(item.description)
						}
					}
					.listStyle(.plain)
				}
				else {
					Text("None")
				}
			}

			Spacer()

			Group() {
				NavigationLink(destination: GearServiceItemView(gearId: self.gearId)) {
					HStack() {
						Image(systemName: "doc.append")
						Text("Add Service Record")
					}
					.frame(minWidth: 0, maxWidth: .infinity)
					.foregroundColor(self.colorScheme == .dark ? .black : .white)
					.padding()
				}
				.background(RoundedRectangle(cornerRadius: 10, style: .continuous))
				.opacity(0.8)
				.bold()

				Button(action: {
					let item = GearSummary(gearId: self.gearId, name: self.name, description: self.description)
					self.showingSaveError = !GearVM.createBike(item: item)
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
					self.showingRetireError = !GearVM.retireBike(item: item)
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
					self.showingDeleteError = !GearVM.deleteBike(gearId: self.gearId)
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
