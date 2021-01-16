//
//  RedditClient.swift
//  PogoSnap
//
//  Created by Brandon Nguyen on 11/26/20.
//

import Foundation

class RedditService {
    
    static var sharedInstance = RedditService()
    
    let redditOAuth = RedditOAuth()
    let defaults = UserDefaults(suiteName: "group.com.PogoSnap")
    
    // MARK: Caching
    var userIconCache = NSCache<NSString, NSString>()
    var siteRules = [String]()
    var subRedditRules = [String]()

    private init() {}
    
    typealias MeHandler = (RedditMeResult) -> Void
    public func fetchMe(completion: @escaping MeHandler) {
        redditOAuth.getAccessToken { accessToken in
            var meRequest = URLRequest(url: URL(string: RedditConsts.meEndpoint)!)
            meRequest.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
            meRequest.setValue(RedditConsts.userAgent, forHTTPHeaderField: "User-Agent")
            URLSession.shared.dataTask(with: meRequest) { data, _, _ in
                guard let data = data else {
                    completion(RedditMeResult.error(error: "Unable to fetch user information"))
                    return
                }
                do {
                    let meResponse = try JSONDecoder().decode(RedditMeResponse.self, from: data)
                    let filteredIconImg = meResponse.icon_img.replacingOccurrences(of: "amp;", with: "")
                    if let username = self.getUsername(), let icon_img = self.getIconImg() {
                        if username != meResponse.name {
                            self.defaults?.setValue(meResponse.name, forKey: RedditConsts.username)
                        }
                        if icon_img != meResponse.icon_img {
                            self.defaults?.setValue(filteredIconImg, forKey: RedditConsts.icon_img)
                        }
                    } else {
                        self.defaults?.setValue(meResponse.name, forKey: RedditConsts.username)
                        self.defaults?.setValue(filteredIconImg, forKey: RedditConsts.icon_img)
                    }
                    completion(RedditMeResult.success(username: meResponse.name, icon_img: filteredIconImg))
                } catch {}
            }.resume()
        }
    }
    
    typealias JsonHandler = (RedditJsonResult) -> Void
    public func report(subReddit: String, id: String, reason: String, completion: @escaping JsonHandler) {
        let reason = reason.replacingOccurrences(of: " ", with: "%20").replacingOccurrences(of: ",", with: "%2C")
        let apiType = "json"
        let url = "\(RedditConsts.reportEndpoint)?api_type=\(apiType)&reason=\(reason)&thing_id=\(id)&sr_name=\(subReddit)"
        
        redditOAuth.getAccessToken { accessToken in
            var meRequest = URLRequest(url: URL(string: url)!)
            meRequest.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
            meRequest.setValue(RedditConsts.userAgent, forHTTPHeaderField: "User-Agent")
            meRequest.httpMethod = "POST"
            URLSession.shared.dataTask(with: meRequest) { data, _, _ in
                guard let data = data else {
                    completion(RedditJsonResult.error(error: "Unable to report"))
                    return
                }
                do {
                    let reportResponse = try JSONDecoder().decode(RedditAPIPostResponse.self, from: data)
                    if let errors = reportResponse.json.errors, !errors.isEmpty {
                        completion(RedditJsonResult.error(error: "Unable to report"))
                    } else {
                        completion(RedditJsonResult.success(response: nil))
                    }
                } catch {
                    completion(RedditJsonResult.error(error: "Unable to report"))
                }
            }.resume()
        }
    }
    
    typealias CommentHandler = (RedditPostCommentResult) -> Void
    public func postComment(subReddit: String, parentId: String, text: String, completion: @escaping CommentHandler) {
        let apiType = "json"
        let textEncoded = text.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)
        let url = "\(RedditConsts.commentEndpoint)?api_type=\(apiType)&thing_id=\(parentId)&text=\(textEncoded!)&sr_name=\(subReddit)"

