//
//  File.swift
//  
//
//  Created by Kai on 2022/5/9.
//

import Foundation
import CoreData
import Combine

public extension ManagedObject {
    static func initWithViewContext(_ context: NSManagedObjectContext? = nil) -> Self {
        let context = context ?? Self.viewContext
        let obj = Self.init(context: context)
        let date = Date()
        obj.id = UUID()
        obj.createdAt = date
        obj.updatedAt = date
        obj.createdBuild = Int32(Self.buildNumber)
        obj.updatedBuild = Int32(Self.buildNumber)
        
        return obj
    }
}

extension ManagedObject {
    static var buildNumberString: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? ""
    }
    
    static var buildNumber: Int {
        Int(Self.buildNumberString) ?? 0
    }
}

public extension ManagedObject {
    static func fetch(where predicate: NSPredicate?,
                      sortedBy sortDescriptors: [NSSortDescriptor]?,
                      fetchLimit: Int?,
                      context: NSManagedObjectContext?) async throws -> [Self] {
        try await withCheckedThrowingContinuation { continuation in
            myFetch(where: predicate, sortedBy: sortDescriptors, fetchLimit: fetchLimit, context: context) { objects, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: objects)
                }
            }
        }
    }
    
    static func fetch(where predicate: NSPredicate? = nil,
                      sortedBy sortDescriptors: [NSSortDescriptor]? = nil,
                      fetchLimit: Int? = nil,
                      context: NSManagedObjectContext? = nil) -> [Self] {
        myFetch(where: predicate,
                sortedBy: sortDescriptors,
                fetchLimit: fetchLimit,
                context: context)
    }
    
    static func fetchPublisher<T>(where predicate: NSPredicate? = nil,
                                  sortedBy sortDescriptors: [NSSortDescriptor]? = nil,
                                  fetchLimit: Int? = nil,
                                  transform: @escaping ([Self]) -> [T]) -> AnyPublisher<[T], Error> {
        Future { promise in
            myFetch(where: predicate,
                    sortedBy: sortDescriptors,
                    fetchLimit: fetchLimit,
                    context: Self.newBackgroundContext()) { objects, error in
                if let error = error {
                    promise(.failure(error))
                } else {
                    let result = transform(objects)
                    promise(.success(result))
                }
            }
        }
        .receive(on: RunLoop.main)
        .eraseToAnyPublisher()
    }
    
    static func fetchCount(where predicate: NSPredicate? = nil,
                           context: NSManagedObjectContext? = nil) -> Int {
        let context = context ?? Self.viewContext
        let request = Self.fetchRequest()
        request.predicate = predicate
        
        return (try? context.count(for: request)) ?? 0
    }
    
    static func fetchCountPublisher(where predicate: NSPredicate? = nil) -> AnyPublisher<Int, Error> {
        Future { promise in
            let context = Self.newBackgroundContext()
            
            context.perform {
                let request = Self.fetchRequest()
                
                request.predicate = predicate
                
                do {
                    let count = try context.count(for: request)
                    
                    promise(.success(count))
                } catch {
                    promise(.failure(error))
                }
            }
        }
        .receive(on: RunLoop.main)
        .eraseToAnyPublisher()
    }
    
    static func fetch(byId id: UUID, context: NSManagedObjectContext? = nil) -> Self? {
        Self.fetch(where: .init(format: "id == %@", id as CVarArg),
                   context: context ?? Self.viewContext).first
    }
}

extension ManagedObject {
    static func myFetch(where predicate: NSPredicate? = nil,
                        sortedBy sortDescriptors: [NSSortDescriptor]? = nil,
                        fetchLimit: Int? = nil,
                        context: NSManagedObjectContext?,
                        completion: @escaping (([Self], Error?) -> Void)) {
        let context = context ?? Self.viewContext
        let request = Self.fetchRequest()
        request.predicate = predicate
        request.sortDescriptors = sortDescriptors ?? [.updated, .created]
        
        if let fetchLimit = fetchLimit {
            request.fetchLimit = fetchLimit
        }
        
        context.perform {
            do {
                let items = try context.fetch(request) as! [Self]
                completion(items, nil)
            } catch {
                completion([], error)
            }
        }
    }
    
