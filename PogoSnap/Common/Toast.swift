//
//  Toast.swift
//  PogoSnap
//
//  Created by Brandon Nguyen on 11/28/20.
//

import UIKit
import Toast_Swift

func showSuccessToast(controller: UIViewController, message : String, seconds: Double) {
    var style = ToastStyle()
    style.backgroundColor = .systemBlue
    style.messageColor = .white
    controller.view.makeToast(message, duration: seconds, position: .top, style: style)
}

func showSuccessToastAndDismiss(controller: UIViewController, message : String, seconds: Double) {
    var style = ToastStyle()
    style.backgroundColor = .systemBlue
    style.messageColor = .white
    controller.view.makeToast(message, duration: seconds, position: .top, style: style) { _ in
        controller.dismiss(animated: true, completion: nil)
    }
}


func showErrorToast(controller: UIViewController, message : String, seconds: Double) {
    var style = ToastStyle()
    style.backgroundColor = .systemRed
    style.messageColor = .white
    controller.view.makeToast(message, duration: seconds, position: .top, style: style)
}

func showImageToast(controller: UIViewController, message: String, image: UIImage, seconds: Double) {
    var style = ToastStyle()
    style.backgroundColor = .systemBlue
    style.messageColor = .white
    controller.view.makeToast(message, position: .top, image: image, style: style)
}

