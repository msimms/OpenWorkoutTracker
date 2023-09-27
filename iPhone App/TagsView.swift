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
	@State private var tagToDelete: String = ""
	@State private var showingDeleteConfirmation: Bool = false

	var body: some View {
		ScrollView() {
			GeometryReader { geometry in
				VStack() {
					let tags = self.activityVM.listTags()
					self.generateTagCloud(in: geometry, items: tags, handler: { tag in
						self.tagToDelete = tag
						self.showingDeleteConfirmation = true
					})
					Text("Potential Tags")
						.bold()
						.padding()
					let potentialTags = self.activityVM.listValidGearNames()
					self.generateTagCloud(in: geometry, items: potentialTags, handler: { tag in
						if self.activityVM.createTag(tag: tag) {
							self.presentation.wrappedValue.dismiss()
						}
					})
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
				.alert("Are you sure you want to delete this tag?", isPresented: self.$showingDeleteConfirmation) {
					Button("Delete") {
						if self.activityVM.deleteTag(tag: self.tagToDelete) {
							self.presentation.wrappedValue.dismiss()
						}
					}
					Button("Cancel") {
					}
				}
			}
			.padding(10)
		}
	}
	
	private func generateTagCloud(in g: GeometryProxy, items: Array<String>, handler: @escaping (_: String) -> ()) -> some View {
		var width = CGFloat.zero
		var height = CGFloat.zero
		
		return ZStack(alignment: .topLeading) {
			ForEach(items, id: \.self) { item in
				self.generateTag(for: item, handler: handler)
					.padding([.horizontal, .vertical], 4)
					.alignmentGuide(.leading, computeValue: { d in
						if (abs(width - d.width) > g.size.width)
						{
							width = 0
							height -= d.height
						}
						let result = width
						if item == items.last! {
							width = 0
						} else {
							width -= d.width
						}
						return result
					})
					.alignmentGuide(.top, computeValue: {d in
						let result = height
						if item == items.last! {
							height = 0
						}
						return result
					})
			}
		}
	}
	
	private func generateTag(for text: String, handler: @escaping (_: String) -> ()) -> some View {
		Button {
			handler(text)
		} label: {
			Text(text)
		}
		.padding()
		.background(Color.gray)
		.foregroundColor(.white)
		.cornerRadius(10)
		.buttonStyle(PlainButtonStyle())
	}
}
