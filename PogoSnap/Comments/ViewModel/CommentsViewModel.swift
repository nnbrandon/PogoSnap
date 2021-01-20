//
//  CommentsViewModel.swift
//  PogoSnap
//
//  Created by Brandon Nguyen on 1/16/21.
//

import Foundation

class CommentsViewModel {
    
    let redditStaticService: StaticServiceProtocol
    let redditService: RedditService
    let commentsLink: String
    let archived: Bool
    let authenticated: Bool
    let postId: String
    let postSubReddit: String
    
    var flattenedComments: [Comment] = []
    
    init(post: Post, authenticated: Bool, redditStaticService: StaticServiceProtocol, redditService: RedditService) {
        archived = post.archived
        commentsLink = post.commentsLink
        postId = post.id
        postSubReddit = post.subReddit
        self.authenticated = authenticated
        self.redditStaticService = redditStaticService
        self.redditService = redditService
    }
}

// RedditService
extension CommentsViewModel {
    func getSubredditRules(subReddit: String) -> [String] {
        return redditService.getSubredditRules(subReddit: subReddit)
    }
    
    func getSiteRules() -> [String] {
        return redditService.getSiteRules()
    }
    
    func canDelete(author: String) -> Bool {
        return redditService.getUsername() == author
    }
    
    func deleteComment(commentId: String, completion: @escaping (String?) -> Void) {
        let cid = "t1_\(commentId)"
        redditService.delete(id: cid) { result in
            switch result {
            case .success:
                if let index = self.flattenedComments.firstIndex(where: { comment -> Bool in comment.id == commentId}) {
                    self.flattenedComments[index].author = "[deleted]"
                    self.flattenedComments[index].body = "[deleted]"
                }
                completion(nil)
            case .error(let error):
                completion(error)
            }
        }
    }
    
    func reportComment(commentId: String, reason: String, completion: @escaping (String?) -> Void) {
        let cid = "t1_\(commentId)"
        redditService.report(subReddit: postSubReddit, id: cid, reason: reason) { result in
            switch result {
            case .success:
                completion(nil)
            case .error(let error):
                completion(error)
            }
        }
    }
}

// RedditStaticService
extension CommentsViewModel {
        
    func getMoreChildren(children: [String], completion: @escaping (String?) -> Void) {
        redditStaticService.moreChildren(postId: postId, children: children) { result in
            switch result {
            case .success(let comments):
                self.addMoreReplies(moreReplies: comments, children: children)
                completion(nil)
            case .error(let error):
                completion(error)
            }
        }
    }
    
    func addMoreReplies(moreReplies: [Comment], children: [String]) {
        if moreReplies.isEmpty {
            for (idx, comment) in flattenedComments.enumerated() {
                if let commentChildren = comment.children, commentChildren == children {
                    flattenedComments.remove(at: idx)
                }
            }
        } else {
            let flattenedNewComments = self.flattenComments(comments: moreReplies)
            guard let parentId = flattenedNewComments.first?.parent_id else {return}
            var index = 0
            for (idx, comment) in self.flattenedComments.enumerated() {
                if let commentParentId = comment.parent_id, comment.children != nil, commentParentId == parentId {
                    index = idx
                }
            }
            var replaced = false
            for reply in flattenedNewComments {
                if replaced {
                    flattenedComments.insert(reply, at: index)
                } else {
                    flattenedComments[index] = reply
                    replaced = true
                }
                index += 1
            }
        }
    }
    
    func addReply(reply: Comment, parentCommentId: String) -> IndexPath {
        var index = 0
        for (idx, comment) in flattenedComments.enumerated() where comment.id == parentCommentId {
            index = idx + 1
        }
        flattenedComments.insert(reply, at: index)
        return IndexPath(row: index, section: 0)
    }
    
    func insertNewComment(newComment: Comment) -> IndexPath {
        flattenedComments.insert(newComment, at: 0)
        return IndexPath(row: 0, section: 0)
    }
    
    func getCount() -> Int {
        return flattenedComments.count
    }
    
    func expandSelectedComment(selectedIndex: Int, selectedComment: Comment, indexPath: IndexPath) -> [IndexPath] {
        var flattenedNewComments = flattenComments(comments: [selectedComment])
        flattenedNewComments.remove(at: 0)
        flattenedComments.insert(contentsOf: flattenedNewComments, at: selectedIndex + 1)

        var indexPaths: [IndexPath] = []
        for index in 0..<flattenedNewComments.count {
            indexPaths.append(IndexPath(row: selectedIndex + index + 1, section: indexPath.section))
        }
        return indexPaths
    }
    
    func removeCells(selectedIndex: Int, nCellsToDelete: Int, indexPath: IndexPath) -> [IndexPath] {
        flattenedComments.removeSubrange(Range(uncheckedBounds: (lower: selectedIndex + 1, upper: selectedIndex + nCellsToDelete + 1)))
        var indexPaths: [IndexPath] = []
        for index in 0..<nCellsToDelete {
            indexPaths.append(IndexPath(row: selectedIndex + index + 1, section: indexPath.section))
        }
        return indexPaths
    }
    
    func getNumberOfCellsToDelete(comment: Comment, selectedIndex: Int) -> Int {
        var nCellsToDelete = 0
        repeat {
            nCellsToDelete += 1
        } while (flattenedComments.count > selectedIndex + nCellsToDelete + 1 && flattenedComments[selectedIndex + nCellsToDelete + 1].depth > comment.depth)
        return nCellsToDelete
    }
    
    func isCellExpanded(selectedIndex: Int) -> Bool {
        let comment = flattenedComments[selectedIndex]
        return flattenedComments.count > selectedIndex + 1 &&  // if not last cell
            flattenedComments[selectedIndex + 1].depth > comment.depth // if replies are displayed
    }

    func getComment(selectedIndex: Int) -> Comment {
        return flattenedComments[selectedIndex]
    }

    func fetchComments(completion: @escaping (String?) -> Void) {
        redditStaticService.fetchComments(commentsLink: commentsLink) { result in
            switch result {
            case .success(let comments):
                let flattenedComments = self.flattenComments(comments: comments)
                self.flattenedComments = flattenedComments
                completion(nil)
            case .error(let error):
                completion(error)
            }
        }
    }

    func flattenComments(comments: [Comment]) -> [Comment] {
        return comments.flatMap { comment -> [Comment] in
            var result = [comment]
            result.append(contentsOf: flattenComments(comments: comment.replies))
            return result
        }
    }
}
