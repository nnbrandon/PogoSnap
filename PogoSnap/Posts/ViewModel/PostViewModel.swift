//
//  PostsViewModel.swift
//  PogoSnap
//
//  Created by Brandon Nguyen on 1/12/21.
//

import Foundation
import UIKit
import IGListKit

class PostViewModel: ListDiffable {
        
    public let imageSources: [ImageSource]
    public let index: Int
    public let headerText: String
    public let titleText: String
    public let subReddit: String
    public let hideDots: Bool
    public let aspectFit: Bool
    public let archived: Bool
    public let userIconString: String?
    public let authenticated: Bool
    
    init(post: Post, index: Int, authenticated: Bool) {
        self.index = index
        self.authenticated = authenticated
        
        let date = Date(timeIntervalSince1970: post.created_utc)
        imageSources = post.imageSources
        headerText = "u/\(post.author)・r/\(post.subReddit)・\(date.timeAgoSinceDate())"
        titleText = post.title
        subReddit = post.subReddit
        hideDots = post.imageSources.count <= 1
        aspectFit = post.aspectFit
        archived = post.archived
        userIconString = post.user_icon
    }
    
    weak var postViewDelegate: PostViewDelegate?
    
    func diffIdentifier() -> NSObjectProtocol {
        return "post" as NSObjectProtocol
    }
    
    func isEqual(toDiffableObject object: ListDiffable?) -> Bool {
        guard let object = object as? PostViewModel else  { return false }
        return titleText == object.titleText && headerText == object.headerText
    }
}

extension PostViewModel {
    
    func showFullImages(position: Int) {
        postViewDelegate?.showFullImages(imageSources: imageSources, position: position)
    }
    
    func showOptions() {
//        let subRedditRules = redditClient.getSubredditRules(subReddit: post.subReddit)
//        let siteRules = redditClient.getSiteRules()
//        let authenticated = redditClient.isUserAuthenticated()
//        var canDelete = false
//        if let username = redditClient.getUsername(), post.author == username {
//            canDelete = true
//        }
//        postViewDelegate?.showOptions(id: post.id, subReddit: post.subReddit, subRedditRules: subRedditRules, siteRules: siteRules, authenticated: authenticated, canDelete: canDelete)
    }
    
    func votePost(direction: Int) {
//        if direction == 0 {
//            if let liked = post.liked {
//                if liked {
//                    post.liked = nil
//                    post.score -= 1
//                } else {
//                    post.liked = nil
//                    post.score += 1
//                }
//            }
//        } else if direction == 1 {
//            post.liked = true
//            post.score += 1
//        } else {
//            post.liked = false
//            post.score -= 1
//        }
//
//        redditClient.votePost(subReddit: post.subReddit, postId: post.id, direction: direction) { _ in}
//        let authenticated = isUserAuthenticated
//        postViewDelegate?.votePost(index: index, direction: direction, authenticated: authenticated, archived: post.archived)
    }
}
