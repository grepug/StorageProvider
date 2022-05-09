//
//  File.swift
//  
//
//  Created by Kai on 2022/5/8.
//

import CoreData

public protocol ManagedObject: NSManagedObject {
    var id: UUID? { get set }
    var createdAt: Date? { get set }
    var updatedAt: Date? { get set }
    
    static var viewContext: NSManagedObjectContext { get }
    static func newBackgroundContext() -> NSManagedObjectContext
}
