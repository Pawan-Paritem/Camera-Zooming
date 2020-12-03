//
//  CameraController.swift
//  MicroscopeApp
//
//  Created by Umer Khan on 28/08/2020.
//  Copyright © 2020 CodesOrbit. All rights reserved.
//

import UIKit
import AVFoundation


enum CameraControllerError: Swift.Error {
    
    case captureSessionAlreadyRunning
    case captureSessionIsMissing
    case inputsAreInvalid
    case invalidOperation
    case noCamerasAvailable
    case unknown
}

public enum OutputType {
    case photo
    case video
}

class CameraController: NSObject {
    
    
    //MARK: - Properties
    var captureSession:     AVCaptureSession?
    var backCamera:         AVCaptureDevice?
    var backCameraInput:    AVCaptureDeviceInput?
    var previewLayer:       AVCaptureVideoPreviewLayer?
    var photoOutput:        AVCapturePhotoOutput?
    var audioDevice:        AVCaptureDevice?
    var videoOutput:        AVCaptureMovieFileOutput?
    var audioInput:         AVCaptureDeviceInput?
    var outputType:         OutputType?
    
    var photoCaptureCompletionBlock: ((UIImage?, Error?) -> Void)?
    var videoRecordCompletionBlock: ((URL?, Error?) -> Void)?

    
    func prepare(completionHandler: @escaping (Error?) -> Void) {
        
        func createCaptureSession() {
            self.captureSession = AVCaptureSession()
        }
        
        
        //TODO: - Capture Device
        func configureCaptureDevices() throws {
            let camera = AVCaptureDevice.default(for: AVMediaType.video)
            
            self.backCamera = camera
            
            try camera?.lockForConfiguration()
            camera?.unlockForConfiguration()
            
            self.audioDevice = AVCaptureDevice.default(for: AVMediaType.audio)
        }
        
        //TODO: - Device Inputs
        func configureDeviceInputs() throws {
            
            guard let captureSession = self.captureSession
                else {
                    throw CameraControllerError.captureSessionIsMissing
            }
            
            if let backCamera = self.backCamera {
                
                self.backCameraInput = try AVCaptureDeviceInput(device: backCamera)
                
                if captureSession.canAddInput(self.backCameraInput!) { captureSession.addInput(self.backCameraInput!)
                    
                } else {
                    throw CameraControllerError.inputsAreInvalid
                }
                
            } else {
                
                throw CameraControllerError.noCamerasAvailable
            }
            
            if let audioDevice = self.audioDevice {
                
                self.audioInput = try AVCaptureDeviceInput(device: audioDevice)
                
                if captureSession.canAddInput(self.audioInput!) {
                    captureSession.addInput(self.audioInput!)
                    
                } else {
                    throw CameraControllerError.inputsAreInvalid
                }
            }
            
            captureSession.startRunning()
        }
        
        //TODO: - Photo Output
        func configurePhotoOutput() throws {
            
            guard let captureSession = self.captureSession else { throw CameraControllerError.captureSessionIsMissing }
            
            self.photoOutput = AVCapturePhotoOutput()
            
            self.photoOutput!.setPreparedPhotoSettingsArray([AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.jpeg])], completionHandler: nil)
            
            if captureSession.canAddOutput(self.photoOutput!) {
                captureSession.addOutput(self.photoOutput!)
            }
            
            self.outputType = .photo
            captureSession.startRunning()
        }
        
        func configureVideoOutput() throws {
            
            guard let captureSession = self.captureSession else {
                
                throw CameraControllerError.captureSessionIsMissing
            }
            
            self.videoOutput = AVCaptureMovieFileOutput()
            
            if captureSession.canAddOutput(self.videoOutput!) {
                
                captureSession.addOutput(self.videoOutput!)
            }
        }
        
        DispatchQueue(label: "prepare").async {
            do {
                createCaptureSession()
                try configureCaptureDevices()
                try configureDeviceInputs()
                try configurePhotoOutput()
                try configureVideoOutput()
            }
                
            catch {
                DispatchQueue.main.async{
                    completionHandler(error)
                }
                return
            }
            
            DispatchQueue.main.async {
                completionHandler(nil)
            }
        }
    }
    
    func displayPreview(on view: UIView) throws {
        
        guard let captureSession = self.captureSession, captureSession.isRunning
            else {
                throw CameraControllerError.captureSessionIsMissing
        }
        
        self.previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        
        self.previewLayer?.videoGravity = AVLayerVideoGravity.resizeAspectFill
        self.previewLayer?.connection?.videoOrientation = .portrait
        
        view.layer.insertSublayer(self.previewLayer!, at: 0)
        self.previewLayer?.frame = view.frame
    }
    
    //TODO: - Capture Image
    func captureImage(completion: @escaping (UIImage?, Error?) -> Void) {
        
        guard let captureSession = captureSession, captureSession.isRunning else {
            
            completion(nil, CameraControllerError.captureSessionIsMissing)
            return
        }
        
        let settings = AVCapturePhotoSettings()
        self.photoOutput?.capturePhoto(with: settings, delegate: self)
        self.photoCaptureCompletionBlock = completion
    }
    
    func recordVideo(completion: @escaping (URL?, Error?)-> Void) {
        
        guard let captureSession = self.captureSession, captureSession.isRunning else {
            completion(nil, CameraControllerError.captureSessionIsMissing)
            return
        }
        
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        
        let fileUrl = paths[0].appendingPathComponent("output.mp4")
        
        try? FileManager.default.removeItem(at: fileUrl)
        
        videoOutput!.startRecording(to: fileUrl, recordingDelegate: self)
        self.videoRecordCompletionBlock = completion
    }
    
    func stopRecording(completion: @escaping (Error?)->Void) {
        
        guard let captureSession = self.captureSession, captureSession.isRunning else {
            completion(CameraControllerError.captureSessionIsMissing)
            return
        }
        self.videoOutput?.stopRecording()
    }
}


//MARK: - AVCapturePhotoCaptureDelegate
extension CameraController: AVCapturePhotoCaptureDelegate {
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        
        if let error = error {
            self.photoCaptureCompletionBlock?(nil, error)
            
        } else if let data = photo.fileDataRepresentation() {
            let image = UIImage(data: data)
            self.photoCaptureCompletionBlock?(image, nil)
            
        } else {
            self.photoCaptureCompletionBlock?(nil, CameraControllerError.unknown)
        }
    }
}


//MARK: - AVCaptureFileOutputRecordingDelegate
extension CameraController: AVCaptureFileOutputRecordingDelegate {
    
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        
        if error == nil {
            self.videoRecordCompletionBlock?(outputFileURL, nil)
            
        } else {
            self.videoRecordCompletionBlock?(nil, error)
        }
    }
}
