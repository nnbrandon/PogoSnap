//
//  RedditCommentResponse.swift
//  PogoSnap
//
//  Created by Brandon Nguyen on 11/21/20.
//

import Foundation

struct RedditCommentResponse: Decodable {
    let kind: String // Listing
    let data: RedditData
}

struct RedditData: Decodable {
    let children: [RedditChild]
}

struct RedditChild: Decodable {
    let kind: String // t1
    let data: RedditComment?
}

struct RedditComment: Decodable {
    let author: String?
    let title: String? // Title for the original post title
    let body: String?
    let depth: Int?
    let replies: Reply?
    let id: String?
    let created_utc: TimeInterval?
    
    let preview: Preview?
    let media_metadata: MediaData?
    
    // More
    let count: Int?
    let name: String?
    let parent_id: String?
    let children: [String]?
}

enum Reply: Decodable {
    case string(String) // empty reply
    case redditCommentResponse(RedditCommentResponse)

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let stringValue = try? container.decode(String.self) {
            self = .string(stringValue)
            return
        }
        if let commentValue = try? container.decode(RedditCommentResponse.self) {
            self = .redditCommentResponse(commentValue)
            return
        }
        throw DecodingError.typeMismatch(Reply.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Wrong type for Reply"))
    }
}

// More Replies
struct RedditMoreChildrentResponse: Decodable {
    let json: MoreRepliesJsonResponse
}

struct MoreRepliesJsonResponse: Decodable {
    let errors: [String]?
    let data: MoreReplies?
}

struct MoreReplies: Decodable {
    let things: [RedditRepliesResponse]?
}

struct RedditRepliesResponse: Decodable {
    let kind: String // Listing
    let data: RedditComment
}

