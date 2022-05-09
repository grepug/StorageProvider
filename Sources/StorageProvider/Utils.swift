//
//  File.swift
//  
//
//  Created by Kai on 2022/5/9.
//

import UIKit

extension String {
    var loc: Self {
        String(format: NSLocalizedString(self, comment: ""), "")
    }
    
    func loc(_ string: String) -> Self {
        String(format: NSLocalizedString(self, comment: ""), string)
    }
}

class ViewControllerWrapper: ObservableObject {
    weak var vc: UIViewController?

    var isCollapsed: Bool {
        vc?.splitViewController?.isCollapsed ?? false
    }
}
