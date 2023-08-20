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
    var videoEditor = UIVideoEditorController()

    let videoPlayerView: UIView = {
            let view = UIView()
            view.backgroundColor = .green
            return view
        }()
        
        let selectVideoButton: UIButton = {
            let button = UIButton()
            button.setTitle("Select Video", for: .normal)
            button.setTitleColor(.blue, for: .normal)
            button.addTarget(self, action: #selector(selectVideoButtonTapped), for: .touchUpInside)
            return button
        }()
        
        let editVideoButton: UIButton = {
            let button = UIButton()
            button.setTitle("Edit Video", for: .normal)
            button.setTitleColor(.blue, for: .normal)
            button.addTarget(self, action: #selector(editVideoButtonTapped), for: .touchUpInside)
            return button
        }()
        
    var selectedVideoURL: URL?
    var player: AVPlayer?
    var playerLayer: AVPlayerLayer?
 
    override func viewDidLoad() {
        super.viewDidLoad()
        picker = UIImagePickerController()
        picker.delegate = self

        PHPhotoLibrary.execute(controller: self, onAccessHasBeenGranted: {
            
        })

        pickImageButton.addTarget(self, action: #selector(onPickImageButtonClicked), for: .touchUpInside)
        setupViews()
        setupConstraints()
 
//        if let videoURL = Bundle.main.url(forResource: "sampleVideo", withExtension: "mp4") {
//                    player = AVPlayer(url: videoURL)
//                    playerLayer = AVPlayerLayer(player: player)
//                    playerLayer?.frame = videoPlayerView.bounds
//                    playerLayer?.videoGravity = .resizeAspectFill
//                    videoPlayerView.layer.addSublayer(playerLayer!)
//                    player?.play()
//                }

    }

    
    @objc func onPickImageButtonClicked(){        
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
    
    
    func setupViews() {
            view.addSubview(videoPlayerView)
            view.addSubview(selectVideoButton)
            view.addSubview(editVideoButton)
        }
        
        func setupConstraints() {
            videoPlayerView.translatesAutoresizingMaskIntoConstraints = false
            selectVideoButton.translatesAutoresizingMaskIntoConstraints = false
            editVideoButton.translatesAutoresizingMaskIntoConstraints = false
            
            NSLayoutConstraint.activate([
                videoPlayerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
                videoPlayerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                videoPlayerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                videoPlayerView.heightAnchor.constraint(equalToConstant: 200),
                
                selectVideoButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                selectVideoButton.topAnchor.constraint(equalTo: videoPlayerView.bottomAnchor, constant: 16),
                
                editVideoButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                editVideoButton.topAnchor.constraint(equalTo: selectVideoButton.bottomAnchor, constant: 16)
            ])
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

    
    @objc func selectVideoButtonTapped() {
        let imagePicker = UIImagePickerController()
        imagePicker.sourceType = .photoLibrary
        imagePicker.mediaTypes = ["public.movie"]
        imagePicker.delegate = self
        present(imagePicker, animated: true, completion: nil)
    }

    func playSelectedVideo() {
        guard let videoURL = selectedVideoURL else {
            return
        }
        
        player = AVPlayer(url: videoURL)
        playerLayer = AVPlayerLayer(player: player)
        playerLayer?.frame = videoPlayerView.bounds
        playerLayer?.videoGravity = .resizeAspectFill
        videoPlayerView.layer.addSublayer(playerLayer!)
        player?.play()
    }
    
       @objc func editVideoButtonTapped() {
           guard let videoURL = selectedVideoURL else {
                      return
                  }
                  
                  if UIVideoEditorController.canEditVideo(atPath: videoURL.path) {
                      let videoEditor = UIVideoEditorController()
                      videoEditor.delegate = self
                      videoEditor.videoPath = videoURL.path
                      present(videoEditor, animated: true, completion: nil)
                  } else {
                      print("Video editing is not available for the selected video.")
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
//    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
//        // 1
//        picker.dismiss(animated: true)
//    }
//
//    func imagePickerController(
//        _ picker: UIImagePickerController,
//        didFinishPickingMediaWithInfo
//        info: [UIImagePickerController.InfoKey : Any]
//    ) {
//        picker.dismiss(animated: true)
//
//        // 2
//        guard let image = info[.originalImage] as? UIImage else {
//            return
//        }
//        //        print(image.size, image.cgImage, image.scale, image.imageOrientation)
//    }
    
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true, completion: nil)
        
        if let mediaType = info[.mediaType] as? String,
           mediaType == "public.movie",
           let videoURL = info[.mediaURL] as? URL {
            selectedVideoURL = videoURL
            playSelectedVideo() // Play the selected video
        }
    }
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
}




extension ViewController: UIVideoEditorControllerDelegate {
    func videoEditorController(_ editor: UIVideoEditorController, didSaveEditedVideoToPath editedVideoPath: String) {
          editor.dismiss(animated: true, completion: nil)
          // You can perform actions with the edited video, like saving it or playing it.
      }
      
      func videoEditorControllerDidCancel(_ editor: UIVideoEditorController) {
          editor.dismiss(animated: true, completion: nil)
      }
      
      func videoEditorController(_ editor: UIVideoEditorController, didFailWithError error: Error) {
          print("Video editing failed with error: \(error.localizedDescription)")
          editor.dismiss(animated: true, completion: nil)
      }
}
