//
//  SRCoreDataStack.swift
//  SRCoreDataLayer
//
//  Created by Subhr Roy on 11/08/18.
//  Copyright © 2018 Subhr Roy. All rights reserved.
//

import Foundation
import CoreData

final public class SRCoreDataStackManager : NSObject {
	
	let migrationManager: SRCoreDataMigrationManager
	
	static  let sharedManager : SRCoreDataStackManager = SRCoreDataStackManager()
	
	private override init() {
		self.migrationManager = SRCoreDataMigrationManager()
		super.init()
	}
	
	
	// MARK: - Core Data stack
	lazy var persistentContainer: NSPersistentContainer! = {
		let persistentContainer = NSPersistentContainer(name: "SRCoreDataLayer")
		let description = persistentContainer.persistentStoreDescriptions.first
		description?.shouldInferMappingModelAutomatically = false //inferred mapping will be handled else where
		
		return persistentContainer
	}()
	
	//MARK:- Background ManageObjectContext
	lazy var backgroundContext: NSManagedObjectContext = {
		let context = self.persistentContainer.newBackgroundContext()
		context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
		
		return context
	}()
	
	//MARK:- Main ManageObjectContext

	lazy var mainContext: NSManagedObjectContext = {
		let context = self.persistentContainer.viewContext
		context.automaticallyMergesChangesFromParent = true
		
		return context
	}()
	
	// MARK: - SetUp
	func setup(completion: @escaping () -> Void) {
		loadPersistentStore {
			completion()
		}
	}
	
	// MARK: - Loading
	private func loadPersistentStore(completion: @escaping () -> Void) {
		migrateStoreIfNeeded {
			self.persistentContainer.loadPersistentStores { description, error in
				guard error == nil else {
					fatalError("was unable to load store \(error!)")
				}
				
				completion()
			}
		}
	}
	
	private func migrateStoreIfNeeded(completion: @escaping () -> Void) {
		guard let storeURL = persistentContainer.persistentStoreDescriptions.first?.url else {
			fatalError("persistentContainer was not set up properly")
		}
		
		if self.migrationManager.requiresMigration(at: storeURL) {
			
			DispatchQueue.global(qos: .userInitiated).async { [unowned self] in
				self.migrationManager.migrateStore(at: storeURL)
				
				DispatchQueue.main.async {
					completion()
				}
			}
		} else {
			completion()
		}
	}
	
}

public extension SRCoreDataStackManager{
	
	// MARK: - Core Data Saving support on Main Context
	func saveOnMainContext () {
		let context = persistentContainer.viewContext
		if context.hasChanges {
			do {
				try context.save()
			} catch {
				// Replace this implementation with code to handle the error appropriately.
				// fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
				let nserror = error as NSError
				fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
			}
		}
	}
	
	//MARK: - Save on Background Context
	func saveOnBackgroundContextWith( _ context : NSManagedObjectContext ,_ completionHandler : (( _ success : SaveResult) -> Void)? = nil) -> Void{
		
		context.saveContextToStore { result in
			
			if let _ = completionHandler {
				
				completionHandler?(result)
			}
			
		}
		
	}
	
}

public extension SRCoreDataStackManager{
	
	/// Result containing either an instance of `SRCoreDataStack` or `ErrorType`
	public enum SetupResult {
		/// A success case with associated `SRCoreDataStack` instance
		case success(SRCoreDataStackManager)
		/// A failure case with associated `ErrorType` instance
		case failure(Swift.Error)
	}
	/// Result of void representing `success` or an instance of `ErrorType`
	public enum SuccessResult {
		/// A success case
		case success
		/// A failure case with associated ErrorType instance
		case failure(Swift.Error)
	}
	
	public typealias SaveResult = SuccessResult

}
