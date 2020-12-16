//
//  RedditMeResponse.swift
//  PogoSnap
//
//  Created by Brandon Nguyen on 11/26/20.
//

import Foundation

struct RedditMeResponse: Decodable {
    let name: String
    let icon_img: String
    let id: String
}

struct RedditAboutResponse: Decodable {
    let data: RedditMeResponse
}
