//
//  CommentViewModel.swift
//  PogoSnap
//
//  Created by Brandon Nguyen on 1/16/21.
//

import Foundation

class CommentViewModel {
    
    let redditClient: RedditService
    let archived: Bool
    let commentsLink: String
    
    var comments: [Comment] = []
    var currentlyDisplayedComments: [Comment] = []
    
    init(post: Post, redditClient: RedditService) {
        archived = post.archived
        commentsLink = post.commentsLink
        self.redditClient = redditClient
    }
}

extension CommentViewModel {
    /**
            Add comment services into RedditClient
     */
}
