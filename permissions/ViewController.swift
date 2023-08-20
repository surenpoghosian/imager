//
//  ViewController.swift
//  permissions
//
//  Created by Suren Poghosyan on 18.08.23.
//

import UIKit
import Photos
import Zip
import AudioToolbox


class ViewController: UIViewController {
    var picker: UIImagePickerController!
    @IBOutlet weak var pickImageButton: UIButton!
    
    var selectedVideoURL: URL?
    var player: AVPlayer?
    var playerLayer: AVPlayerLayer?
    
    let videoPlayerView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemGray5
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
    
    
    let playButton: UIButton = {
        let button = UIButton()
        let biggerPlayButtonImage = UIImage(systemName: "play.circle.fill")?
            .withConfiguration(UIImage.SymbolConfiguration(pointSize: 30)) // Adjust the pointSize to make the icon bigger

        button.setImage(biggerPlayButtonImage, for: .normal)
        button.addTarget(self, action: #selector(playButtonTapped), for: .touchUpInside)
        return button
    }()
    
    let replayButton: UIButton = {
        let button = UIButton()
        let biggerReplayButtonImage = UIImage(systemName: "arrow.counterclockwise")?
            .withConfiguration(UIImage.SymbolConfiguration(pointSize: 30)) // Adjust the pointSize to make the icon bigger

        button.setImage(biggerReplayButtonImage, for: .normal)
        button.addTarget(self, action: #selector(replayButtonTapped), for: .touchUpInside)
        button.isHidden = true // Hide the replay button initially
        return button
    }()
    
    let pauseButton: UIButton = {
        let button = UIButton()
        let biggerPauseButtonImage = UIImage(systemName: "pause.circle.fill")?
            .withConfiguration(UIImage.SymbolConfiguration(pointSize: 30)) // Adjust the pointSize to make the icon bigger

        button.setImage(biggerPauseButtonImage, for: .normal)
        button.addTarget(self, action: #selector(pauseButtonTapped), for: .touchUpInside)
        return button
    }()
    
    let timerLabel: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.font = UIFont.systemFont(ofSize: 14)
        return label
    }()
    
    let exportButton: UIButton = {
        let button = UIButton()
        let biggerExportButtonImage = UIImage(systemName: "arrow.down.to.line.alt")?
            .withConfiguration(UIImage.SymbolConfiguration(pointSize: 30)) // Adjust the pointSize to make the icon bigger

        button.setImage(biggerExportButtonImage, for: .normal)
        button.addTarget(self, action: #selector(exportButtonTapped), for: .touchUpInside)
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        picker = UIImagePickerController()
        picker.delegate = self
        
        PHPhotoLibrary.execute(controller: self, onAccessHasBeenGranted: {
            
        })
        
        
        pickImageButton.addTarget(self, action: #selector(onPickImageButtonClicked), for: .touchUpInside)
        setupViews()
        setupConstraints()
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Start a timer to update the timer label every second
        Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.updateTimerLabel()
        }
    }
    
    
    @objc func playButtonTapped() {
        if let _ = selectedVideoURL{
            
            
            print("playButtonTapped CLICKED")
            player?.play()
            playButton.isHidden = true
            pauseButton.isHidden = false
            replayButton.isHidden = true // Hide the replay button when play is tapped
        }
    }
    
    @objc func pauseButtonTapped() {
        print("pauseButtonTapped CLICKED")
        player?.pause()
        playButton.isHidden = false
        pauseButton.isHidden = true
    }
    
    @objc func replayButtonTapped() {
        player?.seek(to: .zero)
        player?.play()
        replayButton.isHidden = true
        pauseButton.isHidden = false
    }
    
    @objc func exportButtonTapped() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()

        guard let videoURL = selectedVideoURL else {
            showAlert(message: "No video to export")
            return
        }


        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: videoURL)
        }) { success, error in
            if success {
                print("Video exported to gallery.")
                DispatchQueue.main.async {
                    self.showAlert(message:"Video exported to gallery.")
                    self.vibrateDevice(state: .success)
                }
                
            } else if let error = error {
                print("Error exporting video: \(error)")
                DispatchQueue.main.async {
                    self.showAlert(message:"Error exporting video")
                    self.vibrateDevice(state: .fail)
                }

            }
        }
    }
    
    func updateTimerLabel() {
        guard let player = player else {
            return
        }
        
        let currentTime = player.currentTime().seconds
        let duration = player.currentItem?.duration.seconds ?? 0
        
        let currentTimeString = String(format: "%.1f", currentTime)
        let durationString = String(format: "%.1f", duration)
        
        timerLabel.text = "\(currentTimeString)s / \(durationString)s"
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
        //        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(videoPlayerViewTapped))
        //        videoPlayerView.addGestureRecognizer(tapGesture)
        //        videoPlayerView.isUserInteractionEnabled = true
        
        videoPlayerView.addSubview(playButton)
        videoPlayerView.addSubview(pauseButton)
        videoPlayerView.addSubview(replayButton)
        videoPlayerView.addSubview(timerLabel)
        videoPlayerView.addSubview(exportButton)
        
        
        videoPlayerView.bringSubviewToFront(playButton)
        videoPlayerView.bringSubviewToFront(pauseButton)
        videoPlayerView.bringSubviewToFront(replayButton)
        videoPlayerView.bringSubviewToFront(exportButton)
        
        
        // Set up their initial positions (adjust as needed)
        playButton.frame = CGRect(x: 20, y: 20, width: 100, height: 100)
        pauseButton.frame = CGRect(x: 20, y: 20, width: 100, height: 100)
        timerLabel.frame = CGRect(x: 70, y: 25, width: 100, height: 30)
        
        
        playButton.translatesAutoresizingMaskIntoConstraints = false
        pauseButton.translatesAutoresizingMaskIntoConstraints = false
        replayButton.translatesAutoresizingMaskIntoConstraints = false
        exportButton.translatesAutoresizingMaskIntoConstraints = false
        
        timerLabel.translatesAutoresizingMaskIntoConstraints = false
        
        
        NSLayoutConstraint.activate([
            playButton.leadingAnchor.constraint(equalTo: videoPlayerView.leadingAnchor, constant: 20),
            playButton.bottomAnchor.constraint(equalTo: videoPlayerView.bottomAnchor, constant: -10),
            
            
            pauseButton.leadingAnchor.constraint(equalTo: videoPlayerView.leadingAnchor, constant: 20),
            pauseButton.bottomAnchor.constraint(equalTo: videoPlayerView.bottomAnchor, constant: -10),
            
            replayButton.leadingAnchor.constraint(equalTo: videoPlayerView.leadingAnchor, constant: 20),
            replayButton.bottomAnchor.constraint(equalTo: videoPlayerView.bottomAnchor, constant: -10),
            
            exportButton.trailingAnchor.constraint(equalTo: videoPlayerView.trailingAnchor, constant: -20),
            exportButton.bottomAnchor.constraint(equalTo: videoPlayerView.bottomAnchor, constant: -10),
            
            
            timerLabel.centerXAnchor.constraint(equalTo: videoPlayerView.centerXAnchor),
            timerLabel.topAnchor.constraint(equalTo: playButton.bottomAnchor, constant: 20),
            
            
        ])
        
        
        pauseButton.isHidden = true
        
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
            selectVideoButton.topAnchor.constraint(equalTo: videoPlayerView.bottomAnchor, constant: 40),
            
            editVideoButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            editVideoButton.topAnchor.constraint(equalTo: selectVideoButton.bottomAnchor)
        ])
    }
    
    @objc func videoPlayerViewTapped() {
        if let player = player {
            player.seek(to: CMTime.zero)
            player.play()
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
        
        NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: player?.currentItem, queue: nil) { [weak self] _ in
            self?.playButton.isHidden = true
            self?.pauseButton.isHidden = true
            self?.replayButton.isHidden = false
        }
        
    }
    
    @objc func editVideoButtonTapped() {
        guard let videoURL = selectedVideoURL else {
            return
        }
        player?.pause()
        if UIVideoEditorController.canEditVideo(atPath: videoURL.path) {
            let videoEditor = UIVideoEditorController()
            videoEditor.delegate = self
            videoEditor.videoPath = videoURL.path
            present(videoEditor, animated: true, completion: nil)
        } else {
            print("Video editing is not available for the selected video.")
        }
    }
    
    func showAlert(message: String) {
        let alertController = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        alertController.addAction(okAction)
        present(alertController, animated: true, completion: nil)
    }
    
    func vibrateDevice(state: VibrationState) {
        let feedbackGenerator = UINotificationFeedbackGenerator()
        feedbackGenerator.prepare()
        if state == .success {
            feedbackGenerator.notificationOccurred(.success)
        } else if state == .fail {
            feedbackGenerator.notificationOccurred(.error)
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
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true, completion: nil)
        
        if let mediaType = info[.mediaType] as? String,
           mediaType == "public.movie",
           let videoURL = info[.mediaURL] as? URL {
            selectedVideoURL = videoURL
            playSelectedVideo()
            playButtonTapped()
            self.videoPlayerView.bringSubviewToFront(self.playButton)
            self.videoPlayerView.bringSubviewToFront(self.pauseButton)
            self.videoPlayerView.bringSubviewToFront(self.replayButton)
            self.videoPlayerView.bringSubviewToFront(self.exportButton)

        }
    }
    
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
}




extension ViewController: UIVideoEditorControllerDelegate {
    func videoEditorController(_ editor: UIVideoEditorController, didSaveEditedVideoToPath editedVideoPath: String) {
          editor.dismiss(animated: true, completion: nil)
        if let editedVideoURL = URL(string: "file://" + editedVideoPath) {
            self.selectedVideoURL = editedVideoURL
            self.player?.pause()
            self.playSelectedVideo()
            playButtonTapped()

            self.videoPlayerView.bringSubviewToFront(self.playButton)
            self.videoPlayerView.bringSubviewToFront(self.pauseButton)
            self.videoPlayerView.bringSubviewToFront(self.replayButton)
            self.videoPlayerView.bringSubviewToFront(self.exportButton)
            
            print(editedVideoURL)
          }
      }
      
      func videoEditorControllerDidCancel(_ editor: UIVideoEditorController) {
          editor.dismiss(animated: true, completion: nil)
      }
      
      func videoEditorController(_ editor: UIVideoEditorController, didFailWithError error: Error) {
          print("Video editing failed with error: \(error.localizedDescription)")
          editor.dismiss(animated: true, completion: nil)
      }
    
}


enum VibrationState {
    case success
    case fail
}
