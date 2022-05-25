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

extension SyncMonitor.SyncSummaryStatus {
    var text: String {
        switch self {
        case .inProgress: return "settings_icloud_SyncSummaryStatus_inProgress".loc
        case .error: return "settings_icloud_SyncSummaryStatus_error".loc
        case .accountNotAvailable: return "settings_icloud_SyncSummaryStatus_accountNotAvailable".loc
        case .notSyncing: return "settings_icloud_SyncSummaryStatus_notSyncing".loc
        case .noNetwork: return "settings_icloud_SyncSummaryStatus_noNetwork".loc
        case .succeeded: return "settings_icloud_SyncSummaryStatus_succeeded".loc
        case .notStarted: return "settings_icloud_SyncSummaryStatus_notStarted".loc
        case .unknown: return "settings_icloud_SyncSummaryStatus_unknown".loc
        }
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

extension CKContainer {
    public var isProductionEnvironment:Bool {
        let containerID = self.value(forKey: "containerID") as! NSObject // CKContainerID
        return containerID.value(forKey: "environment")! as! CLongLong == 1
    }
}
