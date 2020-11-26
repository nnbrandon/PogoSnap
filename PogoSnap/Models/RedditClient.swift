//
//  RedditClient.swift
//  PogoSnap
//
//  Created by Brandon Nguyen on 11/26/20.
//

import Foundation

struct RedditClient {
    struct Const {
        static let clientId = "jR0pBnlr2bENWA"
        static let clientSecret = ""
        static let authorizeUrl = "https://www.reddit.com/api/v1/authorize.compact"
        static let accessTokenUrl = "https://www.reddit.com/api/v1/access_token"
        static let responseType = "code"
        static let duration = "permanent"
        static let scope = "read submit identity report save history"
        static let callbackURL = "PogoSnap://response"
        
        static let oauthEndpoint = "https://oauth.reddit.com/api/v1/"
        static let meEndpoint = oauthEndpoint + "me"
        static let userAgent = "ios:PogoSnap:1.0.0 (by /u/HeroSekai)"
    }
}
