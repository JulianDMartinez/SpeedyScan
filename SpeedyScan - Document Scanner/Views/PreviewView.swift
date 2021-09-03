//
//  PreviewView.swift
//  PreviewView
//
//  Created by Julian Martinez on 8/29/21.
//

import UIKit
import AVFoundation

class PreviewView: UIView {

	var videoPreviewLayer: AVCaptureVideoPreviewLayer {
		guard let layer = layer as? AVCaptureVideoPreviewLayer else {
			fatalError("Expected `AVCaptureVideoPreviewLayer` type for layer. Check PreviewView.layerClass implementation.")
		}
		
		return layer
	}
	
	override class var layerClass: AnyClass {
		return AVCaptureVideoPreviewLayer.self
	}

}
