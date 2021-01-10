//
//  PostViewDelegate.swift
//  PogoSnap
//
//  Created by Brandon Nguyen on 1/10/21.
//

import Foundation

protocol PostViewDelegate: class {
    func didTapComment(post: Post, index: Int)
    func didTapUsername(username: String, user_icon: String?)
    func didTapImage(imageSources: [ImageSource], position: Int)
    func didTapOptions(post: Post)
    func didTapVote(post: Post, direction: Int, index: Int, authenticated: Bool, archived: Bool)
}
