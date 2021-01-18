//
//  RedditStaticService.swift
//  PogoSnap
//
//  Created by Brandon Nguyen on 1/16/21.
//

import Foundation

/**
 OAuth is not needed in this class to access Reddit APIs
 */
class RedditStaticService: StaticServiceProtocol {
    typealias CommentsHandler = (RedditCommentsResult) -> Void
    func fetchComments(commentsLink: String, completion: @escaping CommentsHandler) {
        guard let url = URL(string: commentsLink) else {return}
        URLSession.shared.dataTask(with: url) { data, response, _ in
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200, let data = data {
                let comments = self.extractComments(data: data)
                completion(RedditCommentsResult.success(comments: comments))
            } else {
                completion(RedditCommentsResult.error(error: "Unable to retrieve comments"))
            }
        }.resume()
    }
    
    private func extractComments(data: Data) -> [Comment] {
        var comments = [Comment]()
        do {
            let decoded = try JSONDecoder().decode([RedditCommentResponse].self, from: data)
            for (index, commentResponse) in decoded.enumerated() {
                if index == 0 {
                    continue
                } else {
                    let children = commentResponse.data.children
                    for child in children {
                        guard let redditComment = child.data else {continue}
                        let author = redditComment.author ?? ""
                        let body = redditComment.body ?? ""
                        let depth = redditComment.depth ?? 0
                        let commentId = redditComment.id ?? ""
                        let created_utc = redditComment.created_utc ?? Date().timeIntervalSince1970

                        var replies = [Comment]()
                        if let commentReplies = redditComment.replies {
                            replies = extractReplies(commentReplies: commentReplies)
                        }

                        let comment = Comment(author: author, body: body, depth: depth, replies: replies, id: commentId, isAuthorPost: false, created_utc: created_utc, count: redditComment.count, name: redditComment.name, parent_id: redditComment.parent_id, children: redditComment.children)
                        comments.append(comment)
                    }
                }
            }
        } catch let error {
            print(error)
        }
        return comments
    }
    
    private func extractReplies(commentReplies: Reply) -> [Comment] {
        var replies = [Comment]()

        switch commentReplies {
        case .string:
            break
        case .redditCommentResponse(let commentResponse):
            let children = commentResponse.data.children
            for child in children {
                guard let redditComment = child.data else {break}
                let author = redditComment.author ?? ""
                let body = redditComment.body ?? ""
                let depth = redditComment.depth ?? 0
                let commentId = redditComment.id ?? ""
                let created_utc = redditComment.created_utc ?? Date().timeIntervalSince1970
                
                if let count = redditComment.count, count == 0 {
                    // on more
                    continue
                }

                var cReplies = [Comment]()
                if let commentReplies = redditComment.replies {
                    cReplies = extractReplies(commentReplies: commentReplies)
                }
                let comment = Comment(author: author, body: body, depth: depth, replies: cReplies, id: commentId, isAuthorPost: false, created_utc: created_utc, count: redditComment.count, name: redditComment.name, parent_id: redditComment.parent_id, children: redditComment.children)
                replies.append(comment)
            }
        }

        return replies
    }
    
    func moreChildren(data: Data) -> [Comment] {
        var comments = [Comment]()
        do {
            let decoded = try JSONDecoder().decode(RedditMoreChildrentResponse.self, from: data)
            if let things = decoded.json.data?.things {
                for thing in things {
                    let redditComment = thing.data
                    let author = redditComment.author ?? ""
                    let body = redditComment.body ?? ""
                    let depth = redditComment.depth ?? 0
                    let commentId = redditComment.id ?? ""
                    let created_utc = redditComment.created_utc ?? Date().timeIntervalSince1970

                    var replies = [Comment]()
                    if let commentReplies = redditComment.replies {
                        replies = extractReplies(commentReplies: commentReplies)
                    }

                    let comment = Comment(author: author, body: body, depth: depth, replies: replies, id: commentId, isAuthorPost: false, created_utc: created_utc, count: redditComment.count, name: redditComment.name, parent_id: redditComment.parent_id, children: redditComment.children)
                    comments.append(comment)
                }
            }
        } catch let error {
            print(error)
        }
        return comments
    }
}
