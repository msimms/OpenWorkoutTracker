//
//  PhotoPicker.swift
//  Created by Michael Simms on 8/7/23.
//

import SwiftUI
import PhotosUI

typealias PhotoResponse = (_: UIImage) -> ()

struct PhotoPicker: UIViewControllerRepresentable {
	var callback: PhotoResponse

	func makeUIViewController(context: Context) -> PHPickerViewController {
		var config = PHPickerConfiguration()
		config.selectionLimit = 3
		config.filter = .images

		let picker = PHPickerViewController(configuration: config)
		picker.delegate = context.coordinator

		return picker
	}

	func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {
	}

	func makeCoordinator() -> Coordinator {
		Coordinator(self)
	}

	class Coordinator: NSObject, PHPickerViewControllerDelegate {
		let parent: PhotoPicker
		
		init(_ parent: PhotoPicker) {
			self.parent = parent
		}
		
		func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
			picker.dismiss(animated: true)
			
			guard let provider = results.first?.itemProvider else { return }
			
			if provider.canLoadObject(ofClass: UIImage.self) {
				provider.loadObject(ofClass: UIImage.self) { image, _ in
					if let tempImage = image as? UIImage {
						self.parent.callback(tempImage)
					}
				}
			}
		}
	}
}
