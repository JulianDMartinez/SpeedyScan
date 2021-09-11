//
//  TipsVC.swift
//  TipsVC
//
//  Created by Julian Martinez on 9/7/21.
//

import UIKit

class TipsVC: UIViewController {
	
	private let tipsContainerView          		= UIView()
	private let visualEffectView                = UIVisualEffectView(effect: UIBlurEffect(style: .systemThinMaterial))
	private let cancelButton                    = SSRectangularButton()
	private let selectionButton                 = SSRectangularButton()
	private let buttonsStackView                = UIStackView()
	private let verticalStackView               = UIStackView()
	private let tipsDataModel					= TipsDataModel()

    override func viewDidLoad() {
        super.viewDidLoad()
		
		configureTipsContainerView()
		configureOkayButton()
		configureButtonsStackView()
		configureVerticalStackView()
		configureVisualEffectView()
    }
	
	private func configureSelf() {
		view.isOpaque = false
		view.backgroundColor = UIColor.clear
	}
	
	
	private func configureOkayButton() {
		cancelButton.setTitle("Okay", for: .normal)
		cancelButton.setTitleColor(.label, for: .normal)
		cancelButton.addTarget(self, action: #selector(okayButtonTapped), for: .touchUpInside)
	}
	
	
	@objc private func okayButtonTapped() {
		dismiss(animated: true, completion: nil)
	}
	
	
	private func configureTipsContainerView() {

		tipsContainerView.heightAnchor.constraint(equalToConstant: view.frame.height*0.73).isActive = true
		
		let titleLabel = UILabel()
		
		titleLabel.text = "Tips For Best Results"
		titleLabel.textAlignment = .center
		titleLabel.font = .preferredFont(forTextStyle: .title1)
		titleLabel.translatesAutoresizingMaskIntoConstraints = false
	
		tipsContainerView.addSubview(titleLabel)
		
		NSLayoutConstraint.activate([
			titleLabel.topAnchor.constraint(equalTo: tipsContainerView.topAnchor),
			titleLabel.widthAnchor.constraint(equalTo: tipsContainerView.widthAnchor)
		])
		
		let tipsScrollView = UIScrollView()
		
		tipsContainerView.addSubview(tipsScrollView)
		
//		tipsScrollView.contentSize = CGSize(width: tipsContainerView.frame.width, height: 2180)
		tipsScrollView.translatesAutoresizingMaskIntoConstraints 	= false
		tipsScrollView.isScrollEnabled 								= true
		tipsScrollView.showsVerticalScrollIndicator = false 
		
		NSLayoutConstraint.activate([
			tipsScrollView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 10),
			tipsScrollView.leadingAnchor.constraint(equalTo: tipsContainerView.leadingAnchor),
			tipsScrollView.trailingAnchor.constraint(equalTo: tipsContainerView.trailingAnchor),
			tipsScrollView.bottomAnchor.constraint(equalTo: tipsContainerView.bottomAnchor)
		])
		
		let tipStackView = UIStackView()

		tipsScrollView.addSubview(tipStackView)

		tipStackView.axis = .vertical

		tipStackView.distribution = .fillProportionally

		tipStackView.translatesAutoresizingMaskIntoConstraints = false
		
		tipStackView.spacing = 15

		NSLayoutConstraint.activate([
			tipStackView.topAnchor.constraint(equalTo: tipsScrollView.topAnchor),
			tipStackView.centerXAnchor.constraint(equalTo: tipsScrollView.centerXAnchor),
			tipStackView.widthAnchor.constraint(equalTo: tipsScrollView.widthAnchor),
			tipStackView.bottomAnchor.constraint(equalTo: tipsScrollView.contentLayoutGuide.bottomAnchor)
		])
		
		let itemOneTextView = SSTipTextView(itemNumber: 1, itemText: tipsDataModel.tipsTextData[0])
		let itemTwoTextView = SSTipTextView(itemNumber: 2, itemText: tipsDataModel.tipsTextData[1])
		let itemThreeTextView = SSTipTextView(itemNumber: 3, itemText: tipsDataModel.tipsTextData[2])
		let itemFourTextView = SSTipTextView(itemNumber: 4, itemText: tipsDataModel.tipsTextData[3])
		
		let testImageViewOne = SSTipImageView(correctImageName: "gif1", incorrectImageName: "gif2")
		let testImageViewTwo = SSTipImageView(correctImageName: "gif3", incorrectImageName: "gif4")
		let testImageViewThree = SSTipImageView(correctImageName: "gif5", incorrectImageName: "gif6")
		let testImageViewFour =  SSTipImageView(correctImageName: "gif6", incorrectImageName: "gif7")
		
		tipStackView.addArrangedSubview(itemOneTextView)
		tipStackView.addArrangedSubview(testImageViewOne)
		tipStackView.addArrangedSubview(itemTwoTextView)
		tipStackView.addArrangedSubview(testImageViewTwo)
		tipStackView.addArrangedSubview(itemThreeTextView)
		tipStackView.addArrangedSubview(testImageViewThree)
		tipStackView.addArrangedSubview(itemFourTextView)
		tipStackView.addArrangedSubview(testImageViewFour)
		
	}
	
	
	private func configureButtonsStackView() {
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
		
		verticalStackView.addArrangedSubview(tipsContainerView)
		verticalStackView.addArrangedSubview(buttonsStackView)
		
		verticalStackView.spacing = 10
		verticalStackView.distribution = .fill
		verticalStackView.axis = .vertical
		verticalStackView.clipsToBounds = true
		verticalStackView.translatesAutoresizingMaskIntoConstraints = false
		
		NSLayoutConstraint.activate([
			verticalStackView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -27),
			verticalStackView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 15),
			verticalStackView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -15),
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

