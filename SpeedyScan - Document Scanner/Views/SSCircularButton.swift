//
//  CaptureButton.swift
//  SpeedyScan
//
//  Created by Julian Martinez on 7/3/21.
//

import UIKit

class SSCircularButton: UIButton {

    let buttonHeight: CGFloat
    private let symbolConfiguration: UIImage.SymbolConfiguration
	var normalBackgroundColor: UIColor = .systemBackground.withAlphaComponent(0.7)
	var highlightedBackgroundColor: UIColor = .systemBackground.withAlphaComponent(0.2)
	private let highlightDuration: TimeInterval = 0.25
	
	override var isHighlighted: Bool {
		didSet {
			if oldValue == false && isHighlighted {
				highlight()
			} else if oldValue == true && !isHighlighted {
				unhighlight()
			}
		}
	}
    
    override init(frame: CGRect) {
        
        buttonHeight = 70
        symbolConfiguration = UIImage.SymbolConfiguration(pointSize: buttonHeight - 5, weight: .ultraLight)
        super.init(frame: frame)
        
        configureSelf()
    }
	
	init(buttonHeight: CGFloat, symbolConfiguration: UIImage.SymbolConfiguration, symbolName: String) {
		self.buttonHeight = buttonHeight
		self.symbolConfiguration = symbolConfiguration
		super.init(frame: .zero)
		setImage(UIImage(systemName: symbolName)?.applyingSymbolConfiguration(symbolConfiguration), for: .normal)
		configureSelf()
	}
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func configureSelf() {
        
        imageView?.tintColor    = .label.withAlphaComponent(0.9)
        backgroundColor         = normalBackgroundColor
		layer.cornerRadius      = buttonHeight / 2
        clipsToBounds           = true
        
        translatesAutoresizingMaskIntoConstraints = false
    }
	
	private func highlight() {
		animateBackground(to: highlightedBackgroundColor, duration: highlightDuration)
	}

	private func unhighlight() {
		animateBackground(to: normalBackgroundColor, duration: highlightDuration)
	}
	
	private func animateBackground(to color: UIColor, duration: TimeInterval) {
		UIView.animate(withDuration: duration) {
			self.backgroundColor = color
		}
	}
}
