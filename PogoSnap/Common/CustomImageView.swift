//
//  CustomImageView.swift
//  PogoSnap
//
//  Created by Brandon Nguyen on 11/17/20.
//

import UIKit
import Kingfisher

class CustomImageView: UIImageView {
    
    func loadImage(urlString: String) {
        guard let url = URL(string: urlString) else { return }
        kf.indicatorType = .activity
        kf.setImage(with: url)
    }
}
