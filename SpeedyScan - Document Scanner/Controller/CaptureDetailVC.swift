//
//  CaptureDetailVC.swift
//  SpeedyScan
//
//  Created by Julian Martinez on 7/5/21.
//

import UIKit
import PDFKit
import Photos

class CaptureDetailVC: UIViewController {
	
	//MARK: Class Properties
	var image: UIImage
	
	private let imageView                       = UIImageView()
	private let imageViewContainerView          = UIView()
	private let visualEffectView                = UIVisualEffectView(effect: UIBlurEffect(style: .systemThinMaterial))
	private let cancelButton                    = SelectionButton()
	private let selectionButton                 = SelectionButton()
	private let buttonsStackView                = UIStackView()
	private let verticalStackView               = UIStackView()

		
	private var cloudMetadataManager 			=  CloudMetadataManager(containerIdentifier: "iCloud.SpeedyScan")
	
	//MARK: Initializers
	init(image: UIImage) {
		self.image = image
		super.init(nibName: nil, bundle: nil)
	}
	
	
	required init?(coder: NSCoder) {
		image = UIImage()
		super.init(coder: coder)
	}
	
	
	//MARK: Methods
	override func viewDidLoad() {
		super.viewDidLoad()
		configureSelf()
		configureCancelButton()
		configureSelectButton()
		configureImageView()
		configureButtonsStackView()
		configureVerticalStackView()
		configureVisualEffectView()
//		image = compressImage(image: image)
	}
	
	
	private func configureSelf() {
		view.isOpaque = false
		view.backgroundColor = UIColor.clear
	}
	
	
	private func configureCancelButton() {
		cancelButton.setTitle("Cancel", for: .normal)
		cancelButton.setTitleColor(.systemRed, for: .normal)
		cancelButton.addTarget(self, action: #selector(cancelButtonTapped), for: .touchUpInside)
	}
	
	
	@objc private func cancelButtonTapped() {
		dismiss(animated: true, completion: nil)
	}
	
	
	private func configureSelectButton() {
		
		let shareImage                          		= UIImage(systemName: "square.and.arrow.up")
		let localSaveImage                           	= UIImage(systemName: "folder")
		let cloudSaveImage								= UIImage(systemName: "icloud.and.arrow.up")
		
		let shareAsPDFAction                    		= configureSharePDFAction()
		let shareAsImageAction                  		= configureShareImageAction()
		let saveToCameraRollAction              		= configureSaveToCameraRollAction()
		
		let savePDFToReceiptsCloudFolderAction       	= configureSavePDFToReceiptsCloudFolderAction()
		let savePDFToContactCardsCloudFolderAction   	= configureSavePDFToContactCardsCloudFolderAction()
		let savePDFToOtherDocumentsCloudFolderAction 	= configureSavePDFToOtherDocumentsCloudFolderAction()
		
		let savePDFToReceiptsLocalFolderAction       	= configureSavePDFToReceiptsLocalFolderAction()
		let savePDFToContactCardsLocalFolderAction   	= configureSavePDFToContactCardsLocalFolderAction()
		let savePDFToOtherDocumentsLocalFolderAction 	= configureSavePDFToOtherDocumentsLocalFolderAction()
		
		let savePDFToCloudFolderSubmenu              = UIMenu(
			title: "Save PDF to iCloud Folder",
			image: cloudSaveImage,
			children: [
				savePDFToOtherDocumentsCloudFolderAction,
				savePDFToContactCardsCloudFolderAction,
				savePDFToReceiptsCloudFolderAction
			])
		
		let savePDFToDeviceSubmenu              = UIMenu(
			title: "Save PDF to Local Folder",
			image: localSaveImage,
			children: [
				savePDFToOtherDocumentsLocalFolderAction,
				savePDFToContactCardsLocalFolderAction,
				savePDFToReceiptsLocalFolderAction
			])
		
		let imageMenu                           = UIMenu(
			title: "Image", image: shareImage,
			options: .displayInline,
			children: [
				shareAsImageAction,
				saveToCameraRollAction
			])
		
		let pdfMenu                             = UIMenu(
			title: "PDF",
			image: shareImage,
			options: .displayInline,
			children: [
				shareAsPDFAction,
				savePDFToDeviceSubmenu,
				savePDFToCloudFolderSubmenu
			])
		
		selectionButton.setTitle("Select", for: .normal)
		
		selectionButton.showsMenuAsPrimaryAction    = true
		selectionButton.menu                        = UIMenu(
			children: [
				imageMenu,
				pdfMenu
			])
	}
	
	
	private func configureSharePDFAction() -> UIAction {
		let shareImage          = UIImage(systemName: "square.and.arrow.up")
		
		return UIAction(title: "Share PDF", image: shareImage) { _ in
			self.shareAsPDF()
		}
	}
	
	private func configureSavePDFToReceiptsCloudFolderAction() -> UIAction {
		return UIAction(title: "Receipts") { action in
			self.showCloudSaveTextEntryAlert(forDocumentType: action.title)
		}
	}
	
	
	private func configureSavePDFToContactCardsCloudFolderAction() -> UIAction {
		return UIAction(title: "Contact Cards") { action in
			self.showCloudSaveTextEntryAlert(forDocumentType: action.title)
		}
	}
	
	
	private func configureSavePDFToOtherDocumentsCloudFolderAction() -> UIAction {
		return UIAction(title: "Other Documents") { action in
			self.showCloudSaveTextEntryAlert(forDocumentType: action.title)
		}
	}
	
	private func configureSavePDFToReceiptsLocalFolderAction() -> UIAction {
		return UIAction(title: "Receipts") { action in
			self.showLocalSaveTextEntryAlert(forDocumentType: action.title)
		}
	}
	
	
	private func configureSavePDFToContactCardsLocalFolderAction() -> UIAction {
		return UIAction(title: "Contact Cards") { action in
			self.showLocalSaveTextEntryAlert(forDocumentType: action.title)
		}
	}
	
	
	private func configureSavePDFToOtherDocumentsLocalFolderAction() -> UIAction {
		return UIAction(title: "Other Documents") { action in
			self.showLocalSaveTextEntryAlert(forDocumentType: action.title)
		}
	}
	
	func showCloudSaveTextEntryAlert(forDocumentType documentType: String) {
		let title               	= "File Name"
		let message             	= ""
		let alertController     	= UIAlertController(title: title, message: message, preferredStyle: .alert)
		let cancelButtonTitle   	= "Cancel"
		let cancelAction        	= UIAlertAction(title: cancelButtonTitle, style: .cancel) { _ in }
		let rightButtonTitle    	= "Ok"
		let dateFormatter 			= DateFormatter()
		
		dateFormatter.dateFormat = "YYYY-MM-dd hhmmss a"
		
		let defaultFileNameTime		= dateFormatter.string(from: Date())
		
		alertController.addTextField { textField in
			textField.text				= "\(defaultFileNameTime)"
			textField.clearButtonMode 	= .always
		}
		
		let rightButtonAction = UIAlertAction(title: rightButtonTitle, style: .default) { _ in
			var fileName                = ""
			
			guard let textFields = alertController.textFields else {
				debugPrint("An error was encountered while trying to access the text fields array.")
				return
			}
			
			guard let textFieldValue = textFields[0].text else {
				debugPrint("An error was encountered while trying to access the text field value.")
				return
			}
			
			fileName = textFieldValue
			
			guard let cloudRootURL 			= self.cloudMetadataManager?.containerRootURL else {
				print("An error was encountered while accessing the iCloud root URL")
				return
			}
			
			let fileManager         		= FileManager.default
			let cloudDocumentsDirectoryURL 	= cloudRootURL.appendingPathComponent("Documents")
			let documentTypeFolderURL 		= cloudDocumentsDirectoryURL.appendingPathComponent(documentType)
			
			if !fileManager.fileExists(atPath: cloudDocumentsDirectoryURL.path) {
				do {
					try fileManager.createDirectory(at: cloudDocumentsDirectoryURL, withIntermediateDirectories: false, attributes: nil)
				} catch {
					print(error.localizedDescription)
				}
			}
			
			if !fileManager.fileExists(atPath: documentTypeFolderURL.path) {
				do {
					try fileManager.createDirectory(at: documentTypeFolderURL, withIntermediateDirectories: false, attributes: nil)
				} catch {
					print(error.localizedDescription)
				}
			}
			
			let fileURL 	= documentTypeFolderURL.appendingPathComponent(fileName).appendingPathExtension("pdf")
			let pdfDocument = PDFDocument()
			let pdfPage     = PDFPage(image: self.image)
			
			pdfDocument.insert(pdfPage!, at: 0)
			pdfDocument.write(to: fileURL)
			
			self.dismiss(animated: true)
		}
		
		alertController.addAction(cancelAction)
		alertController.addAction(rightButtonAction)
		present(alertController, animated: true, completion: nil)
	}
	
	
	func showLocalSaveTextEntryAlert(forDocumentType documentType: String) {
		let title               	= "File Name"
		let message             	= ""
		let alertController     	= UIAlertController(title: title, message: message, preferredStyle: .alert)
		let cancelButtonTitle   	= "Cancel"
		let cancelAction        	= UIAlertAction(title: cancelButtonTitle, style: .cancel) { _ in }
		let rightButtonTitle    	= "Ok"
		let dateFormatter 			= DateFormatter()
		
		dateFormatter.dateFormat = "YYYY-MM-dd hhmmss a"
		
		let defaultFileNameTime		= dateFormatter.string(from: Date())
		
		alertController.addTextField { textField in
			textField.text				= "\(defaultFileNameTime)"
			textField.clearButtonMode	= .always
		}
		
		let rightButtonAction = UIAlertAction(title: rightButtonTitle, style: .default) { _ in
			var fileName                = ""
			
			guard let textFields = alertController.textFields else {
				debugPrint("An error was encountered while trying to access the text fields array.")
				return
			}
			
			guard let textFieldValue = textFields[0].text else {
				debugPrint("An error was encountered while trying to access the text field value.")
				return
			}
			
			fileName = textFieldValue
			
			let fileManager             = FileManager.default
			let documentDirectoryURL    = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
			let documentTypeFolderURL   = documentDirectoryURL.appendingPathComponent(documentType)
			
			if !fileManager.fileExists(atPath: documentTypeFolderURL.path) {
				do {
					try fileManager.createDirectory(at: documentTypeFolderURL, withIntermediateDirectories: false, attributes: nil)
				} catch {
					print(error.localizedDescription)
				}
			}
			
			let pdfDocument = PDFDocument()
			let pdfPage     = PDFPage(image: self.image)
			let fileURL		= documentTypeFolderURL.appendingPathComponent("\(fileName).pdf")
			
			pdfDocument.insert(pdfPage!, at: 0)
			pdfDocument.write(to: fileURL)
			
			self.dismiss(animated: true)
		}
		
		alertController.addAction(cancelAction)
		alertController.addAction(rightButtonAction)
		present(alertController, animated: true, completion: nil)
	}
	
	
	private func configureShareImageAction() -> UIAction {
		
		let shareImage          = UIImage(systemName: "square.and.arrow.up")
		
		return UIAction(title: "Share Image", image: shareImage) { _ in
			self.shareAsImage()
		}
		
	}
	
	private func configureSaveToCameraRollAction() -> UIAction {
		
		let saveImage       = UIImage(systemName: "photo.on.rectangle.angled")
		
		return UIAction(title: "Save to Camera Roll", image: saveImage) { _ in
			PHPhotoLibrary.requestAuthorization { status in
				guard status == .authorized else {
					let okayAlertAction = UIAlertAction(title: "Ok", style: .default)
					let alert = UIAlertController(
						title: "Enable Photo Library Access",
						message: "Enable Photo Library Access to save to Camera Roll.",
						preferredStyle: .alert)
					
					alert.addAction(okayAlertAction)
					self.present(alert, animated: true)
					return
				}
				UIImageWriteToSavedPhotosAlbum(self.image, nil, nil, nil)
				
				DispatchQueue.main.async {
					self.dismiss(animated: true)
				}
			}
		}
	}
	
	
	private func shareAsPDF() {
		let pdfDocument = PDFDocument()
		let pdfPage     = PDFPage(image: image)
		
		pdfDocument.insert(pdfPage!, at: 0)
		
		let data = pdfDocument.dataRepresentation()
		
		let activitySheet = UIActivityViewController(activityItems: [data as Any], applicationActivities: nil)
		
		activitySheet.completionWithItemsHandler = { activity, success, items, error in
			self.dismiss(animated: true, completion: nil)
		}
		
		present(activitySheet, animated: true, completion: nil)
	}
	
	
	private func shareAsImage() {
		let jpgImage        = image.jpegData(compressionQuality: 1.0)
		let activitySheet   = UIActivityViewController(activityItems: [jpgImage as Any], applicationActivities: nil)
		
		activitySheet.completionWithItemsHandler = { activity, success, items, error in
			self.dismiss(animated: true, completion: nil)
		}
		
		present(activitySheet, animated: true, completion: nil)
	}
	
	private func compressImage(image: UIImage) -> UIImage {
		//Downsampling of image.
		
		let imageReductionFactor = 1.0
		
		let reducedImageSize = CGSize(width: image.size.width * imageReductionFactor, height: image.size.height * imageReductionFactor)
		
		let renderer = UIGraphicsImageRenderer(size: reducedImageSize)
		
		let compressedImage = renderer.image(actions: { context in
			image.draw(in: CGRect(origin: .zero, size: reducedImageSize))
		})
		
		return compressedImage
	}
	
	
	private func configureImageView() {
		imageViewContainerView.addSubview(imageView)
		imageViewContainerView.layer.shadowOpacity = 0
		imageViewContainerView.layer.shadowRadius   = 3
		imageViewContainerView.layer.shadowOffset   = CGSize(width: 1, height: 1)
		
		imageView.image = image
		imageView.contentMode = .scaleAspectFit
		imageView.layer.cornerRadius = 5
		imageView.clipsToBounds = true
		imageView.translatesAutoresizingMaskIntoConstraints = false
		
		NSLayoutConstraint.activate([
			imageView.heightAnchor.constraint(equalTo: imageView.widthAnchor, multiplier: imageView.image!.size.height / imageView.image!.size.width),
			imageView.topAnchor.constraint(equalTo: imageViewContainerView.topAnchor, constant: 3),
			imageView.bottomAnchor.constraint(equalTo: imageViewContainerView.bottomAnchor),
			imageView.centerXAnchor.constraint(equalTo: imageViewContainerView.centerXAnchor),
			imageView.widthAnchor.constraint(lessThanOrEqualTo: imageViewContainerView.widthAnchor)
		])
	}
	
	
	private func configureButtonsStackView() {
		buttonsStackView.addArrangedSubview(selectionButton)
		buttonsStackView.addArrangedSubview(cancelButton)
		buttonsStackView.axis       = .horizontal
		buttonsStackView.spacing    = 10
		buttonsStackView.distribution = .fillEqually
		buttonsStackView.layoutMargins = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
		buttonsStackView.isLayoutMarginsRelativeArrangement = true
		
		buttonsStackView.layer.shadowOpacity = 0.3
		buttonsStackView.layer.shadowRadius   = 2
		buttonsStackView.layer.shadowOffset   = CGSize(width: 1, height: 1)
		
		buttonsStackView.heightAnchor.constraint(equalToConstant: 75).isActive = true
	}
	
	
	private func configureVerticalStackView() {
		view.addSubview(verticalStackView)
		verticalStackView.addArrangedSubview(imageViewContainerView)
		verticalStackView.addArrangedSubview(buttonsStackView)
		
		verticalStackView.spacing = 10
		verticalStackView.distribution = .fill
		verticalStackView.axis = .vertical
		verticalStackView.clipsToBounds = true
		verticalStackView.translatesAutoresizingMaskIntoConstraints = false
		
		NSLayoutConstraint.activate([
			verticalStackView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -27),
			verticalStackView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
			verticalStackView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
			verticalStackView.heightAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.heightAnchor, multiplier: 0.92)
		])
	}
	
	
	private func configureVisualEffectView() {
		view.insertSubview(visualEffectView, belowSubview: verticalStackView)
		visualEffectView.layer.cornerRadius = 20
		visualEffectView.clipsToBounds = true
		visualEffectView.translatesAutoresizingMaskIntoConstraints = false
		
		NSLayoutConstraint.activate([
			visualEffectView.topAnchor.constraint(equalTo: verticalStackView.topAnchor, constant: -30),
			visualEffectView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
			visualEffectView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
			visualEffectView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
		])
	}
}

