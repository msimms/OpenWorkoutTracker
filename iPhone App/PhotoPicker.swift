//
//  PhotoPicker.swift
//  Created by Michael Simms on 8/7/23.
//

import SwiftUI

typealias PhotoResponse = (_: UIImage) -> ()

struct PhotoPicker: UIViewControllerRepresentable {
	var callback: PhotoResponse

	final class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
		var parent: PhotoPicker

		init(parent: PhotoPicker) {
			self.parent = parent
		}
		
		func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
			if let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
				self.parent.callback(image)
			}
			picker.dismiss(animated: false)
		}

		func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
			picker.dismiss(animated: false)
		}
	}
	
	func makeCoordinator() -> Coordinator {
		return Coordinator(parent: self)
	}
	
	func makeUIViewController(context: UIViewControllerRepresentableContext<PhotoPicker>) -> UIImagePickerController {
		let imagePicker = UIImagePickerController()
		imagePicker.allowsEditing = false
		imagePicker.sourceType = .photoLibrary
		imagePicker.delegate = context.coordinator
		return imagePicker
	}
	
	func updateUIViewController(_ uiViewController: UIImagePickerController, context: UIViewControllerRepresentableContext<PhotoPicker>) {
	}
}
