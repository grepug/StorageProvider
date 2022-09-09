//
//  StoreDescriptionConfiguration.swift
//  
//
//  Created by Kai Shao on 2022/9/9.
//

import CoreData

public struct StoreDescriptionConfiguration {
    public init(url: URLConfiguration, configuration: String? = nil, cloudKitContainerIdentifier: String? = nil) {
        self.url = url
        self.configuration = configuration
        self.cloudKitContainerIdentifier = cloudKitContainerIdentifier
    }
    
    let url: URLConfiguration
    var configuration: String?
    let cloudKitContainerIdentifier: String?
    
    func storeDescription(iCloudEnabled: Bool) -> NSPersistentStoreDescription {
        let description = NSPersistentStoreDescription(url: realURL)
        
        description.configuration = configuration
        description.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
        description.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
        
        if let cloudKitOptions, iCloudEnabled {
            description.cloudKitContainerOptions = cloudKitOptions
        }
        
        return description
    }
}

public extension StoreDescriptionConfiguration {
    enum URLConfiguration {
        case url(URL), appGroup(appGroupIdentifier: String, dataBaseName: String)
    }
}

private extension StoreDescriptionConfiguration {
    private var cloudKitOptions: NSPersistentCloudKitContainerOptions? {
        guard let cloudKitContainerIdentifier else {
            return nil
        }
        
        return .init(containerIdentifier: cloudKitContainerIdentifier)
    }
    
    private var realURL: URL {
        switch url {
        case .url(let url): return url
        case .appGroup(appGroupIdentifier: let appGroup, dataBaseName: let dataBase): return .storeURL(for: appGroup, databaseName: dataBase)
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
