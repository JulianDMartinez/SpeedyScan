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
	
	//MARK: UIKit Properties
	
	private let visualEffectView                	= UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterial))
	private let wideAnglePreviewView				= PreviewView()
	private let ultraWideAnglePreviewView			= PreviewView()
	private let outlineLayer                		= CAShapeLayer()
	private let captureButton               		= CaptureButton()
	private let flashActivationButton       		= FlashToggleButton()
	private var uiImage                     		= UIImage()
	private var framesWithoutRecognitionCounter   	= 0
	
	private var ciImage : CIImage?
	
	//MARK: AVFoundation Properties
	
	private let captureSession              		= AVCaptureMultiCamSession()
	private let videoDataOutput             		= AVCaptureVideoDataOutput()
	private let photoOutput 						= AVCapturePhotoOutput()
	private let wideAnglePhotoOutput				= AVCapturePhotoOutput()
	private let wideAngleVideoDataOutput			= AVCaptureVideoDataOutput()
	private let ultraWideAngleVideoDataOutput		= AVCaptureVideoDataOutput()
	private let photoSettings 						= AVCapturePhotoSettings(format: [
		AVVideoCodecKey 	: AVVideoCodecType.hevc
	])
	
	private var wideAngleDeviceInput: AVCaptureDeviceInput?
	private var ultraWideCameraDeviceInput: AVCaptureDeviceInput?
	private var wideAnglePhotoOutputConnection: AVCaptureConnection?

	private lazy var wideAngleCameraPreviewLayer 		= AVCaptureVideoPreviewLayer(session: captureSession)
	private lazy var ultraWideAngleCameraPreviewLayer 	= AVCaptureVideoPreviewLayer(session: captureSession)
	private lazy var wideAngleCameraDevice          = AVCaptureDevice(uniqueID: "")

	//MARK: Vision Properties
	private var detectedRectangle	: VNRectangleObservation?

	//MARK: View Controller Life Cycle
	
	override func viewDidLoad() {
		super.viewDidLoad()
	}
	
	//Start configuration of preview capture session to ensure cases where the the user returns to a state where the view had already been loaded.
	override func viewWillAppear(_ animated: Bool) {
		configureSubViews()
	}

	
	override func viewDidAppear(_ animated: Bool) {
		verifyAndConfigureCaptureSession()
		captureSession.startRunning()
	}
	
	//MARK: Class Methods
	
	private func verifyAndConfigureCaptureSession() {
		
		//Start of verification of camera devices support.
		let deviceDiscoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera],
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
		
		// Verify if camera access authorization is provided and start capture session configuration if it is or is not determined yet.
		guard verifyCameraAccessOrNotDetermined() else {
			return
		}
		
		configureCaptureSession()
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
	
	private func configureSubViews() {
		configureUltraWideAnglePreviewView()
		configureCaptureButton()
		configureFlashActivationButton()
		configureWideAnglePreviewView()
		configureVisualEffectView()
	}
	
	private func configureCaptureSession() {
		configureWideAngleCameraCapture()
		configureUltraWideAngleCameraCapture()
		configureUpOutlineLayer()

		configureUltraWideAngleCameraPreviewLayer()
		configureWideAngleCameraPreviewLayer()

	}
	
	private func configureWideAngleCameraCapture() {
		
		//Find the wide angle camera.
		guard let wideAngleCameraDevice = AVCaptureDevice.DiscoverySession(
			deviceTypes : [.builtInWideAngleCamera],
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
		
		self.wideAngleCameraDevice = wideAngleCameraDevice
		
		//Add the wide angle camera input to the capture session.
		do {
			try wideAngleCameraDevice.lockForConfiguration()
			
			wideAngleCameraDevice.activeFormat = wideAngleCameraDevice.formats[38]
			wideAngleCameraDevice.exposureMode = .continuousAutoExposure
			wideAngleCameraDevice.whiteBalanceMode = .continuousAutoWhiteBalance
			
			wideAngleCameraDevice.focusMode = .continuousAutoFocus
			wideAngleDeviceInput = try AVCaptureDeviceInput(device: wideAngleCameraDevice)
			
			guard let wideAngleDeviceInput = wideAngleDeviceInput,
				  captureSession.canAddInput(wideAngleDeviceInput) else {
					  debugPrint("Could not add camera input.")
					  return
				  }
			
			captureSession.addInputWithNoConnections(wideAngleDeviceInput)
			wideAngleCameraDevice.unlockForConfiguration()
			
			
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
		
		//Find the wide angle camera device input's video port
		
		guard let wideAngleDeviceInput = wideAngleDeviceInput,
			  let wideAngleVideoPort = wideAngleDeviceInput.ports(for: .video,
																	 sourceDeviceType: wideAngleCameraDevice.deviceType,
																	 sourceDevicePosition: .back).first
		else {
			debugPrint("Cloud not find the back camera device input's video port.")
			return
		}
		
		//Add the wide angle camera photo and output.
		guard captureSession.canAddOutput(wideAnglePhotoOutput),
			  captureSession.canAddOutput(wideAngleVideoDataOutput)
		else {
			debugPrint("Could not add the wide angle camera photo and/or video data output.")
			return
		}
		
		
		wideAnglePhotoOutput.isHighResolutionCaptureEnabled = true
		wideAnglePhotoOutput.maxPhotoQualityPrioritization = .quality
		
		captureSession.addOutputWithNoConnections(wideAnglePhotoOutput)

		
		captureSession.addOutputWithNoConnections(wideAngleVideoDataOutput)
		wideAngleVideoDataOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "camera_frame_processing_queue"))
		wideAngleVideoDataOutput.videoSettings = [
			(kCVPixelBufferPixelFormatTypeKey as NSString) : NSNumber(value: kCVPixelFormatType_32BGRA),
		] as [String : Any]
		
		
		//Connect the wide angle camera device input to the wide angle camera video data output.
		let wideAngleCameraVideoDataOutputConnection = AVCaptureConnection(inputPorts: [wideAngleVideoPort], output: wideAngleVideoDataOutput)
		
		guard captureSession.canAddConnection(wideAngleCameraVideoDataOutputConnection) else {
			debugPrint("Could not add a connection to the wide angle camera video data output.")
			return
		}
		
		wideAngleCameraVideoDataOutputConnection.videoOrientation = .portrait
		wideAngleCameraVideoDataOutputConnection.preferredVideoStabilizationMode = .off

		
		captureSession.addConnection(wideAngleCameraVideoDataOutputConnection)


		//Connect the wide angle camera device input to the wide angle camera photo output.
		let wideAngleCameraPhotoOutputConnection = AVCaptureConnection(inputPorts: [wideAngleVideoPort], output: wideAnglePhotoOutput)
		
		guard captureSession.canAddConnection(wideAngleCameraPhotoOutputConnection) else {
			debugPrint("Could not add a connection to the wide angle camera video data output.")
			return
		}
		
		captureSession.addConnection(wideAngleCameraPhotoOutputConnection)
		
		//Connect the wide angle camera device input to the wide angle camera video preview layer
		
		_ = AVCaptureConnection(inputPort: wideAngleVideoPort, videoPreviewLayer: wideAngleCameraPreviewLayer)

		return
	}
	
	private func configureUltraWideAngleCameraCapture() {
		
		//Find the ultraWide angle camera.
		
		guard let ultraWideAngleCameraDevice = AVCaptureDevice.DiscoverySession(
			deviceTypes : [.builtInUltraWideCamera],
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
		
		//Add the ultra wide angle camera input to the capture session.
		do {
			try ultraWideAngleCameraDevice.lockForConfiguration()
			
			ultraWideAngleCameraDevice.activeFormat = ultraWideAngleCameraDevice.formats[9]
						
			ultraWideCameraDeviceInput = try AVCaptureDeviceInput(device: ultraWideAngleCameraDevice)
			
			guard let ultraWideCameraDeviceInput = ultraWideCameraDeviceInput,
				  captureSession.canAddInput(ultraWideCameraDeviceInput) else {
					  debugPrint("Could not add ultra wide camera input.")
					  return
				  }
			
			captureSession.addInputWithNoConnections(ultraWideCameraDeviceInput)
			ultraWideAngleCameraDevice.unlockForConfiguration()
			
			
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
		
		//Find the ultra wide angle camera device input's video port
		
		guard let ultraWideCameraDeviceInput = ultraWideCameraDeviceInput,
			  let ultraWideCameraVideoPort = ultraWideCameraDeviceInput.ports(for: .video,
																				 sourceDeviceType: ultraWideAngleCameraDevice.deviceType,
																				 sourceDevicePosition: .back).first
		else {
			debugPrint("Cloud not find the ultra wide camera device input's video port.")
			return
		}
		
		//Add the wide angle camera photo and output.
		guard captureSession.canAddOutput(ultraWideAngleVideoDataOutput)
		else {
			debugPrint("Could not add the ultra wide angle camera photo and/or video data output.")
			return
		}
		
		captureSession.addOutputWithNoConnections(ultraWideAngleVideoDataOutput)
		
		wideAngleVideoDataOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "camera_frame_processing_queue"))
		wideAngleVideoDataOutput.videoSettings = [
			(kCVPixelBufferPixelFormatTypeKey as NSString) : NSNumber(value: kCVPixelFormatType_32BGRA)
		] as [String : Any]
		
		//Connect the wide angle camera device input to the wide angle camera video data output.
		let ultraWideAngleCameraVideoDataOutputConnection = AVCaptureConnection(inputPorts: [ultraWideCameraVideoPort], output: ultraWideAngleVideoDataOutput)
		
		guard captureSession.canAddConnection(ultraWideAngleCameraVideoDataOutputConnection) else {
			debugPrint("Could not add a connection to the wide angle camera video data output.")
			return
		}
		
		captureSession.addConnection(ultraWideAngleCameraVideoDataOutputConnection)
		ultraWideAngleCameraVideoDataOutputConnection.videoOrientation = .portrait
		
		//Connect the wide angle camera device input to the wide angle camera video preview layer
		
		_ = AVCaptureConnection(inputPort: ultraWideCameraVideoPort, videoPreviewLayer: ultraWideAngleCameraPreviewLayer)
		
		return
	}
	
	
	private func configureUltraWideAnglePreviewView() {
		view.addSubview(ultraWideAnglePreviewView)
		
		ultraWideAnglePreviewView.translatesAutoresizingMaskIntoConstraints = false
		ultraWideAnglePreviewView.backgroundColor = .systemBackground
		
		NSLayoutConstraint.activate([
			ultraWideAnglePreviewView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 1.7),
			ultraWideAnglePreviewView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 1.7),
			ultraWideAnglePreviewView.centerXAnchor.constraint(equalTo: view.centerXAnchor, constant: 0),
			ultraWideAnglePreviewView.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: 0)
		])
	}
	
	private func configureVisualEffectView() {
	 	view.insertSubview(visualEffectView, aboveSubview: ultraWideAnglePreviewView)
		visualEffectView.translatesAutoresizingMaskIntoConstraints = false
		
		NSLayoutConstraint.activate([
			visualEffectView.topAnchor.constraint(equalTo:view.topAnchor),
			visualEffectView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
			visualEffectView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
			visualEffectView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
		])
	}
	
	
	private func configureWideAnglePreviewView() {
		
		view.addSubview(wideAnglePreviewView)
		
		wideAnglePreviewView.layer.borderColor = UIColor.white.cgColor
		wideAnglePreviewView.backgroundColor = .systemGray4
		
		wideAnglePreviewView.layer.borderWidth = 1
		
		wideAnglePreviewView.layer.cornerRadius = 10
		
		wideAnglePreviewView.clipsToBounds = true
		
		wideAnglePreviewView.translatesAutoresizingMaskIntoConstraints = false
		
		NSLayoutConstraint.activate([
			wideAnglePreviewView.bottomAnchor.constraint(equalTo: captureButton.topAnchor, constant: -80),
			wideAnglePreviewView.heightAnchor.constraint(equalTo: view.widthAnchor, multiplier: (4/3)*0.98),
			wideAnglePreviewView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.98),
			wideAnglePreviewView.centerXAnchor.constraint(equalTo: view.centerXAnchor)
		])
	}
	
	private func configureWideAngleCameraPreviewLayer() {
		
		let previewFrame = wideAnglePreviewView.bounds
		
		wideAngleCameraPreviewLayer.frame          = previewFrame
		wideAngleCameraPreviewLayer.videoGravity   = .resizeAspect
		
		wideAnglePreviewView.layer.addSublayer(wideAngleCameraPreviewLayer)

	}
	
	

	private func configureUltraWideAngleCameraPreviewLayer() {
		
		let previewFrame = ultraWideAnglePreviewView.bounds
		
		ultraWideAngleCameraPreviewLayer.frame          = previewFrame
		ultraWideAngleCameraPreviewLayer.videoGravity   = .resizeAspect
		
		ultraWideAnglePreviewView.layer.addSublayer(ultraWideAngleCameraPreviewLayer)

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
		guard let device = wideAngleCameraDevice else {return}
		
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
		
		let currentPhotoCaptureSettings = AVCapturePhotoSettings(from: photoSettings)
		
		currentPhotoCaptureSettings.isHighResolutionPhotoEnabled = true
		currentPhotoCaptureSettings.photoQualityPrioritization = .quality
		currentPhotoCaptureSettings.isAutoVirtualDeviceFusionEnabled = true
		
		wideAnglePhotoOutput.capturePhoto(with: currentPhotoCaptureSettings, delegate: self)
	}
	
	func turnOffFlash() {
		guard let device = wideAngleCameraDevice else {return}
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
		outlineLayer.frame = wideAngleCameraPreviewLayer.bounds
		wideAngleCameraPreviewLayer.insertSublayer(outlineLayer, at: 1)
	}
	
	
	private func resetRecognition() {
		self.detectedRectangle = nil
		self.drawBoundingBox(rect: VNRectangleObservation())
		self.ciImage = nil
		self.uiImage = UIImage()
	}
	
	private func detectRectangle(in image: CIImage) {
		
		DispatchQueue.main.async {
			
			//Stop recognition if ScannerVC is not presented.
			guard self.presentedViewController == nil else {
				self.resetRecognition()
				return
			}
			
			self.ciImage = image
			
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
					
					self.presentCaptureDetailVC(with: self.ciImage)
					self.turnOffFlash()
					
				}
			}
			
			request.minimumAspectRatio  = VNAspectRatio(0.1)
			request.maximumAspectRatio  = VNAspectRatio(4)
			request.minimumSize         = Float(0.15)
			request.minimumConfidence   = 1.0
			request.maximumObservations = 1
			
			let imageRequestHandler = VNImageRequestHandler(ciImage: self.ciImage!, options: [:])
			
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
	
	private func detectRectangle(in cvBuffer: CVPixelBuffer) {
		
		DispatchQueue.main.async {
			
			//Stop recognition if ScannerVC is not presented.
			guard self.presentedViewController == nil else {
				self.resetRecognition()
				return
			}
			
			self.ciImage = CIImage(cvPixelBuffer: cvBuffer)
			
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
			
			let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: cvBuffer, options: [:])
			
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
		
		guard let ciImage = ciImage, let unwrappedObservation = observation else {
			let okayAlertAction = UIAlertAction(title: "Ok", style: .default)
			let alert = UIAlertController(
				title: "No Object Detected",
				message: "Move the camera closer to the object until the recognition box is shown, or place object on a contrasting background.",
				preferredStyle: .alert)
			
			alert.addAction(okayAlertAction)
			self.present(alert, animated: true)
			return
		}
		
		var image = ciImage
		
		let topLeft     = unwrappedObservation.topLeft.scaled(to: ciImage.extent.size)
		let topRight    = unwrappedObservation.topRight.scaled(to: ciImage.extent.size)
		let bottomLeft  = unwrappedObservation.bottomLeft.scaled(to: ciImage.extent.size)
		let bottomRight = unwrappedObservation.bottomRight.scaled(to: ciImage.extent.size)
		
		image = image.applyingFilter("CIPerspectiveCorrection", parameters: [
			"inputTopLeft"      : CIVector(cgPoint: topLeft),
			"inputTopRight"     : CIVector(cgPoint: topRight),
			"inputBottomLeft"   : CIVector(cgPoint: bottomLeft),
			"inputBottomRight"  : CIVector(cgPoint: bottomRight)
		]).applyingFilter("CIDocumentEnhancer", parameters: [
			"inputAmount" : 1
		]).applyingFilter("CIColorControls", parameters: [
			"inputBrightness" : -0.2,
			"inputContrast"	  : 1.5
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
		
		let bottomTopTransform = CGAffineTransform(scaleX: 1, y: -1).translatedBy(x: 0, y: -wideAngleCameraPreviewLayer.frame.height)
		
		let topRight    = VNImagePointForNormalizedPoint(rect.topRight, Int(wideAngleCameraPreviewLayer.frame.width), Int(wideAngleCameraPreviewLayer.frame.height)).applying(bottomTopTransform)
		let topLeft     = VNImagePointForNormalizedPoint(rect.topLeft, Int(wideAngleCameraPreviewLayer.frame.width), Int(wideAngleCameraPreviewLayer.frame.height)).applying(bottomTopTransform)
		let bottomRight = VNImagePointForNormalizedPoint(rect.bottomRight, Int(wideAngleCameraPreviewLayer.frame.width), Int(wideAngleCameraPreviewLayer.frame.height)).applying(bottomTopTransform)
		let bottomLeft  = VNImagePointForNormalizedPoint(rect.bottomLeft, Int(wideAngleCameraPreviewLayer.frame.width), Int(wideAngleCameraPreviewLayer.frame.height)).applying(bottomTopTransform)
		
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

//MARK: AVCaptureVideoDataOutputSampleBufferDelegate

extension ScannerVC: AVCaptureVideoDataOutputSampleBufferDelegate {
	
	//This function provides each frame used in the preview layer. Detect rectangle is called out to detect and draw detected rectangles in the preview layer frame.
	func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
		guard let frame = CMSampleBufferGetImageBuffer(sampleBuffer) else {return}
		detectRectangle(in: frame)
	}
}

//MARK: AVCapturePhotoCaptureDelegate

extension ScannerVC: AVCapturePhotoCaptureDelegate {
	
	//This function is called out when a picture is captured in capturePhoto
	func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
		
		guard let cgImage = photo.cgImageRepresentation() else {
			let okayAlertAction = UIAlertAction(title: "Ok", style: .default)
			let alert = UIAlertController(
				title: "No Object Detected",
				message: "Move the camera closer to the object until the recognition box is shown, or place object on a background with different color.",
				preferredStyle: .alert)
			
			alert.addAction(okayAlertAction)
			self.present(alert, animated: true)
			return
		}
		
		ciImage = CIImage(cgImage: cgImage)
		
		guard let ciImage = ciImage else {
			let okayAlertAction = UIAlertAction(title: "Ok", style: .default)
			let alert = UIAlertController(
				title: "No Object Detected",
				message: "Move the camera closer to the object until the recognition box is shown, or place object on a background with different color.",
				preferredStyle: .alert)
			
			alert.addAction(okayAlertAction)
			self.present(alert, animated: true)
			return
		}
		
		self.ciImage = ciImage.oriented(.right)
		
	}
	
	
	func photoOutput(_ output: AVCapturePhotoOutput, didFinishCaptureFor resolvedSettings: AVCaptureResolvedPhotoSettings, error: Error?) {
		
		guard let ciImage = ciImage else {
			let okayAlertAction = UIAlertAction(title: "Ok", style: .default)
			let alert = UIAlertController(
				title: "No Object Detected",
				message: "Move the camera closer to the object until the recognition box is shown, or place object on a background with different color.",
				preferredStyle: .alert)
			
			alert.addAction(okayAlertAction)
			self.present(alert, animated: true)
			return
		}
		
		detectRectangle(in: ciImage)
	}
	
}
