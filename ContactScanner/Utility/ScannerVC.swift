//
//  ScannerViewController.swift
//  ContactScanner
//
//  Created by Julian Martinez on 5/22/21.
//

import UIKit
import AVFoundation

class ScannerVC: UIViewController {
    
    // MARK: - UI Objects
    let cameraPreviewView       = CameraPreviewView()
    let cutoutView              = UIView()
    let captureButton           = UIButton()
    
    
    var maskLayer               = CAShapeLayer()
    var currentOrientation      = UIDeviceOrientation.portrait
    
    // MARK: - Capture Related Objects
    private let captureSession  = AVCaptureSession()
    let captureSessionQueue     = DispatchQueue(label: "CaptureSessionQueue")
    
    var captureDevice: AVCaptureDevice?
    
    var videoDataOutput       = AVCaptureVideoDataOutput()
    let videoDataOutputQueue    = DispatchQueue(label: "VideoDataOutputQueue")
    
    // MARK: - Region of Interest (ROI) and Text Orientation
    // Region of video data output buffer that recognition should be run on.
    // Gets recalculated once the bounds of the preview layer are known.
    var regionOfInterest    = CGRect(x: 0, y: 0, width: 1, height: 1)
    // Orientation of text to search for in the region of interest
    var textOrientation     = CGImagePropertyOrientation.up
    
    // MARK: - Coordinate Transforms
    var bufferAspectRatio: Double!
    // Transform from UI orientation to buffer orientation.
    var uiRotationTransform     = CGAffineTransform.identity
    // Transform bottom-left coordinates to top-left.
    var bottomToTopTransform    = CGAffineTransform(scaleX: 1, y: -1).translatedBy(x: 0, y: -1)
    // Transform coordinates in ROI to global coordinates (still normalize).
    var roiToGlobalTransform    = CGAffineTransform.identity
    
    // Vision -> AVF coordinate transform.
    var visionToAVFTransform    = CGAffineTransform.identity
    
    // MARK: - View Controller Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configurePreviewView()
        configureCutoutView()
        configureCaptureButton()
        
