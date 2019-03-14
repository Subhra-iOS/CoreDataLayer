//
//  NSManageObjectModel+Utility.swift
//  CoreDataVersion3
//
//  Created by Subhr Roy on 20/05/17.
//  Copyright © 2017 Subhr Roy. All rights reserved.
//

import Foundation
import CoreData

extension  NSManagedObjectModel {

	class func allModelPaths() -> [Any] {
		//Find all of the mom and momd files in the Resources directory
		var modelPaths = [Any]()
		let momdArray: [NSString] = Bundle.main.paths(forResourcesOfType: "momd", inDirectory: nil) as [NSString]
		
		for (_,momdPath) in momdArray.enumerated() {
			
			let resourceSubpath: String = momdPath.lastPathComponent
			let array: [Any] = Bundle.main.paths(forResourcesOfType: "mom", inDirectory: resourceSubpath)
			modelPaths += array
			
		}
		
		let otherModels: [Any] = Bundle.main.paths(forResourcesOfType: "mom", inDirectory: nil)
		modelPaths += otherModels
		return modelPaths
	}


	func migrationModelName() -> String {
		var modelName: String? = nil
		let modelPaths: [NSString] = type(of: self).allModelPaths() as! [NSString]
		
		for (_,modelPath) in modelPaths.enumerated() {
			
			let modelURL : URL = URL(fileURLWithPath: modelPath as String)
			let model = NSManagedObjectModel(contentsOf: modelURL)
			if (model?.isEqual(self))! {
				modelName = modelURL.deletingPathExtension().absoluteString
				break
			}
		}
		
		return modelName!
	}

}
