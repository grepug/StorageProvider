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
    }
    
    public lazy var persistentContainer = makeContainer()

    let storeDescriptionConfigurations: [StoreDescriptionConfiguration]
    var objectModel: NSManagedObjectModel?
    let modelName: String
    var iCloudEnabled: Bool
}

public extension StorageProvider {
    func iCloudToggle(iCloudEnabled: Bool) {
        self.iCloudEnabled = iCloudEnabled
        persistentContainer = makeContainer()
    }
}

extension StorageProvider {
    func makeContainer() -> NSPersistentContainer {
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
        persistentContainer.loadPersistentStores { [weak self] description, error in
            if let error = error {
                fatalError("Core Data store failed to load with error: \(error)")
            }
            
            print(description)
            persistentContainer.viewContext.automaticallyMergesChangesFromParent = true
            self?.objectModel = persistentContainer.managedObjectModel
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
