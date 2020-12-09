//
//  UINavigationController+Progress.swift
//  PogoSnap
//
//  Created by Brandon Nguyen on 12/7/20.
//

import UIKit

extension UINavigationController {

    public override func viewDidLoad() {
        super.viewDidLoad()
        navigationBar.backgroundColor = .white
        navigationBar.isTranslucent = false

        let progressView = UIProgressView(progressViewStyle: .bar)
        view.addSubview(progressView)
        let navBar = navigationBar

        progressView.translatesAutoresizingMaskIntoConstraints = false
        progressView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        progressView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        progressView.topAnchor.constraint(equalTo: navBar.bottomAnchor).isActive = true
        
        progressView.setProgress(0, animated: false)

        view.bringSubviewToFront(progressView)
    }
}
