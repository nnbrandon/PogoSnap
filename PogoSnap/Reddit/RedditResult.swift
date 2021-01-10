//
//  RedditResult.swift
//  PogoSnap
//
//  Created by Brandon Nguyen on 12/22/20.
//

import Foundation

enum RedditAuthResult {
    case success
    case error
}

enum RedditJsonResult {
    case success(response: PostData?)
    case error(error: String)
}

enum RedditMeResult {
    case success(username: String, icon_img: String)
    case error(error: String)
}

enum RedditPostCommentResult {
    case success(commentId: String)
    case error(error: String)
}

enum RedditPostsResult {
    case success(posts: [Post], nextAfter: String?)
    case error(error: String)
}

enum RedditGoAndSnapResult {
    case success(posts: [Post], pokemonGoSnapAfter: String?, pokemonGoAfter: String?)
    case error(error: String)
}

enum RedditBoolResult {
    case success
    case error(error: String)
}

enum RedditRulesResult {
    case success(rules: RedditRulesResponse)
    case error(error: String)
}
