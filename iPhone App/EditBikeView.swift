//
//  EditBikeView.swift
//  Created by Michael Simms on 10/10/22.
//

import SwiftUI

struct EditBikeView: View {
	@State var gearId: UUID = UUID()
	@State var name: String = ""
	@State var description: String = ""
	@State var serviceHistory: Array<GearServiceItem> = []
	@State var showingSaveError: Bool = false
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
					.bold()
				TextField("Name", text: self.$name)
			}

			Group() {
				Text("Description")
					.bold()
				TextField("Description", text: self.$description, axis: .vertical)
					.lineLimit(2...10)
			}

			Spacer()
			
			Group() {
				Text("Service History")
					.bold()
				if self.serviceHistory.count > 0 {
					List(self.serviceHistory, id: \.self) { item in
						VStack(alignment: .leading) {
							Text("\(self.dateFormatter.string(from: item.servicedTime))")
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
				Button(action: {
					let item = GearSummary(gearId: self.gearId, name: self.name, description: self.description)
					self.showingSaveError = !GearVM.createBike(item: item)
				}) {
					Text("Save")
						.frame(minWidth: 0, maxWidth: .infinity)
						.foregroundColor(.white)
						.padding()
				}
				.alert("Failed to save.", isPresented: self.$showingSaveError) {}
				.background(RoundedRectangle(cornerRadius: 10, style: .continuous))
				.opacity(0.8)
				.bold()
				
				Button(action: {
					self.showingDeleteError = !GearVM.deleteBike(gearId: self.gearId)
				}) {
					Text("Delete")
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
