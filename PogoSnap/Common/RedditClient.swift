//
//  RedditClient.swift
//  PogoSnap
//
//  Created by Brandon Nguyen on 11/26/20.
//

import Foundation

import OAuthSwift
import KeychainAccess

struct RedditClient {
    
    static var sharedInstance = RedditClient()
    let oauthSwift = OAuth2Swift(
        consumerKey:    Const.clientId,
        consumerSecret: Const.clientSecret,
        authorizeUrl:   Const.authorizeUrl,
        accessTokenUrl: Const.accessTokenUrl,
        responseType:   Const.responseType
    )
    let keychain = Keychain(service: "com.PogoSnap")
    let defaults = UserDefaults.standard
    
    private init() {}

    struct Const {
        static let username = "username"
        static let accessToken = "accessToken"
        static let refreshToken = "refreshToken"
        static let expireDate = "expireDate"

        static let clientId = "jR0pBnlr2bENWA"
        static let clientSecret = ""
        static let authorizeUrl = "https://www.reddit.com/api/v1/authorize.compact"
        static let accessTokenUrl = "https://www.reddit.com/api/v1/access_token"
        static let responseType = "code"
        static let duration = "permanent"
        static let scope = "read submit identity report save history"
        static let callbackURL = "PogoSnap://response"
        
        static let dateFormat = "yyyy-MM-dd hh:mm:ssZ"
        static let locale = "en_US_POSIX"
        
        static let oauthEndpoint = "https://oauth.reddit.com"
        static let meEndpoint = oauthEndpoint + "/api/v1/me"
        static let reportEndpoint = oauthEndpoint + "/api/report"
        static let userAgent = "ios:PogoSnap:1.0.0 (by /u/HeroSekai)"
    }
    
    private func dateToString(date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = Const.dateFormat
        dateFormatter.locale = Locale(identifier: Const.locale)
        let expireDateString = dateFormatter.string(from: date)
        return expireDateString
    }
    
