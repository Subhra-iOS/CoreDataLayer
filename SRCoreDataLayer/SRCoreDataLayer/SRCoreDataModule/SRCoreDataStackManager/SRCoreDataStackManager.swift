//
//  SRCoreDataStack.swift
//  SRCoreDataLayer
//
//  Created by Subhr Roy on 11/08/18.
//  Copyright © 2018 Subhr Roy. All rights reserved.
//

import Foundation
import CoreData

// MARK: - Action callbacks
public typealias SetupCallback = (SRCoreDataStackManager.SetupResult) -> Void

final public class SRCoreDataStackManager : NSObject {
	
	public static var isMigrationTrue = false
	public static var dataStoreURL : URL?
	
	fileprivate static var managedObjectModel: NSManagedObjectModel?
	fileprivate let saveBubbleDispatchGroup = DispatchGroup()
	
	/// SRCoreDataStackManager specific ErrorTypes
	public enum Error: Swift.Error {
		/// Case when an `NSPersistentStore` is not found for the supplied store URL
		case storeNotFound(at: URL)
		/// Case when an In-Memory store is not found
		case inMemoryStoreMissing
		/// Case when the store URL supplied to contruct function cannot be used
		case unableToCreateStore(at: URL)
	}
	
	// MARK: - Lifecycle
	
	public static func createSQLiteStack(modelName: String,
										 in bundle: Bundle = Bundle.main,
										 at desiredStoreURL: URL? = nil,
										 persistentStoreOptions: [AnyHashable : Any]? = NSPersistentStoreCoordinator.stockSQLiteStoreOptions,
										 on callbackQueue: DispatchQueue? = nil,
										 callback: @escaping SetupCallback) {
		
		let model = bundle.managedObjectModel(name: modelName)
		SRCoreDataStackManager.managedObjectModel = model
		let storeFileURL = desiredStoreURL ?? URL(string: "\(modelName).sqlite", relativeTo: documentsDirectory!)!
		
		print("Store URL : \(storeFileURL)")
		SRCoreDataStackManager.dataStoreURL = storeFileURL
		
		var storeMigrationOption : [AnyHashable : Any]?
		
		if self.isMigrationRequired(modelName){
			
			storeMigrationOption = NSPersistentStoreCoordinator.stockSQLiteStoreMigrationOptions
			SRCoreDataStackManager.isMigrationTrue = true
			
		}else{
			
			storeMigrationOption = persistentStoreOptions
			SRCoreDataStackManager.isMigrationTrue = false
		}
		
		
		self.constructSQLiteStack(model: model, at: storeFileURL, persistentStoreOptions: storeMigrationOption, on: callbackQueue, callback: callback)
	}
	

	public static func constructSQLiteStack(model: NSManagedObjectModel,
											at desiredStoreURL: URL? = nil,
											persistentStoreOptions: [AnyHashable : Any]? = NSPersistentStoreCoordinator.stockSQLiteStoreOptions,
											on callbackQueue: DispatchQueue? = nil,
											callback: @escaping SetupCallback) {
		
		let storeFileURL = desiredStoreURL ?? URL(string: "\(DBStore.dataStoreName).sqlite", relativeTo: documentsDirectory!)!
		
		do {
			try createDirectoryIfNecessary(storeFileURL)
		} catch {
			callback(.failure(Error.unableToCreateStore(at: storeFileURL)))
			return
		}
		
		let backgroundQueue = DispatchQueue.global(qos: .background)
		let callbackQueue: DispatchQueue = callbackQueue ?? backgroundQueue
		NSPersistentStoreCoordinator.setUpSQLiteContainer(model,storeFileURL: storeFileURL,persistentStoreOptions: persistentStoreOptions as? [String : Any]) { contanierResult in
				switch contanierResult {
				case .success(let container):
					let stack = SRCoreDataStackManager(model:model,
													   persistentStoreContainer: container,
												storeType: .sqLite(storeURL: storeFileURL),storeURL:storeFileURL)
					callbackQueue.async {
						callback(.success(stack))
					}
				case .failure(let error):
					callbackQueue.async {
						callback(.failure(error))
					}
				}
		}
	}
	
	private static func createDirectoryIfNecessary(_ url: URL) throws {
		let fileManager = FileManager.default
		let directory = url.deletingLastPathComponent()
		try fileManager.createDirectory(at: directory, withIntermediateDirectories: true, attributes: nil)
	}
	
	// MARK: - Private Implementation
	
	fileprivate enum StoreType {
		case inMemory
		case sqLite(storeURL: URL)
	}
	
	fileprivate let storeType: StoreType
	var persistentContainer: NSPersistentContainer!
	
