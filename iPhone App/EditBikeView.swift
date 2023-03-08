//
//  EditBikeView.swift
//  Created by Michael Simms on 10/10/22.
//

import SwiftUI

struct EditBikeView: View {
	@State var id: UInt64 = 0
	@State var name: String = ""
	@State var description: String = ""
	@State var showingSaveError: Bool = false
	@State var showingDeleteError: Bool = false

	var body: some View {
		VStack(alignment: .center) {
			Group() {
				Text("Name")
					.bold()
				TextField("Name", text: $name)
			}

			Group() {
				Text("Description")
					.bold()
				TextField("Description", text: $description, axis: .vertical)
					.lineLimit(2...10)
			}

			Spacer()

			Group() {
				Button(action: {
					let item = GearSummary(id: self.id, name: self.name, description: self.description)
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
					self.showingDeleteError = !GearVM.deleteBike(id: self.id)
				}) {
					Text("Delete")
						.frame(minWidth: 0, maxWidth: .infinity)
						.foregroundColor(.white)
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
