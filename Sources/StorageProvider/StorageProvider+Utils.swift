//
//  StorageProvider+Utils.swift
//  
//
//  Created by Kai on 2022/5/8.
//

import Foundation
import CoreData
import Combine

public extension ManagedObject {
    static func initWithViewContext(_ context: NSManagedObjectContext?) -> Self {
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
    @available(iOS 15.0, *)
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
                      context: NSManagedObjectContext?) -> [Self] {
        myFetch(where: predicate,
                sortedBy: sortDescriptors,
                fetchLimit: fetchLimit,
                context: context,
                completion: nil)
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
    @discardableResult
    static func myFetch(where predicate: NSPredicate? = nil,
                      sortedBy sortDescriptors: [NSSortDescriptor]? = nil,
                      fetchLimit: Int? = nil,
                      context: NSManagedObjectContext?,
                      completion: (([Self], Error?) -> Void)?) -> [Self] {
        let context = context ?? Self.viewContext
        let request = Self.fetchRequest()
        request.predicate = predicate
        request.sortDescriptors = sortDescriptors ?? [.updated, .created]
        
        if let fetchLimit = fetchLimit {
            request.fetchLimit = fetchLimit
        }
        
        do {
            let items = try context.fetch(request) as! [Self]
            completion?(items, nil)
            return items
        } catch {
            completion?([], error)
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

extension NSSortDescriptor {
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

extension Optional where Wrapped == NSSet {
    var count: Int {
        self?.count ?? 0
    }
}
