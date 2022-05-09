//
//  StorageProvider.swift
//
//
//  Created by Kai on 2022/5/8.
//

import CoreData
import Foundation

public class StorageProvider {
    public lazy var persistentContainer = makeContainer()

    var objectModel: NSManagedObjectModel?
    let modelName: String
    let databaseName: String
    let appGroupIdentifier: String
    var iCloudEnabled: Bool
    let iCloudContainerIdentifier: String?
    
    public init(modelName: String,
                databaseName: String,
                appGroupIdentifier: String,
                iCloudEnabled: Bool,
                iCloudContainerIdentifier: String? = nil,
                objectModel: NSManagedObjectModel? = nil) {
        self.databaseName = databaseName
        self.modelName = modelName
        self.appGroupIdentifier = appGroupIdentifier
        self.objectModel = objectModel
        self.iCloudEnabled = iCloudEnabled
        self.iCloudContainerIdentifier = iCloudContainerIdentifier
    }
}

public extension StorageProvider {
    func iCloudToggle(iCloudEnabled: Bool) {
        self.iCloudEnabled = iCloudEnabled
        persistentContainer = makeContainer()
    }
}

extension StorageProvider {
    var cloudKitOptions: NSPersistentCloudKitContainerOptions? {
        guard let identifier = iCloudContainerIdentifier else {
            return nil
        }
        
        return NSPersistentCloudKitContainerOptions(containerIdentifier: identifier)
    }
    
    func makeStoreDescription() -> NSPersistentStoreDescription {
        let storeURL = URL.storeURL(for: appGroupIdentifier, databaseName: databaseName)
        let storeDescription = NSPersistentStoreDescription(url: storeURL)
        
        storeDescription.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
        storeDescription.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
        
        return storeDescription
    }
    
    func makeContainer() -> NSPersistentContainer {
        let persistentContainer: NSPersistentCloudKitContainer
        
        if let model = objectModel {
            persistentContainer = NSPersistentCloudKitContainer(name: modelName, managedObjectModel: model)
        } else {
            persistentContainer = NSPersistentCloudKitContainer(name: modelName)
        }
        
        let storeDescription = makeStoreDescription()
        storeDescription.cloudKitContainerOptions = iCloudEnabled ? cloudKitOptions : nil
        
        persistentContainer.persistentStoreDescriptions = [storeDescription]
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

extension URL {
    static func storeURL(for appGroup: String, databaseName: String) -> URL {
        guard let fileContainer = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroup) else {
            fatalError("Shared file container could not be created.")
        }

        return fileContainer.appendingPathComponent("\(databaseName).sqlite")
    }
}
