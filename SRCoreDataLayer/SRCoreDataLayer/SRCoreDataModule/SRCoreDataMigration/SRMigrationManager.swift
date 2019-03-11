//
//  SRMigrationManager.swift
//  SRCoreDataLayer
//
//  Created by Subhr Roy on 13/05/17.
//  Copyright © 2017 Subhr Roy. All rights reserved.
//

import Foundation
import CoreData

protocol SRMigrationManagerDelegate {
	
	func  migrationManager(migrationManager : SRMigrationManager , migrationProgress : Float) -> Void
	
}

class SRMigrationManager : NSObject {
	
	var  migrationDelegate : SRMigrationManagerDelegate?
	
	//MARK:-----------Progressive Migration-----------
	func progressivelyMigrateURL(sourceStoreURL: URL, ofType type: String, to finalModel: NSManagedObjectModel) throws -> Bool {
		
		let sourceMetadata: [AnyHashable: Any]? = try? NSPersistentStoreCoordinator.metadataForPersistentStore(ofType: type, at: sourceStoreURL)
		if sourceMetadata == nil {
			return false
		}
		if finalModel.isConfiguration(withName: nil, compatibleWithStoreMetadata: sourceMetadata as! [String : Any]) {
			/*if nil != error {
				error = nil
			}*/
			return true
		}
		let sourceModel: NSManagedObjectModel = createSourceModel(forSourceMetadata: sourceMetadata!)
		
		var destinationModel: NSManagedObjectModel?
		var mappingModel: NSMappingModel?
		var modelName: String?
		
		if self.getDestinationModel(&destinationModel, mappingModel: &mappingModel, modelName: &modelName, forSourceModel: sourceModel){
		
			var mappingModels : Array = [mappingModel]
			
			let explicitMappingModels : [NSMappingModel]? = self.migrationModelsWith(mappingModelsForSourceModel: sourceModel) as? [NSMappingModel]
			
			if (explicitMappingModels?.count)! > 0 {
			
				mappingModels = explicitMappingModels!
			
			}
			
			let  destinationStoreURL : URL = self.destinationStoreURL(withSourceStore: sourceStoreURL, modelName: modelName!)
			
			let  manager : NSMigrationManager = NSMigrationManager(sourceModel: sourceModel, destinationModel: destinationModel!)
			manager.addObserver(self, forKeyPath: "migrationProgress", options: NSKeyValueObservingOptions.new, context: nil)
			
			var didMigrate : Bool = true
			
			//var _mappingModel : NSMappingModel?
			for (_ , _mappingModel) in mappingModels.enumerated(){
			
				do{
				
					try manager.migrateStore(from: sourceStoreURL, sourceType: type, options: nil, with: _mappingModel, toDestinationURL: destinationStoreURL, destinationType: type, destinationOptions: nil)
				
					didMigrate = true
					
				}catch {
				
					didMigrate = false
				
				}
			
			}
			
			manager.removeObserver(self, forKeyPath: "migrationProgress")
			
			if didMigrate {
			
				// Migration was successful, move the files around to preserve the source in case things go bad
				
				if try! self.backupSourceStore(at: sourceStoreURL, movingDestinationStoreAt: destinationStoreURL){
					
					// We may not be at the "current" model yet, so recurse

					return  try! self.progressivelyMigrateURL(sourceStoreURL:sourceStoreURL, ofType:type ,to:finalModel)
				
				}else{
				
					return false
				}
			
			}else{
			
			
				return  false
			}
			
			
		
		}else{
		
			return false
		}
		
	}
	//MARK:---------Get Destination Model-------------
	func getDestinationModel(_ destinationModel: inout NSManagedObjectModel?, mappingModel: inout NSMappingModel?,  modelName: inout String?, forSourceModel sourceModel: NSManagedObjectModel) -> Bool {
		
		let modelPaths : NSArray = self.modelPaths()!
		
		if modelPaths.count > 0 {
			
			var mapping : NSMappingModel?
			let modelPath : NSString? = ""
			var model : NSManagedObjectModel?
			
			for (_ , modelPath) in modelPaths.enumerated(){
			
				model = NSManagedObjectModel(contentsOf: URL(fileURLWithPath: modelPath as! String))!
				mapping = NSMappingModel(from: [Bundle.main], forSourceModel: sourceModel, destinationModel: model)
				
				//If we found a mapping model then proceed
				if let _ = mapping {
					break
				}
			}
			
			if let _mapping = mapping {
			
				destinationModel = model
				mappingModel = _mapping
				modelName = modelPath?.deletingPathExtension
			
			}else{
			
				return false
			}
			
		}else{
		
			return false
		}
		
		return  true
		
	}
	//MARK:-------------Create Source Model-------------
	func createSourceModel(forSourceMetadata sourceMetadata: [AnyHashable: Any]) -> NSManagedObjectModel {
		return NSManagedObjectModel.mergedModel(from: [Bundle.main], forStoreMetadata: sourceMetadata as! [String : Any])!
	}
	
	
	//MARK:--------Model Paths----------
	func  modelPaths() -> NSMutableArray?{
	
		let modelPaths : NSMutableArray = NSMutableArray()
		let momdArray : [NSString] = Bundle.main.paths(forResourcesOfType: "momd", inDirectory: nil) as [NSString]
		
		for (_,momdPath) in  momdArray.enumerated(){
		
			let resourceSubpath : String = momdPath.lastPathComponent
			let array = Bundle.main.paths(forResourcesOfType: "mom", inDirectory: resourceSubpath)
		
			modelPaths.addingObjects(from: array)
		}
		
		let otherModelArr : [NSString] = Bundle.main.paths(forResourcesOfType: "mom", inDirectory: nil) as [NSString]
		
		modelPaths.addingObjects(from: otherModelArr)
		
		return  modelPaths
	
	}
	
