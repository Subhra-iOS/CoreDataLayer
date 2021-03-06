//
//  NSManagedObjectContext+Utility.swift
//  SRCoreDataLayer
//
//  Created by Subhr Roy on 06/05/17.
//  Copyright © 2017 Subhr Roy. All rights reserved.
//

import CoreData
import Swift

extension NSManagedObjectContext {
    /**
     Synchronously exexcutes a given function on the receiver’s queue.

     You use this method to safely address managed objects on a concurrent
     queue.

     - attention: This method may safely be called reentrantly.
     - parameter body: The method body to perform on the reciever.
     - returns: The value returned from the inner function.
     - throws: Any error thrown by the inner function. This method should be
       technically `rethrows`, but cannot be due to Swift limitations.
    **/
    public func performAndWaitOrThrow<Return>(_ body: () throws -> Return) rethrows -> Return {
        func impl(execute work: () throws -> Return, recover: (Error) throws -> Void) rethrows -> Return {
            var result: Return!
            var error: Error?

            // performAndWait is marked @escaping as of iOS 10.0.
            // swiftlint:disable type_name
            typealias Fn = (() -> Void) -> Void
			let performAndWaitNoescape = self.performAndWait
            performAndWaitNoescape {
                do {
                    result = try work()
                } catch let e {
                    error = e
                }
            }

            if let error = error {
                try recover(error)
            }

            return result
        }

        return try impl(execute: body, recover: { throw $0 })
    }
}
