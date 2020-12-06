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
        consumerKey:    Const.redditClientId,
        consumerSecret: Const.redditClientSecret,
        authorizeUrl:   Const.redditAuthorizeUrl,
        accessTokenUrl: Const.redditAccessTokenUrl,
        responseType:   Const.responseType
    )
    let keychain = Keychain(service: "com.PogoSnap", accessGroup: "group.com.PogoSnap")
    let defaults = UserDefaults(suiteName: "group.com.PogoSnap")
    
    private init() {}

    struct Const {
//        static let subredditName = "PokemonGoSnap"
        static let subredditName = "PogoSnap"

        static let username = "username"
        static let redditAccessToken = "redditAccessToken"
        static let redditRefreshToken = "redditRefreshToken"
        static let redditExpireDate = "redditExpireDate"

        static let redditClientId = "f5M2aPLjT8rUgg"
        static let redditClientSecret = ""
        static let redditAuthorizeUrl = "https://www.reddit.com/api/v1/authorize.compact"
        static let redditAccessTokenUrl = "https://www.reddit.com/api/v1/access_token"
        static let redditCallbackURL = "PogoSnap://response"

        static let responseType = "code"
        static let duration = "permanent"
        static let scope = "read submit identity report save history vote"
        
        static let userAgent = "ios:PogoSnap:1.0.0 (by /u/nnbrandon)"
        static let oauthEndpoint = "https://oauth.reddit.com"
        static let meEndpoint = oauthEndpoint + "/api/v1/me"
        static let reportEndpoint = oauthEndpoint + "/api/report"
        static let voteEndpoint = oauthEndpoint + "/api/vote"
        static let commentEndpoint = oauthEndpoint + "/api/comment"
        static let submitEndpoint = oauthEndpoint + "/api/submit"
    }
    
    private func isTokenExpired(expireDate: Date) -> Bool {
        return expireDate <= Date()
    }
    
    typealias TokenHandler = (String) -> Void
    private func getAccessToken(completion: @escaping TokenHandler) {
        if let accessToken = keychain[Const.redditAccessToken], let refreshToken = keychain[Const.redditRefreshToken], let expireDate = defaults?.object(forKey: Const.redditExpireDate) as? Date {
            if isTokenExpired(expireDate: expireDate) {
                oauthSwift.accessTokenBasicAuthentification = true
                oauthSwift.renewAccessToken(withRefreshToken: refreshToken) { result in
                    switch result {
                    case .success(let (credential, _, _)):
                        keychain[Const.redditAccessToken] = credential.oauthToken
                        if let expireDate = credential.oauthTokenExpiresAt {
                            defaults?.set(expireDate, forKey: Const.redditExpireDate)
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
        return defaults?.string(forKey: Const.username)
    }
    
    typealias MeHandler = (String, String) -> Void
    public func fetchMe(completion: @escaping MeHandler) {
        getAccessToken { accessToken in
            var meRequest = URLRequest(url: URL(string: Const.meEndpoint)!)
            meRequest.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
            meRequest.setValue(Const.userAgent, forHTTPHeaderField: "User-Agent")
            URLSession.shared.dataTask(with: meRequest) { data, response, error in
                if let data = data {
                    do {
                        let meResponse = try JSONDecoder().decode(RedditMeResponse.self, from: data)
                        defaults?.setValue(meResponse.name, forKey: Const.username)
                        completion(meResponse.name, meResponse.icon_img)
                    } catch {
                        print(error)
                    }

                }
            }.resume()
        }
    }
    
    // errors, PostData
    typealias JsonHandler = ([String], PostData?) -> Void
    public func reportPost(postId: String, reason: String, completion: @escaping JsonHandler) {
        let postId = "t3_" + postId
        let reason = reason.replacingOccurrences(of: " ", with: "%20").replacingOccurrences(of: ",", with: "%2C")
        let apiType = "json"
        let url = "\(Const.reportEndpoint)?api_type=\(apiType)&reason=\(reason)&thing_id=\(postId)&sr_name=\(Const.subredditName)"
        
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
                            completion(errors, nil)
                        } else {
                            completion([String](), nil)
                        }
                    } catch {
                        print(error)
                    }
                    
                }
            }.resume()
        }
    }
    
    public func postComment(postId: String, text: String, completion: @escaping JsonHandler) {
        let postId = "t3_" + postId
        let apiType = "json"
        let textEncoded = text.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)
        let url = "\(Const.commentEndpoint)?api_type=\(apiType)&thing_id=\(postId)&text=\(textEncoded!)&sr_name=\(Const.subredditName)"

        getAccessToken { accessToken in
            var commentRequest = URLRequest(url: URL(string: url)!)
            commentRequest.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
            commentRequest.setValue(Const.userAgent, forHTTPHeaderField: "User-Agent")
            commentRequest.httpMethod = "POST"
            URLSession.shared.dataTask(with: commentRequest) { data, response, error in
                if error != nil {
                    completion(["failed"], nil)
                }
                
                if let httpResponse = response as? HTTPURLResponse, let data = data {
                    if httpResponse.statusCode == 200 {
                        do {
                            let commentResponse = try JSONDecoder().decode(RedditAPIPostResponse.self, from: data)
                            if let errors = commentResponse.json.errors {
                                completion(errors, nil)
                            } else {
                                completion([String](), nil)
                            }
                        } catch {
                            print(error)
                        }
                    } else {
                        completion(["failed"], nil)
                    }
                }
            }.resume()
        }
    }
        
    typealias PostsHandler = ([Post], String?) -> Void
    public func fetchPosts(after: String, sort: String, completion: @escaping PostsHandler) {
        if let _ = defaults?.string(forKey: "username") {
            print("fetching posts with acesstoken")
            let url = "\(Const.oauthEndpoint)/r/\(Const.subredditName)/\(sort).json?after=" + after
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
            let url = "https://www.reddit.com/r/\(Const.subredditName)/\(sort).json?after=" + after
            URLSession.shared.dataTask(with: URL(string: url)!) { data, response, error in
                let (posts, nextAfter) = extractPosts(after: after, data: data)
                completion(posts, nextAfter)
            }.resume()
        }
    }
    
    public func fetchUserPosts(username: String, after: String, completion: @escaping PostsHandler) {
        var url = ""
        if getUsername() != nil {
            url = "\(Const.oauthEndpoint)/r/\(RedditClient.Const.subredditName)/search.json?q=author:\(username)&restrict_sr=t&sort=new"
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
            url = "https://www.reddit.com/r/\(RedditClient.Const.subredditName)/search.json?q=author:\(username)&restrict_sr=t&sort=new"
            URLSession.shared.dataTask(with: URL(string: url)!) { data, response, error in
                let (posts, nextAfter) = extractPosts(after: after, data: data)
                completion(posts, nextAfter)
            }.resume()
        }
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
                    var imageSources = [ImageSource]()
                    if let preview = redditPost.preview {
                        if preview.images.count != 0 {
                            imageSources = preview.images.map { image in
                                let url = image.source.url.replacingOccurrences(of: "amp;", with: "")
                                return ImageSource(url: url, width: image.source.width, height: image.source.height)
                            }
                        }
                    } else if let mediaData = redditPost.media_metadata {
                        if mediaData.mediaImages.count != 0 {
                            imageSources = mediaData.mediaImages.map { image in
                                let url = image.url.replacingOccurrences(of: "amp;", with: "")
                                return ImageSource(url: url, width: image.width, height: image.height)
                            }
                        }
                    } else {
                        // If it does not contain images at all, do not append
                        continue
                    }
                    let commentsLink = "https://www.reddit.com/r/\(Const.subredditName)/comments/" + redditPost.id + ".json"
                    let post = Post(author: redditPost.author, title: redditPost.title, imageSources: imageSources, score: redditPost.score, numComments: redditPost.num_comments, commentsLink: commentsLink, archived: redditPost.archived, id: redditPost.id, liked: redditPost.likes)
                    posts.append(post)
                }
                return (posts, nextAfter)
            } catch {
                print(error)
            }
        }
        return ([Post](), nil)
    }
    
    typealias BoolHandler = (Bool) -> Void
    public func votePost(postId: String, direction: Int, completion: @escaping BoolHandler) {
        let postId = "t3_" + postId
        let url = "\(Const.voteEndpoint)?id=\(postId)&dir=\(direction)&sr_name=\(Const.subredditName)"
        
        getAccessToken { accessToken in
            var meRequest = URLRequest(url: URL(string: url)!)
            meRequest.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
            meRequest.setValue(Const.userAgent, forHTTPHeaderField: "User-Agent")
            meRequest.httpMethod = "POST"
            URLSession.shared.dataTask(with: meRequest) { data, response, error in
                if error != nil {
                    completion(false)
                }
                
                if let httpResponse = response as? HTTPURLResponse {
                    if httpResponse.statusCode == 200 {
                        completion(true)
                    } else {
                        completion(false)
                    }
                }
            }.resume()
        }
    }
    
    public func submitImageLink(link: String, text: String, completion: @escaping JsonHandler) {
        print(link)
        let apiType = "json"
        let kind = "link"
        let textEncoded = text.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)
        let url = "\(Const.submitEndpoint)?api_type=\(apiType)&sr=\(Const.subredditName)&title=\(textEncoded!)&kind=\(kind)&url=\(link)"
        
        getAccessToken { accessToken in
            var submitRequest = URLRequest(url: URL(string: url)!)
            submitRequest.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
            submitRequest.setValue(Const.userAgent, forHTTPHeaderField: "User-Agent")
            submitRequest.httpMethod = "POST"
            URLSession.shared.dataTask(with: submitRequest) { data, response, error in
                if error != nil {
                    completion(["failed"], nil)
                }
                
                if let httpResponse = response as? HTTPURLResponse, let data = data {
                    if httpResponse.statusCode == 200 {
                        do {
                            let submitResponse = try JSONDecoder().decode(RedditAPIPostResponse.self, from: data)
                            if let postData = submitResponse.json.data {
                                completion([String](), postData)
                            } else {
                                completion(["failed"], nil)
                            }
                        } catch {
                            print(error)
                        }
                    } else {
                        completion(["failed"], nil)
                    }
                }
            }.resume()
        }
    }
    
    
    public func isUserAuthenticated() -> Bool {
        if let _ = keychain[Const.redditAccessToken] {
            return true
        } else {
            return false
        }
    }
    
    public func deleteCredentials() {
        do {
            try keychain.remove(Const.redditAccessToken)
            try keychain.remove(Const.redditRefreshToken)
            defaults?.removeObject(forKey: Const.username)
            defaults?.removeObject(forKey: Const.redditExpireDate)
        } catch _ {
            print("unable to delete credentials")
        }
    }
    
    public func registerCredentials(accessToken: String, refreshToken: String, expireDate: Date) {
        keychain[Const.redditAccessToken] = accessToken
        keychain[Const.redditRefreshToken] = refreshToken
        defaults?.set(expireDate, forKey: Const.redditExpireDate)
    }
    
    typealias RulesHandler = (RedditRulesResponse) -> Void
    static func fetchRules(completion: @escaping RulesHandler) {
        if let url = URL(string: "https://www.reddit.com/r/\(Const.subredditName)/about/rules.json") {
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
