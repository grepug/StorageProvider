//
//  File.swift
//  
//
//  Created by Kai Shao on 2022/10/7.
//

import CoreData

public extension NSManagedObjectContext {
    func perform<T>(handler: @escaping () throws -> T) async throws -> T {
        try await withCheckedThrowingContinuation { continuation in
            self.perform {
                do {
                    let result = try handler()
                    
                    continuation.resume(returning: result)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}
