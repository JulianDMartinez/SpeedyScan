//
//  CaptureDetailVC.swift
//  ContactScanner
//
//  Created by Julian Martinez on 7/5/21.
//

import UIKit
import PDFKit

class CaptureDetailVC: UIViewController {
    
    var image: UIImage
    
    private let imageView               = UIImageView()
    private let imageViewContainerView  = UIView()
    private let visualEffectView        = UIVisualEffectView(effect: UIBlurEffect(style: .systemThinMaterial))
    private let cancelButton            = SelectionButton()
    private let selectionButton         = SelectionButton()
    private let buttonsStackView        = UIStackView()
    private let verticalStackView       = UIStackView()
    
    init(image: UIImage) {
        self.image = image
        super.init(nibName: nil, bundle: nil)
    }
    
    
    required init?(coder: NSCoder) {
        //Non-utilized required initializer
        image = UIImage()
        super.init(coder: coder)
    }
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureSelf()
        configureCancelButton()
        configureSelectButton()
        configureImageView()
        configureButtonsStackView()
        configureVerticalStackView()
        configureVisualEffectView()
        
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
        
        let shareImage                          = UIImage(systemName: "square.and.arrow.up")
//        let saveImage                           = UIImage(systemName: "folder")
        
        let shareAsPDFAction                    = configureSharePDFAction()
        let shareAsImageAction                  = configureShareImageAction()
        let saveToCameraRollAction              = configureSaveToCameraRollAction()
        let savePDFToFilesAction                = configureSavePDFToFilesAction()
        
        //MARK: By-type folder storage implementation in progress inside configureSelectButton
//        let savePDFToReceiptsFolderAction       = configureSavePDFToReceiptsFolderAction()
//        let savePDFToContactCardsFolderAction   = configureSavePDFToContactCardsFolderAction()
//        let savePDFToOtherDocumentsFolderAction = configureSavePDFToOtherDocumentsFolderAction()
//        let savePDFToFolderSubmenu        = UIMenu(title: "Save PDF to Folder", image: saveImage, children: [savePDFToReceiptsFolderAction, savePDFToContactCardsFolderAction, savePDFToOtherDocumentsFolderAction])
        
        let imageMenu               = UIMenu(title: "Image", image: shareImage, options: .displayInline, children: [shareAsImageAction, saveToCameraRollAction])
        let pdfMenu                 = UIMenu(title: "PDF", image: shareImage, options: .displayInline, children: [shareAsPDFAction, savePDFToFilesAction])
        
        selectionButton.setTitle("Select", for: .normal)
        
        selectionButton.showsMenuAsPrimaryAction    = true
        selectionButton.menu                        = UIMenu(children: [imageMenu, pdfMenu])
            
    }
    
    private func configureSharePDFAction() -> UIAction {
        
        let shareImage          = UIImage(systemName: "square.and.arrow.up")
        
        return UIAction(title: "Share PDF", image: shareImage) { _ in
            self.shareAsPDF()
        }
        
    }
    


    //TODO: Implement individual folder storage.
    //TODO: Implement iCloud storage.
    private func configureSavePDFToReceiptsFolderAction() -> UIAction {
        return UIAction(title: "Receipts") { _ in
            
            let fileManager = FileManager.default
            
            print(fileManager.urls(for: .documentDirectory, in: .allDomainsMask).first?.absoluteString)
            
            let documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: [.folder])
            documentPicker.delegate = self
            self.present(documentPicker, animated: true)
        }
    }

    private func configureSavePDFToContactCardsFolderAction() -> UIAction {

        return UIAction(title: "Contact Cards") { _ in
            #warning("Implement save to cloud folder.")
        }
    }

    private func configureSavePDFToOtherDocumentsFolderAction() -> UIAction {

        return UIAction(title: "Other Documents") { _ in
            #warning("Implement save to cloud folder.")
        }
    }

    
    private func configureShareImageAction() -> UIAction {
        
        let shareImage          = UIImage(systemName: "square.and.arrow.up")
        
        return UIAction(title: "Share Image", image: shareImage) { _ in
            self.shareAsImage()
        }
        
    }
    
    private func configureSaveToCameraRollAction() -> UIAction {
        
        //TODO: Check for camera roll authorization. Handle no authorization provided.
        
        let saveImage       = UIImage(systemName: "photo.on.rectangle.angled")
        
        return UIAction(title: "Save to Camera Roll", image: saveImage) { _ in
            //TODO: Handle error on saving to user camera roll.
            UIImageWriteToSavedPhotosAlbum(self.image, nil, nil, nil)
        }
        
    }

    private func savePDFToFiles() {
        
        
        
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
        
        let jpgImage = image.jpegData(compressionQuality: 1.0)
        
        let activitySheet = UIActivityViewController(activityItems: [jpgImage as Any], applicationActivities: nil)

        activitySheet.completionWithItemsHandler = { activity, success, items, error in
            self.dismiss(animated: true, completion: nil)
        }

        present(activitySheet, animated: true, completion: nil)
        
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

extension CaptureDetailVC: UIDocumentPickerDelegate {
    
    private func configureSavePDFToFilesAction() -> UIAction {
        
        return UIAction(title: "Save PDF to Files") { _ in
            
            let fileManager = FileManager.default
            
            let documentDirectoryURL        = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let testFolderURL = documentDirectoryURL.appendingPathComponent("Test Folder")
            
            do {

                try fileManager.createDirectory(at: testFolderURL, withIntermediateDirectories: false, attributes: nil)

                
            } catch {
                #warning("Handle error on creating test folder.")
            }
            
            let pdfDocument = PDFDocument()
            let pdfPage     = PDFPage(image: self.image)

            pdfDocument.insert(pdfPage!, at: 0)
            
            pdfDocument.write(to: testFolderURL.appendingPathComponent("document.pdf"))
            
//            let pdfDocument = PDFDocument()
//            let pdfPage     = PDFPage(image: self.image)
//
//            pdfDocument.insert(pdfPage!, at: 0)
//
//            pdfDocument.write(to: documentDirectoryPath.appendingPathComponent("Test Folder"))
//
//            print(fileManager.urls(for: .documentDirectory, in: .userDomainMask))
            
//            let documentPicker      = UIDocumentPickerViewController(forOpeningContentTypes: [.pdf])
//
//            documentPicker.delegate = self
//
//            self.present(documentPicker, animated: true)
            
        }
    }
    
}
