//
//  EditRouteView.swift
//  Created by Michael Simms on 10/14/23.
//

import SwiftUI
import MapKit
import UniformTypeIdentifiers

func showFilePicker(callback: @escaping DocumentResponse) -> DocumentPicker {
	let gpxType = UTType(tag: "gpx", tagClass: .filenameExtension, conformingTo: nil)!
	let tcxType = UTType(tag: "tcx", tagClass: .filenameExtension, conformingTo: nil)!
	let fitType = UTType(tag: "fit", tagClass: .filenameExtension, conformingTo: nil)!
	let contentTypes = [gpxType, tcxType, fitType]
	
	return DocumentPicker(contentTypes: contentTypes, callback: callback)
}

struct EditRouteView: View {
	@Environment(\.colorScheme) var colorScheme
	@Environment(\.dismiss) var dismiss
	@StateObject private var routesVM: RoutesVM = RoutesVM()
	@State private var tempRouteSummary: RouteSummary
	@State private var showingSaveError: Bool = false
	@State private var urlStr: String = ""
	@State private var isShowingFileSourceSelection: Bool = false
	@State private var isShowingUrlSelection: Bool = false
	@State private var isShowingUrlError: Bool = false
	@State private var isShowingUrlImportError: Bool = false
	@State private var isShowingFileImportError: Bool = false
	@State private var isShowingDeleteConfirmation: Bool = false
	@State private var isShowingDocPicker: Bool = false
	@State private var isShowingDeleteError: Bool = false

	init(route: RouteSummary) {
		_tempRouteSummary = State(initialValue: route)
	}
	
	func importRouteFromUrl(url: URL) {
		let downloadsUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
		let destFileUrl = downloadsUrl.appendingPathComponent(url.lastPathComponent)
		let session = URLSession(configuration: URLSessionConfiguration.default, delegate: nil, delegateQueue: nil)
		var request = URLRequest(url: url)
		request.httpMethod = "GET"
		
		let task = session.dataTask(with: request, completionHandler: {
			data, response, error in
			if error == nil {
				if let response = response as? HTTPURLResponse {
					if response.statusCode == 200 {
						if let data = data {
							do {
								try data.write(to: destFileUrl, options: Data.WritingOptions.atomic)
								if self.routesVM.importRouteFromFile(fileName: destFileUrl.absoluteString) == false {
									self.isShowingUrlImportError = true
								}
								try FileManager.default.removeItem(at: destFileUrl)
							}
							catch {
								self.isShowingUrlImportError = true
							}
						}
					}
				}
			}
		})
		task.resume()
	}
	
	var body: some View {
		VStack(alignment: .center) {
			Group() {
				Text("Name")
					.font(.system(size: 24))
					.bold()
				TextField("Name", text: self.$tempRouteSummary.name)
					.foregroundColor(self.colorScheme == .dark ? .white : .black)
					.background(self.colorScheme == .dark ? .black : .white)
			}
			.padding(SIDE_INSETS)

			Group() {
				Text("Description")
					.font(.system(size: 24))
					.bold()
				TextField("Description", text: self.$tempRouteSummary.description)
					.foregroundColor(self.colorScheme == .dark ? .white : .black)
					.background(self.colorScheme == .dark ? .black : .white)
			}
			.padding(SIDE_INSETS)

			Group() {
				if self.isShowingUrlSelection == true {
					Text("File Location (URL)")
						.bold()
					TextField("URL", text: self.$urlStr)
						.foregroundColor(self.colorScheme == .dark ? .white : .black)
						.background(self.colorScheme == .dark ? .black : .white)
				}
				
				Spacer()

				if self.isShowingUrlSelection == true {
					Button(action: {
						let url = URL(string: self.urlStr)
						if url != nil {
							self.importRouteFromUrl(url: url!)
						}
						else {
							self.isShowingUrlError = true
						}
					}) {
						HStack() {
							Image(systemName: "arrowshape.down.circle.fill")
							Text("Download...")
						}
						.frame(minWidth: 0, maxWidth: .infinity)
						.foregroundColor(self.colorScheme == .dark ? .black : .white)
						.padding()
					}
					.alert("Invalid URL!", isPresented: self.$isShowingUrlError) { }
					.alert("Failed to import a route from the URL!", isPresented: self.$isShowingUrlImportError) { }
					.background(RoundedRectangle(cornerRadius: 10, style: .continuous))
					.opacity(0.8)
					.bold()
				}

				if self.tempRouteSummary.name.count == 0 {
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
						Button("URL") {
							self.isShowingUrlSelection = true
						}
						Button("iCloud Drive") {
							self.isShowingDocPicker = true
						}
					}
					.background(RoundedRectangle(cornerRadius: 10, style: .continuous))
					.opacity(0.8)
					.bold()
				}
			}
			
			Group() {
				if self.tempRouteSummary.locationTrack.first != nil {
					GeometryReader { reader in
						let region = MKCoordinateRegion(
							center: CLLocationCoordinate2D(latitude: self.tempRouteSummary.locationTrack.first!.latitude,
														   longitude: self.tempRouteSummary.locationTrack.first!.longitude),
							span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
						)

						MapWithPolyline(region: region, trackUser: false, updates: false)
							.setOverlay(self.tempRouteSummary.trackLine)
							.ignoresSafeArea()
							.frame(width: reader.size.width, height: 300)
					}
				}
			}

			// Save button
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
				.help("Save this route")
			}

			// Delete button
			Group() {
				if self.tempRouteSummary.name.count > 0 {
					Button(action: {
						self.isShowingDeleteConfirmation = true
					}) {
						HStack() {
							Image(systemName: "trash")
							Text("Delete")
						}
						.frame(minWidth: 0, maxWidth: .infinity)
						.foregroundColor(.red)
						.padding()
					}
					.alert("Are you sure you want to delete this route? This cannot be undone.", isPresented: self.$isShowingDeleteConfirmation) {
						Button("Delete") {
							if self.routesVM.deleteRoute(routeId: self.tempRouteSummary.routeId) {
								self.dismiss()
							}
							else {
								self.isShowingDeleteError = true
							}
						}
						Button("Cancel") {
						}
					}
					.alert("Failed to delete.", isPresented: self.$isShowingDeleteError) {}
					.background(RoundedRectangle(cornerRadius: 10, style: .continuous))
					.opacity(0.8)
					.bold()
					.help("Delete this route")
				}
			}
		}
		.sheet(isPresented: self.$isShowingDocPicker) {
			showFilePicker(callback: { url in
				self.isShowingFileImportError = self.routesVM.importRouteFromUrl(url: url)
			})
		}
		.alert("Failed to import a route from the file!", isPresented: self.$isShowingFileImportError) { }
		.padding(10)
    }
}
