//
//  StorageProvider+Utils.swift
//  
//
//  Created by Kai on 2022/5/8.
//

import Combine
import Foundation

public extension StorageProvider {
    static var dbChangePublisher: AnyPublisher<Void, Never> {
         NotificationCenter.default
             .publisher(for: .NSManagedObjectContextObjectsDidChange)
             .merge(with: NotificationCenter.default.publisher(for: .NSManagedObjectContextDidSave))
             .debounce(for: 0.3, scheduler: RunLoop.current)
             .map { _ in }
             .eraseToAnyPublisher()
     }
}
