//
//  SRCoreDataStore.swift
//  SRCoreDataLayer
//
//  Created by Subhr Roy on 15/08/18.
//  Copyright © 2018 Subhr Roy. All rights reserved.
//

import Foundation
import UIKit
import CoreData

public struct DBStore{
	static let  dataStoreName = "SRCoreDataLayer"
	
}

public class SRCoreDataStore : NSObject {
	
	private var dataStack : SRCoreDataStackManager!
	
	static let sharedStore : SRCoreDataStore = SRCoreDataStore()
	
	override private init() {
		
	}
	
	public func setDataStack(stack : SRCoreDataStackManager) -> Void{
		self.dataStack = stack
	}
	
	public func getDataStack() -> SRCoreDataStackManager?{
		return  self.dataStack
	}
	
	public func fetchMainContext() -> NSManagedObjectContext{
		print("\(String(describing: self.dataStack))")
		return self.dataStack.mainQueueContext
	}
	
	public func fetchBackgroundContext() -> NSManagedObjectContext{
        print("\(String(describing: self.dataStack))")
		return self.dataStack.newChildContext()
	}
	//MARK:----------Migration-----------
	public  func migrate(_ error : inout NSError?) -> Bool {
		
		// Enable migrations to run even while user exits app
		var  bgTask : UIBackgroundTaskIdentifier?
		let application : UIApplication = UIApplication.shared
		
		bgTask = application.beginBackgroundTask {
			
			application.endBackgroundTask(bgTask!)
			bgTask = UIBackgroundTaskIdentifier(rawValue: convertFromUIBackgroundTaskIdentifier(UIBackgroundTaskIdentifier.invalid))
			
		}
		
		let migrationManager = SRMigrationManager()
		migrationManager.migrationDelegate = self as? SRMigrationManagerDelegate
		
		let isSucceed : Bool = try! migrationManager.progressivelyMigrateURL(sourceStoreURL: SRCoreDataStackManager.dataStoreURL!, ofType: NSSQLiteStoreType, to: SRCoreDataStackManager.stackObjectModel)
		
		application.endBackgroundTask(bgTask!)
		bgTask = UIBackgroundTaskIdentifier(rawValue: convertFromUIBackgroundTaskIdentifier(UIBackgroundTaskIdentifier.invalid))
		
		return  isSucceed
		
	}
	
	//MARK:---------Migration Delegate----------
	func  migrationManager(migrationManager : SRMigrationManager , migrationProgress : Float) -> Void {
		
		print("Migration Progress Value : \(migrationProgress)")
		
	}
	
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromUIBackgroundTaskIdentifier(_ input: UIBackgroundTaskIdentifier) -> Int {
	return input.rawValue
}