    private func stringToDate(string: String) -> Date? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = Const.dateFormat
        dateFormatter.locale = Locale(identifier: Const.locale)
        let expireDate = dateFormatter.date(from: string)
        return expireDate
    }
    
    private func isTokenExpired(expireDateString: String) -> Bool {
        let expireDate = stringToDate(string: expireDateString)
        
        if let expireDate = expireDate {
            let currentDate = Date()
            let currentDateString = dateToString(date: currentDate)
            guard let formattedCurrentDate = stringToDate(string: currentDateString) else {return false}

            return expireDate <= formattedCurrentDate
        }

        return false
    }
    
    typealias TokenHandler = (String) -> Void
    private func getAccessToken(completion: @escaping TokenHandler) {
        if let accessToken = keychain[Const.accessToken], let refreshToken = keychain[Const.refreshToken], let expireDate = keychain[Const.expireDate] {
            if isTokenExpired(expireDateString: expireDate) {
                oauthSwift.accessTokenBasicAuthentification = true
                oauthSwift.renewAccessToken(withRefreshToken: refreshToken) { result in
                    switch result {
                    case .success(let (credential, _, _)):
                        self.keychain[Const.accessToken] = credential.oauthToken
                        self.keychain[Const.refreshToken] = credential.oauthRefreshToken
                        if let expireDate = credential.oauthTokenExpiresAt {
                            let expireDateString = dateToString(date: expireDate)
                            self.keychain[Const.expireDate] = expireDateString
                        }
                        print("fetched new access token on refresh, accessToken = \(accessToken)")
                        completion(credential.oauthToken)
                    case .failure(let error):
                        print(error.description)
                    }
                }
            } else {
                print("did not need to refresh token, accessToken = \(accessToken)")
                completion(accessToken)
            }
        }
    }
    
    public func getUsername() -> String? {
        return defaults.string(forKey: Const.username)
    }
    
    typealias MeHandler = (String) -> Void
    public func fetchMe(completion: @escaping MeHandler) {
        getAccessToken { accessToken in
            var meRequest = URLRequest(url: URL(string: Const.meEndpoint)!)
            meRequest.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
            meRequest.setValue(Const.userAgent, forHTTPHeaderField: "User-Agent")
            URLSession.shared.dataTask(with: meRequest) { data, response, error in
                if let data = data {
                    do {
                        let meResponse = try JSONDecoder().decode(RedditMeResponse.self, from: data)
                        defaults.setValue(meResponse.name, forKey: Const.username)
                        completion(meResponse.name)
                    } catch {
                        print(error)
                    }

                }
            }.resume()
        }
    }
    
    typealias ReportHandler = ([String]) -> Void
    public func reportPost(postId: String, reason: String, completion: @escaping ReportHandler) {
        let postId = "t3_" + postId
        let reason = reason.replacingOccurrences(of: " ", with: "%20").replacingOccurrences(of: ",", with: "%2C")
        let subredditName = "pogosnap"
        let apiType = "json"
        let url = "\(Const.reportEndpoint)?api_type=\(apiType)&reason=\(reason)&thing_id=\(postId)&sr_name=\(subredditName)"
        
        getAccessToken { accessToken in
            var meRequest = URLRequest(url: URL(string: url)!)
            meRequest.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
            meRequest.setValue(Const.userAgent, forHTTPHeaderField: "User-Agent")
            meRequest.httpMethod = "POST"
            URLSession.shared.dataTask(with: meRequest) { data, response, error in
                if let data = data {
                    do {
                        let reportResponse = try JSONDecoder().decode(RedditAPIPostResponse.self, from: data)
                        if let errors = reportResponse.json.errors {
                            completion(errors)
                        } else {
                            completion([String]())
                        }
                    } catch {
                        print(error)
                    }
                    
                }
            }.resume()
        }
    }
        
    typealias PostsHandler = ([Post], String?) -> Void
    public func fetchPosts(after: String, completion: @escaping PostsHandler) {
        if let _ = defaults.string(forKey: "username") {
            print("fetching posts with acesstoken")
            let url = "\(Const.oauthEndpoint)/r/Pokemongosnap/new.json?sort=new&after=" + after
//            let url = "\(Const.oauthEndpoint)/r/Pogosnap/new.json?sort=new&after=" + after
            getAccessToken { accessToken in
                var postsRequest = URLRequest(url: URL(string: url)!)
                postsRequest.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
                postsRequest.setValue(Const.userAgent, forHTTPHeaderField: "User-Agent")
                URLSession.shared.dataTask(with: postsRequest) { data, response, error in
                    let (posts, nextAfter) = extractPosts(after: after, data: data)
                    completion(posts, nextAfter)
                }.resume()
            }
        } else {
            print("fetching posts without acesstoken")
            let url = "https://www.reddit.com/r/Pokemongosnap/new.json?sort=new&after=" + after
//            let url = "https://www.reddit.com/r/Pogosnap/new.json?sort=new&after=" + after
            URLSession.shared.dataTask(with: URL(string: url)!) { data, response, error in
                let (posts, nextAfter) = extractPosts(after: after, data: data)
                completion(posts, nextAfter)
            }.resume()
        }
    }
    
    public func fetchUserPosts(url: String, after: String, completion: @escaping PostsHandler) {
        URLSession.shared.dataTask(with: URL(string: url)!) { data, response, error in
            let (posts, nextAfter) = extractPosts(after: after, data: data)
            completion(posts, nextAfter)
        }.resume()
    }
    
    private func extractPosts(after: String, data: Data?) -> ([Post], String?) {
        if let data = data {
            var nextAfter: String?
            do {
                var posts = [Post]()
                let decoded = try JSONDecoder().decode(RedditPostResponse.self, from: data)
                if let responseAfter = decoded.data.after, responseAfter != after {
                    nextAfter = responseAfter
                }
                for child in decoded.data.children {
                    let redditPost = child.data
                    var imageUrls = [String]()
                    if let preview = redditPost.preview {
                        if preview.images.count != 0 {
                            imageUrls = preview.images.map { imageUrl in
                                imageUrl.source.url.replacingOccurrences(of: "amp;", with: "")
                            }
                        }
                    } else if let mediaData = redditPost.media_metadata {
                        if mediaData.mediaImages.count != 0 {
                            imageUrls = mediaData.mediaImages.map { imageUrl in
                                imageUrl.replacingOccurrences(of: "amp;", with: "")
                            }
                        }
                    } else {
                        // If it does not contain images at all, do not append
                        continue
                    }
                    let commentsLink = "https://www.reddit.com/r/PokemonGoSnap/comments/" + redditPost.id + ".json"
                    let post = Post(author: redditPost.author, title: redditPost.title, imageUrls: imageUrls, score: redditPost.score, numComments: redditPost.num_comments, commentsLink: commentsLink, archived: redditPost.archived, id: redditPost.id, liked: redditPost.likes)
                    posts.append(post)
                }
                return (posts, nextAfter)
            } catch {
                print(error)
            }
        }
        return ([Post](), nil)
    }
    
    public func isUserAuthenticated() -> Bool {
        if let _ = keychain[Const.accessToken] {
            return true
        } else {
            return false
        }
    }
    
    public func deleteCredentials() {
        do {
            try keychain.remove(Const.accessToken)
            try keychain.remove(Const.refreshToken)
            try keychain.remove(Const.expireDate)
            defaults.removeObject(forKey: Const.username)
        } catch _ {
            print("unable to delete credentials")
        }
    }
    
    public func registerCredentials(accessToken: String, refreshToken: String, expireDate: Date) {
        keychain[Const.accessToken] = accessToken
        keychain[Const.refreshToken] = refreshToken
        keychain[Const.expireDate] = dateToString(date: expireDate)
    }

    
    typealias RulesHandler = (RedditRulesResponse) -> Void
    static func fetchRules(completion: @escaping RulesHandler) {
        if let url = URL(string: "https://www.reddit.com/r/PokemonGoSnap/about/rules.json") {
            URLSession.shared.dataTask(with: url) { data, response, error in
                if let data = data {
                    do {
                        let rulesResponse = try JSONDecoder().decode(RedditRulesResponse.self, from: data)
                        completion(rulesResponse)
                    } catch {
                        print(error)
                    }
                }
            }.resume()
        }
    }
}
