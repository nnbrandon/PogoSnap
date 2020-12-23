//
//  RedditOAuth.swift
//  PogoSnap
//
//  Created by Brandon Nguyen on 12/22/20.
//

import Foundation
import OAuthSwift

struct RedditOAuth {
    let oauthSwift = OAuth2Swift(
        consumerKey: RedditConsts.redditClientId,
        consumerSecret: RedditConsts.redditClientSecret,
        authorizeUrl: RedditConsts.redditAuthorizeUrl,
        accessTokenUrl: RedditConsts.redditAccessTokenUrl,
        responseType: RedditConsts.responseType
    )
    let defaults = UserDefaults(suiteName: "group.com.PogoSnap")

    private func isTokenExpired(expireDate: Date) -> Bool {
        return expireDate <= Date()
    }
    
    typealias TokenHandler = (String) -> Void
    public func getAccessToken(completion: @escaping TokenHandler) {
        if let accessToken = defaults?.string(forKey: RedditConsts.redditAccessToken), let refreshToken = defaults?.string(forKey: RedditConsts.redditRefreshToken), let expireDate = defaults?.object(forKey: RedditConsts.redditExpireDate) as? Date {
            if isTokenExpired(expireDate: expireDate) {
                oauthSwift.accessTokenBasicAuthentification = true
                oauthSwift.renewAccessToken(withRefreshToken: refreshToken) { result in
                    switch result {
                    case .success(let (credential, _, _)):
                        defaults?.set(credential.oauthToken, forKey: RedditConsts.redditAccessToken)
                        if let expireDate = credential.oauthTokenExpiresAt {
                            defaults?.set(expireDate, forKey: RedditConsts.redditExpireDate)
                        }
                        completion(credential.oauthToken)
                    case .failure: break
                    }
                }
            } else {
                completion(accessToken)
            }
        }
    }
    
    typealias TokensHandler = (RedditAuthResult) -> Void
    public func doAuth(urlHandlerType: OAuthSwiftURLHandlerType, completion: @escaping TokensHandler) {
        oauthSwift.accessTokenBasicAuthentification = true
        oauthSwift.authorizeURLHandler = urlHandlerType
        oauthSwift.authorize(
            withCallbackURL: URL(string: RedditConsts.redditCallbackURL)!,
            scope: RedditConsts.scope,
            state: generateState(withLength: 20),
            parameters: ["duration": RedditConsts.duration]) { result in
                switch result {
                case .success(let (credential, _, _)):
                    if let expireDate = credential.oauthTokenExpiresAt {
                        RedditClient.sharedInstance.registerCredentials(accessToken: credential.oauthToken, refreshToken: credential.oauthRefreshToken, expireDate: expireDate)
                        completion(RedditAuthResult.success)
                    }
                case .failure:
                    completion(RedditAuthResult.success)
                }
        }
    }
}
