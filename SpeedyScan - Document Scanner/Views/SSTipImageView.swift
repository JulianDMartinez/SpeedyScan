//
//  SSTipImageView.swift
//  SSTipImageView
//
//  Created by Julian Martinez on 9/10/21.
//

import UIKit

class SSTipImageView: UIView {

	init(correctImageName: String, incorrectImageName: String) {
		super.init(frame: .zero)
		
		let verticalStackView = UIStackView()
		
		self.addSubview(verticalStackView)
		
		verticalStackView.axis = .vertical
		verticalStackView.spacing = 8
		
		verticalStackView.translatesAutoresizingMaskIntoConstraints = false
		
		NSLayoutConstraint.activate([
			verticalStackView.topAnchor.constraint(equalTo: self.topAnchor, constant: 25),
			verticalStackView.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 25),
			verticalStackView.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -25),
			verticalStackView.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -15)
		])
		
		let gifStackView 	= UIStackView()
		
		verticalStackView.addArrangedSubview(gifStackView)
		
		let correctImageView = UIImageView()
		let incorrectImageView = UIImageView()
		
		correctImageView.loadGif(name: correctImageName)
		incorrectImageView.loadGif(name: incorrectImageName)
		
		correctImageView.contentMode = .scaleAspectFill
		incorrectImageView.contentMode = .scaleAspectFill
		
		correctImageView.layer.cornerRadius = 3
		incorrectImageView.layer.cornerRadius = 3
		
		correctImageView.clipsToBounds = true
		incorrectImageView.clipsToBounds = true
		

		gifStackView.addArrangedSubview(incorrectImageView)
		gifStackView.addArrangedSubview(correctImageView)
		
		gifStackView.axis = .horizontal
		gifStackView.distribution = .fillEqually
		
		gifStackView.spacing = 10
		
	
		let xAndCheckmarkStackView = UIStackView()
		
		verticalStackView.addArrangedSubview(xAndCheckmarkStackView)
		
		let xImageView = UIImageView()
		let checkmarkImageView = UIImageView()
		
		xImageView.image = UIImage(systemName: "multiply")
		xImageView.preferredSymbolConfiguration = UIImage.SymbolConfiguration(weight: .bold)
		xImageView.tintColor = .systemRed
		xImageView.contentMode = .scaleAspectFit
//		xImageView.layer.shadowColor = UIColor.white.withAlphaComponent(0.8).cgColor
		xImageView.layer.shadowOpacity = 1
		xImageView.layer.shadowOffset = CGSize(width: 0, height: 0)
		xImageView.layer.shadowRadius = 0.3
		
		checkmarkImageView.image = UIImage(systemName: "checkmark")
		checkmarkImageView.preferredSymbolConfiguration = UIImage.SymbolConfiguration(weight: .bold)
		checkmarkImageView.tintColor = .systemGreen
		checkmarkImageView.contentMode = .scaleAspectFit
//		checkmarkImageView.layer.shadowColor = UIColor.white.cgColor
		checkmarkImageView.layer.shadowOpacity = 1
		checkmarkImageView.layer.shadowOffset = CGSize(width: 0, height: 0)
		checkmarkImageView.layer.shadowRadius = 0.3
		
		xAndCheckmarkStackView.axis = .horizontal
		xAndCheckmarkStackView.distribution = .fillEqually
		xAndCheckmarkStackView.addArrangedSubview(xImageView)
		xAndCheckmarkStackView.addArrangedSubview(checkmarkImageView)
		xAndCheckmarkStackView.heightAnchor.constraint(equalToConstant: 44).isActive = true
		
		self.heightAnchor.constraint(equalTo: self.widthAnchor, multiplier: 1.08).isActive = true
		self.backgroundColor = .systemBackground.withAlphaComponent(0.25)
		self.layer.cornerRadius = 7
		self.clipsToBounds = true
	}
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
}


