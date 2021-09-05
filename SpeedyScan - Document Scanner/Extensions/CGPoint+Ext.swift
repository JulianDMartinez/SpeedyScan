//
//  CGPoint+Ext.swift
//  CGPoint+Ext
//
//  Created by Julian Martinez on 9/5/21.
//

import UIKit

extension CGPoint {
	func scaled(to size: CGSize) -> CGPoint {
		return CGPoint(x: self.x * size.width,
					   y: self.y * size.height)
	}
}
