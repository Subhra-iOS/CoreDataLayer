//
//  AppDelegate.swift
//  SRCoreDataLayer
//
//  Created by Subhr Roy on 11/08/18.
//  Copyright © 2018 Subhr Roy. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

	var window: UIWindow?
    var navigationController : UINavigationController?

	func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
		// Override point for customization after application launch.
		
        
        let rootVC : RootViewController = RootViewController(nibName: "RootViewController", bundle: nil)
        self.navigationController = UINavigationController(rootViewController: rootVC)
       self.window = UIWindow(frame: UIScreen.main.bounds)
      self.window?.backgroundColor = UIColor.white
        
		let dataStore : SRCoreDataStore = SRCoreDataStore.sharedStore
		SRCoreDataStackManager.createSQLiteStack(modelName: DBStore.dataStoreName) { [unowned self, weak weakStore = dataStore] result in
			switch result {
                case .success(let stack):
                    
                    print("Success in DataBase Setup \(stack)")
                    
                    weakStore?.setDataStack(stack: stack)
                    
                    var  dbError : NSError?
                    if SRCoreDataStackManager.isMigrationTrue {
                        
                        let success : Bool = weakStore?.migrate(&dbError) ?? false
                        
                        print("Success : \(success)")
                        print("MigrationError : \(String(describing: dbError))")
                        
                    }
                    
                    // Note don't actually use dispatch_after
                    // Arbitrary 2 second delay to illustrate an async setup.
                    // dispatch_async(dispatch_get_main_queue()) {} should be used in production
                    DispatchQueue.main.async { [weak self] in // just for example purposes
                        
                        
                            self?.window?.rootViewController = self?.navigationController
                            self?.window?.makeKeyAndVisible()
                        
                    }
                
                case .failure(let error):
                    assertionFailure("\(error)")
			}
		}
		
		return true
	}

	func applicationWillResignActive(_ application: UIApplication) {
		// Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
		// Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
	}

	func applicationDidEnterBackground(_ application: UIApplication) {
		// Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
		// If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
	}

	func applicationWillEnterForeground(_ application: UIApplication) {
		// Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
	}

	func applicationDidBecomeActive(_ application: UIApplication) {
		// Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
	}

	func applicationWillTerminate(_ application: UIApplication) {
		// Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
		// Saves changes in the application's managed object context before the application terminates.
		 let mainContext = SRCoreDataStore.sharedStore.fetchMainContext()
		mainContext.saveContextToStore()
	}


}

