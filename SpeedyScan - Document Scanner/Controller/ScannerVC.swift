//
//  VisionViewController.swift
//  SpeedyScan
//
//  Created by Julian Martinez on 5/23/21.
//

import UIKit
import AVFoundation
import Vision

class ScannerVC: UIViewController {
	
	//MARK: Class Properties
	
	private let captureSession              		= AVCaptureSession()
	private let videoDataOutput             		= AVCaptureVideoDataOutput()
	private let outlineLayer                		= CAShapeLayer()
	private let captureButton               		= CaptureButton()
	private let flashActivationButton       		= FlashToggleButton()
	private let photoSettings 						= AVCapturePhotoSettings(format: [
		AVVideoCodecKey 	: AVVideoCodecType.hevc
	])
	private let photoOutput 						= AVCapturePhotoOutput()
	
	private var detectedRectangle	: VNRectangleObservation?
	
	private var ciImage				: CIImage?
	private var uiImage                     		= UIImage()
	private var framesWithoutRecognitionCounter   	= 0
	
	private lazy var device                 		= AVCaptureDevice(uniqueID: "")
	private lazy var previewLayer           		= AVCaptureVideoPreviewLayer(session: captureSession)

	
	override func viewDidLoad() {
		super.viewDidLoad()
	}
	
	//Start configuration of preview capture session to ensure cases where the the user returns to a state where the view had already been loaded.
	override func viewWillAppear(_ animated: Bool) {
		verifyAndConfigureRecognitionPreviewCaptureSession()
	}
	
