//
//  MetadataManager.swift
//  MetadataManager
//
//  Created by Julian Martinez on 8/7/21.
//

import Foundation
import Combine

extension Notification.Name {
	static let pdfMetadataDidChange = Notification.Name("pdfMetadataDidChange")
}

class CloudMetadataManager {
	
	typealias MetadataDidChangeUserInfo = [MetadataDidChangeUserInfoKey: [MetadataItem]]
	
	enum MetadataDidChangeUserInfoKey: String {
		case queryResults
	}
	
	private(set) var containerRootURL: URL?
	private var querySubscriber: AnyCancellable?
	private let metadataQuery = NSMetadataQuery()
	
	//Failable init: fails if there isn't a logged-in iCloud account.
	
	init?(containerIdentifier: String?) {
		guard FileManager.default.ubiquityIdentityToken != nil else {
#warning("Implement alert controller - iCloud isn't enabled yet. Please enable iCloud and run again.")
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
		
		//Observe and handle NSMetadataQuery's Notifications
		// Post .metadataDidChange from main queue and return after clients finish handling it.
		
#warning("Implement alert controller - ⛔️ Failed to retrieve iCloud container URL for containerIdentifier. Make sure your iCloud is available and run again")
		let names: [NSNotification.Name] 	= [.NSMetadataQueryDidFinishGathering, .NSMetadataQueryDidUpdate]
		let publishers 						= names.map { NotificationCenter.default.publisher(for: $0) }
		
		querySubscriber = Publishers.MergeMany(publishers).receive(on: DispatchQueue.main).sink { notification in
			guard notification.object as? NSMetadataQuery === self.metadataQuery else {return}
			var userInfo = MetadataDidChangeUserInfo()
			userInfo[.queryResults] = self.provideMetadataItemList()
			NotificationCenter.default.post(name: .pdfMetadataDidChange, object: self, userInfo: userInfo)
		}
		
		metadataQuery.notificationBatchingInterval 	= 1
		metadataQuery.searchScopes					= [NSMetadataQueryUbiquitousDataScope, NSMetadataQueryUbiquitousDocumentsScope]
		metadataQuery.predicate						= NSPredicate(format: "%K LIKE %@", NSMetadataItemFSNameKey, "*." + Document.extensionName)
		metadataQuery.sortDescriptors				= [NSSortDescriptor(key: NSMetadataItemFSNameKey, ascending: true)]
		metadataQuery.start()
	}
	
	deinit {
		guard metadataQuery.isStarted else {return}
		metadataQuery.stop()
	}
}

//MARK: - Providing Metadata Items

extension CloudMetadataManager {
	
	private func provideMetadataItemList(from nsMetadataItems: [NSMetadataItem]) -> [MetadataItem] {
		let validItems = nsMetadataItems.filter { item in
			guard let fileURL = item.value(forAttribute: NSMetadataItemURLKey) as? URL,
				  item.value(forAttribute: NSMetadataItemFSNameKey) != nil
			else {
				return false
			}
			
			let resourceKeys: [URLResourceKey] = [.isDirectoryKey, .isPackageKey]
			
			if let resourceValues 	= try? (fileURL as NSURL).resourceValues(forKeys: resourceKeys),
			   let isDirectory 		= resourceValues[URLResourceKey.isDirectoryKey] as? Bool, isDirectory,
			   let isPackage 		= resourceValues[URLResourceKey.isPackageKey] as? Bool, !isPackage {
				return false
			}
			
			return true
		}
		
		return validItems.sorted {
			let name0 = $0.value(forAttribute: NSMetadataItemFSNameKey) as? String
			let name1 = $1.value(forAttribute: NSMetadataItemFSNameKey) as? String
			return name0! < name1!
		} .map {
			let itemURL = $0.value(forAttribute: NSMetadataItemURLKey) as? URL
			return MetadataItem(nsMetadataItem: $0, url: itemURL!)
		}
	}
	
	func provideMetadataItemList() -> [MetadataItem] {
		var result = [MetadataItem]()
		
		metadataQuery.disableUpdates()
		
		if let metadataItems = metadataQuery.results as? [NSMetadataItem] {
			result = provideMetadataItemList(from: metadataItems)
		}
		
		metadataQuery.enableUpdates()
		
		return result
	}
}
