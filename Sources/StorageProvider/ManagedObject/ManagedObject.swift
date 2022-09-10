//
//  File.swift
//  
//
//  Created by Kai on 2022/5/8.
//

import CoreData
import SwiftUI

public protocol SimpleManagedObject: NSManagedObject {
    var id: UUID? { get set }
    var createdAt: Date? { get set }
    var updatedAt: Date? { get set }
    
    static var viewContext: NSManagedObjectContext { get }
    static func newBackgroundContext() -> NSManagedObjectContext
}

public protocol ManagedObject: SimpleManagedObject {
    var createdBuild: Int32 { get set }
    var updatedBuild: Int32 { get set }
}

public protocol Unwrappable {
    static var defaultValue: Self { get }
}

extension Date: Unwrappable {
    public static var defaultValue: Date { .init() }
}

extension String: Unwrappable {
    public static var defaultValue: String { "" }
}

extension UUID: Unwrappable {
    public static var defaultValue: UUID { .init() }
}

public extension SimpleManagedObject {
    subscript<T: Unwrappable>(_ keyPath: ReferenceWritableKeyPath<Self, T?>) -> T {
        get {
            self[keyPath: keyPath] ?? T.defaultValue
        }
        
        set {
            self[keyPath: keyPath] = newValue
        }
    }
}

public extension Binding where Value == Optional<Unwrappable> {
    func unwrapped<T: Unwrappable>(defaultsTo defaultValue: T? = nil) -> Binding<Unwrappable> {
        .init {
            wrappedValue ?? defaultValue ?? T.defaultValue
        } set: { newValue in
            wrappedValue = newValue
        }

    }
}
