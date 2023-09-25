//
//  TagsView.swift
//  Created by Michael Simms on 10/20/22.
//

import SwiftUI

struct TagsView: View {
	@Environment(\.colorScheme) var colorScheme
	@Environment(\.presentationMode) var presentation
	@StateObject var activityVM: StoredActivityVM
	@State private var newTag: String = ""
	@State private var showingDeleteConfirmation: Bool = false

	var body: some View {
		VStack(alignment: .center) {
			HStack() {
				ForEach(self.activityVM.listTags(), id: \.self) { item in
					Button(action: {
						self.showingDeleteConfirmation = true
					}) {
						HStack {
							Text(item)
							Image(systemName: "trash")
						}
					}
					.padding()
					.background(Color.gray)
					.foregroundColor(.white)
					.cornerRadius(10)
					.buttonStyle(PlainButtonStyle())
					.alert("Are you sure you want to delete this tag?", isPresented: self.$showingDeleteConfirmation) {
						Button("Delete") {
							if self.activityVM.deleteTag(tag: item) {
								self.presentation.wrappedValue.dismiss()
							}
						}
						Button("Cancel") {
						}
					}
					.foregroundColor(self.colorScheme == .dark ? .white : .black)
					.help("Delete this activity")
				}
			}
			Text("Potential Tags")
				.bold()
				.padding()
			HStack() {
				ForEach(self.activityVM.listValidGearNames(), id: \.self) { item in
					Button {
						let _ = self.activityVM.createTag(tag: item)
					} label: {
						Text(item)
					}
					.padding()
					.background(Color.gray)
					.foregroundColor(.white)
					.cornerRadius(10)
					.buttonStyle(PlainButtonStyle())
				}
			}
			Text("New Tag")
				.bold()
				.padding()
			TextField("Tag", text: self.$newTag)
				.foregroundColor(self.colorScheme == .dark ? .white : .black)
				.background(self.colorScheme == .dark ? .black : .white)
				.autocapitalization(.none)
			Button {
				if self.activityVM.createTag(tag: self.newTag) {
					self.presentation.wrappedValue.dismiss()
				}
			} label: {
				Text("Create a New Tag")
			}
			.padding()
			.background(Color.gray)
			.foregroundColor(.white)
			.cornerRadius(10)
			.buttonStyle(PlainButtonStyle())
		}
		.padding(10)
    }
}
