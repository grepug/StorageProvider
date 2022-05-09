//
//  File.swift
//  
//
//  Created by Kai on 2022/5/9.
//

import CloudKitSyncMonitor
import Foundation
import CloudKit

public protocol SyncMonitorWithCloudKit {
    var iCloudAccountStatus: CKAccountStatus? { get }
    
    var isPro: Bool { get }
    var iCloudEnabled: Bool { get }
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
