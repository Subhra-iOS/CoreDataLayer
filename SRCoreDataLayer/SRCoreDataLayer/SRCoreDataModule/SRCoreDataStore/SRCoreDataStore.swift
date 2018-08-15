//
//  SRCoreDataStore.swift
//  SRCoreDataLayer
//
//  Created by Subhr Roy on 15/08/18.
//  Copyright © 2018 Subhr Roy. All rights reserved.
//

import Foundation

public class SRCoreDataStore : NSObject {
	
	private var dataStack : SRCoreDataStackManager?
	
	static let sharedStore : SRCoreDataStore = SRCoreDataStore()
	
	override private init() {
		
	}
	
	public func setDataStack(stack : SRCoreDataStackManager) -> Void{
		self.dataStack = stack
	}
	
	public func getDataStack() -> SRCoreDataStackManager?{
		return  self.dataStack
	}
	
	
}