        redditOAuth.getAccessToken { accessToken in
            var commentRequest = URLRequest(url: URL(string: url)!)
            commentRequest.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
            commentRequest.setValue(RedditConsts.userAgent, forHTTPHeaderField: "User-Agent")
            commentRequest.httpMethod = "POST"
            URLSession.shared.dataTask(with: commentRequest) { data, response, error in
                guard let httpResponse = response as? HTTPURLResponse, let data = data, httpResponse.statusCode == 200 else {
                    completion(RedditPostCommentResult.error(error: "Unable to post comment"))
                    return
                }
                do {
                    let commentResponse = try JSONDecoder().decode(RedditAPIPostResponse.self, from: data)
                    if let commentThings = commentResponse.json.data?.things, let commentId = commentThings.first?.data?.id {
                        completion(RedditPostCommentResult.success(commentId: commentId))
                    }
                } catch {
                    completion(RedditPostCommentResult.error(error: "Unable to post comment"))
                }
            }.resume()
        }
    }
    
    typealias CombinedPosts = (RedditGoAndSnapResult) -> Void
    public func fetchGoAndSnapPosts(pokemonGoAfter: String?, pokemonGoSnapAfter: String?, sort: String, topOption: String?, completion: @escaping CombinedPosts) {
        let limit = 10
        let requestsGroup = DispatchGroup()

        var pokemonGoSnapPosts = [Post]()
        var nextPokemonGoSnapAfter: String?

        var pokemonGoPosts = [Post]()
        var nextPokemonGoAfter: String?
        
        if let pokemonGoSnapAfter = pokemonGoSnapAfter {
            var pokemonGoSnapURL = getUsername() != nil ? "\(RedditConsts.oauthEndpoint)/r/\(RedditConsts.pokemonGoSnapSubredditName)/\(sort).json?limit=\(limit)&after=" + pokemonGoSnapAfter : "https://www.reddit.com/r/\(RedditConsts.pokemonGoSnapSubredditName)/\(sort).json?limit=\(limit)&after=" + pokemonGoSnapAfter
            if let topOption = topOption {
                pokemonGoSnapURL += "&t=\(topOption)"
            }
            requestsGroup.enter()
            fetchPosts(subReddit: RedditConsts.pokemonGoSnapSubredditName, url: pokemonGoSnapURL, after: pokemonGoSnapAfter) { result in
                switch result {
                case .success(let posts, let nextAfter):
                    pokemonGoSnapPosts = posts
                    nextPokemonGoSnapAfter = nextAfter
                case .error:
                    break
                }
                requestsGroup.leave()
            }
        }
        
        if let pokemonGoAfter = pokemonGoAfter {
            let query = "flair:\"AR SHOT\"".addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)
            var pokemonGoURL = getUsername() != nil ? "\(RedditConsts.oauthEndpoint)/r/\(RedditConsts.pokemonGoSubredditName)/search.json?q=\(query!)&restrict_sr=t&sort=\(sort)&limit=\(limit)&after=" + pokemonGoAfter : "https://www.reddit.com/r/\(RedditConsts.pokemonGoSubredditName)/search.json?q=\(query!)&restrict_sr=t&sort=\(sort)&limit=\(limit)&after=" + pokemonGoAfter
            if let topOption = topOption {
                pokemonGoURL += "&t=\(topOption)"
            }
            requestsGroup.enter()
            fetchPosts(subReddit: RedditConsts.pokemonGoSubredditName, url: pokemonGoURL, after: pokemonGoAfter) { result in
                switch result {
                case .success(let posts, let nextAfter):
                    pokemonGoPosts = posts
                    nextPokemonGoAfter = nextAfter
                case .error:
                    break
                }
                requestsGroup.leave()
            }
        }
        
        requestsGroup.notify(queue: .main) {
            var posts = [Post]()
            let pokemonGoSnapPostsCount = pokemonGoSnapPosts.count - 1
            let pokemonGoPostsCount = pokemonGoPosts.count - 1
            for index in 0..<limit {
                if index <= pokemonGoSnapPostsCount {
                    posts.append(pokemonGoSnapPosts[index])
                }
                if index <= pokemonGoPostsCount {
                    posts.append(pokemonGoPosts[index])
                }
            }
            completion(RedditGoAndSnapResult.success(posts: posts, pokemonGoSnapAfter: nextPokemonGoSnapAfter, pokemonGoAfter: nextPokemonGoAfter))
        }
    }
    
    public func fetchGoAndSnapUserPosts(username: String, user_icon: String?, pokemonGoAfter: String?, pokemonGoSnapAfter: String?, completion: @escaping CombinedPosts) {
        let limit = 20
        let requestsGroup = DispatchGroup()

        var pokemonGoSnapPosts = [Post]()
        var nextPokemonGoSnapAfter: String?

        var pokemonGoPosts = [Post]()
        var nextPokemonGoAfter: String?
        
        if let pokemonGoSnapAfter = pokemonGoSnapAfter {
            let pokemonGoSnapURL = getUsername() != nil ? "\(RedditConsts.oauthEndpoint)/r/\(RedditConsts.pokemonGoSnapSubredditName)/search.json?q=author:\(username)&restrict_sr=t&sort=new&limit=\(limit)&after=" + pokemonGoSnapAfter : "https://www.reddit.com/r/\(RedditConsts.pokemonGoSnapSubredditName)/search.json?q=author:\(username)&restrict_sr=t&sort=new&after=" + pokemonGoSnapAfter
            requestsGroup.enter()
            fetchUserPosts(subReddit: RedditConsts.pokemonGoSnapSubredditName, url: pokemonGoSnapURL, after: pokemonGoSnapAfter, user_icon: user_icon) { result in
                switch result {
                case .success(let posts, let nextAfter):
                    pokemonGoPosts = posts
                    nextPokemonGoAfter = nextAfter
                case .error:
                    break
                }
                requestsGroup.leave()
            }
        }
        
        if let pokemonGoAfter = pokemonGoAfter {
            let query = "author:\(username) AND flair:\"AR SHOT\"".addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)
            let pokemonGoURL = getUsername() != nil ? "\(RedditConsts.oauthEndpoint)/r/\(RedditConsts.pokemonGoSubredditName)/search.json?q=\(query!)&restrict_sr=t&sort=new&limit=\(limit)&after=" + pokemonGoAfter : "https://www.reddit.com/r/\(RedditConsts.pokemonGoSubredditName)/search.json?q=\(query!)&restrict_sr=t&sort=new&limit=\(limit)&after=" + pokemonGoAfter
            requestsGroup.enter()
            fetchUserPosts(subReddit: RedditConsts.pokemonGoSubredditName, url: pokemonGoURL, after: pokemonGoAfter, user_icon: user_icon) { result in
                switch result {
                case .success(let posts, let nextAfter):
                    pokemonGoSnapPosts = posts
                    nextPokemonGoSnapAfter = nextAfter
                case .error:
                    break
                }
                requestsGroup.leave()
            }
        }
        
        requestsGroup.notify(queue: .main) {
            var posts = [Post]()
            let pokemonGoSnapPostsCount = pokemonGoSnapPosts.count - 1
            let pokemonGoPostsCount = pokemonGoPosts.count - 1
            for index in 0..<limit {
                if index <= pokemonGoSnapPostsCount {
                    posts.append(pokemonGoSnapPosts[index])
                }
                if index <= pokemonGoPostsCount {
                    posts.append(pokemonGoPosts[index])
                }
            }
            completion(RedditGoAndSnapResult.success(posts: posts, pokemonGoSnapAfter: nextPokemonGoSnapAfter, pokemonGoAfter: nextPokemonGoAfter))
        }
    }
        
    typealias PostsHandler = (RedditPostsResult) -> Void
    public func fetchPosts(subReddit: String, url: String, after: String, completion: @escaping PostsHandler) {
        if getUsername() != nil {
            redditOAuth.getAccessToken { accessToken in
                var postsRequest = URLRequest(url: URL(string: url)!)
                postsRequest.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
                postsRequest.setValue(RedditConsts.userAgent, forHTTPHeaderField: "User-Agent")
                URLSession.shared.dataTask(with: postsRequest) { data, response, _ in
                    guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200, let data = data else {
                        completion(RedditPostsResult.error(error: "Unable to fetch posts"))
                        return
                    }
                    let (posts, nextAfter) = self.extractPosts(subReddit: subReddit, after: after, data: data, user_icon: nil)
                    self.assignUserImageIcons(posts: posts) { postsWithImageIcons in
                        completion(RedditPostsResult.success(posts: postsWithImageIcons, nextAfter: nextAfter))
                    }
                }.resume()
            }
        } else {
            URLSession.shared.dataTask(with: URL(string: url)!) { data, response, _ in
                guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200, let data = data else {
                    completion(RedditPostsResult.error(error: "Unable to fetch posts"))
                    return
                }
                let (posts, nextAfter) = self.extractPosts(subReddit: subReddit, after: after, data: data, user_icon: nil)
                self.assignUserImageIcons(posts: posts) { postsWithImageIcons in
                    completion(RedditPostsResult.success(posts: postsWithImageIcons, nextAfter: nextAfter))
                }
            }.resume()
        }
    }
    
    public func fetchUserPosts(subReddit: String, url: String, after: String, user_icon: String?, completion: @escaping PostsHandler) {
        if getUsername() != nil {
            redditOAuth.getAccessToken { accessToken in
                var postsRequest = URLRequest(url: URL(string: url)!)
                postsRequest.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
                postsRequest.setValue(RedditConsts.userAgent, forHTTPHeaderField: "User-Agent")
                URLSession.shared.dataTask(with: postsRequest) { data, response, error in
                    guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200, let data = data else {
                        completion(RedditPostsResult.error(error: "Unable to fetch posts"))
                        return
                    }
                    let (posts, nextAfter) = self.extractPosts(subReddit: subReddit, after: after, data: data, user_icon: user_icon)
                    completion(RedditPostsResult.success(posts: posts, nextAfter: nextAfter))
                }.resume()
            }
        } else {
            URLSession.shared.dataTask(with: URL(string: url)!) { data, response, error in
                guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200, let data = data else {
                    completion(RedditPostsResult.error(error: "Unable to fetch posts"))
                    return
                }
                let (posts, nextAfter) = self.extractPosts(subReddit: subReddit, after: after, data: data, user_icon: user_icon)
                completion(RedditPostsResult.success(posts: posts, nextAfter: nextAfter))
            }.resume()
        }
    }
    
    public func searchPosts(subReddit: String, query: String, after: String, sort: String, topOption: String?, completion: @escaping PostsHandler) {
        let limit = 40
        var query = query
        if subReddit == RedditConsts.pokemonGoSubredditName {
            query += " AND flair:\"AR SHOT\""
        }
        query = query.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!
        if getUsername() != nil {
            var url = "\(RedditConsts.oauthEndpoint)/r/\(subReddit)/search.json?q=\(query)&restrict_sr=t&sort=\(sort)&limit=\(limit)&after=\(after)"
            if let topOption = topOption {
                url += "&t=\(topOption)"
            }
            redditOAuth.getAccessToken { accessToken in
                var postsRequest = URLRequest(url: URL(string: url)!)
                postsRequest.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
                postsRequest.setValue(RedditConsts.userAgent, forHTTPHeaderField: "User-Agent")
                URLSession.shared.dataTask(with: postsRequest) { data, _, _ in
                    let (posts, nextAfter) = self.extractPosts(subReddit: subReddit, after: after, data: data, user_icon: nil)
                    self.assignUserImageIcons(posts: posts) { postsWithImageIcons in
                        completion(RedditPostsResult.success(posts: postsWithImageIcons, nextAfter: nextAfter))
                    }
                }.resume()
            }
        } else {
            var url = "https://www.reddit.com/r/\(RedditConsts.pokemonGoSnapSubredditName)/search.json?q=\(query)&restrict_sr=t&sort=\(sort)&limit=\(limit)&after=\(after)"
            if let topOption = topOption {
                url += "&t=\(topOption)"
            }
            URLSession.shared.dataTask(with: URL(string: url)!) { data, _, _ in
                let (posts, nextAfter) = self.extractPosts(subReddit: subReddit, after: after, data: data, user_icon: nil)
                self.assignUserImageIcons(posts: posts) { postsWithImageIcons in
                    completion(RedditPostsResult.success(posts: postsWithImageIcons, nextAfter: nextAfter))
                }
            }.resume()
        }
    }
    
    private func extractPosts(subReddit: String, after: String, data: Data?, user_icon: String?) -> ([Post], String?) {
        if let data = data {
            var nextAfter: String?
            do {
                var posts = [Post]()
                let decoded = try JSONDecoder().decode(RedditPostResponse.self, from: data)
                if let responseAfter = decoded.data.after, responseAfter != after {
                    nextAfter = responseAfter
                }
                
                for child in decoded.data.children {
                    var aspectFit = false

                    let redditPost = child.data
                    var imageSources = [ImageSource]()
                    if let preview = redditPost.preview, !preview.images.isEmpty {
                        imageSources = preview.images.map { image in
                            let url = image.source.url.replacingOccurrences(of: "amp;", with: "")
                            if image.source.width >= image.source.height {
                                aspectFit = true
                            }
                            return ImageSource(url: url, width: image.source.width, height: image.source.height)
                        }
                    } else if let mediaData = redditPost.media_metadata, !mediaData.mediaImages.isEmpty {
                        imageSources = mediaData.mediaImages.map { image in
                            let url = image.url.replacingOccurrences(of: "amp;", with: "")
                            if image.width >= image.height {
                                aspectFit = true
                            }
                            return ImageSource(url: url, width: image.width, height: image.height)
                        }
                    } else {
                        // If it does not contain images at all, do not append
                        continue
                    }
                    let commentsLink = "https://www.reddit.com/r/\(subReddit)/comments/" + redditPost.id + ".json"
                    let post = Post(author: redditPost.author, title: redditPost.title, imageSources: imageSources, score: redditPost.score, numComments: redditPost.num_comments, commentsLink: commentsLink, archived: redditPost.archived, id: redditPost.id, created_utc: redditPost.created_utc, liked: redditPost.likes, aspectFit: aspectFit, user_icon: user_icon, subReddit: subReddit)
                    posts.append(post)
                }
                return (posts, nextAfter)
            } catch {
                return ([Post](), nil)
            }
        }
        return ([Post](), nil)
    }
    
    private func assignUserImageIcons(posts: [Post], completion: @escaping ([Post]) -> Void) {
        let usernames = posts.map { post in post.author }
        let userAboutGroup = DispatchGroup()
        
        for username in usernames where userIconCache.object(forKey: username as NSString) == nil {
            userAboutGroup.enter()
            fetchUserAbout(username: username) { result in
                switch result {
                case .success(_, let icon_img):
                    self.userIconCache.setObject(icon_img as NSString, forKey: username as NSString)
                case .error:
                    break
                }
                userAboutGroup.leave()
            }
        }
        
        userAboutGroup.notify(queue: .main) {
            let postsWithIcons = posts.map { post -> Post in
                let username = post.author as NSString
                post.user_icon = self.userIconCache.object(forKey: username) as String?
                return post
            }
            completion(postsWithIcons)
        }
    }
    
    typealias BoolHandler = (RedditBoolResult) -> Void
    public func votePost(subReddit: String, postId: String, direction: Int, completion: @escaping BoolHandler) {
        let postId = "t3_" + postId
        let url = "\(RedditConsts.voteEndpoint)?id=\(postId)&dir=\(direction)&sr_name=\(subReddit)"
        
        redditOAuth.getAccessToken { accessToken in
            var meRequest = URLRequest(url: URL(string: url)!)
            meRequest.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
            meRequest.setValue(RedditConsts.userAgent, forHTTPHeaderField: "User-Agent")
            meRequest.httpMethod = "POST"
            URLSession.shared.dataTask(with: meRequest) { _, response, _ in
                guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                    completion(RedditBoolResult.error(error: "Unable to vote post"))
                    return
                }
                completion(RedditBoolResult.success)
            }.resume()
        }
    }
    
    public func delete(id: String, completion: @escaping BoolHandler) {
        let url = "\(RedditConsts.deleteEndpoint)?id=\(id)"
        redditOAuth.getAccessToken { accessToken in
            var deleteRequest = URLRequest(url: URL(string: url)!)
            deleteRequest.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
            deleteRequest.setValue(RedditConsts.userAgent, forHTTPHeaderField: "User-Agent")
            deleteRequest.httpMethod = "POST"
            URLSession.shared.dataTask(with: deleteRequest) { _, response, _ in
                guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                    completion(RedditBoolResult.error(error: "Unable to delete"))
                    return
                }
                completion(RedditBoolResult.success)
            }.resume()
        }
    }
    
    public func submitImageLink(link: String, text: String, completion: @escaping JsonHandler) {
        let apiType = "json"
        let kind = "link"
        let textEncoded = text.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)
        let url = "\(RedditConsts.submitEndpoint)?api_type=\(apiType)&sr=\(RedditConsts.pokemonGoSnapSubredditName)&title=\(textEncoded!)&kind=\(kind)&url=\(link)"
        
        redditOAuth.getAccessToken { accessToken in
            var submitRequest = URLRequest(url: URL(string: url)!)
            submitRequest.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
            submitRequest.setValue(RedditConsts.userAgent, forHTTPHeaderField: "User-Agent")
            submitRequest.httpMethod = "POST"
            URLSession.shared.dataTask(with: submitRequest) { data, response, _ in
                guard let httpResponse = response as? HTTPURLResponse, let data = data, httpResponse.statusCode == 200 else {
                    completion(RedditJsonResult.error(error: "Unable to post to Reddit"))
                    return
                }
                do {
                    let submitResponse = try JSONDecoder().decode(RedditAPIPostResponse.self, from: data)
                    if let postData = submitResponse.json.data {
                        completion(RedditJsonResult.success(response: postData))
                    } else {
                        completion(RedditJsonResult.error(error: "Unable to post to Reddit"))
                    }
                } catch {
                    completion(RedditJsonResult.error(error: "Unable to post to Reddit"))
                }
            }.resume()
        }
    }
    
    public func getUsername() -> String? {
        return defaults?.string(forKey: RedditConsts.username)
    }
    
    public func getIconImg() -> String? {
        return defaults?.string(forKey: RedditConsts.icon_img)
    }
    
    public func isUserAuthenticated() -> Bool {
        return redditOAuth.isUserAuthenticated()
    }
    
    public func getSubredditRules(subReddit: String) -> [String] {
        if subRedditRules.isEmpty {
            guard let subRedditRules = self.defaults?.stringArray(forKey: subReddit) else {
                return [String]()
            }
            self.subRedditRules = subRedditRules
        }
        return subRedditRules
    }
    
    public func getSiteRules() -> [String] {
        if siteRules.isEmpty {
            guard let siteRules = self.defaults?.stringArray(forKey: "SiteRules") else {
                return [String]()
            }
            self.siteRules = siteRules
        }
        return siteRules
    }
    
    public func deleteCredentials() {
        defaults?.removeObject(forKey: RedditConsts.username)
        defaults?.removeObject(forKey: RedditConsts.icon_img)
        defaults?.removeObject(forKey: RedditConsts.redditExpireDate)
        redditOAuth.deleteCredentials()
    }
    
    typealias RulesHandler = (RedditRulesResult) -> Void
    public func fetchRules(subReddit: String, completion: @escaping RulesHandler) {
        if let url = URL(string: "https://www.reddit.com/r/\(subReddit)/about/rules.json") {
            URLSession.shared.dataTask(with: url) { data, response, _ in
                guard let httpResponse = response as? HTTPURLResponse, let data = data, httpResponse.statusCode == 200 else {
                    completion(RedditRulesResult.error(error: "Unable to fetch rules"))
                    return
                }
                do {
                    let rulesResponse = try JSONDecoder().decode(RedditRulesResponse.self, from: data)
                    let subredditRules = rulesResponse.rules.map { subRedditRule in
                        subRedditRule.short_name
                    }
                    let siteRules = rulesResponse.site_rules
                    
                    self.defaults?.setValue(subredditRules, forKey: subReddit)
                    self.defaults?.setValue(siteRules, forKey: "SiteRules")
                    
                    completion(RedditRulesResult.success(rules: rulesResponse))
                } catch {
                    completion(RedditRulesResult.error(error: "Unable to fetch rules"))
                }
            }.resume()
        }
    }
    
    public func fetchUserAbout(username: String, completion: @escaping MeHandler) {
        if let url = URL(string: "https://www.reddit.com/user/\(username)/about.json") {
            URLSession.shared.dataTask(with: url) { data, response, _ in
                guard let httpResponse = response as? HTTPURLResponse, let data = data, httpResponse.statusCode == 200 else {
                    completion(RedditMeResult.error(error: "Unable to fetch user profile information"))
                    return
                }
                do {
                    let aboutResponse = try JSONDecoder().decode(RedditAboutResponse.self, from: data)
                    let filteredIconImg = aboutResponse.data.icon_img.replacingOccurrences(of: "amp;", with: "")
                    completion(RedditMeResult.success(username: aboutResponse.data.name, icon_img: filteredIconImg))
                } catch {
                    completion(RedditMeResult.error(error: "Unable to fetch user profile information"))
                }
            }.resume()
        }
    }
}