	func  migrationModelsWith(mappingModelsForSourceModel : NSManagedObjectModel) -> Array<Any>? {
		
		var mappingModels: Array<NSMappingModel> = Array<NSMappingModel>()
		let modelName: String = mappingModelsForSourceModel.migrationModelName()
		
		if modelName.isEqual("CoreDataVersion3") {
			// Migrating to CoreDataVersion3_V2
			let urls: [URL] = Bundle(for: type(of: self)).urls(forResourcesWithExtension: "cdm", subdirectory: nil)!
			
			for (_,url) in urls.enumerated() {
				
				if (url.lastPathComponent as NSString).range(of:"CoreDataModelV1_To_V2").length != 0 {
					
					let  mappingModel = NSMappingModel(contentsOf: url)
					if let mappedModel = mappingModel {
						
						mappingModels.append(mappedModel)
						
					}
					
				}
			}
		}
		
		return mappingModels
		
	}
	//MARK:--------Destination Store URL-----------
	func destinationStoreURL(withSourceStore sourceStoreURL: URL, modelName: String) -> URL {
		// We have a mapping model, time to migrate
		let storeExtension: String = sourceStoreURL.pathExtension
		var storePath: String = sourceStoreURL.deletingPathExtension().absoluteString
		// Build a path to write the new store
		storePath = "\(storePath).\(modelName).\(storeExtension)"
		return URL(fileURLWithPath: storePath)
	}
	//MARK:-----------Backup Source Store----------
	func backupSourceStore(at sourceStoreURL: URL, movingDestinationStoreAt destinationStoreURL: URL) throws -> Bool {
		
		let guid: String = ProcessInfo.processInfo.globallyUniqueString
		let backupPath: String = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(guid).absoluteString
		let fileManager = FileManager.default
		if (((try? fileManager.moveItem(atPath: sourceStoreURL.path, toPath: backupPath)) != nil)) {
			//Failed to copy the file
			return false
		}
		//Move the destination to the source path
		if (((try? fileManager.moveItem(atPath: destinationStoreURL.path, toPath: sourceStoreURL.path)) != nil)) {
			//Try to back out the source move first, no point in checking it for errors
			try? fileManager.moveItem(atPath: backupPath, toPath: sourceStoreURL.path)
			return false
		}
		return true
	}
	//MARK:-----------Override ObserveValue Func-----------
	override func  observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
		
		if (keyPath == "migrationProgress") {
			print("progress: \((object as AnyObject).migrationProgress)")
			
			let migrationManager : NSMigrationManager? = object as? NSMigrationManager
			
			self.migrationDelegate?.migrationManager(migrationManager: self, migrationProgress: (migrationManager?.migrationProgress)!)
			
		}
		else {
			super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
		}
		
	}
	
}
