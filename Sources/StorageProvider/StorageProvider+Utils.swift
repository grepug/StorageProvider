//
//  StorageProvider+Utils.swift
//  
//
//  Created by Kai on 2022/5/8.
//

import Combine
import Foundation
import CloudKitSyncMonitor

public extension StorageProvider {
    static var shouldUpdateDuring_iCloudSyncing: Bool {
        guard let monitor = SyncMonitor.shared as? SyncMonitorWithCloudKit else {
            return true
        }
        
        guard monitor.isCloudEnabled else {
            return true
        }
        
        return SyncMonitor.shared.syncStateSummary != .inProgress
    }
    
    static var dbChangePublisher: AnyPublisher<Void, Never> {
         NotificationCenter.default
             .publisher(for: .NSManagedObjectContextObjectsDidChange)
             .merge(with: NotificationCenter.default.publisher(for: .NSManagedObjectContextDidSave))
             .filter { _ in shouldUpdateDuring_iCloudSyncing }
             .debounce(for: 0.3, scheduler: RunLoop.current)
             .map { _ in }
             .eraseToAnyPublisher()
     }
}
