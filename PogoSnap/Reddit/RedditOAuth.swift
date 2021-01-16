//
//  RedditOAuth.swift
//  PogoSnap
//
//  Created by Brandon Nguyen on 12/22/20.
//

import Foundation
import OAuthSwift
import KeychainAccess

class RedditOAuth {
    var oauthSwift = OAuth2Swift(
        consumerKey: RedditConsts.redditClientId,
        consumerSecret: RedditConsts.redditClientSecret,
        authorizeUrl: RedditConsts.redditAuthorizeUrl,
        accessTokenUrl: RedditConsts.redditAccessTokenUrl,
        responseType: RedditConsts.responseType
    )
    let defaults = UserDefaults(suiteName: "group.com.PogoSnap")
    let keychain = Keychain(service: "com.PogoSnap", accessGroup: "group.com.PogoSnap")

    private func isTokenExpired(expireDate: Date) -> Bool {
        return expireDate <= Date()
    }
    
    typealias TokenHandler = (String) -> Void
    public func getAccessToken(completion: @escaping TokenHandler) {
        if let accessToken = keychain[RedditConsts.redditAccessToken], let refreshToken = keychain[RedditConsts.redditRefreshToken], let expireDate = defaults?.object(forKey: RedditConsts.redditExpireDate) as? Date {
            if isTokenExpired(expireDate: expireDate) {
                oauthSwift.accessTokenBasicAuthentification = true
                oauthSwift.renewAccessToken(withRefreshToken: refreshToken) { result in
                    switch result {
                    case .success(let (credential, _, _)):
                        self.keychain[RedditConsts.redditAccessToken] = credential.oauthToken
                        if let expireDate = credential.oauthTokenExpiresAt {
                            self.defaults?.set(expireDate, forKey: RedditConsts.redditExpireDate)
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
                        self.registerCredentials(accessToken: credential.oauthToken, refreshToken: credential.oauthRefreshToken, expireDate: expireDate)
//                        self.accessToken = credential.oauthToken
//                        self.refreshToken = credential.oauthRefreshToken
//                        self.expireDate = expireDate
                        completion(RedditAuthResult.success)
                    }
                case .failure:
                    completion(RedditAuthResult.success)
                }
        }
    }
    
    public func changeCompact(compact: Bool) {
        if compact {
            self.oauthSwift = OAuth2Swift(
                consumerKey: RedditConsts.redditClientId,
                consumerSecret: RedditConsts.redditClientSecret,
                authorizeUrl: RedditConsts.redditAuthorizeUrl,
                accessTokenUrl: RedditConsts.redditAccessTokenUrl,
                responseType: RedditConsts.responseType
            )
        } else {
            self.oauthSwift = OAuth2Swift(
                consumerKey: RedditConsts.redditClientId,
                consumerSecret: RedditConsts.redditClientSecret,
                authorizeUrl: RedditConsts.redditNonCompactAuthorizeUrl,
                accessTokenUrl: RedditConsts.redditAccessTokenUrl,
                responseType: RedditConsts.responseType
            )
        }
    }
    
    private func registerCredentials(accessToken: String, refreshToken: String, expireDate: Date) {
        keychain[RedditConsts.redditAccessToken] = accessToken
        keychain[RedditConsts.redditRefreshToken] = refreshToken

        defaults?.set(expireDate, forKey: RedditConsts.redditExpireDate)
        defaults?.set(true, forKey: RedditConsts.redditSignedIn)
    }
    
    public func deleteCredentials() {
        do {
            try keychain.remove(RedditConsts.redditAccessToken)
            try keychain.remove(RedditConsts.redditRefreshToken)
        } catch _ {}

        defaults?.removeObject(forKey: RedditConsts.username)
        defaults?.removeObject(forKey: RedditConsts.icon_img)
        defaults?.removeObject(forKey: RedditConsts.redditExpireDate)
        defaults?.removeObject(forKey: RedditConsts.redditSignedIn)
    }
    
    public func isUserAuthenticated() -> Bool {
        if let isAuthenticated = defaults?.bool(forKey: RedditConsts.redditSignedIn), isAuthenticated {
            return true
        } else {
            return false
        }
    }
}
