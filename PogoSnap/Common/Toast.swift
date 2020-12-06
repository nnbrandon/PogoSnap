//
//  Toast.swift
//  PogoSnap
//
//  Created by Brandon Nguyen on 11/28/20.
//

import UIKit

func showToast(controller: UIViewController, message : String, seconds: Double, dismissAfter: Bool) {
    let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
    alert.view.backgroundColor = UIColor.black
    alert.view.alpha = 0.6
    alert.view.layer.cornerRadius = 15

    controller.present(alert, animated: true)

    DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + seconds) {
        alert.dismiss(animated: true)
        if dismissAfter {
            controller.dismiss(animated: true, completion: nil)
        }
    }
}
