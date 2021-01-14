//
//  PostViewDelegate.swift
//  PogoSnap
//
//  Created by Brandon Nguyen on 1/10/21.
//

import Foundation

protocol PostViewDelegate: class {
//    func didTapComment(postViewModel: PostViewModel)
//    func didTapUsername(username: String, userIconURL: String?)
//    func didTapImage(imageSources: [ImageSource], position: Int)
//    func didTapOptions(postViewModel: PostViewModel)
//    func didTapVote(postViewModel: PostViewModel, direction: Int, authenticated: Bool, archived: Bool)
//
    
    func showComments(post: Post, index: Int)
    func votePost(index: Int, direction: Int, authenticated: Bool, archived: Bool)
    func showOptions(id: String, subReddit: String, subRedditRules: [String], siteRules: [String], authenticated: Bool, canDelete: Bool)
    func showFullImages(imageSources: [ImageSource], position: Int)
}