	fileprivate var persistentStoreContainer: NSPersistentContainer {
		didSet {
			privateQueueContext = constructPersistingContext()
			privateQueueContext.persistentStoreCoordinator = persistentStoreContainer.persistentStoreCoordinator
			mainQueueContext = constructMainQueueContext()
			
		}
	}
	
	
	private convenience init(modelName: String, bundle: Bundle, persistentStoreCoordinator: NSPersistentContainer, storeType: StoreType,storeUrl : URL?) {
		
		let model = bundle.managedObjectModel(name: modelName)
		self.init(model:model, persistentStoreContainer: persistentStoreCoordinator, storeType:storeType,storeURL:storeUrl)
		
	}
	
	private  convenience init(model: NSManagedObjectModel, persistentStoreContainer: NSPersistentContainer, storeType: StoreType,storeURL : URL? = nil) {
		
		self.init(storeType: storeType, container: persistentStoreContainer)
		
		SRCoreDataStackManager.managedObjectModel = model
		SRCoreDataStackManager.dataStoreURL = storeURL
		
		privateQueueContext.persistentStoreCoordinator = self.persistentStoreContainer.persistentStoreCoordinator
	}

	private  init(storeType : StoreType , container : NSPersistentContainer) {
		self.storeType = storeType
		self.persistentStoreContainer = container
		super.init()

	}
	
	// MARK: - Core Data stack
//	lazy var persistentContainer: NSPersistentContainer! = {
//		let persistentContainer = NSPersistentContainer(name: DBStore.dataStoreName)
//		let description = persistentContainer.persistentStoreDescriptions.first
//		print("\(String(describing: description))")
//				
//		return persistentContainer
//	}()
	
	//MARK:- Background ManageObjectContext
	/*lazy var backgroundContext: NSManagedObjectContext = {
		let context = self.persistentContainer.newBackgroundContext()
		context.mergePolicy = NSMergePolicy(merge: .mergeByPropertyStoreTrumpMergePolicyType)
		context.parent = self.persistentContainer.viewContext
		
		NotificationCenter.default.addObserver(self,selector: #selector(SRCoreDataStackManager.stackMemberContextDidSaveNotification(_:)), name: NSNotification.Name.NSManagedObjectContextDidSave, object: context)
		
		return context
	}()*/
	
	//MARK:- Main ManageObjectContext

//	lazy var mainContext: NSManagedObjectContext = {
//		let context = self.persistentContainer.viewContext
//		context.automaticallyMergesChangesFromParent = true
//
//		return context
//	}()
	
	/**
	Primary persisting background managed object context. This is the top level context that possess an
	`NSPersistentStoreCoordinator` and saves changes to disk on a background queue.
	
	Fetching, Inserting, Deleting or Updating managed objects should occur on a child of this context rather than directly.
	
	note: `NSBatchUpdateRequest` and `NSAsynchronousFetchRequest` require a context with a persistent store connected directly.
	*/
	public private(set) lazy var privateQueueContext: NSManagedObjectContext = {
		return self.constructPersistingContext()
	}()
	private func constructPersistingContext() -> NSManagedObjectContext {
		let managedObjectContext = self.persistentContainer.newBackgroundContext()
		managedObjectContext.mergePolicy = NSMergePolicy(merge: .mergeByPropertyStoreTrumpMergePolicyType)
		managedObjectContext.name = "Primary Private Queue Context (Persisting Context)"
		return managedObjectContext
	}
	
	/**
	The main queue context for any work that will be performed on the main queue.
	Its parent context is the primary private queue context that persist the data to disk.
	Making a `save()` call on this context will automatically trigger a save on its parent via `NSNotification`.
	*/
	public private(set) lazy var mainQueueContext: NSManagedObjectContext = {
		return self.constructMainQueueContext()
	}()
	private func constructMainQueueContext() -> NSManagedObjectContext {
		var managedObjectContext: NSManagedObjectContext!
		let setup: () -> Void = {
			managedObjectContext = self.persistentContainer.viewContext
			managedObjectContext.mergePolicy = NSMergePolicy(merge: .mergeByPropertyStoreTrumpMergePolicyType)
			managedObjectContext.parent = self.privateQueueContext
			
			NotificationCenter.default.addObserver(self,
												   selector: #selector(SRCoreDataStackManager.stackMemberContextDidSaveNotification(_:)),
												   name: NSNotification.Name.NSManagedObjectContextDidSave,
												   object: managedObjectContext)
		}
		// Always create the main-queue ManagedObjectContext on the main queue.
		if !Thread.isMainThread {
			DispatchQueue.main.sync {
				setup()
			}
		} else {
			setup()
		}
		return managedObjectContext
	}
	
	
	// MARK: - SetUp
	/*func setup(completion: @escaping (_ stack : SRCoreDataStackManager) -> Void) {
		loadPersistentStore { stackObject in
			completion(stackObject)
		}
	}
	
	// MARK: - Loading
	private func loadPersistentStore(completion: @escaping (_ stack : SRCoreDataStackManager) -> Void) {
		migrateStoreIfNeeded {
			self.persistentContainer.loadPersistentStores { description, error in
				guard error == nil else {
					fatalError("was unable to load store \(error!)")
				}
				
				completion(self)
			}
		}
	}
	
	private func migrateStoreIfNeeded(completion: @escaping () -> Void) {
		guard let storeURL = persistentContainer.persistentStoreDescriptions.first?.url else {
			fatalError("persistentContainer was not set up properly")
		}
		
		print("\(storeURL)")
		
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
	}*/
	
