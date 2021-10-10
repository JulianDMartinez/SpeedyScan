//
//  VisionViewController.swift
//  SpeedyScan
//
//  Created by Julian Martinez on 5/23/21.
//

import UIKit

class ScannerVC: UIViewController {
	
	//MARK: Properties
	
	private let wideAnglePreviewView					= SSPreviewView()
	private let ultraWideAnglePreviewView				= SSPreviewView()
	
	private let captureButton   						= SSCircularButton(
		buttonHeight: 70,
		symbolConfiguration:  UIImage.SymbolConfiguration(pointSize: 65, weight: .ultraLight),
		symbolName: "camera.circle"
	)
	
	private let flashButton   = SSCircularButton(
		buttonHeight: 50,
		symbolConfiguration: UIImage.SymbolConfiguration(pointSize: 35, weight: .ultraLight),
		symbolName: "flashlight.off.fill"
	)
	
	private let tipsButton   			= SSCircularButton(
		buttonHeight: 30,
		symbolConfiguration: UIImage.SymbolConfiguration(pointSize: 20, weight: .bold),
		symbolName: "questionmark"
	)
	
	private let captureSessionManager 					= DocumentScanningManager()

	//MARK: ScannerVC Life Cycle Methods
	
	//Subviews are configured in viewWillAppear
	override func viewWillAppear(_ animated: Bool) {
		configureUltraWideAnglePreviewView()
		configureWideAnglePreviewView()
		configureVisualEffectView()
		configureCaptureButton()
		configureFlashButton()
		configureTipsButton()
	}
	
	//The capture session is configured in viewDidAppear in order to show the subviews while the capture session is being configured.
	override func viewDidAppear(_ animated: Bool) {
		captureSessionManager.viewController = self
		captureSessionManager.configureCaptureSession()
		configureUltraWideAngleCameraPreviewLayer()
		configureWideAngleCameraPreviewLayer()
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
	
	
	private func configureCaptureButton() {
		view.addSubview(captureButton)
		
		captureButton.addTarget(captureSessionManager, action: #selector(captureSessionManager.scanAction), for: .touchUpInside)
		
		NSLayoutConstraint.activate([
			captureButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
			captureButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -30),
			captureButton.heightAnchor.constraint(equalToConstant: captureButton.buttonHeight),
			captureButton.widthAnchor.constraint(equalToConstant: captureButton.buttonHeight)
		])
	}
	
	
	private func configureFlashButton() {
		view.addSubview(flashButton)
		
		flashButton.addTarget(captureSessionManager, action: #selector(DocumentScanningManager.toggleFlashAction), for: .touchUpInside)
		
		NSLayoutConstraint.activate([
			flashButton.leadingAnchor.constraint(equalTo: captureButton.trailingAnchor, constant: 20),
			flashButton.centerYAnchor.constraint(equalTo: captureButton.centerYAnchor),
			flashButton.heightAnchor.constraint(equalToConstant: flashButton.buttonHeight),
			flashButton.widthAnchor.constraint(equalToConstant: flashButton.buttonHeight)
		])
	}
	
	
	private func configureTipsButton() {
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
	
	//MARK: Preview View Layers Configuration
	
	private func configureWideAngleCameraPreviewLayer() {
		let previewFrame = wideAnglePreviewView.bounds
		
		captureSessionManager.wideAngleCameraPreviewLayer.frame          	= previewFrame
		captureSessionManager.wideAngleCameraPreviewLayer.videoGravity   	= .resizeAspectFill
		
		wideAnglePreviewView.layer.addSublayer(captureSessionManager.wideAngleCameraPreviewLayer)
	}
	
	
	private func configureUltraWideAngleCameraPreviewLayer() {
		let previewFrame = ultraWideAnglePreviewView.bounds

		captureSessionManager.ultraWideAngleCameraPreviewLayer.frame          = previewFrame
		captureSessionManager.ultraWideAngleCameraPreviewLayer.videoGravity   = .resizeAspectFill

		ultraWideAnglePreviewView.layer.addSublayer(captureSessionManager.ultraWideAngleCameraPreviewLayer)
	}
	
	//MARK: Button Action Configuration
	
	@objc private func tipsButtonTapped() {
		let tipsVC = TipsVC()
		
		tipsVC.modalPresentationStyle = .overCurrentContext
		
		present(tipsVC, animated: true)
	}
}
