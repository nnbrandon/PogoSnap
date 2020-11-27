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
    
    typealias PostsHandler = ([Post], String?) -> Void
    
    static func fetchPosts(url: String, after: String, completion: @escaping PostsHandler) {
        if let url = URL(string: url) {
            URLSession.shared.dataTask(with: url) { data, response, error in
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
                            var imageUrl = ""
                            if let preview = redditPost.preview {
                                if preview.images.count != 0 {
                                    let sourceUrl = preview.images[0].source.url
                                    imageUrl = sourceUrl.replacingOccurrences(of: "amp;", with: "")
                                }
                            } else if let mediaData = redditPost.media_metadata {
                                if mediaData.mediaImages.count != 0 {
                                    let sourceUrl = mediaData.mediaImages[0]
                                    imageUrl = sourceUrl.replacingOccurrences(of: "amp;", with: "")
                                }
                            } else {
                                // If it does not contain images at all, do not append
                                continue
                            }
                            let commentsLink = "https://www.reddit.com/r/PokemonGoSnap/comments/" + redditPost.id + ".json"
                            let post = Post(author: redditPost.author, title: redditPost.title, imageUrl: imageUrl, score: redditPost.score, numComments: redditPost.num_comments, commentsLink: commentsLink)
                            posts.append(post)
                        }
                        completion(posts, nextAfter)
                    } catch {
                        print(error)
                    }
                }
            }.resume()
        }
    }
}
