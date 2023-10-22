//
//  ImportRouteView.swift
//  Created by Michael Simms on 10/14/23.
//

import SwiftUI
import MapKit

struct ImportRouteView: View {
	@Environment(\.colorScheme) var colorScheme
	@StateObject var routesVM: RoutesVM = RoutesVM()
	@State private var tempRouteSummary: RouteSummary
	@State private var showingSaveError: Bool = false
	@State private var urlStr: String = ""
	@State private var isShowingFileSourceSelection: Bool = false
	@State private var isShowingUrlSelection: Bool = false
	@State private var isShowingUrlError: Bool = false
	@State private var isShowingImportError: Bool = false

	init(route: RouteSummary) {
		_tempRouteSummary = State(initialValue: route)
	}

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
									self.isShowingImportError = true
								}
								try FileManager.default.removeItem(at: destFileUrl)
							}
							catch {
								self.isShowingImportError = true
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
					.bold()
				TextField("Name", text: self.$tempRouteSummary.name)
					.foregroundColor(self.colorScheme == .dark ? .white : .black)
					.background(self.colorScheme == .dark ? .black : .white)
				
				Text("Description")
					.bold()
				TextField("Description", text: self.$tempRouteSummary.description)
					.foregroundColor(self.colorScheme == .dark ? .white : .black)
					.background(self.colorScheme == .dark ? .black : .white)
			}
	
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
					.alert("Failed to import a route from the URL!", isPresented: self.$isShowingImportError) { }
					.background(RoundedRectangle(cornerRadius: 10, style: .continuous))
					.opacity(0.8)
					.bold()
				}

				if self.tempRouteSummary.locationTrack.first == nil {
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
			}
			
			Group() {
				if self.tempRouteSummary.locationTrack.first != nil {
					GeometryReader { reader in
						MapWithPolyline(region: MKCoordinateRegion(
							center: CLLocationCoordinate2D(latitude: self.tempRouteSummary.locationTrack.first!.latitude,
														   longitude: self.tempRouteSummary.locationTrack.first!.longitude),
							span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
						), trackUser: false)
						.setOverlay(self.tempRouteSummary.trackLine)
						.ignoresSafeArea()
						.frame(width: reader.size.width, height: 300)
					}
				}
			}

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
