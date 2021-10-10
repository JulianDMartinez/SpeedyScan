//
//  VisionViewController.swift
//  SpeedyScan
//
//  Created by Julian Martinez on 5/23/21.
//

import UIKit
import AVFoundation
import Vision

class CaptureSessionManager: NSObject {
	
	weak var viewController = UIViewController()
	
	//MARK: UIKit Properties
	
	let wideAnglePreviewView					= SSPreviewView()
	let ultraWideAnglePreviewView				= SSPreviewView()
	let outlineLayer                			= CAShapeLayer()
	var uiImage                     			= UIImage()
	var framesWithoutRecognitionCounter   		= 0
	var ciImage : CIImage?
	
	
	//MARK: AVFoundation Properties
	
	let wideAnglePhotoOutput					= AVCapturePhotoOutput()
	lazy var captureSession              		= AVCaptureSession()
	lazy var wideAngleCameraDevice          	= AVCaptureDevice(uniqueID: "")
	lazy var wideAngleCameraPreviewLayer 		= AVCaptureVideoPreviewLayer(session: captureSession)
	lazy var ultraWideAngleCameraPreviewLayer 	= AVCaptureVideoPreviewLayer(session: captureSession)
	
	
	//MARK: Vision Properties
	
	var detectedRectangle	: VNRectangleObservation?
	
	//MARK: Class Methods
	
	func configureCaptureSession() {
		
		guard let viewController = viewController else {return}
		
		let availableDevices = AVCaptureDevice.DiscoverySession(
			deviceTypes : [.builtInDualCamera, .builtInWideAngleCamera],
			mediaType   : .video,
			position    : .back
		).devices
		
		guard !availableDevices.isEmpty else {
			DispatchQueue.main.async {
				let okayAlertAction = UIAlertAction(title: "Ok", style: .default)
				let alert = UIAlertController(
					title: "Device Not Supported",
					message: "Please submit a request to julian.martinez.s@outlook.com for added support.",
					preferredStyle: .alert)
				
				alert.addAction(okayAlertAction)
				viewController.present(alert, animated: true)
			}
			return
		}
		
		var availableDevicesRawValues = [String]()
		
		for device in availableDevices {
			availableDevicesRawValues.append(device.deviceType.rawValue)
		}
		
		guard verifyDeviceSupportAndCameraAccess() else {return}
		
		if availableDevicesRawValues.contains("AVCaptureDeviceTypeBuiltInDualCamera") {
			captureSession = AVCaptureMultiCamSession()
			
			configureMulticamWideAngleCameraCapture()
			configureMulticamUltraWideAngleCameraCapture()
			configureUpOutlineLayer()
			configureWideAngleCameraPreviewLayer()
			configureUltraWideAngleCameraPreviewLayer()
		} else if availableDevicesRawValues.contains("AVCaptureDeviceTypeBuiltInWideAngleCamera") {
			captureSession = AVCaptureSession()
			configureWideAngleCameraCapture()
			configureUpOutlineLayer()
			configureWideAngleCameraPreviewLayer()
		}
		
		captureSession.startRunning()
	}

	//MARK: AVFoundation Capture Session Configuration
	
