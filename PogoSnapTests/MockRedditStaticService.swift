//
//  MockRedditStaticService.swift
//  PogoSnapTests
//
//  Created by Brandon Nguyen on 1/17/21.
//

import Foundation
@testable import PogoSnap

class MockRedditStaticService: StaticServiceProtocol {
    
    func getExpectedComments() -> [Comment] {
        let baseComment = Comment(author: "test", body: "test", depth: 0, replies: [Comment](), id: "test", isAuthorPost: false, created_utc: 123, count: nil, name: nil, parent_id: nil, children: nil)
        
        var comments = [Comment]()
        for commentIndex in 0..<4 {
            var newComment = baseComment
            newComment.author += " commentIndex=\(commentIndex)"
            var replies = [Comment]()
            if commentIndex % 2 == 0 {
                for replyIndex in 0..<2 {
                    var newReply = baseComment
                    newReply.author = " commentIndex=\(commentIndex) replyIndex=\(replyIndex)"
                    replies.append(newReply)
                }
            }
            newComment.replies = replies
            comments.append(newComment)
        }
        return comments
    }

    func fetchComments(commentsLink: String, completion: @escaping RedditStaticService.CommentsHandler) {
        completion(RedditCommentsResult.success(comments: getExpectedComments()))
    }
    
    func moreChildren(data: Data) -> [Comment] {
        return [Comment]()
    }
}
