//
//  SaveButton.swift
//  ContactScanner
//
//  Created by Julian Martinez on 7/5/21.
//

import UIKit

class SelectionButton: UIButton {

    let buttonHeight: CGFloat
	
	private let normalBackgroundColor: UIColor = .systemBackground.withAlphaComponent(0.7)
	private let highlightedBackgroundColor: UIColor = .systemBackground.withAlphaComponent(0.2)
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
        
        buttonHeight = 50
        super.init(frame: frame)
        
        configureSelf()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func configureSelf() {

        setTitleColor(.label, for: .normal)
        
        titleLabel?.font = UIFont.systemFont(ofSize: 23)
        contentEdgeInsets = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10)
        backgroundColor         = normalBackgroundColor
        layer.cornerRadius      = buttonHeight / 4

        clipsToBounds           = true
        
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