        captureSessionQueue.async {
            self.setupCamera()
            DispatchQueue.main.async {
                self.calculateRegionOfInterest()
            }
        }
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)

        let deviceOrientation = UIDevice.current.orientation
        if deviceOrientation.isPortrait || deviceOrientation.isLandscape {
            currentOrientation = deviceOrientation
        }
        
        if let videoPreviewLayerConnection = cameraPreviewView.videoPreviewLayer.connection {
            if let newVideoOrientation = AVCaptureVideoOrientation(deviceOrientation: deviceOrientation) {
                videoPreviewLayerConnection.videoOrientation = newVideoOrientation
            }
        }

        calculateRegionOfInterest()
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        updateCutout()
    }
    
    func configurePreviewView() {
        view.addSubview(cameraPreviewView)
        
        cameraPreviewView.session = captureSession
        
        cameraPreviewView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            cameraPreviewView.topAnchor.constraint(equalTo: view.topAnchor),
            cameraPreviewView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            cameraPreviewView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            cameraPreviewView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }
    
    func configureCutoutView() {
        view.addSubview(cutoutView)
    
        cutoutView.backgroundColor  = UIColor.systemBackground.withAlphaComponent(0.3)
        maskLayer.backgroundColor   = UIColor.clear.cgColor
        maskLayer.fillRule          = .evenOdd

        cutoutView.layer.mask       = maskLayer
        
        cutoutView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            cutoutView.topAnchor.constraint(equalTo: view.topAnchor),
            cutoutView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            cutoutView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            cutoutView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }
    
    func configureCaptureButton() {
        view.addSubview(captureButton)
        
        let buttonHeight: CGFloat = 55
        let symbolConfiguration = UIImage.SymbolConfiguration(pointSize: 47, weight: .ultraLight)
        
        captureButton.setImage(UIImage(systemName: "camera.circle")?.applyingSymbolConfiguration(symbolConfiguration), for: .normal)
        captureButton.imageView?.tintColor  = .label
        captureButton.backgroundColor       = .systemGray6
        captureButton.layer.cornerRadius    = buttonHeight / 2
        
        captureButton.translatesAutoresizingMaskIntoConstraints = false
        
        captureButton.addTarget(self, action: #selector(captureButtonTapped), for: .touchUpInside)
        
        NSLayoutConstraint.activate([
            captureButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            captureButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -11),
            captureButton.heightAnchor.constraint(equalToConstant: buttonHeight),
            captureButton.widthAnchor.constraint(equalToConstant: buttonHeight),
        ])
    }
    
    @objc func captureButtonTapped() {
        print("Button tapped").self
        
    }
        
    // MARK: - Set Up Methods
    
    func setupCamera() {
        
        // Configure capture device.
        guard let captureDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
            print("Could not create capture device.")
            return
        }
        
        self.captureDevice = captureDevice
        
        // Configure buffer size.
        if captureDevice.supportsSessionPreset(.hd4K3840x2160) {
            captureSession.sessionPreset    = AVCaptureSession.Preset.hd4K3840x2160
            bufferAspectRatio               = 3840.0 / 2160.0
        } else {
            captureSession.sessionPreset    = AVCaptureSession.Preset.hd1920x1080
            bufferAspectRatio               = 1920.0 / 1080.0
        }
        
        // Configure session input.
        guard let deviceInput = try? AVCaptureDeviceInput(device: captureDevice) else {
            print("Could not create device input")
            return
        }
        
        if captureSession.canAddInput(deviceInput) {
            captureSession.addInput(deviceInput)
        }
        
        // Configure session output.
        videoDataOutput.alwaysDiscardsLateVideoFrames = false
        videoDataOutput.setSampleBufferDelegate(self, queue: videoDataOutputQueue)
        videoDataOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_420YpCbCr8BiPlanarFullRange]
        
        if captureSession.canAddOutput(videoDataOutput) {
            captureSession.addOutput(videoDataOutput)
            // Set stabilization off to ease drawing rectangles on recognition
            videoDataOutput.connection(with: .video)?.preferredVideoStabilizationMode = .off
        } else {
            print("Could not add VDO output.")
            return
        }
        
        // Set zoom and autofocus to help focus on very small text
        do {
            try captureDevice.lockForConfiguration()
            captureDevice.videoZoomFactor           = 2
            captureDevice.autoFocusRangeRestriction = .near
            captureDevice.unlockForConfiguration()
        } catch {
            print("Could not set zoom level due to error \(error)")
            return
        }
        
        captureSession.startRunning()
    }
    
    func calculateRegionOfInterest() {
        // In landscape orientation the desired ROI is specified as the ratio of
        // buffer width to height. When the UI is rotated to portrait, keep the
        // vertical size the same (in buffer pixels). Also try to keep the
        // horizontal size the same up to a maximum ratio.
        let desiredHeightRatio = 0.5
        let desiredWidthRatio = 0.6
        let maxPortraitWidth = 0.9
        
        // Figure out size of ROI.
        let size: CGSize
        if currentOrientation.isPortrait || currentOrientation == .unknown {
            size = CGSize(width: min(desiredWidthRatio * bufferAspectRatio, maxPortraitWidth), height: desiredHeightRatio / bufferAspectRatio)
        } else {
            size = CGSize(width: desiredWidthRatio, height: desiredHeightRatio)
        }
        // Make it centered.
        regionOfInterest.origin = CGPoint(x: (1 - size.width) / 2, y: 5*(1 - size.height) / 6)
        regionOfInterest.size = size
        
        // ROI changed, update transform.
        setupOrientationAndTransform()
        
        // Update the cutout to match the new ROI.
        DispatchQueue.main.async {
            // Wait for the next run cycle before updating the cutout. This
            // ensures that the preview layer already has its new orientation.
            self.updateCutout()
        }
    }
    
    func updateCutout() {
        // Figure out where the cutout ends up in layer coordinates.
        let roiRectTransform = bottomToTopTransform.concatenating(uiRotationTransform)
        let cutout = cameraPreviewView.videoPreviewLayer.layerRectConverted(fromMetadataOutputRect: regionOfInterest.applying(roiRectTransform))
        
        // Create the mask.
        let path = UIBezierPath(rect: cutoutView.frame)
        path.append(UIBezierPath(rect: cutout))
        maskLayer.path = path.cgPath
    }
    
    func setupOrientationAndTransform() {
        // Recalculate the affine transform between Vision coordinates and AVF coordinates.
        
        // Compensate for region of interest.
        let roi = regionOfInterest
        roiToGlobalTransform = CGAffineTransform(translationX: roi.origin.x, y: roi.origin.y).scaledBy(x: roi.width, y: roi.height)
        
        // Compensate for orientation (buffers always come in the same orientation).
        switch currentOrientation {
        case .landscapeLeft:
            textOrientation     = .up
            uiRotationTransform = CGAffineTransform(translationX: 0, y: 0.05)
        case .landscapeRight:
            textOrientation     = .down
            uiRotationTransform = CGAffineTransform(translationX: 1, y: 0.95).rotated(by: .pi)
        case .portraitUpsideDown:
            textOrientation     = .left
            uiRotationTransform = CGAffineTransform(translationX: 1, y: 0).rotated(by: .pi / 2)
        default:
            textOrientation     = .right
            uiRotationTransform = CGAffineTransform(translationX: 0, y: 1).rotated(by: -.pi / 2)
        }
        
        // Full Vision ROI to AVF transform.
        visionToAVFTransform    = roiToGlobalTransform.concatenating(bottomToTopTransform).concatenating(uiRotationTransform)
    }
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate
extension ScannerVC: AVCaptureVideoDataOutputSampleBufferDelegate {
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        //Implemented in VisionViewController
    }
}

// MARK: - Utility extensions

extension AVCaptureVideoOrientation {
    init?(deviceOrientation: UIDeviceOrientation) {
        switch deviceOrientation {
        case .portrait: self = .portrait
        case .portraitUpsideDown: self = .portraitUpsideDown
        case .landscapeLeft: self = .landscapeRight
        case .landscapeRight: self = .landscapeLeft
        default: return nil
        }
    }
}


