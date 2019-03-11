//
//  NSManagedObjectContext+Utility.swift
//  CoreDataVersion3
//
//  Created by Subhr Roy on 06/05/17.
//  Copyright © 2017 Subhr Roy. All rights reserved.
//

import Foundation
import CoreData

extension Bundle {
    static private let modelExtension = "momd"
    static private let modelAlternateExtension = "mom"
    /**
     Attempts to return an instance of NSManagedObjectModel for a given name within the bundle.

     - parameter name: The file name of the model without the extension.
     - returns: The NSManagedObjectModel from the bundle with the given name.
     **/
    public func managedObjectModel(name: String) -> NSManagedObjectModel {
        
        /*guard let URL = url(forResource: name, withExtension: Bundle.modelExtension),
            let model = NSManagedObjectModel(contentsOf: URL) else {
                preconditionFailure("Model not found or corrupted with name: \(name) in bundle: \(self)")
        }
        return model*/
        
        var momPath : String? = Bundle.main.path(forResource: name, ofType: Bundle.modelExtension) ?? ""
        
        if let _ =  momPath {
            
        }else{
            
            momPath = Bundle.main.path(forResource: name, ofType: Bundle.modelAlternateExtension)!
            
        }
        
        let url : URL = URL(fileURLWithPath: momPath ?? "")
        
        guard let model = NSManagedObjectModel(contentsOf: url) else {
            
            preconditionFailure("Model not found or corrupted with name: \(name) in bundle: \(self)")
            
        }
        
        return model
        
    }
}
