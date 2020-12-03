//
//  CameraViewController.swift
//  CameraZooming
//
//  Created by Pawan  on 11/11/2020.
//


import UIKit
import Photos
import AVFoundation

protocol CameraViewControllerDelegate: AnyObject {
    func capturedImage(_ image: UIImage)
}
class CameraViewController: UIViewController, UIGestureRecognizerDelegate {

    let cameraController = CameraController()
    var previewView      =  UIView()
    var videoRecordingStarted: Bool = false
    var capturedImage: UIImage = UIImage()
    
    weak var delegate: CameraViewControllerDelegate?
    
    //Marks: - Zoom Camera Code
  
    let minimumZoom: CGFloat = 1.0
    var maximumZoom: CGFloat = 4.0
    var lastZoomFactor: CGFloat = 1.0
    
    @IBOutlet weak var labelTextShow: UILabel!
  
    
    override func viewDidLoad() {
        super.viewDidLoad()
        loadCamera()
        
        let pinchRecognizer = UIPinchGestureRecognizer(target: self, action:#selector(pinch(_:)))
        previewView.addGestureRecognizer(pinchRecognizer)
        pinchRecognizer.delegate = self

    }
   
    
    @objc func pinch(_ pinch: UIPinchGestureRecognizer) {
        
        let device = AVCaptureDevice.default(for: .video)
//        print(pinch.scale)
//
//        let vZoomFactor = pinch.scale * prevZoomFactor
//        if pinch.state == .ended {
//            prevZoomFactor = vZoomFactor >= 1 ? vZoomFactor : 1
//        }
//
//        if pinch.state == .changed{
//            do {
//                try device!.lockForConfiguration()
//                if (vZoomFactor <= device!.activeFormat.videoMaxZoomFactor) {
//                    device!.videoZoomFactor = max(1.0, min(vZoomFactor, device!.activeFormat.videoMaxZoomFactor))
//
//                    var y:Float = Float(vZoomFactor)
//                    labelTextShow.text = String(format: "%.1f",y)
//                    device?.unlockForConfiguration()
//                } else {
//                    print("Unable to set videoZoom: (max (device!.activeFormat.videoMaxZoomFactor), asked (vZoomFactor))")
//                }
//            } catch {
//                print("(error.localizedDescription)")
//            }
//        }
//
        func minMaxZoom(_ factor: CGFloat) -> CGFloat {

                   return min(min(max(factor, minimumZoom), maximumZoom), device!.activeFormat.videoMaxZoomFactor)
               }

               func update(scale factor: CGFloat) {
                   do {
                       try device!.lockForConfiguration()
                       defer { device!.unlockForConfiguration() }
                    device!.videoZoomFactor = factor

                   } catch {
                       print("\(error.localizedDescription)")
                   }
               }

               let newScaleFactor = minMaxZoom(pinch.scale * lastZoomFactor)
                let y:Float = Float(newScaleFactor)
                labelTextShow.text = "\(String(format: "%.1f", y))x"

               switch pinch.state {

               case .began: fallthrough
               case .changed: update(scale: newScaleFactor)
               case .ended:
                   lastZoomFactor = minMaxZoom(newScaleFactor)
                   update(scale: lastZoomFactor)

               default: break

            }
}
    
    func loadCamera() {
        
        previewView = UIView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height))
        previewView.contentMode = UIView.ContentMode.scaleAspectFit
        
        view.addSubview(previewView)
        
        cameraController.prepare {(error) in
            
            if let error = error {
                print(error)
            }
            
            try? self.cameraController.displayPreview(on: self.previewView)
        }
    }
    
    @IBAction func capturePhotoTapppedButton(_ sender: UIButton) {
        capturePhotos()
    }
    func capturePhotos() {
        
        cameraController.captureImage { (image, error) in
            guard let image = image else { return }
            
            UIImageWriteToSavedPhotosAlbum(image, self, #selector(self.image(_:didFinishSavingWithError:contextInfo:)), nil)
        }
    }
    
    func captureVideo() {
        cameraController.outputType = .video
        
        if videoRecordingStarted {
            
            videoRecordingStarted = false
            self.cameraController.stopRecording { (error) in
                print("\(error?.localizedDescription ?? "Video Recording Error")")
            }
            
        } else if !videoRecordingStarted {
            
            videoRecordingStarted = true
            self.cameraController.recordVideo { (url, error) in
                
                guard let url = url else {
                    print("\(error?.localizedDescription ?? "Video recording error")")
                    return
                }
                UISaveVideoAtPathToSavedPhotosAlbum(url.path, self, #selector(self.video(_:didFinishSavingWithError:contextInfo:)), nil)
            }
        }
    }
    
    @objc func video(_ video: String, didFinishSavingWithError error: NSError?, contextInfo: UnsafeRawPointer) {
        
        if error != nil {
            print("Could not save video, Error: \(error!.localizedDescription)")
            
        } else {
            print("Video saved successfully")
        }
        print(video)
    }
    
    @objc func image(_ image: UIImage, didFinishSavingWithError error: NSError?, contextInfo: UnsafeRawPointer) {
        
        if let error = error {
            print("Could not save image, Error: \(error.localizedDescription)")
            
        } else {
            //TODO: - assign captured image to gallery button
            delegate?.capturedImage(image)
            print("Image saved successfully")
        }
    }
    
    func accessPhotoLibrary() {
        
        if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
            let imagePickerController = UIImagePickerController()
            imagePickerController.sourceType = .photoLibrary
            imagePickerController.delegate = self
            
            present(imagePickerController, animated: true)
        }
    }
}


//MARK: - UIImagePickerControllerDelegate
extension CameraViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        if let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            print(image)
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true)
    }
}
