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
	
	private let wideAnglePreviewView					= SSPreviewView()
	private let ultraWideAnglePreviewView				= SSPreviewView()
	private let outlineLayer                			= CAShapeLayer()
	private var uiImage                     			= UIImage()
	private var framesWithoutRecognitionCounter   		= 0
	private var ciImage : CIImage?
	
	
	//MARK: AVFoundation Properties
	
	private let captureSession              			= AVCaptureMultiCamSession()
	private let wideAnglePhotoOutput					= AVCapturePhotoOutput()
	private lazy var wideAngleCameraDevice          	= AVCaptureDevice(uniqueID: "")
	private lazy var wideAngleCameraPreviewLayer 		= AVCaptureVideoPreviewLayer(session: captureSession)
	private lazy var ultraWideAngleCameraPreviewLayer 	= AVCaptureVideoPreviewLayer(session: captureSession)
	

	//MARK: Vision Properties
	
	private var detectedRectangle	: VNRectangleObservation?
	

	//MARK: ScannerVC Life Cycle Methods
	
	//Subviews are configured in viewWillAppear
	override func viewWillAppear(_ animated: Bool) {
		configureUltraWideAnglePreviewView()
		configureWideAnglePreviewView()
		configureVisualEffectView()
		configureButtons()
	}
	
	//The capture session is configured in viewDidAppear in order to show the subviews while the capture session is being configured.
	override func viewDidAppear(_ animated: Bool) {
		guard verifyDeviceSupportAndCameraAccess() else {return}
		configureWideAngleCameraCapture()
		configureUltraWideAngleCameraCapture()
		configureUpOutlineLayer()
		configureWideAngleCameraPreviewLayer()
		configureUltraWideAngleCameraPreviewLayer()
		captureSession.startRunning()
	}
	
	
	//MARK: Subview Configuration
	
	private func configureUltraWideAnglePreviewView() {
		view.addSubview(ultraWideAnglePreviewView)
		
		ultraWideAnglePreviewView.backgroundColor = .black
		ultraWideAnglePreviewView.translatesAutoresizingMaskIntoConstraints = false
		
		NSLayoutConstraint.activate([
			ultraWideAnglePreviewView.heightAnchor.constraint(equalTo: view.heightAnchor),
			ultraWideAnglePreviewView.widthAnchor.constraint(equalTo: view.widthAnchor),
			ultraWideAnglePreviewView.centerXAnchor.constraint(equalTo: view.centerXAnchor, constant: 0),
			ultraWideAnglePreviewView.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: 0)
		])
	}
	
	
	private func configureVisualEffectView() {
		
		let visualEffectView = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterial))
		
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
		
		wideAnglePreviewView.layer.borderColor 	= UIColor.white.cgColor
		wideAnglePreviewView.backgroundColor 	= .black.withAlphaComponent(0.8)
		wideAnglePreviewView.clipsToBounds 		= true
		wideAnglePreviewView.layer.borderWidth 	= 1
		wideAnglePreviewView.layer.cornerRadius = 10
		wideAnglePreviewView.translatesAutoresizingMaskIntoConstraints = false
		
		let viewOffsetMultiplier = 0.98
		
		NSLayoutConstraint.activate([
			wideAnglePreviewView.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor, constant: -50),
			wideAnglePreviewView.heightAnchor.constraint(equalTo: view.widthAnchor, multiplier: CGFloat((4/3)*viewOffsetMultiplier)),
			wideAnglePreviewView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: CGFloat(viewOffsetMultiplier)),
			wideAnglePreviewView.centerXAnchor.constraint(equalTo: view.centerXAnchor)
		])
	}
	
	
	private func configureButtons() {
		
		//Capture Button Configuration
		let captureButtonHeight: CGFloat 		= 70
		let captureButtonSymbolConfiguration 	= UIImage.SymbolConfiguration(pointSize: captureButtonHeight - 5, weight: .ultraLight)
		let captureButton   					= SSCircularButton(buttonHeight: captureButtonHeight, symbolConfiguration: captureButtonSymbolConfiguration, symbolName: "camera.circle")
		
		view.addSubview(captureButton)
		
		captureButton.addTarget(self, action: #selector(captureButtonTapped), for: .touchUpInside)
		
		NSLayoutConstraint.activate([
			captureButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
			captureButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -30),
			captureButton.heightAnchor.constraint(equalToConstant: captureButton.buttonHeight),
			captureButton.widthAnchor.constraint(equalToConstant: captureButton.buttonHeight)
		])
		
		//Flash Button Configuration
		
		let flashButtonHeight: CGFloat 	= 50
		let flashButtonSymbolConfiguration 	= UIImage.SymbolConfiguration(pointSize: flashButtonHeight - 15, weight: .ultraLight)
		let flashButton   = SSCircularButton(buttonHeight: flashButtonHeight, symbolConfiguration: flashButtonSymbolConfiguration, symbolName: "flashlight.off.fill")
		
		view.addSubview(flashButton)
		
		flashButton.addTarget(self, action: #selector(flashButtonTapped), for: .touchUpInside)
		
		NSLayoutConstraint.activate([
			flashButton.leadingAnchor.constraint(equalTo: captureButton.trailingAnchor, constant: 20),
			flashButton.centerYAnchor.constraint(equalTo: captureButton.centerYAnchor),
			flashButton.heightAnchor.constraint(equalToConstant: flashButton.buttonHeight),
			flashButton.widthAnchor.constraint(equalToConstant: flashButton.buttonHeight)
		])
		
		//TipsButtonConfiguration
		let tipsButtonHeight: CGFloat 	= 30
		let tipsButtonSymbolConfiguration 	= UIImage.SymbolConfiguration(pointSize: tipsButtonHeight-10, weight: .bold)
		let tipsButton   			= SSCircularButton(buttonHeight: tipsButtonHeight, symbolConfiguration: tipsButtonSymbolConfiguration, symbolName: "questionmark")
		let tipsButtonNormalBackgroundColor = UIColor.gray.withAlphaComponent(0.2)
		let tipsButtonHighlightedBackgroundColor = UIColor.gray.withAlphaComponent(0.6)
		view.addSubview(tipsButton)
		
		tipsButton.addTarget(self, action: #selector(tipsButtonTapped), for: .touchUpInside)
		
		tipsButton.layer.borderWidth = 1
		tipsButton.layer.borderColor = UIColor.white.cgColor
		tipsButton.backgroundColor = tipsButtonNormalBackgroundColor
		tipsButton.normalBackgroundColor = tipsButtonNormalBackgroundColor
		tipsButton.highlightedBackgroundColor = tipsButtonHighlightedBackgroundColor
		tipsButton.imageView?.tintColor = .white
		
		NSLayoutConstraint.activate([
			tipsButton.trailingAnchor.constraint(equalTo: wideAnglePreviewView.trailingAnchor, constant: -10),
			tipsButton.bottomAnchor.constraint(equalTo: wideAnglePreviewView.bottomAnchor, constant: -10),
			tipsButton.heightAnchor.constraint(equalToConstant: tipsButton.buttonHeight),
			tipsButton.widthAnchor.constraint(equalToConstant: tipsButton.buttonHeight)
		])
		
	}
	
	
	//MARK: AVFoundation Capture Session Configuration
	
	private func verifyDeviceSupportAndCameraAccess() -> Bool {
		//Verify primary camera device support.
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
			return false
		}
		
		// Verify that camera access authorization is provided and start capture session configuration if it is or is not determined yet.
		guard verifyCameraAccessOrNotDetermined() else {return false}
		
		return true
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
		var wideAngleDeviceInput: AVCaptureDeviceInput? = nil
		
		do {
			try wideAngleCameraDevice.lockForConfiguration()
			
			let formats = wideAngleCameraDevice.formats
			
			for format in formats {
				if format.isMultiCamSupported {
					let photoDimensions = format.highResolutionStillImageDimensions
					let maxFrameRate 	= format.videoSupportedFrameRateRanges.first!.maxFrameRate
					let videoDimensions = CMVideoFormatDescriptionGetDimensions(format.formatDescription)

					if (Float(videoDimensions.width) / Float(videoDimensions.height) == 1.3333334) && photoDimensions.width == 4032 &&  photoDimensions.height == 3024 && maxFrameRate == 60 && format.isVideoHDRSupported {
						wideAngleCameraDevice.activeFormat = format
						break
					}
				}
			}
			
			var activeFormatPhotoDimensions = wideAngleCameraDevice.activeFormat.highResolutionStillImageDimensions
			var activeFormatMaxFrameRate 	= wideAngleCameraDevice.activeFormat.videoSupportedFrameRateRanges.first!.maxFrameRate
			var activeFormatVideoDimensions = CMVideoFormatDescriptionGetDimensions(wideAngleCameraDevice.activeFormat.formatDescription)
			
			if !(Float(activeFormatVideoDimensions.width) / Float(activeFormatVideoDimensions.height) == 1.3333334) || activeFormatPhotoDimensions.width != 4032 ||  activeFormatPhotoDimensions.height != 3024 || activeFormatMaxFrameRate != 60 || !wideAngleCameraDevice.activeFormat.isVideoHDRSupported {
				for format in formats {
					if format.isMultiCamSupported {

						let photoDimensions = format.highResolutionStillImageDimensions

						let videoDimensions = CMVideoFormatDescriptionGetDimensions(format.formatDescription)

						if (Float(videoDimensions.width) / Float(videoDimensions.height) == 1.3333334) && photoDimensions.width == 4032 &&  photoDimensions.height == 3024 && format.isVideoHDRSupported {
							wideAngleCameraDevice.activeFormat = format
							activeFormatPhotoDimensions = wideAngleCameraDevice.activeFormat.highResolutionStillImageDimensions
							activeFormatMaxFrameRate 	= wideAngleCameraDevice.activeFormat.videoSupportedFrameRateRanges.first!.maxFrameRate
							activeFormatVideoDimensions = CMVideoFormatDescriptionGetDimensions(wideAngleCameraDevice.activeFormat.formatDescription)
							break
						}
					}
				}
			}
			
			
			if !wideAngleCameraDevice.activeFormat.isVideoHDRSupported || !(activeFormatPhotoDimensions.width == 4032 && activeFormatPhotoDimensions.height == 3024) {
				for format in formats {
					if format.isMultiCamSupported {
						let videoDimensions = CMVideoFormatDescriptionGetDimensions(format.formatDescription)
						
						if (Float(videoDimensions.width) / Float(videoDimensions.height) == 1.3333334) {
							wideAngleCameraDevice.activeFormat = format
							break
						}
					}
				}
			}
			
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
		
		
		let wideAngleVideoDataOutput			= AVCaptureVideoDataOutput()
		//Add the wide angle camera photo and and video data outputs.
		guard captureSession.canAddOutput(wideAnglePhotoOutput),
			  captureSession.canAddOutput(wideAngleVideoDataOutput)
		else {
			debugPrint("Could not add the wide angle camera photo and/or video data output.")
			return
		}
		
		wideAnglePhotoOutput.isHighResolutionCaptureEnabled = true
		wideAnglePhotoOutput.maxPhotoQualityPrioritization = .balanced
		captureSession.addOutputWithNoConnections(wideAnglePhotoOutput)

		wideAngleVideoDataOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "camera_frame_processing_queue"))
		wideAngleVideoDataOutput.videoSettings = [(kCVPixelBufferPixelFormatTypeKey as NSString) : NSNumber(value: kCVPixelFormatType_32BGRA)] as [String : Any]
		captureSession.addOutputWithNoConnections(wideAngleVideoDataOutput)

		//Connect the wide angle camera device input to the wide angle camera video data output.
		let wideAngleCameraVideoDataOutputConnection = AVCaptureConnection(inputPorts: [wideAngleVideoPort], output: wideAngleVideoDataOutput)
		
		guard captureSession.canAddConnection(wideAngleCameraVideoDataOutputConnection) else {
			debugPrint("Could not add a connection to the wide angle camera video data output.")
			return
		}
		
		wideAngleCameraVideoDataOutputConnection.videoOrientation = .portrait
		//Stabilization is turned off to allow for maximum still image resolution capture.
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
		
		//Find the ultra wide angle camera.
		
		let deviceDiscoverySession = AVCaptureDevice.DiscoverySession(
			deviceTypes : [.builtInUltraWideCamera],
			mediaType   : .video,
			position    : .back
			
		)
		
		guard !deviceDiscoverySession.devices.isEmpty else {return}
		
		guard let ultraWideAngleCameraDevice = deviceDiscoverySession.devices.first else {return}
		
		//Add the ultra wide angle camera input to the capture session.
		var ultraWideCameraDeviceInput: AVCaptureDeviceInput? = nil
		
		do {
			try ultraWideAngleCameraDevice.lockForConfiguration()
			
			let formats = ultraWideAngleCameraDevice.formats
			
			for format in formats {
				if format.isMultiCamSupported {
					let videoDimensions = CMVideoFormatDescriptionGetDimensions(format.formatDescription)
					if (Float(videoDimensions.width) / Float(videoDimensions.height) == 1.3333334) && format.isVideoBinned {
						ultraWideAngleCameraDevice.activeFormat = format
					}
				}
			}
						
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
			debugPrint("Could not find the ultra wide camera device input's video port.")
			return
		}
		
		let ultraWideAngleVideoDataOutput		= AVCaptureVideoDataOutput()
		//Add the wide angle camera photo and output.
		guard captureSession.canAddOutput(ultraWideAngleVideoDataOutput)
		else {
			debugPrint("Could not add the ultra wide angle camera photo and/or video data output.")
			return
		}
		
		captureSession.addOutputWithNoConnections(ultraWideAngleVideoDataOutput)
		
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
	
	
	private func configureWideAngleCameraPreviewLayer() {
		let previewFrame = wideAnglePreviewView.bounds
		
		wideAngleCameraPreviewLayer.frame          	= previewFrame
		wideAngleCameraPreviewLayer.videoGravity   	= .resizeAspect
		
		wideAnglePreviewView.layer.addSublayer(wideAngleCameraPreviewLayer)
	}
	
	
	private func configureUltraWideAngleCameraPreviewLayer() {
		let previewFrame = ultraWideAnglePreviewView.bounds
		
		ultraWideAngleCameraPreviewLayer.frame          = previewFrame
		ultraWideAngleCameraPreviewLayer.videoGravity   = .resizeAspectFill
		
		ultraWideAnglePreviewView.layer.addSublayer(ultraWideAngleCameraPreviewLayer)
	}
	
	
	private func configureUpOutlineLayer() {
		outlineLayer.frame = wideAngleCameraPreviewLayer.bounds
		wideAngleCameraPreviewLayer.insertSublayer(outlineLayer, at: 1)
	}
	
	
	//MARK: Vision Rectangle Recognition Configuration
	
	private func detectPreviewRectangle(in cvBuffer: CVPixelBuffer) {
		
		DispatchQueue.main.async {
			
			//Stop recognition if ScannerVC is not presented.
			guard self.presentedViewController == nil else {
				self.resetRecognition()
				return
			}
			
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
	
	
	private func detectPhotoCaptureRectangle(in image: CIImage) {
		
		DispatchQueue.main.async {
			
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
						let imageAttachment = NSTextAttachment()
						imageAttachment.image = UIImage(systemName: "questionmark.circle")?.withTintColor(.label)
						
						
						let fullString = NSMutableAttributedString(string: "Make sure all of the object edges are within view. \nPress ")
						fullString.append(NSAttributedString(attachment: imageAttachment))
						fullString.append(NSAttributedString(string: " to see more tips for best results."))
						
						let okayAlertAction = UIAlertAction(title: "Ok", style: .default)
						let alert = UIAlertController(
							title: "No Object Detected",
							message: "",
							preferredStyle: .alert)
						alert.setValue(fullString, forKey: "attributedMessage")
						
						alert.addAction(okayAlertAction)
						self.present(alert, animated: true)
						return
					}
					
					self.detectedRectangle = rect
					
					self.presentCaptureDetailVC(with: self.ciImage)
					self.toggleFlash()
				}
			}
			
			request.minimumAspectRatio  = VNAspectRatio(0.1)
			request.maximumAspectRatio  = VNAspectRatio(4)
			request.minimumSize         = Float(0.15)
			request.minimumConfidence   = 1.0
			request.maximumObservations = 1
			
			let imageRequestHandler = VNImageRequestHandler(ciImage: image, options: [:])
			
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
	
	
	private func resetRecognition() {
		self.detectedRectangle = nil
		self.drawBoundingBox(rect: VNRectangleObservation())
		self.ciImage = nil
		self.uiImage = UIImage()
	}

	
	//MARK: Photo Capture Processing Configuration
	
	private func processPhotoCapture(_ observation: VNRectangleObservation?, from ciImage: CIImage?) {
		
		guard let ciImage = ciImage, let unwrappedObservation = observation else {
			let imageAttachment = NSTextAttachment()
			imageAttachment.image = UIImage(systemName: "questionmark.circle")
			
			
			let fullString = NSMutableAttributedString(string: "Make sure all of the object edges are within view. \nPress ")
			fullString.append(NSAttributedString(attachment: imageAttachment))
			fullString.append(NSAttributedString(string: " to see more tips for best results."))
			
			let okayAlertAction = UIAlertAction(title: "Ok", style: .default)
			let alert = UIAlertController(
				title: "No Object Detected",
				message: "",
				preferredStyle: .alert)
			alert.setValue(fullString, forKey: "attributedMessage")
			
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
			"inputContrast"	  : 1.4
		])
		
		let context = CIContext()
		let cgImage = context.createCGImage(image, from: image.extent)
		uiImage  = UIImage(cgImage: cgImage!, scale: 1, orientation: .up)
	}
	
	
	//MARK: Button Action Configuration
	
	@objc private func captureButtonTapped() {
		
		guard verifyCameraAccessOrNotDetermined() else {
			return
		}
		
		let photoSettings = AVCapturePhotoSettings(format: [
			AVVideoCodecKey 	: AVVideoCodecType.hevc
		])
		
		photoSettings.isHighResolutionPhotoEnabled = true
		photoSettings.photoQualityPrioritization = .balanced
		
		
		wideAnglePhotoOutput.capturePhoto(with: photoSettings, delegate: self)
	}
	
	
	private func presentCaptureDetailVC(with image: CIImage?) {
		
		processPhotoCapture(detectedRectangle, from: image)
		
		let captureDetailVC = CaptureDetailVC(image: uiImage)
		
		captureDetailVC.modalPresentationStyle = .overCurrentContext
		
		present(captureDetailVC, animated: true, completion: nil)
		
	}
	
	
	@objc private func flashButtonTapped() {
		toggleFlash()
	}
	
	
	private func toggleFlash() {
		guard let device = wideAngleCameraDevice else {return}
		
		guard device.hasTorch else { return }
		
		do {
			try device.lockForConfiguration()
			
			if (device.torchMode == AVCaptureDevice.TorchMode.on) || (self.presentedViewController != nil) {
				device.torchMode = AVCaptureDevice.TorchMode.off
			} else {
				do {
					try device.setTorchModeOn(level: 0.1)
				} catch {
					let okayAlertAction = UIAlertAction(title: "Ok", style: .default)
					let alert = UIAlertController(
						title: "Flash Toggle Error",
						message: "An error was encountered while accessing the flash light. Restarting the device may solve this error.",
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
					title: "Flash Toggle Error",
					message: "The system may have locked the flash light. Restarting the device may solve this error.",
					preferredStyle: .alert)
				
				alert.addAction(okayAlertAction)
				self.present(alert, animated: true)
			}
		}
	}
	
	@objc private func tipsButtonTapped() {
		let tipsVC = TipsVC()
		
		tipsVC.modalPresentationStyle = .overCurrentContext
		
		present(tipsVC, animated: true)
	}
}


//MARK: AVFoundation Delegate Extensions

extension ScannerVC: AVCaptureVideoDataOutputSampleBufferDelegate {
	func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
		guard let frame = CMSampleBufferGetImageBuffer(sampleBuffer) else {return}
		detectPreviewRectangle(in: frame)
	}
}

