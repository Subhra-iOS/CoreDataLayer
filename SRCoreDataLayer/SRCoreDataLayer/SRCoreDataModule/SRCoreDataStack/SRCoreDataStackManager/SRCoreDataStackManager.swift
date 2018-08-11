//
//  SRCoreDataStack.swift
//  SRCoreDataLayer
//
//  Created by Subhr Roy on 11/08/18.
//  Copyright © 2018 Subhr Roy. All rights reserved.
//

import Foundation
import CoreData

final class SRCoreDataStackManager : NSObject {
	
	static  let sharedManager : SRCoreDataStackManager = SRCoreDataStackManager()
	
	override private init() {
		super.init()
	}
	
	// MARK: - Core Data stack
	lazy var persistentContainer: NSPersistentContainer = {
		/*
		The persistent container for the application. This implementation
		creates and returns a container, having loaded the store for the
		application to it. This property is optional since there are legitimate
		error conditions that could cause the creation of the store to fail.
		*/
		let container = NSPersistentContainer(name: "SRCoreDataLayer")
		
		return container
	}()
	
	// MARK: - SetUp
	func setup(completion: @escaping () -> Void) {
		loadPersistentStore {
			completion()
		}
	}
	
	// MARK: - Loading
	private func loadPersistentStore(completion: @escaping () -> Void) {
		self.persistentContainer.loadPersistentStores { storeDescription, error in
			
			if let error = error as NSError? {
				// Replace this implementation with code to handle the error appropriately.
				// fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
				
				/*
				Typical reasons for an error here include:
				* The parent directory does not exist, cannot be created, or disallows writing.
				* The persistent store is not accessible, due to permissions or data protection when the device is locked.
				* The device is out of space.
				* The store could not be migrated to the current model version.
				Check the error message to determine what the actual problem was.
				*/
				fatalError("Unresolved error \(error), \(error.userInfo)")
			}
			
			completion()
		}
	}
	
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
	func saveOnBackgroundContextWith( _ context : NSManagedObjectContext ,_ completionHandler : (( _ success : Bool) -> Void)? = nil) -> Void{
		
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
