//
//  CurrentInterface.swift
//  PogoSnap
//
//  Created by Brandon Nguyen on 12/15/20.
//

import UIKit

public func getCurrentInterfaceForAlerts() -> UIAlertController.Style {
    if UIDevice.current.userInterfaceIdiom == .phone {
        return .actionSheet
    } else {
        return .alert
    }
}

public func getSpacingForCells() -> CGFloat {
    if UIDevice.current.userInterfaceIdiom == .phone {
        return 1
    } else {
        return 0
    }
}
