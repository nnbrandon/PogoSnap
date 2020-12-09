//
//  RedditAPIPostResponse.swift
//  PogoSnap
//
//  Created by Brandon Nguyen on 11/28/20.
//

import Foundation

struct RedditAPIPostResponse: Decodable {
    let json: JsonResponse
}

struct JsonResponse: Decodable {
    let errors: [String]?
    let data: PostData?
}

struct PostData: Decodable {
    let url: String? // Comment url
    let id: String?  // Post ID
    let things: [RedditChild]?
}
