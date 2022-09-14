//
//  File.swift
//  
//
//  Created by Kai on 2022/5/9.
//

import Foundation

extension String {
    var loc: Self {
        NSLocalizedString(self, bundle: .module, comment: "")
    }
    
    func loc(_ string: String) -> Self {
        String(format: NSLocalizedString(self, bundle: .module, comment: ""), string)
    }
}

#if os(iOS)
import UIKit

class ViewControllerWrapper: ObservableObject {
    weak var vc: UIViewController?

    var isCollapsed: Bool {
        vc?.splitViewController?.isCollapsed ?? true
    }
}
#endif
