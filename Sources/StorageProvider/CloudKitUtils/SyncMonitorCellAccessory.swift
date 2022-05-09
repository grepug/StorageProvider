//
//  File.swift
//  
//
//  Created by Kai on 2022/5/9.
//

import UIKit
import CloudKitSyncMonitor

public extension UICellAccessory {
    static func cloudSyncIndicator(status: SyncMonitor.SyncSummaryStatus, parentVC: UIViewController) -> UICellAccessory? {
        guard let syncMonitor = SyncMonitor.shared as? SyncMonitorWithCloudKit else {
            return nil
        }
        
        guard syncMonitor.isCloudEnabled else {
            return nil
        }
        
        let configuration: CustomViewConfiguration?
        let placement: UICellAccessory.Placement = .trailing(displayed: .always)
        
        switch status {
        case .inProgress:
            let progressView = UIActivityIndicatorView()
            progressView.startAnimating()
            configuration = .init(customView: progressView, placement: placement)
        case .succeeded:
            configuration = nil
        default:
            let button = UIButton()
            button.setImage(.init(systemName: status.symbolName), for: .normal)
            button.sizeToFit()
            button.addAction(.init(handler: { _ in
                let handler: (UIAlertAction) -> Void = { _ in
                    let vc = iCloudSettingsView.makeViewController()
                    let navVC = vc.navigationControllerWrapped()
                    navVC.navigationBar.prefersLargeTitles = true
                    navVC.modalPresentationStyle = .formSheet
                    
                    vc.navigationItem.rightBarButtonItem = .init(systemItem: .close,
                                                                 primaryAction: .init { _ in
                        vc.presentingViewController?.dismiss(animated: true)
                    })
                    
                    parentVC.present(navVC, animated: true)
                }
                
                parentVC.presentAlertController(title: "同步失败",
                                                                    message: status.text,
                                                                    actions: [
                                                                        .cancel,
                                                                        .init(title: "查看 iCloud 同步状态",
                                                                              style: .default,
                                                                              handler: handler)
                                                                    ])
            }), for: .touchUpInside)
            
            configuration = .init(customView: button, placement: placement)
        }
        
        if let configuration = configuration {
            return .customView(configuration: configuration)
        }
        
        return nil
    }
}
