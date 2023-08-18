//
//  ViewController.swift
//  permissions
//
//  Created by Suren Poghosyan on 18.08.23.
//

import UIKit
import Photos
import Zip

class ViewController: UIViewController {
    var picker: UIImagePickerController!
    @IBOutlet weak var pickImageButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        picker = UIImagePickerController()
        picker.delegate = self

        PHPhotoLibrary.execute(controller: self, onAccessHasBeenGranted: {
            
        })

        pickImageButton.addTarget(self, action: #selector(onPickImageButtonClicked), for: .touchUpInside)
        

    }

    
    @objc func onPickImageButtonClicked(){
//        DispatchQueue.main.async {
//            self.present(self.picker, animated: true)
//        }
        
        let status = PHPhotoLibrary.authorizationStatus()
        switch status {
        case .notDetermined:
            print("notDetermined")
        case .denied, .restricted:
            print("denied | restricted")
        case .authorized:
            print("authorized")
            DispatchQueue.main.async {
                self.present(self.picker, animated: true)
            }

        default:
           fatalError("PHPhotoLibrary::execute - \"Unknown case\"")
        }
    }
    
    
    func compressImageAndCreateZip(image: UIImage, zipFileName: String) {
        // Get the binary data of the image
        guard let imageData = image.pngData() else {
            print("Error converting image to data")
            return
        }
        
        // Create a temporary directory for storing the ZIP archive
        let tempDirectory = FileManager.default.temporaryDirectory.appendingPathComponent("TempZip")
        
        do {
            // Create the temporary directory if it doesn't exist
            try FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true, attributes: nil)
            
            // Save the image data to a temporary file
            let tempImageFileURL = tempDirectory.appendingPathComponent("image.png")
            try imageData.write(to: tempImageFileURL)
            
            // Create the ZIP archive
            let zipFileURL = try Zip.quickZipFiles([tempImageFileURL], fileName: zipFileName)
            
            print("ZIP archive created at: \(zipFileURL.path)")
            
            // Clean up temporary files
            try FileManager.default.removeItem(at: tempDirectory)
        } catch {
            print("Error creating ZIP archive: \(error)")
        }
    }


}


public extension PHPhotoLibrary {
   
   static func execute(controller: UIViewController,
                       onAccessHasBeenGranted: @escaping () -> Void,
                       onAccessHasBeenDenied: (() -> Void)? = nil) {
      
      let onDeniedOrRestricted = onAccessHasBeenDenied ?? {
         let alert = UIAlertController(
            title: "We were unable to load your album groups. Sorry!",
            message: "You can enable access in Privacy Settings",
            preferredStyle: .alert)
         alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
         alert.addAction(UIAlertAction(title: "Settings", style: .default, handler: { _ in
            if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
               UIApplication.shared.open(settingsURL)
            }
         }))
         DispatchQueue.main.async {
            controller.present(alert, animated: true)
         }
      }

      let status = PHPhotoLibrary.authorizationStatus()
      switch status {
      case .notDetermined:
         onNotDetermined(onDeniedOrRestricted, onAccessHasBeenGranted)
      case .denied, .restricted:
         onDeniedOrRestricted()
      case .authorized:
         onAccessHasBeenGranted()
      default:
         fatalError("PHPhotoLibrary::execute - \"Unknown case\"")
      }
   }
   
}

private func onNotDetermined(_ onDeniedOrRestricted: @escaping (()->Void), _ onAuthorized: @escaping (()->Void)) {
   PHPhotoLibrary.requestAuthorization({ status in
      switch status {
      case .notDetermined:
         onNotDetermined(onDeniedOrRestricted, onAuthorized)
      case .denied, .restricted:
         onDeniedOrRestricted()
      case .authorized:
         onAuthorized()
      default:
         fatalError("PHPhotoLibrary::execute - \"Unknown case\"")
      }
   })
}



extension ViewController: UIImagePickerControllerDelegate,
                              UINavigationControllerDelegate {
  func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
    // 1
    picker.dismiss(animated: true)
  }
  
  func imagePickerController(
    _ picker: UIImagePickerController,
    didFinishPickingMediaWithInfo
    info: [UIImagePickerController.InfoKey : Any]
    ) {
    picker.dismiss(animated: true)
    
    // 2
    guard let image = info[.originalImage] as? UIImage else {
      return
    }
//        print(image.size, image.cgImage, image.scale, image.imageOrientation)
  }
}
