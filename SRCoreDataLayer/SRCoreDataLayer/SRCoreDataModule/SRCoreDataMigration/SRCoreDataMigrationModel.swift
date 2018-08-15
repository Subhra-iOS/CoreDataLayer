//
//  SRCoreDataMigrationModel.swift
//  SRCoreDataLayer
//
//  Created by Subhr Roy on 11/08/18.
//  Copyright © 2018 Subhr Roy. All rights reserved.
//

import Foundation
import CoreData

enum SRCoreDataVersion: Int {
    case version1 = 1
    case version2
    case version3
    case version4
    
    // MARK: - Accessors
    
    var name: String {
        if rawValue == 1 {
            return "SRCoreDataLayer"
        } else {
            return "SRCoreDataLayer_V\(rawValue)"
        }
    }
    
    static var all: [SRCoreDataVersion] {
        var versions = [SRCoreDataVersion]()
        
        for rawVersionValue in 1...1000 { // A bit of a hack here to avoid manual mapping
            if let version = SRCoreDataVersion(rawValue: rawVersionValue) {
                versions.append(version)
                continue
            }
            
            break
        }
        
        return versions.reversed()
    }
    
    static var latest: SRCoreDataVersion {
        return all.first!
    }
}

class SRCoreDataMigrationModel {
    
    let version: SRCoreDataVersion
    
    var modelBundle: Bundle {
        return Bundle.main
    }
    
    var modelDirectoryName: String {
        return "SRCoreDataLayer.momd"
    }
    
    static var all: [SRCoreDataMigrationModel] {
        var migrationModels = [SRCoreDataMigrationModel]()
        
        for version in SRCoreDataVersion.all {
            migrationModels.append(SRCoreDataMigrationModel(version: version))
        }
        
        return migrationModels
    }
    
    static var current: SRCoreDataMigrationModel {
        return SRCoreDataMigrationModel(version: SRCoreDataVersion.latest)
    }
    
    /**
     Determines the next model version from the current model version.
     
     NB: the next version migration is not always the next actual version. With
     this solution we can skip "bad/corrupted" versions.
     */
    var successor: SRCoreDataMigrationModel? {
        switch self.version {
        case .version1:
            return SRCoreDataMigrationModel(version: .version2)
        case .version2:
            return SRCoreDataMigrationModel(version: .version3)
        case .version3:
            return SRCoreDataMigrationModel(version: .version4)
        case .version4:
            return nil
        }
    }
    
    // MARK: - Init
    
    init(version: SRCoreDataVersion) {
        self.version = version
    }
    
    // MARK: - Model
    
    func managedObjectModel() -> NSManagedObjectModel {
        let omoURL = modelBundle.url(forResource: version.name, withExtension: "omo", subdirectory: modelDirectoryName) // optimized model file
        let momURL = modelBundle.url(forResource: version.name, withExtension: "mom", subdirectory: modelDirectoryName)
        
        guard let url = omoURL ?? momURL else {
            fatalError("unable to find model in bundle")
        }
        
        guard let model = NSManagedObjectModel(contentsOf: url) else {
            fatalError("unable to load model in bundle")
        }
        
        return model
    }
    
    // MARK: - Mapping
    
    func mappingModelToSuccessor() -> NSMappingModel? {
        guard let nextVersion = successor else {
            return nil
        }
        
        switch version {
        case .version1, .version2: //manual mapped versions
            guard let mapping = customMappingModel(to: nextVersion) else {
                return nil
            }
            
            return mapping
        default:
            return inferredMappingModel(to: nextVersion)
        }
    }
    
    func inferredMappingModel(to nextVersion: SRCoreDataMigrationModel) -> NSMappingModel {
        do {
            let sourceModel = managedObjectModel()
            let destinationModel = nextVersion.managedObjectModel()
            return try NSMappingModel.inferredMappingModel(forSourceModel: sourceModel, destinationModel: destinationModel)
        } catch {
            fatalError("unable to generate inferred mapping model")
        }
    }
    
    func customMappingModel(to nextVersion: SRCoreDataMigrationModel) -> NSMappingModel? {
        let sourceModel = managedObjectModel()
        let destinationModel = nextVersion.managedObjectModel()
        guard let mapping = NSMappingModel(from: [modelBundle], forSourceModel: sourceModel, destinationModel: destinationModel) else {
            return nil
        }
        
        return mapping
    }
    
    // MARK: - MigrationSteps
    
    func migrationSteps(to version: SRCoreDataMigrationModel) -> [SRCoreDataMigrationStep] {
        guard self.version != version.version else {
            return []
        }
        
        guard let mapping = mappingModelToSuccessor(), let nextVersion = successor else {
            return []
        }
        
        let sourceModel = managedObjectModel()
        let destinationModel = nextVersion.managedObjectModel()
        
        let step = SRCoreDataMigrationStep(source: sourceModel, destination: destinationModel, mapping: mapping)
        let nextStep = nextVersion.migrationSteps(to: version)
        
        return [step] + nextStep
    }
    
    // MARK: - Metadata
    
    static func migrationModelCompatibleWithStoreMetadata(_ metadata: [String : Any]) -> SRCoreDataMigrationModel? {
        let compatibleMigrationModel = SRCoreDataMigrationModel.all.first {
            $0.managedObjectModel().isConfiguration(withName: nil, compatibleWithStoreMetadata: metadata)
        }
        
        return compatibleMigrationModel
    }
}

// MARK: - Source

class CoreDataMigrationSourceModel: SRCoreDataMigrationModel {
    
    // MARK: - Init
    
    init?(storeURL: URL) {
        guard let metadata = NSPersistentStoreCoordinator.metadata(at: storeURL) else {
            return nil
        }
        
        let migrationVersionModel = SRCoreDataMigrationModel.all.first {
            $0.managedObjectModel().isConfiguration(withName: nil, compatibleWithStoreMetadata: metadata)
        }
        
        guard migrationVersionModel != nil else {
            return nil
        }
        
        super.init(version: migrationVersionModel!.version)
    }
}