	deinit {
		NotificationCenter.default.removeObserver(self)
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
	
	/// Result containing either an instance of `NSPersistentStoreCoordinator` or `ErrorType`
	public enum CoordinatorResult {
		/// A success case with associated `NSPersistentStoreCoordinator` instance
		//case success(NSPersistentStoreCoordinator)
		case success(NSPersistentContainer)
		/// A failure case with associated `ErrorType` instance
		case failure(Swift.Error)
	}
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
	public typealias ResetResult = SuccessResult

}

fileprivate extension SRCoreDataStackManager {
	
	@objc fileprivate func stackMemberContextDidSaveNotification(_ notification: Notification) {
		guard let notificationMOC = notification.object as? NSManagedObjectContext else {
			assertionFailure("Notification posted from an object other than an NSManagedObjectContext")
			return
		}
		guard let parentContext = notificationMOC.parent else {
			return
		}
		
		saveBubbleDispatchGroup.enter()
		parentContext.saveContext() { _ in
			self.saveBubbleDispatchGroup.leave()
		}
	}
	
}
fileprivate extension SRCoreDataStackManager {
	fileprivate static var documentsDirectory: URL? {
		let urls = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
		return urls.first
	}
}


public extension SRCoreDataStackManager {
	/**
	Returns a new `NSManagedObjectContext` as a child of the main queue context.
	
	Calling `save()` on this managed object context will automatically trigger a save on its parent context via `NSNotification` observing.
	
	- parameter type: The NSManagedObjectContextConcurrencyType of the new context.
	**Note** this function will trap on a preconditionFailure if you attempt to create a MainQueueConcurrencyType context from a background thread.
	Default value is .PrivateQueueConcurrencyType
	- parameter name: A name for the new context for debugging purposes. Defaults to *Main Queue Context Child*
	
	- returns: `NSManagedObjectContext` The new worker context.
	*/
	public func newChildContext(type: NSManagedObjectContextConcurrencyType = .privateQueueConcurrencyType,
								name: String? = "Main Queue Context Child") -> NSManagedObjectContext {
		if type == .mainQueueConcurrencyType && !Thread.isMainThread {
			preconditionFailure("Main thread MOCs must be created on the main thread")
		}
		
		let moc = self.persistentContainer.newBackgroundContext()
		moc.mergePolicy = NSMergePolicy(merge: .mergeByPropertyStoreTrumpMergePolicyType)
		moc.parent = mainQueueContext
		moc.name = name
		
		NotificationCenter.default.addObserver(self,
											   selector: #selector(stackMemberContextDidSaveNotification(_:)),
											   name: NSNotification.Name.NSManagedObjectContextDidSave,
											   object: moc)
		return moc
	}
	
}


public  extension  SRCoreDataStackManager{
	
	//MARK:-------- computed property in swift extension-----------
	static var  stackObjectModel : NSManagedObjectModel {
		get{
			return  managedObjectModel!
		}
		set{
			if managedObjectModel != newValue{
				managedObjectModel = newValue
			}
		}
	}
	
	static var  sourceURL : URL {
		
		let storeFileURL = SRCoreDataStackManager.dataStoreURL!
		
		return  storeFileURL
		
	}
	
	
	//MARK:---------Check Migation is Needed or not--------
	public static func  isMigrationRequired(_ modelName : String) -> Bool{
		
		// Check if we need to migrate
		var sourceMetaData : [String : Any]?
		
		do{
			
			sourceMetaData = try NSPersistentStoreCoordinator.metadataForPersistentStore(ofType: NSSQLiteStoreType , at: sourceURL)
			
		}catch let error as NSError{
			
			print("\(error)")
			return false
		}
		
		var  destinationModel : NSManagedObjectModel {
			
			return stackObjectModel
			
		}
		
		var  isMigrationNeeded : Bool = false
		
		if let metaData = sourceMetaData {
			
			// Migration is needed if destinationModel is NOT compatible
			let success = destinationModel.isConfiguration(withName: nil, compatibleWithStoreMetadata: metaData)
			
			
			if success {
				
				isMigrationNeeded = false
			}else{
				
				isMigrationNeeded = true
				
			}
			
		}
		
		return  isMigrationNeeded
	}
	
}