	private func verifyAndConfigureRecognitionPreviewCaptureSession() {
		
		//Start of verification of camera devices support.
		let deviceDiscoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInUltraWideCamera, .builtInDualCamera, .builtInWideAngleCamera],
																	  mediaType: .video, position: .back)
	
		guard !deviceDiscoverySession.devices.isEmpty else {
			DispatchQueue.main.async {
				let okayAlertAction = UIAlertAction(title: "Ok", style: .default)
				let alert = UIAlertController(
					title: "Device Not Supported",
					message: "Please submit a request to julian.martinez.s@outlook.com for added support.",
					preferredStyle: .alert)
				
				alert.addAction(okayAlertAction)
				self.present(alert, animated: true)
			}
			return
		}
		
		// Verify if camera access authorization is provided and configure preview layer if it is or is not determined yet.
		guard verifyCameraAccessOrNotDetermined() else {
			return
		}
		
		configureRecognitionPreviewCaptureSession()
	}
	
	private func verifyCameraAccessOrNotDetermined() -> Bool {
		switch AVCaptureDevice.authorizationStatus(for: .video) {
		case .authorized:
			return true
		case .notDetermined:
			return true
		case .restricted:
			DispatchQueue.main.async {
				let okayAlertAction = UIAlertAction(title: "Ok", style: .default)
				let alert = UIAlertController(
					title: "Camera Restriction",
					message: "Unable configure camera session due to device restriction.",
					preferredStyle: .alert)
				
				alert.addAction(okayAlertAction)
				self.present(alert, animated: true)
			}
			return false
		case .denied:
			DispatchQueue.main.async {
				let okayAlertAction = UIAlertAction(title: "Ok", style: .default)
				let alert = UIAlertController(
					title: "Enable Camera Access",
					message: "To scan please enable camera access in Settings -> SpeedyScan",
					preferredStyle: .alert)
				
				alert.addAction(okayAlertAction)
				self.present(alert, animated: true)
			}
			return false
		@unknown default:
			DispatchQueue.main.async {
				let okayAlertAction = UIAlertAction(title: "Ok", style: .default)
				let alert = UIAlertController(
					title: "Access Error",
					message: "An error was encountered while verifying camera access.",
					preferredStyle: .alert)
				alert.addAction(okayAlertAction)
				self.present(alert, animated: true)
			}
			return false
		}
	}
	
	private func configureRecognitionPreviewCaptureSession() {
		configureCameraInput()
		configureCameraOutput()
		configureCameraPreview()
		configureUpOutlineLayer()
		configureCaptureButton()
		configureFlashActivationButton()
	}
	
	private func configureCameraInput() {
		guard let device = AVCaptureDevice.DiscoverySession(
			deviceTypes : [.builtInUltraWideCamera, .builtInDualCamera, .builtInWideAngleCamera],
			mediaType   : .video,
			position    : .back
			
		).devices.first else {
			DispatchQueue.main.async {
				let okayAlertAction = UIAlertAction(title: "Ok", style: .default)
				let alert = UIAlertController(
					title: "Camera Not Found",
					message: "An error was encountered while trying to access the device built in camera.",
					preferredStyle: .alert)
				
				alert.addAction(okayAlertAction)
				self.present(alert, animated: true)
			}
			return
		}
		
		self.device = device
		
		do {
			let cameraInput = try AVCaptureDeviceInput(device: device)
			captureSession.addInput(cameraInput)
			device.unlockForConfiguration()
		} catch {
			DispatchQueue.main.async {
				let okayAlertAction = UIAlertAction(title: "Ok", style: .default)
				let alert = UIAlertController(
					title: "Camera Configuration Error",
					message: "An error was encountered while trying to configure the device built in camera.",
					preferredStyle: .alert)
				
				alert.addAction(okayAlertAction)
				self.present(alert, animated: true)
			}
		}
	}
	
	
	private func configureCameraOutput() {
		
		captureSession.beginConfiguration()
		
		videoDataOutput.videoSettings = [
			(kCVPixelBufferPixelFormatTypeKey as NSString) : NSNumber(value: kCVPixelFormatType_32BGRA)
		] as [String : Any]

		videoDataOutput.alwaysDiscardsLateVideoFrames = true
		videoDataOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "camera_frame_processing_queue"))
		captureSession.addOutput(videoDataOutput)

		guard let connection = videoDataOutput.connection(with: .video) else {
			DispatchQueue.main.async {
				let okayAlertAction = UIAlertAction(title: "Ok", style: .default)
				let alert = UIAlertController(
					title: "Camera Configuration Error",
					message: "An error was encountered while trying to configure the device built in camera.",
					preferredStyle: .alert)

				alert.addAction(okayAlertAction)
				self.present(alert, animated: true)
			}
			return
		}

		connection.videoOrientation = .portrait

		//Stabilization added to smooth out the movement of the bounding box on screen.
		connection.preferredVideoStabilizationMode = .cinematic
		
		photoOutput.maxPhotoQualityPrioritization = .speed
		
		guard captureSession.canAddOutput(photoOutput) else {return}
		
		captureSession.sessionPreset = .photo
		captureSession.addOutput(photoOutput)
		
		captureSession.commitConfiguration()
		
	}
	
	
	private func configureCameraPreview() {
		previewLayer.frame          = view.frame
		previewLayer.videoGravity   = .resizeAspectFill
		
		view.layer.addSublayer(previewLayer)
		
		captureSession.startRunning()
	}
	
	
	private func configureFlashActivationButton() {
		view.addSubview(flashActivationButton)
		
		flashActivationButton.addTarget(self, action: #selector(flashActivationButtonTapped), for: .touchUpInside)
		
		NSLayoutConstraint.activate([
			flashActivationButton.leadingAnchor.constraint(equalTo: captureButton.trailingAnchor, constant: 20),
			flashActivationButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -30),
			flashActivationButton.heightAnchor.constraint(equalToConstant: flashActivationButton.buttonHeight),
			flashActivationButton.widthAnchor.constraint(equalToConstant: flashActivationButton.buttonHeight)
		])
	}
	
	
	@objc private func flashActivationButtonTapped() {
		toggleFlash()
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
					try device.setTorchModeOn(level: 0.1)
				} catch {
					let okayAlertAction = UIAlertAction(title: "Ok", style: .default)
					let alert = UIAlertController(
						title: "Flash Toggle",
						message: "An error was encountered while toggling flash light.",
						preferredStyle: .alert)
					
					alert.addAction(okayAlertAction)
					self.present(alert, animated: true)
				}
			}
			
			device.unlockForConfiguration()
		} catch {
			DispatchQueue.main.async {
				let okayAlertAction = UIAlertAction(title: "Ok", style: .default)
				let alert = UIAlertController(
					title: "Flash Toggle",
					message: "An error was encountered while toggling flash light.",
					preferredStyle: .alert)
				
				alert.addAction(okayAlertAction)
				self.present(alert, animated: true)
			}
		}
	}
	
	
	private func configureCaptureButton() {
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
		
		guard verifyCameraAccessOrNotDetermined() else {
			return
		}
		
		guard let photoOutputConnection = photoOutput.connection(with: .video) else {fatalError("Unable to establish photo capture connection")}
		
		photoOutputConnection.videoOrientation = .portrait
		
		let currentPhotoCaptureSettings = AVCapturePhotoSettings(from: photoSettings)
		
		print(currentPhotoCaptureSettings.format)
		
		photoOutput.capturePhoto(with: currentPhotoCaptureSettings, delegate: self)
	
		
//		presentCaptureDetailVC(with: ciImage)
		
		//Turn off flash light if it is on when transitioning to detail view.
	}
	
	func turnOffFlash() {
		guard let device = device else {return}
		guard device.hasTorch else { return }
		
		do {
			try device.lockForConfiguration()
			if (device.torchMode == AVCaptureDevice.TorchMode.on) {
				device.torchMode = AVCaptureDevice.TorchMode.off
			}
			device.unlockForConfiguration()
		} catch {
			print(error)
		}
	}
	
	
	
	func presentCaptureDetailVC(with image: CIImage?) {
		
		doPerspectiveCorrection(detectedRectangle, from: image)
		
		let captureDetailVC = CaptureDetailVC(image: uiImage)
		
		captureDetailVC.modalPresentationStyle = .overCurrentContext
		
		present(captureDetailVC, animated: true, completion: nil)
		
	}
	
	
	private func configureUpOutlineLayer() {
		outlineLayer.frame = previewLayer.bounds
		previewLayer.insertSublayer(outlineLayer, at: 1)
	}
	
	
	private func resetRecognition() {
		self.detectedRectangle = nil
		self.drawBoundingBox(rect: VNRectangleObservation())
		self.ciImage = nil
		self.uiImage = UIImage()
	}
	
	
	private func detectRectangle(in image: CVPixelBuffer) {
		
		DispatchQueue.main.async {
			
			//Stop recognition if ScannerVC is not presented.
			guard self.presentedViewController == nil else {
				self.resetRecognition()
				return
			}
			
			self.ciImage = CIImage(cvPixelBuffer: image)
			
			let request = VNDetectRectanglesRequest { request, error in
				DispatchQueue.main.async { [self] in
					guard let results = request.results as? [VNRectangleObservation] else {
						DispatchQueue.main.async {
							let okayAlertAction = UIAlertAction(title: "Ok", style: .default)
							let alert = UIAlertController(
								title: "Document Recognition Error",
								message: "An error was encountered while configuring recognition.",
								preferredStyle: .alert)
							
							alert.addAction(okayAlertAction)
							self.present(alert, animated: true)
						}
						return
					}
					
					guard let rect = results.first else {
						
						//Allow up to 5 frames without recognition to prevent abrupt reset of drawing on screen.
						if framesWithoutRecognitionCounter > 5 {
							resetRecognition()
						} else {
							framesWithoutRecognitionCounter += 1
						}
					
						return
					}
					
					framesWithoutRecognitionCounter = 0
					
					self.detectedRectangle = rect
					
					guard let detectedRectangle = self.detectedRectangle else {
						return
					}

					
					self.drawBoundingBox(rect: detectedRectangle)
					
				}
			}
			
			request.minimumAspectRatio  = VNAspectRatio(0.1)
			request.maximumAspectRatio  = VNAspectRatio(4)
			request.minimumSize         = Float(0.15)
			request.minimumConfidence   = 1.0
			request.maximumObservations = 1
			
			let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: image, options: [:])
			
			do {
				try imageRequestHandler.perform([request])
			} catch {
				DispatchQueue.main.async {
					let okayAlertAction = UIAlertAction(title: "Ok", style: .default)
					let alert = UIAlertController(
						title: "Document Recognition Error",
						message: "An error was encountered while performing recognition.",
						preferredStyle: .alert)
					
					alert.addAction(okayAlertAction)
					self.present(alert, animated: true)
				}
			}
		}
	}
	
	
	private func doPerspectiveCorrection(_ observation: VNRectangleObservation?, from ciImage: CIImage?) {
		
		guard let unwrappedCIImage = ciImage, let unwrappedObservation = observation else {
			let okayAlertAction = UIAlertAction(title: "Ok", style: .default)
			let alert = UIAlertController(
				title: "No Object Detected",
				message: "Move the camera closer to the object until the recognition box is shown, or place object on a contrasting background.",
				preferredStyle: .alert)
			
			alert.addAction(okayAlertAction)
			self.present(alert, animated: true)
			return
		}
		
		var image = unwrappedCIImage
		
		let topLeft     = unwrappedObservation.topLeft.scaled(to: unwrappedCIImage.extent.size)
		let topRight    = unwrappedObservation.topRight.scaled(to: unwrappedCIImage.extent.size)
		let bottomLeft  = unwrappedObservation.bottomLeft.scaled(to: unwrappedCIImage.extent.size)
		let bottomRight = unwrappedObservation.bottomRight.scaled(to: unwrappedCIImage.extent.size)
//
		image =
		
		image.applyingFilter("CIPerspectiveCorrection", parameters: [
			"inputTopLeft"      : CIVector(cgPoint: topLeft),
			"inputTopRight"     : CIVector(cgPoint: topRight),
			"inputBottomLeft"   : CIVector(cgPoint: bottomLeft),
			"inputBottomRight"  : CIVector(cgPoint: bottomRight)
		])
			.applyingFilter("CIDocumentEnhancer", parameters: [
			"inputAmount" : 1
		])
			.applyingFilter("CIColorControls", parameters: [
			"inputBrightness" : -0.35,
			"inputContrast"   : 1.2
		]).applyingFilter("CISharpenLuminance", parameters: [
			"inputSharpness" : 1.0
		])
		
		let context = CIContext()
		let cgImage = context.createCGImage(image, from: image.extent)
		uiImage  = UIImage(cgImage: cgImage!, scale: 1, orientation: .up)
	}
	
	
	private func drawBoundingBox(rect: VNRectangleObservation) {
		
		let outlinePath = UIBezierPath()
		
		outlineLayer.lineCap        = .butt
		outlineLayer.lineJoin       = .round
		outlineLayer.lineWidth      = 2
		outlineLayer.strokeColor    = UIColor.systemGray2.cgColor
		outlineLayer.fillColor      = UIColor.white.withAlphaComponent(0.3).cgColor
		
		let bottomTopTransform = CGAffineTransform(scaleX: 1.5, y: -1).translatedBy(x: 0, y: -previewLayer.frame.height)
		
		let topRight    = VNImagePointForNormalizedPoint(rect.topRight, Int(previewLayer.frame.width), Int(previewLayer.frame.height)).applying(bottomTopTransform)
		let topLeft     = VNImagePointForNormalizedPoint(rect.topLeft, Int(previewLayer.frame.width), Int(previewLayer.frame.height)).applying(bottomTopTransform)
		let bottomRight = VNImagePointForNormalizedPoint(rect.bottomRight, Int(previewLayer.frame.width), Int(previewLayer.frame.height)).applying(bottomTopTransform)
		let bottomLeft  = VNImagePointForNormalizedPoint(rect.bottomLeft, Int(previewLayer.frame.width), Int(previewLayer.frame.height)).applying(bottomTopTransform)
		
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
}


extension ScannerVC: AVCaptureVideoDataOutputSampleBufferDelegate {
	
	func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
		
		guard let frame = CMSampleBufferGetImageBuffer(sampleBuffer) else {return}
		detectRectangle(in: frame)
		
	}
}

extension ScannerVC: AVCapturePhotoCaptureDelegate {
	func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
		var ciImage = CIImage(cgImage: photo.cgImageRepresentation()!)
		
		ciImage = ciImage.oriented(.right)
		
		presentCaptureDetailVC(with: ciImage)
		turnOffFlash()
	}
}


extension CGPoint {
	func scaled(to size: CGSize) -> CGPoint {
		return CGPoint(x: self.x * size.width,
					   y: self.y * size.height)
	}
}
