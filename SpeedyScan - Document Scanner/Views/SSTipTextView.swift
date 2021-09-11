//
//  SSTipTextView.swift
//  SSTipTextView
//
//  Created by Julian Martinez on 9/10/21.
//

import UIKit

class SSTipTextView: UIView {
	
	init(itemNumber: Int, itemText: String) {
		super.init(frame: .zero)
		
		let itemNumberLabel = UILabel()
		let itemTextView 	= UITextView()
		
		itemNumberLabel.text 	= "\(itemNumber)."
		itemTextView.text		= itemText
		itemTextView.isEditable = false
		
		let itemNumberContainerView = UIView()
		
		itemNumberContainerView.widthAnchor.constraint(equalToConstant: 20).isActive = true
		
		itemNumberContainerView.addSubview(itemNumberLabel)
		itemNumberLabel.font = .preferredFont(forTextStyle: .body)
		itemNumberLabel.textAlignment = .right
		itemNumberLabel.translatesAutoresizingMaskIntoConstraints = false
		
		NSLayoutConstraint.activate([
			itemNumberLabel.topAnchor.constraint(equalTo: itemNumberContainerView.topAnchor, constant: 8),
			itemNumberLabel.trailingAnchor.constraint(equalTo: itemNumberContainerView.trailingAnchor)
		])
		
		itemTextView.font 	= .preferredFont(forTextStyle: .body)
		itemTextView.backgroundColor = .clear
		itemTextView.sizeToFit()
		itemTextView.isScrollEnabled = false
		
		
		let itemStackView 	= UIStackView()
		
		self.addSubview(itemStackView)
		itemStackView.addArrangedSubview(itemNumberContainerView)
		itemStackView.addArrangedSubview(itemTextView)
		
		itemStackView.axis = .horizontal
		
		itemStackView.translatesAutoresizingMaskIntoConstraints = false
		
		NSLayoutConstraint.activate([
			itemStackView.topAnchor.constraint(equalTo: self.topAnchor),
			itemStackView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
			itemStackView.trailingAnchor.constraint(equalTo: self.trailingAnchor),
		])
		
		self.heightAnchor.constraint(equalTo: itemStackView.heightAnchor).isActive = true
		self.backgroundColor = .clear
	}
	
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
}
