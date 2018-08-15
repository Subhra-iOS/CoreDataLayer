//
//  SRCoreDataMigrationPolicy.swift
//  SRCoreDataLayer
//
//  Created by Subhr Roy on 15/08/18.
//  Copyright © 2018 Subhr Roy. All rights reserved.
//

import CoreData

class SRCoreDataMigrationPolicy : NSEntityMigrationPolicy{
	
	func convertZipCodeToString(_ zipCode : NSNumber) -> String {
		
		return  String(format: "%@", arguments: [zipCode])
		
	}
	
}
