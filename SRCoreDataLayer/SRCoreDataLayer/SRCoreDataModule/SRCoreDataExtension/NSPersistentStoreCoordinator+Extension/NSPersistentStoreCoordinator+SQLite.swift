//
//  NSPersistentStoreCoordinator+SQLite.swift
//  SRCoreDataLayer
//
//  Created by Subhr Roy on 11/08/18.
//  Copyright © 2018 Subhr Roy. All rights reserved.
//

import CoreData

extension NSPersistentStoreCoordinator {
    
    // MARK: - Destroy
    
    static func destroyStore(at storeURL: URL) {
        do {
            let persistentStoreCoordinator = NSPersistentStoreCoordinator(managedObjectModel: NSManagedObjectModel())
            try persistentStoreCoordinator.destroyPersistentStore(at: storeURL, ofType: NSSQLiteStoreType, options: nil)
        } catch let error {
            fatalError("failed to destroy persistent store at \(storeURL), error: \(error)")
        }
    }
    
    // MARK: - Replace
    
    static func replaceStore(at targetURL: URL, withStoreAt sourceURL: URL) {
        do {
            let persistentStoreCoordinator = NSPersistentStoreCoordinator(managedObjectModel: NSManagedObjectModel())
            try persistentStoreCoordinator.replacePersistentStore(at: targetURL, destinationOptions: nil, withPersistentStoreFrom: sourceURL, sourceOptions: nil, ofType: NSSQLiteStoreType)
        } catch let error {
            fatalError("failed to replace persistent store at \(targetURL) with \(sourceURL), error: \(error)")
        }
    }
    
    // MARK: - Meta
    
    static func metadata(at storeURL: URL) -> [String : Any]?  {
        return try? NSPersistentStoreCoordinator.metadataForPersistentStore(ofType: NSSQLiteStoreType, at: storeURL, options: nil)
    }
    
    // MARK: - Add
    
    func addPersistentStore(at storeURL: URL, options: [AnyHashable : Any]) -> NSPersistentStore {
        do {
            return try addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: storeURL, options: options)
        } catch let error {
            fatalError("failed to add persistent store to coordinator, error: \(error)")
        }
        
    }
}

public extension NSPersistentStoreCoordinator {
	
	/**
	Default persistent store options used for the `SQLite` backed `NSPersistentStoreCoordinator`
	*/
	public static var stockSQLiteStoreOptions: [String : Any] = [
		NSMigratePersistentStoresAutomaticallyOption: true,
		NSInferMappingModelAutomaticallyOption: true,
		NSSQLitePragmasOption: ["journal_mode": "WAL"]
	]

	public static var stockSQLiteStoreMigrationOptions: [String : Any] {
		return [
			NSMigratePersistentStoresAutomaticallyOption: true,
			NSInferMappingModelAutomaticallyOption: true,
			NSSQLitePragmasOption: ["journal_mode": "DELETE"]
		]
	}
	
	/**
	Asynchronously creates an `NSPersistentStoreCoordinator` and adds a `SQLite` based store.
	
	- parameter managedObjectModel: The `NSManagedObjectModel` describing the data model.
	- parameter storeFileURL: The URL where the SQLite store file will reside.
	- parameter persistentStoreOptions: Custom options for persistent store. Default value is stockSQLiteStoreOptions
	- parameter completion: A completion closure with a `CoordinatorResult` that
	will be executed following the `NSPersistentStore` being added to the `NSPersistentStoreCoordinator`.
	*/
	@available(iOS, introduced: 8.0, deprecated: 10.0, message: "Use NSPersistentContainer")

	public class func setUpSQLiteContainer(_ managedObjectModel: NSManagedObjectModel,
												   storeFileURL: URL,
												   persistentStoreOptions: [String : Any]? = NSPersistentStoreCoordinator.stockSQLiteStoreOptions,completion: @escaping (SRCoreDataStackManager.CoordinatorResult) -> Void) {
		
		guard  let storeOptions = persistentStoreOptions else {
			let error = Error.self
			completion(.failure(error as! Error))
			return
		}
		
		// Helper
		let persistentStoreURL = storeFileURL
		
		// Create Persistent Store Description
		let persistentStoreDescription = NSPersistentStoreDescription(url: persistentStoreURL)
		
		// Configure Persistent Store Description
		persistentStoreDescription.type = NSSQLiteStoreType
		persistentStoreDescription.shouldMigrateStoreAutomatically = storeOptions[NSMigratePersistentStoresAutomaticallyOption] as! Bool
		persistentStoreDescription.shouldInferMappingModelAutomatically = storeOptions[NSInferMappingModelAutomaticallyOption] as! Bool
		persistentStoreDescription.setOption(storeOptions[NSSQLitePragmasOption] as? NSObject, forKey: NSSQLitePragmasOption)
		
		let persistentContainer = NSPersistentContainer(name: DBStore.dataStoreName, managedObjectModel: managedObjectModel)
		let description = persistentContainer.persistentStoreDescriptions.first
		print("\(String(describing: description))")
		
		persistentContainer.persistentStoreDescriptions = [persistentStoreDescription]
		persistentContainer.loadPersistentStores { (persistentStoreDescription, error) in
			
			if let error = error {
				print("Unable to Add Persistent Store")
				print("\(error.localizedDescription)")
				
				completion(.failure(error))
			}else {
				completion(.success(persistentContainer))
			}
		}
		
	}
}
