//
//  ImportRouteView.swift
//  Created by Michael Simms on 10/14/23.
//

import SwiftUI

struct ImportRouteView: View {
	@Environment(\.colorScheme) var colorScheme
	@State private var name: String = ""
	@State private var description: String = ""
	@State private var showingSaveError: Bool = false

	var body: some View {
		VStack(alignment: .center) {
			Group() {
				Text("Name")
					.bold()
				TextField("Name", text: self.$name)
					.foregroundColor(self.colorScheme == .dark ? .white : .black)
					.background(self.colorScheme == .dark ? .black : .white)
				
				Text("Description")
					.bold()
				TextField("Description", text: self.$description)
					.foregroundColor(self.colorScheme == .dark ? .white : .black)
					.background(self.colorScheme == .dark ? .black : .white)
			}
			
			SelectFileView()

			Group() {
				Button(action: {
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
			}
		}
		.padding(10)
    }
}

#Preview {
    ImportRouteView()
}
