//
//  StorageProvider.swift
//
//
//  Created by Kai on 2022/5/8.
//

import CoreData
import Foundation

public class StorageProvider {
    public init(storeDescriptionConfigurations: [StoreDescriptionConfiguration], objectModel: NSManagedObjectModel? = nil, modelName: String, iCloudEnabled: Bool) {
        self.storeDescriptionConfigurations = storeDescriptionConfigurations
        self.objectModel = objectModel
        self.modelName = modelName
        self.iCloudEnabled = iCloudEnabled
        self.persistentContainer = Self.makeContainer(objectModel: objectModel,
                                                      modelName: modelName,
                                                      storeDescriptionConfigurations: storeDescriptionConfigurations,
                                                      iCloudEnabled: iCloudEnabled)
    }
    
    public var persistentContainer: NSPersistentContainer

    let storeDescriptionConfigurations: [StoreDescriptionConfiguration]
    var objectModel: NSManagedObjectModel?
    let modelName: String
    var iCloudEnabled: Bool
}

public extension StorageProvider {
    func iCloudToggle(iCloudEnabled: Bool) {
        self.iCloudEnabled = iCloudEnabled
        persistentContainer = Self.makeContainer(objectModel: objectModel, modelName: modelName, storeDescriptionConfigurations: storeDescriptionConfigurations, iCloudEnabled: iCloudEnabled) { [weak self] objectModel in
            self?.objectModel = objectModel
        }
    }
}

extension StorageProvider {
    static func makeContainer(objectModel: NSManagedObjectModel?, modelName: String, storeDescriptionConfigurations: [StoreDescriptionConfiguration], iCloudEnabled: Bool, completion: ((NSManagedObjectModel) -> Void)? = nil) -> NSPersistentContainer {
        let persistentContainer: NSPersistentCloudKitContainer
        
        if let model = objectModel {
            persistentContainer = NSPersistentCloudKitContainer(name: modelName, managedObjectModel: model)
        } else {
            persistentContainer = NSPersistentCloudKitContainer(name: modelName)
        }
        
        let storeDescriptions: [NSPersistentStoreDescription] = storeDescriptionConfigurations.map {
            $0.storeDescription(iCloudEnabled: iCloudEnabled)
        }
        
        persistentContainer.persistentStoreDescriptions = storeDescriptions
        persistentContainer.loadPersistentStores { description, error in
            if let error = error {
                fatalError("Core Data store failed to load with error: \(error)")
            }
            
            print(description)
            persistentContainer.viewContext.automaticallyMergesChangesFromParent = true
            completion?(persistentContainer.managedObjectModel)
        }
        
        return persistentContainer
    }
}

public extension StorageProvider {
    func clearStorage() {
        let entities = persistentContainer.managedObjectModel.entities
        
        for entity in entities {
            if let name = entity.name {
                let fetch = NSFetchRequest<NSFetchRequestResult>(entityName: name)
                let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetch)
                
                do {
                    try persistentContainer.viewContext.execute(deleteRequest)
                    try persistentContainer.viewContext.save()
                } catch  {
                    print("error!!!")
                }
            }
        }
    }
}
