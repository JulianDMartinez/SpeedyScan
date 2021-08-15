//
//  MetadataItem.swift
//  MetadataItem
//
//  Created by Julian Martinez on 8/7/21.
//

import Foundation

struct MetadataItem: Hashable {
	let nsMetadataItem: NSMetadataItem?
	let url: URL
	
	static func == (lhs: MetadataItem, rhs: MetadataItem) -> Bool {
		return lhs.url.path == rhs.url.path
	}
	
	func hash(into hasher: inout Hasher) {
		hasher.combine(url.path)
	}
}
