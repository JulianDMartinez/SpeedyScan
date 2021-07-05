//
//  CaptureButton.swift
//  ContactScanner
//
//  Created by Julian Martinez on 7/3/21.
//

import UIKit

class CaptureButton: UIButton {


    let buttonHeight: CGFloat
    private let symbolConfiguration: UIImage.SymbolConfiguration
    private let visualEffectView = UIVisualEffectView(effect: UIBlurEffect(style: .systemMaterial))
    
    override init(frame: CGRect) {
        
        buttonHeight = 70
        symbolConfiguration = UIImage.SymbolConfiguration(pointSize: buttonHeight - 5, weight: .ultraLight)
        super.init(frame: frame)
        
        configureSelf()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func configureSelf() {
        setImage(UIImage(systemName: "camera.circle")?.applyingSymbolConfiguration(symbolConfiguration), for: .normal)
        imageView?.tintColor    = .label.withAlphaComponent(0.8)
        backgroundColor         = .systemGray3.withAlphaComponent(0.9)
        layer.cornerRadius      = buttonHeight / 2
        clipsToBounds           = true
        
        translatesAutoresizingMaskIntoConstraints = false
    }
}
