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
        
        return obj
    }
}

public extension ManagedObject {
    @available(iOS 15.0, macOS 15.0, *)
    static func fetch(where predicate: NSPredicate?,
                      sortedBy sortDescriptors: [NSSortDescriptor]?,
                      fetchLimit: Int?,
                      context: NSManagedObjectContext?) async -> [Self] {
        let context = context ?? Self.viewContext
        
        let results = try? await context.perform(schedule: .enqueued) { () -> [Self] in
            let request = Self.fetchRequest()
            request.predicate = predicate
            request.sortDescriptors = sortDescriptors ?? [.updated, .created]
            
            if let fetchLimit = fetchLimit {
                request.fetchLimit = fetchLimit
            }
            
            request.resultType = .managedObjectResultType
            
            return try request.execute() as! [Self]
        }
        
        return results ?? []
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


public enum DidChangeType {
    case deletion, insertion, update
    
    var key: String {
        switch self {
        case .deletion: return NSDeletedObjectsKey
        case .insertion: return NSInsertedObjectsKey
        case .update: return NSUpdatedObjectsKey
        }
    }
}

public extension ManagedObject {
    static func didChangePublisher(_ type: DidChangeType) -> AnyPublisher<Set<Self>, Never> {
        NotificationCenter.default
            .publisher(for: NSNotification.Name.NSManagedObjectContextObjectsDidChange)
            .compactMap { notification -> Set<Self>? in
                guard let userInfo = notification.userInfo else {
                    return nil
                }
                
                guard let objects = userInfo[type.key] as? Set<Self>, !objects.isEmpty else {
                    return nil
                }
                
                return objects
            }
            .eraseToAnyPublisher()
    }
}
