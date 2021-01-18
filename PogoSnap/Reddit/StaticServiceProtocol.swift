//
//  StaticServiceProtocol.swift
//  PogoSnap
//
//  Created by Brandon Nguyen on 1/17/21.
//

import Foundation

protocol StaticServiceProtocol {
    func fetchComments(commentsLink: String, completion: @escaping RedditStaticService.CommentsHandler)
    func moreChildren(data: Data) -> [Comment]
}
