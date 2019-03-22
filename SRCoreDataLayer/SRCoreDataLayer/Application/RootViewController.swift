//
//  RootViewController.swift
//  SRCoreDataLayer
//
//  Created by Subhra Roy on 12/03/19.
//  Copyright © 2019 Subhr Roy. All rights reserved.
//

import UIKit
import CoreData

class RootViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        self.loadData { [weak self] (status) in
            
            if status{
                self?.fetchUserWith("123")
            }
            
        }
        
        /*DispatchQueue.main.asyncAfter(deadline: .now() + 5) { [weak self] in
         
         self?.fetchUserWith("123")
         
         }*/
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    private func loadData( _ block : @escaping ( _ isSave : Bool) -> Void ) -> Void{
        
        let privateContext = SRCoreDataStore.sharedStore.fetchBackgroundContext()
        privateContext.perform {
            
            let userDB : UserDB = UserDB(context: privateContext)
            userDB.userEmail = "subhra@yopmail.com"
            userDB.userID = "123"
            userDB.zipCode = NSNumber(value: Int64("700059")!)
            
            privateContext.saveContextToStore({ result in
                
                print("\(result)")
                block(true)
            })
        }
        
    }
    
    private func fetchUserWith( _ userId : String) -> Void{
        
        let privateContext = SRCoreDataStore.sharedStore.fetchBackgroundContext()
        let predicate : NSPredicate = NSPredicate(format: "userID == %@", argumentArray: [NSNumber(value: Int64(userId)!)])
        let request : NSFetchRequest<UserDB> = UserDB.fetchRequest()
        request.predicate = predicate
        
        do{
            
            let userArray : [UserDB]? = try privateContext.fetch(request)
            if let users = userArray, users.count > 0 {
                let user : UserDB = users.first!
                print("\(String(describing: user.userEmail))")
                print("\(String(describing: user.userID))")
                print("\(String(describing: user.zipCode))")
            }
            
        }catch {
            
            
        }
    }
    
    
}
