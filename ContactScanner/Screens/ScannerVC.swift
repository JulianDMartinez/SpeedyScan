//
//  VisionViewController.swift
//  ContactScanner
//
//  Created by Julian Martinez on 5/23/21.
//

import UIKit
import AVFoundation
import Vision

class ScannerVC: UIViewController {
    
    //TODO: Add segmented control for selection of automatic vs. manual.
    //TODO: Add option to adjust zoom level.

    private let captureSession      = AVCaptureSession()
    private let videoDataOutput     = AVCaptureVideoDataOutput()
    private let outlineLayer        = CAShapeLayer()
    private let captureButton       = CaptureButton()
    private let torchButton         = FlashToggleButton()
    private var detectedRectangle   = VNRectangleObservation()
    private var ciImage             = CIImage()
    private var uiImage             = UIImage()
    
    private lazy var device         = AVCaptureDevice(uniqueID: "")
    private lazy var previewLayer   = AVCaptureVideoPreviewLayer(session: captureSession)
    
    
    override func viewDidLoad() {
        
        //TODO: Check for access to camera and photo. Handle case where authorization is not provided.
        
        super.viewDidLoad()
        setCameraInput()
        setCameraOutput()
        setCameraPreview()
        setUpOutlineLayer()
        setCaptureButton()
        setTorchButton()
        
    }
    
    
    private func setCameraInput() {
        
        guard let device = AVCaptureDevice.DiscoverySession(
            deviceTypes : [.builtInUltraWideCamera],
            mediaType   : .video,
            position    : .back
        ).devices.first else {
            //TODO: Handle case where device is not available.
            return
        }
        
        self.device = device
        
        do {
            
            let cameraInput = try AVCaptureDeviceInput(device: device)
            captureSession.addInput(cameraInput)
            device.unlockForConfiguration()
            
        } catch {
            //TODO: Handle case where there is an error with setting the input.
        }
        
    }
    
    
    private func setCameraOutput() {
        
        videoDataOutput.videoSettings = [
            (kCVPixelBufferPixelFormatTypeKey as NSString) : NSNumber(value: kCVPixelFormatType_32BGRA)
        ] as [String : Any]
        
        videoDataOutput.alwaysDiscardsLateVideoFrames = true
        videoDataOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "camera_frame_processing_queue"))
        captureSession.addOutput(videoDataOutput)
        
        guard let connection = videoDataOutput.connection(with: .video) else {
            //TODO: Handle case where value is nil.
            return
        }
        
        connection.videoOrientation = .portrait
        connection.preferredVideoStabilizationMode = .cinematic

    }
    
    
    private func setCameraPreview() {
        
        previewLayer.frame          = view.frame
        previewLayer.videoGravity   = .resizeAspectFill
        
        view.layer.addSublayer(previewLayer)
        
        captureSession.startRunning()
        
    }
    
    
    private func setCaptureButton() {
        view.addSubview(captureButton)
        
        captureButton.addTarget(self, action: #selector(captureButtonTapped), for: .touchUpInside)
        
        NSLayoutConstraint.activate([
            captureButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            captureButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -30),
            captureButton.heightAnchor.constraint(equalToConstant: captureButton.buttonHeight),
            captureButton.widthAnchor.constraint(equalToConstant: captureButton.buttonHeight)
        ])
    }
    
    
    @objc private func captureButtonTapped() {
        
        //TODO: Add alert for nil image before presenting CaptureDetailVC
        
       presentCaptureDetailVC()
    }
    
    
    private func setTorchButton() {
        view.addSubview(torchButton)

        torchButton.addTarget(self, action: #selector(torchButtonTapped), for: .touchUpInside)
        
        NSLayoutConstraint.activate([
            torchButton.leadingAnchor.constraint(equalTo: captureButton.trailingAnchor, constant: 20),
            torchButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -30),
            torchButton.heightAnchor.constraint(equalToConstant: torchButton.buttonHeight),
            torchButton.widthAnchor.constraint(equalToConstant: torchButton.buttonHeight)
        ])
    }
    
    
    @objc private func torchButtonTapped() {
       toggleFlash()
    }
    
    
    func presentCaptureDetailVC() {
        
        doPerspectiveCorrection(detectedRectangle, from: ciImage)
        
        let captureDetailVC = CaptureDetailVC(image: uiImage)
        
        captureDetailVC.modalPresentationStyle = .overCurrentContext
        present(captureDetailVC, animated: true, completion: nil)
        
    }
    
    
    private func setUpOutlineLayer() {
        
        outlineLayer.frame = previewLayer.bounds
        previewLayer.insertSublayer(outlineLayer, at: 1)
        
    }

    
    private func detectRectangle(in image: CVPixelBuffer) {
        
        ciImage = CIImage(cvPixelBuffer: image)
        
        let request = VNDetectRectanglesRequest { request, error in
            DispatchQueue.main.async { [self] in
                guard let results = request.results as? [VNRectangleObservation] else {
                    print("There was an error obtaining the rectangle observations.")
                    return
                }
                
                guard let rect = results.first else {
                    return
                }
                
                self.detectedRectangle = rect
                
                self.drawBoundingBox(rect: self.detectedRectangle)
    
            }
        }
        
        request.minimumAspectRatio  = VNAspectRatio(0.1)
        request.maximumAspectRatio  = VNAspectRatio(4)
        request.minimumSize         = Float(0.2)
        request.minimumConfidence   = 1.0
        request.maximumObservations = 1
        
        let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: image, options: [:])
        
        do {
            try imageRequestHandler.perform([request])
        } catch {
            //TODO: Handle error.
        }
    }
    
    
    private func doPerspectiveCorrection(_ observation: VNRectangleObservation, from ciImage: CIImage) {

        var image = ciImage
        
        let topLeft     = observation.topLeft.scaled(to: ciImage.extent.size)
        let topRight    = observation.topRight.scaled(to: ciImage.extent.size)
        let bottomLeft  = observation.bottomLeft.scaled(to: ciImage.extent.size)
        let bottomRight = observation.bottomRight.scaled(to: ciImage.extent.size)

        image = image.applyingFilter("CIPerspectiveCorrection", parameters: [
            "inputTopLeft"      : CIVector(cgPoint: topLeft),
            "inputTopRight"     : CIVector(cgPoint: topRight),
            "inputBottomLeft"   : CIVector(cgPoint: bottomLeft),
            "inputBottomRight"  : CIVector(cgPoint: bottomRight)
        ]).applyingFilter("CIDocumentEnhancer", parameters: [
            "inputAmount" : 0.7
        ])
        
        let context = CIContext()
        let cgImage = context.createCGImage(image, from: image.extent)
        uiImage  = UIImage(cgImage: cgImage!)
    }
    
    
    private func drawBoundingBox(rect: VNRectangleObservation) {
        
        let outlinePath = UIBezierPath()
        
        outlineLayer.lineCap        = .butt
        outlineLayer.lineJoin       = .round
        outlineLayer.lineWidth      = 2
        outlineLayer.strokeColor    = UIColor.systemGray2.cgColor
        outlineLayer.fillColor      = UIColor.white.withAlphaComponent(0.3).cgColor
        
        //TODO: Test transform in smaller phone sizes. This transform is hardcoded and may only work for iPhone 12 Pro Max.
        let bottomTopTransform = CGAffineTransform(scaleX: 1.2, y: -1).translatedBy(x: -35, y: -previewLayer.frame.height)
        
        let topRight = VNImagePointForNormalizedPoint(rect.topRight, Int(previewLayer.frame.width), Int(previewLayer.frame.height)).applying(bottomTopTransform)
        let topLeft = VNImagePointForNormalizedPoint(rect.topLeft, Int(previewLayer.frame.width), Int(previewLayer.frame.height)).applying(bottomTopTransform)
        let bottomRight = VNImagePointForNormalizedPoint(rect.bottomRight, Int(previewLayer.frame.width), Int(previewLayer.frame.height)).applying(bottomTopTransform)
        let bottomLeft = VNImagePointForNormalizedPoint(rect.bottomLeft, Int(previewLayer.frame.width), Int(previewLayer.frame.height)).applying(bottomTopTransform)
        
        outlinePath.move(to: topLeft)
        outlinePath.addLine(to: topRight)
        outlinePath.addLine(to: bottomRight)
        outlinePath.addLine(to: bottomLeft)
        outlinePath.addLine(to: topLeft)
        outlinePath.addLine(to: topRight)
        outlinePath.addLine(to: bottomLeft)
        outlinePath.move(to: bottomRight)
        outlinePath.addLine(to: topLeft)
    
        outlineLayer.path = outlinePath.cgPath
        
    }
    
    func toggleFlash() {
        
        guard let device = device else {return}
        
        guard device.hasTorch else { return }

        do {
            try device.lockForConfiguration()

            if (device.torchMode == AVCaptureDevice.TorchMode.on) {
                device.torchMode = AVCaptureDevice.TorchMode.off
            } else {
                do {
                    try device.setTorchModeOn(level: 0.5)
                } catch {
                    print(error)
                }
            }

            device.unlockForConfiguration()
        } catch {
            print(error)
        }
    }
    
    
}

extension ScannerVC: AVCaptureVideoDataOutputSampleBufferDelegate {
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
        guard let frame = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            //TODO: Handle case where value is nil.
            return
        }
        
        detectRectangle(in: frame)
    }
}

extension CGPoint {
   func scaled(to size: CGSize) -> CGPoint {
       return CGPoint(x: self.x * size.width,
                      y: self.y * size.height)
   }
}
