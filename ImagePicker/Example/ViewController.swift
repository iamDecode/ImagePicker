//
//  ViewController.swift
//  ImagePicker
//
//  Created by Dennis Collaris on 08/09/2019.
//  Copyright © 2019 Cocode. All rights reserved.
//

import UIKit
import ImagePicker
import Photos


class ViewController: UIViewController, ImagePickerDelegate {
  @IBAction func presentImagePickerSheet(gestureRecognizer: UITapGestureRecognizer?) {
    guard checkImageAuthorizationStatus() else { return }

    let alertController = UIAlertController()

    let picker = ImagePicker(alertController: alertController)
    alertController.view.addSubview(picker)

    alertController.addAction(UIAlertAction(title: "Take Photo", style: .default) { _ in
      return
    })

    alertController.addAction(UIAlertAction(title: "Photo Library", style: .default) { _ in
      return
    })

    alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))

    if UIDevice.current.userInterfaceIdiom == .pad {
      alertController.modalPresentationStyle = .popover
      alertController.popoverPresentationController?.sourceView = view
      alertController.popoverPresentationController?.sourceRect = CGRect(origin: view.center, size: CGSize())
    }

    present(alertController, animated: true, completion: nil)
  }

  fileprivate func checkImageAuthorizationStatus() -> Bool {
    let authorizationStatus = PHPhotoLibrary.authorizationStatus()

    switch authorizationStatus {
    case .notDetermined:
      PHPhotoLibrary.requestAuthorization() { [weak self] _ in
        DispatchQueue.main.async {
          self?.presentImagePickerSheet(gestureRecognizer: nil)
        }
      }
      return false
    case .denied, .restricted:
      return false
    case .authorized:
      return true
    @unknown default:
      fatalError()
    }
  }
}
