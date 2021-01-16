//
//  PostViewDelegate.swift
//  PogoSnap
//
//  Created by Brandon Nguyen on 1/10/21.
//

import Foundation

protocol PostViewDelegate: class {
    func didTapUsername(username: String, userIconURL: String?)
    func didTapImage(imageSources: [ImageSource], position: Int)
}
