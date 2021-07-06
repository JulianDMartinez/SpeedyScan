//
//  CaptureDetailVC.swift
//  ContactScanner
//
//  Created by Julian Martinez on 7/5/21.
//

import UIKit

class CaptureDetailVC: UIViewController {
    
    var image: UIImage
    
    private let imageView               = UIImageView()
    private let imageViewContainerView  = UIView()
    private let visualEffectView        = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterial))
    private let cancelButton            = CancelButton()
    private let saveButton              = SaveButton()
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
        configureSaveButton()
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
            cancelButton.addTarget(self, action: #selector(cancelButtonTapped), for: .touchUpInside)
    }
    
    @objc private func cancelButtonTapped() {
        dismiss(animated: true, completion: nil)
    }
    
    private func configureSaveButton() {
            saveButton.addTarget(self, action: #selector(saveButtonTapped), for: .touchUpInside)
    }

    @objc private func saveButtonTapped() {

        let activitySheet = UIActivityViewController(activityItems: [image], applicationActivities: nil)
        
        activitySheet.completionWithItemsHandler = { activity, success, items, error in
            self.dismiss(animated: true, completion: nil)
        }
        
        present(activitySheet, animated: true, completion: nil)
    }
    
    
    private func configureImageView() {
        
        imageViewContainerView.addSubview(imageView)
        imageViewContainerView.layer.shadowOpacity = 0.2
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

        buttonsStackView.addArrangedSubview(saveButton)
        buttonsStackView.addArrangedSubview(cancelButton)
        buttonsStackView.axis       = .horizontal
        buttonsStackView.spacing    = 10
        buttonsStackView.distribution = .fillEqually
        
        buttonsStackView.layer.shadowOpacity = 0.2
        buttonsStackView.layer.shadowRadius   = 3
        buttonsStackView.layer.shadowOffset   = CGSize(width: 1, height: 1)
        
        buttonsStackView.heightAnchor.constraint(equalToConstant: 55).isActive = true

    }
    
    private func configureVerticalStackView() {
        view.addSubview(verticalStackView)
        
        verticalStackView.addArrangedSubview(imageViewContainerView)
        verticalStackView.addArrangedSubview(buttonsStackView)
        
        verticalStackView.spacing = 30
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

extension CaptureDetailVC: UIViewControllerTransitioningDelegate {
    
}
