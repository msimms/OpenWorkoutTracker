//
//  EditShoesView.swift
//  Created by Michael Simms on 10/10/22.
//

import SwiftUI

struct EditShoesView: View {
	@State var id: UInt64 = 0
	@State var name: String = ""
	@State var description: String = ""
	@State var showingSaveError: Bool = false

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

			Button("Save") {
				let item = GearSummary(id: self.id, name: self.name, description: self.description)
				showingSaveError = !GearVM.saveShoes(item: item)
			}
		}
		.padding(10)
    }
}
