//
//  NSPersistentContainer+SQLite.swift
//  SRCoreDataLayer
//
//  Created by Subhra Roy on 12/03/19.
//  Copyright © 2019 Subhr Roy. All rights reserved.
//

import CoreData

/*public extension NSPersistentContainer {
    
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
    
    public class func setUpSQLiteContainer(_ managedObjectModel: NSManagedObjectModel,
                                           storeFileURL: URL,
                                           persistentStoreOptions: [String : Any]? = NSPersistentContainer.stockSQLiteStoreOptions,completion: @escaping (SRCoreDataStackManager.CoordinatorResult) -> Void) {
        
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
}*/
