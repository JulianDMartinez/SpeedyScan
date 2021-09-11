//
//  MetadataManager.swift
//  MetadataManager
//
//  Created by Julian Martinez on 8/7/21.
//

import Foundation
import Combine


class CloudDriveContainerManager {
	private(set) var containerRootURL: URL?
	init?(containerIdentifier: String?) {
		guard FileManager.default.ubiquityIdentityToken != nil else {
			return
		}
		
		DispatchQueue.global().async {
			if let url = FileManager.default.url(forUbiquityContainerIdentifier: containerIdentifier) {
				DispatchQueue.main.async {
					self.containerRootURL = url
				}
			}
			return
		}
	}
}


