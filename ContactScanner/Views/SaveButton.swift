//
//  SaveButton.swift
//  ContactScanner
//
//  Created by Julian Martinez on 7/5/21.
//

import UIKit

class SaveButton: UIButton {

    let buttonHeight: CGFloat
    
    override init(frame: CGRect) {
        
        buttonHeight = 50
        super.init(frame: frame)
        
        configureSelf()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func configureSelf() {

        setTitle("Save / Share", for: .normal)
        setTitleColor(.label, for: .normal)
        
        titleLabel?.font = UIFont.systemFont(ofSize: 23)
        contentEdgeInsets = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10)
        backgroundColor         = .systemBackground.withAlphaComponent(0.7)
        layer.cornerRadius      = buttonHeight / 4

        clipsToBounds           = true
        
    }
}
