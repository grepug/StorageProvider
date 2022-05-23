//
//  File.swift
//  
//
//  Created by Kai on 2022/5/9.
//

import UIKit
import CloudKitSyncMonitor

public extension UICellAccessory {
    static func cloudSyncIndicator(iCloudSettingsViewController: @autoclosure @escaping () -> UIViewController) -> UICellAccessory? {
        guard let syncMonitor = SyncMonitor.shared as? SyncMonitorWithCloudKit else {
            return nil
        }
        
        guard syncMonitor.isCloudEnabled else {
            return nil
        }
        
        let configuration: CustomViewConfiguration?
        let placement: UICellAccessory.Placement = .trailing(displayed: .always)
        let status = SyncMonitor.shared.syncStateSummary
        
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
                let parentVC = button.parentViewController!
                Self.presentAlertController(status: status,
                                            iCloudSettingsViewController: iCloudSettingsViewController(),
                                            presentingVC: parentVC)
            }), for: .touchUpInside)
            
            configuration = .init(customView: button, placement: placement)
        }
        
        if let configuration = configuration {
            return .customView(configuration: configuration)
        }
        
        return nil
    }
    
    static private func presentAlertController(status: SyncMonitor.SyncSummaryStatus,
                                               iCloudSettingsViewController: UIViewController,
                                               presentingVC: UIViewController) {
        let handler: (UIAlertAction) -> Void = { _ in
            let navVC = UINavigationController(rootViewController: iCloudSettingsViewController)
            navVC.navigationBar.prefersLargeTitles = true
            navVC.modalPresentationStyle = .formSheet
            
            iCloudSettingsViewController.navigationItem.rightBarButtonItem = .init(systemItem: .close,
                                                         primaryAction: .init { _ in
                iCloudSettingsViewController.presentingViewController?.dismiss(animated: true)
            })
            
            presentingVC.present(navVC, animated: true)
        }
        
        let ac = UIAlertController(title: "",
                                   message: status.text,
                                   preferredStyle: .alert)
        ac.addAction(.init(title: "action_cancel".loc, style: .cancel))
        ac.addAction(.init(title: "view_icloud_status".loc,
                           style: .default,
                           handler: handler))
        
        presentingVC.present(ac, animated: true)
    }
}

extension UIView {
    var parentViewController: UIViewController? {
        sequence(first: self) { $0.next }
            .first(where: { $0 is UIViewController })
            .flatMap { $0 as? UIViewController }
    }
}
