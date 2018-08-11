//
//  UserDB+CoreDataProperties.swift
//  SRCoreDataLayer
//
//  Created by Subhr Roy on 11/08/18.
//  Copyright © 2018 Subhr Roy. All rights reserved.
//
//

import Foundation
import CoreData


extension UserDB {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<UserDB> {
        return NSFetchRequest<UserDB>(entityName: "UserDB")
    }

    @NSManaged public var userID: String?
    @NSManaged public var userEmail: Int64
    @NSManaged public var zipCode: Int64

}
