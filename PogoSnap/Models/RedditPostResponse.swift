//
//  RedditPostResponse.swift
//  PogoSnap
//
//  Created by Brandon Nguyen on 11/17/20.
//

import Foundation

struct RedditPostResponse: Decodable {
    let kind: String
    let data: ChildrenData
}

struct ChildrenData: Decodable {
    let modhash: String
    let dist: Int
    let children: [Children]
    let after: String?
}

struct Children: Decodable {
    let data: RedditPost
}

struct RedditPost: Decodable {
    let author: String
    let title: String
    let preview: Preview?
    let media_metadata: MediaData?
    let score: Int
    let num_comments: Int
    let id: String
}

struct Preview: Decodable {
    let images: [Image]
}

struct Image: Decodable {
    let source: ImageSource
}

struct ImageSource: Decodable {
    let url: String
    let width: Int
    let height: Int
}

struct MediaData: Decodable {
    var mediaImages = [String]()
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let json = try container.decode(JSON.self)
        
        guard let (_, unknownJSON) = json.objectValue?.first,
              let fileName = unknownJSON.dictionaryValue
        else {
            throw DecodingError.dataCorrupted(.init(codingPath: [],
                                                    debugDescription: "Could not find dynamic key"))
        }
        if let p = fileName["p"] as? [Any] {
            if let lastImage: [String: Any] = p.last as? [String : Any] {
                if let u = lastImage["u"] as? String {
                    mediaImages.append(u)
                }
            }
        }
    }
}
