//
//  File.swift
//  
//
//  Created by Kai on 2022/5/9.
//

import CloudKitSyncMonitor
import Foundation
import CloudKit
import Combine
import os

fileprivate let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "SyncMonitor")

public protocol SyncMonitorWithCloudKit {
    var iCloudAccountStatus: CKAccountStatus? { get }
    
    var isPro: Bool { get }
    var iCloudEnabled: Bool { get }
    func iCloudToggle(iCloudEnabled: Bool)
}

public extension SyncMonitorWithCloudKit {
    var shouldCloudInitialize: Bool {
        iCloudEnabled &&
        isPro &&
        FileManager.default.ubiquityIdentityToken != nil
    }
    
    var isCloudEnabled: Bool {
        iCloudAccountStatus == .available &&
        shouldCloudInitialize
    }
}

public extension CloudKitSyncMonitor.SyncMonitor {
    var statusPublisher: AnyPublisher<CloudKitSyncMonitor.SyncMonitor.SyncSummaryStatus, Never> {
        objectWillChange
            .map { [unowned self] in
                syncStateSummary
            }
            .removeDuplicates()
            .handleEvents(receiveOutput: { summary in
                logger.info("cloud sync summary changes: \(summary.text)")
            })
            .eraseToAnyPublisher()
    }
}
