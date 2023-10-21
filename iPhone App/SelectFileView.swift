//
//  SelectFileView.swift
//  Created by Michael Simms on 9/6/23.
//

import SwiftUI

struct SelectFileView: View {
	@Environment(\.colorScheme) var colorScheme
	@State private var url: String = ""
	@State private var isShowingFileSourceSelection: Bool = false
	@State private var isShowingUrlSelection: Bool = false

	func showFilePicker() {
		let keyWindow = UIApplication.shared.connectedScenes
			.filter({$0.activationState == .foregroundActive})
			.compactMap({$0 as? UIWindowScene})
			.first?.windows
			.filter({$0.isKeyWindow}).first
		let allowedExtensions = ["gpx", "tcx", "fit", "kml"]
		let documentPicker = UIDocumentPickerViewController(documentTypes: allowedExtensions, in: .import)
		
		documentPicker.allowsMultipleSelection = false
		documentPicker.directoryURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
		keyWindow?.rootViewController?.present(documentPicker, animated: true)
	}
	
	var body: some View {
		Group() {
			if self.isShowingUrlSelection == true {
				Text("File Location (URL)")
					.bold()
				TextField("URL", text: self.$url)
					.foregroundColor(self.colorScheme == .dark ? .white : .black)
					.background(self.colorScheme == .dark ? .black : .white)
				Button(action: {
				}) {
					HStack() {
						Image(systemName: "arrowshape.down.circle.fill")
						Text("Download...")
					}
					.frame(minWidth: 0, maxWidth: .infinity)
					.foregroundColor(self.colorScheme == .dark ? .black : .white)
					.padding()
				}
				.background(RoundedRectangle(cornerRadius: 10, style: .continuous))
				.opacity(0.8)
				.bold()
			}

			Button(action: {
				self.isShowingFileSourceSelection = true
			}) {
				HStack() {
					Image(systemName: "doc")
					Text("Select a route file...")
				}
				.frame(minWidth: 0, maxWidth: .infinity)
				.foregroundColor(self.colorScheme == .dark ? .black : .white)
				.padding()
			}
			.confirmationDialog("Select the source of the file", isPresented: self.$isShowingFileSourceSelection, titleVisibility: .visible) {
				Button("iCloud Drive") {
					self.showFilePicker()
				}
				Button("URL") {
					self.isShowingUrlSelection = true
				}
			}
			.background(RoundedRectangle(cornerRadius: 10, style: .continuous))
			.opacity(0.8)
			.bold()
		}
		.padding(EdgeInsets(top: 2.5, leading: 0, bottom: 0, trailing: 0))
	}
}
