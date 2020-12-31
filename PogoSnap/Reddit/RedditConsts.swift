//
//  RedditConsts.swift
//  PogoSnap
//
//  Created by Brandon Nguyen on 12/22/20.
//

import Foundation
import UIKit

struct RedditConsts {
    static let subredditName = "PokemonGoSnap"
//    static let subredditName = "PogoSnap"

    static let username = "username"
    static let icon_img = "icon_img"
    static let redditAccessToken = "redditAccessToken"
    static let redditRefreshToken = "redditRefreshToken"
    static let redditExpireDate = "redditExpireDate"
    static let redditSignedIn = "redditSignedIn"

    static let redditClientId = "f5M2aPLjT8rUgg"
    static let redditClientSecret = ""
    static let redditAuthorizeUrl = "https://www.reddit.com/api/v1/authorize.compact"
    static let redditNonCompactAuthorizeUrl = "https://www.reddit.com/api/v1/authorize"
    static let redditAccessTokenUrl = "https://www.reddit.com/api/v1/access_token"
    static let redditCallbackURL = "PogoSnap://response"

    static let responseType = "code"
    static let duration = "permanent"
    static let scope = "read submit edit identity report save history vote privatemessages"
    
    static let userAgent = "ios:PogoSnap:1.0.0 (by /u/nnbrandon)"
    static let oauthEndpoint = "https://oauth.reddit.com"
    static let meEndpoint = oauthEndpoint + "/api/v1/me"
    static let reportEndpoint = oauthEndpoint + "/api/report"
    static let voteEndpoint = oauthEndpoint + "/api/vote"
    static let commentEndpoint = oauthEndpoint + "/api/comment"
    static let submitEndpoint = oauthEndpoint + "/api/submit"
    static let deleteEndpoint = oauthEndpoint + "/api/del"
    
    static let sepColor = #colorLiteral(red: 0.9686660171, green: 0.9768124223, blue: 0.9722633958, alpha: 1)
    static let darkSepColor = UIColor.darkGray
    static let backgroundColor = #colorLiteral(red: 0.9961144328, green: 1, blue: 0.9999337792, alpha: 1)
    static let commentMarginColor = RedditConsts.backgroundColor
    static let rootCommentMarginColor = #colorLiteral(red: 0.9332661033, green: 0.9416968226, blue: 0.9327681065, alpha: 1)
    static let identationColor = #colorLiteral(red: 0.929128468, green: 0.9298127294, blue: 0.9208832383, alpha: 1)
    static let metadataFont = UIFont.boldSystemFont(ofSize: 14)
    static let textFont = UIFont.systemFont(ofSize: 14, weight: .medium)
    static let darkControlsColor = #colorLiteral(red: 0.7295756936, green: 0.733242631, blue: 0.7375010848, alpha: 1)
    static let lightControlsColor = UIColor.darkGray
    
    static let redditDarkMode = UIColor(red: 26/255, green: 26/255, blue: 27/255, alpha: 1)
}
