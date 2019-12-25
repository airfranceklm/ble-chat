//
//  ImagePickerView.swift
//  BleChat
//
//  Created by Jean-Jacques Wacksman.
//  Copyright © 2019 Air France - KLM. All rights reserved.
//

import SwiftUI

struct ImagePickerView: UIViewControllerRepresentable {
    let onImagePicked: (_ image: UIImage?) -> Void
    
    func updateUIViewController(_ uiViewController: UIViewController, context: UIViewControllerRepresentableContext<ImagePickerView>) {}
    
    func makeUIViewController(context: UIViewControllerRepresentableContext<ImagePickerView>) -> UIViewController {
        let controller = UIImagePickerController()
        controller.delegate = context.coordinator
        return controller
    }
    
    func makeCoordinator() -> ImagePickerView.Coordinator {
        let coordinator = Coordinator()
        coordinator.onImagePicked = onImagePicked
        return coordinator
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        var onImagePicked: ((_ image: UIImage?) -> Void)!
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            onImagePicked(info[.originalImage] as? UIImage)
        }
    }
}
