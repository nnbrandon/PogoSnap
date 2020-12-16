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
    let archived: Bool
    let media_metadata: MediaData?
    let score: Int
    let num_comments: Int
    let id: String
    let likes: Bool?
    let created_utc: TimeInterval
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
    var mediaImages = [ImageSource]()
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let json = try container.decode(JSON.self)

        json.objectValue?.forEach { object in
            let (_, value) = object
            let jsonDict = value.dictionaryValue
            if let p = jsonDict?["p"] as? [Any] {
                if let lastImage: [String: Any] = p.last as? [String: Any] {
                    if let url = lastImage["u"] as? String, let width = lastImage["x"] as? Int, let height = lastImage["y"] as? Int {
                        let imageSource = ImageSource(url: url, width: width, height: height)
                        mediaImages.append(imageSource)
                    }
                }
            }
        }
    }
}
