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
	@State private var showingNewTagView: Bool = false
	@State private var showingDeleteConfirmation: Bool = false

	var body: some View {
		ScrollView() {
			GeometryReader { geometry in
				VStack(alignment: .center) {
					Text("Existing Tags")
						.foregroundColor(self.colorScheme == .dark ? .white : .black)
						.bold()
					let tags = self.activityVM.listTags()
					if tags.count > 0 {
						self.generateTagCloud(in: geometry, items: tags, handler: { tag in
							self.tagToDelete = tag
							self.showingDeleteConfirmation = true
						})
					}
					else {
						Text("There are currently no tags associated with this activity.")
					}

					Text("Tags From Gear")
						.foregroundColor(self.colorScheme == .dark ? .white : .black)
						.bold()
					let gearTags = self.activityVM.listValidGearNames()
					if gearTags.count > 0 {
						self.generateTagCloud(in: geometry, items: gearTags, handler: { tag in
							if self.activityVM.createTag(tag: tag) {
								self.presentation.wrappedValue.dismiss()
							}
						})
					}
					else {
						Text("There is currently no gear to tag the activity with.")
					}
				}
				.alert("Are you sure you want to delete this tag?", isPresented: self.$showingDeleteConfirmation) {
					Button("Delete") {
						if self.activityVM.deleteTag(tag: self.tagToDelete) {
							self.presentation.wrappedValue.dismiss()
						}
						else {
							NSLog("Delete tag failed.")
						}
					}
					Button("Cancel") {
					}
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
							self.showingNewTagView = true
						} label: {
							Text("+")
								.foregroundColor(self.colorScheme == .dark ? .white : .black)
						}
						.help("Createa a new tag")
						.alert("New Tag", isPresented: self.$showingNewTagView) {
							VStack() {
								TextField("Tag", text: self.$newTag)
								HStack() {
									Button("OK") {
										if self.activityVM.createTag(tag: self.newTag) {
										}
									}
									Button("Cancel") {
									}
								}
							}
						} message: {
							Text("Create a New Tag")
						}
					}
				}
			}
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
		.foregroundColor(self.colorScheme == .dark ? .white : .black)
		.cornerRadius(10)
		.buttonStyle(PlainButtonStyle())
	}
}
