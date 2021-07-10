//
//  TorchButton.swift
//  ContactScanner
//
//  Created by Julian Martinez on 7/5/21.
//

import UIKit

class TorchButton: UIButton {

    
    let buttonHeight: CGFloat
    private let symbolConfiguration: UIImage.SymbolConfiguration
    private let visualEffectView = UIVisualEffectView(effect: UIBlurEffect(style: .systemMaterial))
    
    override init(frame: CGRect) {
        
        buttonHeight = 44
        symbolConfiguration = UIImage.SymbolConfiguration(pointSize: buttonHeight - 5, weight: .ultraLight)
        super.init(frame: frame)
        
        configureSelf()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func configureSelf() {
        setImage(UIImage(systemName: "flashlight.off.fill")?.applyingSymbolConfiguration(symbolConfiguration), for: .normal)
        imageView?.tintColor    = .label
        backgroundColor         = .systemBackground.withAlphaComponent(0.7)
        layer.cornerRadius      = buttonHeight / 2
        clipsToBounds           = true
        
        translatesAutoresizingMaskIntoConstraints = false
    }

}