    static func myFetch(where predicate: NSPredicate? = nil,
                        sortedBy sortDescriptors: [NSSortDescriptor]? = nil,
                        fetchLimit: Int? = nil,
                        context: NSManagedObjectContext?) -> [Self] {
        let context = context ?? Self.viewContext
        let request = Self.fetchRequest()
        request.predicate = predicate
        request.sortDescriptors = sortDescriptors ?? [.updated, .created]
        
        if let fetchLimit = fetchLimit {
            request.fetchLimit = fetchLimit
        }
        
        do {
            let items = try context.fetch(request) as! [Self]
            return items
        } catch {
            return []
        }
    }
}

public extension ManagedObject {
    func delete() {
        let context = Self.viewContext
        context.delete(self)
        save()
    }
    
    func save() {
        let context = Self.viewContext
        objectWillChange.send()
        
        do {
            try context.save()
        } catch {
            context.rollback()
        }
    }
}

public extension Array where Element: ManagedObject {
    func deleteAll() {
        guard let context = first?.managedObjectContext else {
            return
        }
        
        do {
            let objectIDs = map(\.objectID)
            let deleteRequest = NSBatchDeleteRequest(objectIDs: objectIDs)
            let deleteResult = try context.execute(deleteRequest) as? NSBatchDeleteResult
            
            // Extract the IDs of the deleted managed objectss from the request's result.
            if let objectIDs = deleteResult?.result as? [NSManagedObjectID] {
                
                // Merge the deletions into the app's managed object context.
                NSManagedObjectContext.mergeChanges(
                    fromRemoteContextSave: [NSDeletedObjectsKey: objectIDs],
                    into: [context]
                )
            }
        } catch {
            context.rollback()
        }
    }
}

public extension NSSortDescriptor {
    static var updated: NSSortDescriptor {
        NSSortDescriptor(key: "updatedAt", ascending: false)
    }
    
    static var created: NSSortDescriptor {
        NSSortDescriptor(key: "createdAt", ascending: false)
    }
    
    static var ordered: NSSortDescriptor {
        NSSortDescriptor(key: "order", ascending: true)
    }
}

public extension Optional where Wrapped == NSSet {
    var count: Int {
        self?.count ?? 0
    }
}

public enum ChangeType {
    case insertion, deletion, update
}

public struct ChangeResult<Object: ManagedObject> {
    public var deletions: Set<Object>?
    public var insertions: Set<Object>?
    public var updates: Set<Object>?
    
    public var hasChanges: Bool {
        deletions != nil ||
        insertions != nil ||
        updates != nil
    }
    
    public var union: Set<Object> {
        deletions?.union(insertions?.union(updates ?? []) ?? []) ?? []
    }
    
    public func changeType(of object: Object) -> ChangeType? {
        if let deletions = deletions, deletions.contains(object) {
            return .deletion
        }
        
        if let insertions = insertions, insertions.contains(object) {
            return .insertion
        }
        
        if let updates = updates, updates.contains(object) {
            return .update
        }
        
        return nil
    }
}

public extension ManagedObject {
    static var didChangePublisher: AnyPublisher<ChangeResult<Self>, Never> {
        NotificationCenter.default
            .publisher(for: NSManagedObjectContext.didChangeObjectsNotification)
            .compactMap { notification -> ChangeResult<Self>? in
                guard let userInfo = notification.userInfo else {
                    return nil
                }
                
                var result = ChangeResult<Self>()
                
                if let objects = userInfo[NSDeletedObjectsKey] as? Set<Self>, !objects.isEmpty {
                    result.deletions = objects
                }
                
                if let objects = userInfo[NSInsertedObjectsKey] as? Set<Self>, !objects.isEmpty {
                    result.insertions = objects
                }
                
                if let objects = userInfo[NSUpdatedObjectsKey] as? Set<Self>, !objects.isEmpty {
                    result.updates = objects
                }
                
                guard result.hasChanges else {
                    return nil
                }
                
                return result
            }
            .eraseToAnyPublisher()
    }
    
    
}
