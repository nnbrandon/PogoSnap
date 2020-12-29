//
//  ImgurResult.swift
//  PogoSnap
//
//  Created by Brandon Nguyen on 12/28/20.
//

import Foundation

enum ImgurDeleteResult {
    case success
    case error
}

enum ImgurUploadResult {
    case success(imageSource: ImageSource?)
    case error(error: String)
}
