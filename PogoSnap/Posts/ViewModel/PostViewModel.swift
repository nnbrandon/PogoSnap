//
//  PostsViewModel.swift
//  PogoSnap
//
//  Created by Brandon Nguyen on 1/12/21.
//

import Foundation
import UIKit

class PostViewModel {
    
    private let redditClient: RedditClient
    private let post: Post
    public let index: Int
    
    init(post: Post, index: Int, redditClient: RedditClient) {
        self.post = post
        self.index = index
        self.redditClient = redditClient
    }
    
    var titleText: String {
        return post.title
    }
    var headerText: String {
        let date = Date(timeIntervalSince1970: post.created_utc)
        return "u/\(post.author)・r/\(post.subReddit)・\(date.timeAgoSinceDate())"
    }
    var likeCount: String {
        return String(post.score)
    }
    var commentCount: String {
        return String(post.numComments)
    }
    var imageSources: [ImageSource] {
        return post.imageSources
    }
    var hideDots: Bool {
        if post.imageSources.count > 1 {
            return false
        } else {
            return true
        }
    }
    var liked: Bool? {
        if let postLiked = post.liked {
            if postLiked {
                return true
            } else {
                return false
            }
        } else {
            return nil
        }
    }
    var aspectFit: Bool {
        return post.aspectFit
    }
    var userIconURL: String? {
        return post.user_icon
    }
    var isUserAuthenticated: Bool {
        return redditClient.isUserAuthenticated()
    }
    var postArchived: Bool {
        return post.archived
    }
    
    weak var postViewDelegate: PostViewDelegate?
}

extension PostViewModel {
    
    func showFullImages(position: Int) {
        postViewDelegate?.showFullImages(imageSources: post.imageSources, position: position)
    }
    
    func showOptions() {
        let subRedditRules = redditClient.getSubredditRules(subReddit: post.subReddit)
        let siteRules = redditClient.getSiteRules()
        let authenticated = redditClient.isUserAuthenticated()
        var canDelete = false
        if let username = redditClient.getUsername(), post.author == username {
            canDelete = true
        }
        postViewDelegate?.showOptions(id: post.id, subReddit: post.subReddit, subRedditRules: subRedditRules, siteRules: siteRules, authenticated: authenticated, canDelete: canDelete)
    }
    
    func votePost(direction: Int) {
        if direction == 0 {
            if let liked = post.liked {
                if liked {
                    post.liked = nil
                    post.score -= 1
                } else {
                    post.liked = nil
                    post.score += 1
                }
            }
        } else if direction == 1 {
            post.liked = true
            post.score += 1
        } else {
            post.liked = false
            post.score -= 1
        }
        
        redditClient.votePost(subReddit: post.subReddit, postId: post.id, direction: direction) { _ in}
        let authenticated = isUserAuthenticated
        postViewDelegate?.votePost(index: index, direction: direction, authenticated: authenticated, archived: post.archived)
    }
}