	func verifyDeviceSupportAndCameraAccess() -> Bool {
		
		guard let viewController = viewController else {return false}
		
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
				viewController.present(alert, animated: true)
			}
			return false
		}
		
		// Verify that camera access authorization is provided and start capture session configuration if it is or is not determined yet.
		guard verifyCameraAccessOrNotDetermined() else {return false}
		
		return true
	}
	
	
	func verifyCameraAccessOrNotDetermined() -> Bool {
		
		guard let viewController = viewController else {return false}
		
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
				viewController.present(alert, animated: true)
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
				viewController.present(alert, animated: true)
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
				viewController.present(alert, animated: true)
			}
			return false
		}
	}
	
	
	func configureWideAngleCameraCapture() {
		
		guard let viewController = viewController else {return}
		
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
				viewController.present(alert, animated: true)
			}
			return
		}
		
		self.wideAngleCameraDevice = wideAngleCameraDevice
		
		//Add the wide angle camera input to the capture session.
		var wideAngleDeviceInput: AVCaptureDeviceInput? = nil
		
		do {
			try wideAngleCameraDevice.lockForConfiguration()
			
			captureSession.sessionPreset = .photo
			
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
				viewController.present(alert, animated: true)
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
	
	
	func configureMulticamWideAngleCameraCapture() {
		
		guard let viewController = viewController else {return}
		
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
				viewController.present(alert, animated: true)
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
				viewController.present(alert, animated: true)
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
	
	
	func configureMulticamUltraWideAngleCameraCapture() {
		
		guard let viewController = viewController else {return}
		
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
				viewController.present(alert, animated: true)
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
	
	
	func configureWideAngleCameraPreviewLayer() {
		let previewFrame = wideAnglePreviewView.bounds
		
		wideAngleCameraPreviewLayer.frame          	= previewFrame
		wideAngleCameraPreviewLayer.videoGravity   	= .resizeAspectFill
		
		wideAnglePreviewView.layer.addSublayer(wideAngleCameraPreviewLayer)
	}
	
	
	func configureUltraWideAngleCameraPreviewLayer() {
		let previewFrame = ultraWideAnglePreviewView.bounds
		
		ultraWideAngleCameraPreviewLayer.frame          = previewFrame
		ultraWideAngleCameraPreviewLayer.videoGravity   = .resizeAspectFill
		
		ultraWideAnglePreviewView.layer.addSublayer(ultraWideAngleCameraPreviewLayer)
	}
	
	
	func configureUpOutlineLayer() {
		outlineLayer.frame = wideAngleCameraPreviewLayer.bounds
		wideAngleCameraPreviewLayer.insertSublayer(outlineLayer, at: 1)
	}
	
	
	//MARK: Vision Rectangle Recognition Configuration
	
	func detectPreviewRectangle(in cvBuffer: CVPixelBuffer) {
		
		guard let viewController = viewController else {return}
		
		DispatchQueue.main.async {
			
			//Stop recognition if ScannerVC is not presented.
			guard viewController.presentedViewController == nil else {
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
							viewController.present(alert, animated: true)
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
					viewController.present(alert, animated: true)
				}
			}
		}
	}
	
	
	func detectPhotoCaptureRectangle(in image: CIImage) {
		
		guard let viewController = viewController else {return}
		
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
							viewController.present(alert, animated: true)
						}
						return
					}
					
					guard let rect = results.first else {
						let imageAttachment = NSTextAttachment()
						imageAttachment.image = UIImage(systemName: "questionmark.circle")?.withTintColor(.label)
						
						
						let fullString = NSMutableAttributedString(string: "\nTry moving the device away until all edges of the object are within view and a bounding box is shown. \n\nPress ")
						fullString.append(NSAttributedString(attachment: imageAttachment))
						fullString.append(NSAttributedString(string: " to see more tips for best results."))
						
						let okayAlertAction = UIAlertAction(title: "Ok", style: .default)
						let alert = UIAlertController(
							title: "No Object Detected",
							message: "",
							preferredStyle: .alert)
						alert.setValue(fullString, forKey: "attributedMessage")
						
						alert.addAction(okayAlertAction)
						viewController.present(alert, animated: true)
						return
					}
					
					self.detectedRectangle = rect
					
//					viewController.presentCaptureDetailVC(with: self.ciImage)
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
					viewController.present(alert, animated: true)
				}
			}
		}
	}
	
	
	func drawBoundingBox(rect: VNRectangleObservation) {
		
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
	
	
	func resetRecognition() {
		self.detectedRectangle = nil
		self.drawBoundingBox(rect: VNRectangleObservation())
		self.ciImage = nil
		self.uiImage = UIImage()
	}
	
	
	//MARK: Photo Capture Processing Configuration
	
	func processPhotoCapture(_ observation: VNRectangleObservation?, from ciImage: CIImage?) {
		
		guard let viewController = viewController else {return}
		
		guard let ciImage = ciImage, let unwrappedObservation = observation else {
			let imageAttachment = NSTextAttachment()
			imageAttachment.image = UIImage(systemName: "questionmark.circle")
			
			
			let fullString = NSMutableAttributedString(string: "\nTry moving the device away until all edges of the object are within view and a bounding box is shown. \n\nPress ")
			fullString.append(NSAttributedString(attachment: imageAttachment))
			fullString.append(NSAttributedString(string: " to see more tips for best results."))
			
			let okayAlertAction = UIAlertAction(title: "Ok", style: .default)
			let alert = UIAlertController(
				title: "No Object Detected",
				message: "",
				preferredStyle: .alert)
			alert.setValue(fullString, forKey: "attributedMessage")
			
			alert.addAction(okayAlertAction)
			viewController.present(alert, animated: true)
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
	
	
	
	func toggleFlash() {
		
		guard let viewController = viewController else {return}
		
		guard let device = wideAngleCameraDevice else {return}
		
		guard device.hasTorch else { return }
		
		do {
			try device.lockForConfiguration()
			
			if (device.torchMode == AVCaptureDevice.TorchMode.on) || (viewController.presentedViewController != nil) {
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
					viewController.present(alert, animated: true)
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
				viewController.present(alert, animated: true)
			}
		}
	}
	
}

//MARK: AVFoundation Delegate Extensions

extension CaptureSessionManager: AVCaptureVideoDataOutputSampleBufferDelegate {
	func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
		guard let frame = CMSampleBufferGetImageBuffer(sampleBuffer) else {return}
		detectPreviewRectangle(in: frame)
	}
}

extension CaptureSessionManager: AVCapturePhotoCaptureDelegate {
	func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
		
		guard let viewController = viewController else {return}
		
		guard let cgImage = photo.cgImageRepresentation() else {
			let imageAttachment = NSTextAttachment()
			imageAttachment.image = UIImage(systemName: "questionmark.circle")
			
			
			let fullString = NSMutableAttributedString(string: "\nTry moving the device away until all edges of the object are within view and a bounding box is shown. \n\nPress ")
			fullString.append(NSAttributedString(attachment: imageAttachment))
			fullString.append(NSAttributedString(string: " to see more tips for best results."))
			
			let okayAlertAction = UIAlertAction(title: "Ok", style: .default)
			let alert = UIAlertController(
				title: "No Object Detected",
				message: "",
				preferredStyle: .alert)
			alert.setValue(fullString, forKey: "attributedMessage")
			
			alert.addAction(okayAlertAction)
			viewController.present(alert, animated: true)
			return
		}
		
		ciImage = CIImage(cgImage: cgImage)
		
		guard let ciImage = ciImage else {
			let imageAttachment = NSTextAttachment()
			imageAttachment.image = UIImage(systemName: "questionmark.circle")
			
			
			let fullString = NSMutableAttributedString(string: "\nTry moving the device away until all edges of the object are within view and a bounding box is shown. \n\nPress ")
			fullString.append(NSAttributedString(attachment: imageAttachment))
			fullString.append(NSAttributedString(string: " to see more tips for best results."))
			
			let okayAlertAction = UIAlertAction(title: "Ok", style: .default)
			let alert = UIAlertController(
				title: "No Object Detected",
				message: "",
				preferredStyle: .alert)
			alert.setValue(fullString, forKey: "attributedMessage")
			
			alert.addAction(okayAlertAction)
			viewController.present(alert, animated: true)
			return
		}
		
		self.ciImage = ciImage.oriented(.right)
		
	}
	
	
	func photoOutput(_ output: AVCapturePhotoOutput, didFinishCaptureFor resolvedSettings: AVCaptureResolvedPhotoSettings, error: Error?) {
		
		guard let viewController = viewController else {return}
		
		guard let ciImage = ciImage else {
			let imageAttachment = NSTextAttachment()
			imageAttachment.image = UIImage(systemName: "questionmark.circle")
			
			
			let fullString = NSMutableAttributedString(string: "\nTry moving the device away until all edges of the object are within view and a bounding box is shown. \n\nPress ")
			fullString.append(NSAttributedString(attachment: imageAttachment))
			fullString.append(NSAttributedString(string: " to see more tips for best results."))
			
			let okayAlertAction = UIAlertAction(title: "Ok", style: .default)
			let alert = UIAlertController(
				title: "No Object Detected",
				message: "",
				preferredStyle: .alert)
			alert.setValue(fullString, forKey: "attributedMessage")
			
			alert.addAction(okayAlertAction)
			viewController.present(alert, animated: true)
			return
		}
		
		detectPhotoCaptureRectangle(in: ciImage)
	}
}

