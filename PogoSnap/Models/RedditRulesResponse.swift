//
//  RedditRulesResponse.swift
//  PogoSnap
//
//  Created by Brandon Nguyen on 11/28/20.
//

import Foundation

struct RedditRulesResponse: Decodable {
    let rules: [SubRedditRules]
    let site_rules: [String]
}

struct SubRedditRules: Decodable {
    let short_name: String
    let violation_reason: String
}
