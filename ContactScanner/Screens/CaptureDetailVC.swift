//
//  CaptureDetailVC.swift
//  ContactScanner
//
//  Created by Julian Martinez on 7/5/21.
//

import UIKit

class CaptureDetailVC: UIViewController {
    
    let image: UIImage
    
    private let imageView           = UIImageView()
    private let visualEffectView    = UIVisualEffectView(effect: UIBlurEffect(style: .systemThinMaterial))
    private let cancelButton        = CancelButton()
    private let saveButton          = SaveButton()
    
    init(image: UIImage) {
        self.image = image
        print(image)
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
        configureVisualEffectView()
        configureCancelButton()
        configureSaveButton()
        configureImageView()

    }
    
    
    private func configureSelf() {
        view.isOpaque = false
        view.backgroundColor = UIColor.clear
    }
    
    
    private func configureVisualEffectView() {
        view.addSubview(visualEffectView)
        
        visualEffectView.layer.cornerRadius = 20
        visualEffectView.clipsToBounds = true
        
        visualEffectView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            visualEffectView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 5),
            visualEffectView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            visualEffectView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            visualEffectView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 10)
        ])
    }
    
    
    private func configureCancelButton() {

            view.addSubview(cancelButton)
            
            cancelButton.addTarget(self, action: #selector(cancelButtonTapped), for: .touchUpInside)
            
            NSLayoutConstraint.activate([
                cancelButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -30),
                cancelButton.centerXAnchor.constraint(equalTo: visualEffectView.centerXAnchor, constant: cancelButton.intrinsicContentSize.width/2 + 10),
                cancelButton.heightAnchor.constraint(equalToConstant: cancelButton.buttonHeight)
            ])
    
    }
    
    @objc private func cancelButtonTapped() {
        dismiss(animated: true, completion: nil)
    }
    
    private func configureSaveButton() {

            view.addSubview(saveButton)

            saveButton.addTarget(self, action: #selector(saveButtonTapped), for: .touchUpInside)

            NSLayoutConstraint.activate([
                saveButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -30),
                saveButton.centerXAnchor.constraint(equalTo: visualEffectView.centerXAnchor, constant: -(saveButton.intrinsicContentSize.width/2 + 10)),
                saveButton.heightAnchor.constraint(equalToConstant: saveButton.buttonHeight)
            ])

    }

    @objc private func saveButtonTapped() {
        dismiss(animated: true, completion: nil)
    }
    
    
    private func configureImageView() {
        view.addSubview(imageView)
        imageView.image = image
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        imageView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: visualEffectView.topAnchor, constant: 25),
            imageView.leadingAnchor.constraint(equalTo: visualEffectView.leadingAnchor, constant: 15),
            imageView.trailingAnchor.constraint(equalTo: visualEffectView.trailingAnchor, constant: -15),
            imageView.heightAnchor.constraint(lessThanOrEqualTo: visualEffectView.heightAnchor, multiplier: 0.80),
            imageView.heightAnchor.constraint(greaterThanOrEqualTo: visualEffectView.heightAnchor, multiplier: 0.1)
        ])
    }

}

extension CaptureDetailVC: UIViewControllerTransitioningDelegate {
    
}