extension ScannerVC: AVCapturePhotoCaptureDelegate {
	func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
		
		guard let cgImage = photo.cgImageRepresentation() else {
			let imageAttachment = NSTextAttachment()
			imageAttachment.image = UIImage(systemName: "questionmark.circle")
			
			
			let fullString = NSMutableAttributedString(string: "Make sure all of the object edges are within view. \nPress ")
			fullString.append(NSAttributedString(attachment: imageAttachment))
			fullString.append(NSAttributedString(string: " to see more tips for best results."))
			
			let okayAlertAction = UIAlertAction(title: "Ok", style: .default)
			let alert = UIAlertController(
				title: "No Object Detected",
				message: "",
				preferredStyle: .alert)
			alert.setValue(fullString, forKey: "attributedMessage")
			
			alert.addAction(okayAlertAction)
			self.present(alert, animated: true)
			return
		}
		
		ciImage = CIImage(cgImage: cgImage)
		
		guard let ciImage = ciImage else {
			let imageAttachment = NSTextAttachment()
			imageAttachment.image = UIImage(systemName: "questionmark.circle")
			
			
			let fullString = NSMutableAttributedString(string: "Make sure all of the object edges are within view. \nPress ")
			fullString.append(NSAttributedString(attachment: imageAttachment))
			fullString.append(NSAttributedString(string: " to see more tips for best results."))
			
			let okayAlertAction = UIAlertAction(title: "Ok", style: .default)
			let alert = UIAlertController(
				title: "No Object Detected",
				message: "",
				preferredStyle: .alert)
			alert.setValue(fullString, forKey: "attributedMessage")
			
			alert.addAction(okayAlertAction)
			self.present(alert, animated: true)
			return
		}
		
		self.ciImage = ciImage.oriented(.right)
		
	}
	
	
	func photoOutput(_ output: AVCapturePhotoOutput, didFinishCaptureFor resolvedSettings: AVCaptureResolvedPhotoSettings, error: Error?) {
		guard let ciImage = ciImage else {
			let imageAttachment = NSTextAttachment()
			imageAttachment.image = UIImage(systemName: "questionmark.circle")
			
			
			let fullString = NSMutableAttributedString(string: "Make sure all of the object edges are within view. \nPress ")
			fullString.append(NSAttributedString(attachment: imageAttachment))
			fullString.append(NSAttributedString(string: " to see more tips for best results."))
			
			let okayAlertAction = UIAlertAction(title: "Ok", style: .default)
			let alert = UIAlertController(
				title: "No Object Detected",
				message: "",
				preferredStyle: .alert)
			alert.setValue(fullString, forKey: "attributedMessage")
			
			alert.addAction(okayAlertAction)
			self.present(alert, animated: true)
			return
		}
		
		detectPhotoCaptureRectangle(in: ciImage)
	}
}
