//
//  DocumentPicker.swift
//  Created by Michael Simms on 10/23/23.
//

import SwiftUI
import UniformTypeIdentifiers

typealias DocumentResponse = (_: URL) -> ()

struct DocumentPicker: UIViewControllerRepresentable {
	private var callback: DocumentResponse
	private var contentTypes: [UTType] = []

	init(contentTypes: [UTType], callback: @escaping DocumentResponse) {
		self.contentTypes = contentTypes
		self.callback = callback
	}

	func makeUIViewController(context: Context) -> some UIViewController {
		let controller = UIDocumentPickerViewController(forOpeningContentTypes: self.contentTypes)
		controller.allowsMultipleSelection = false
		controller.shouldShowFileExtensions = true
		controller.delegate = context.coordinator
		return controller
	}

	func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {
	}

	func makeCoordinator() -> DocumentPickerCoordinator {
		DocumentPickerCoordinator(callback: self.callback)
	}
}

class DocumentPickerCoordinator: NSObject, UIDocumentPickerDelegate {
	private var callback: DocumentResponse

	init(callback: @escaping DocumentResponse) {
		self.callback = callback
	}

	func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
		guard let url = urls.first else {
			return
		}
		self.callback(url)
	}
}
