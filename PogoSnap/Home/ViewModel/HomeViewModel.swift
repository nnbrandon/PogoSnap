//
//  HomeViewModel.swift
//  PogoSnap
//
//  Created by Brandon Nguyen on 1/12/21.
//

import Foundation
import IGListKit

final class HomeViewModel {
    
    // MARK: - Properties
    let redditClient: RedditClient
    var imgurClient: ImgurClient
    var posts = [Post]()
    var pokemonGoAfter: String? = ""
    var pokemonGoSnapAfter: String? = ""
    var listLayoutOption = ListLayoutOptions.card
    var sort = SortOptions.hot
    var topOption: String?
    var fetching = false

    var postsIsEmpty: Bool {
        return posts.isEmpty || posts.count <= 3
    }
    var username: String?

    init(redditClient: RedditClient, imgurClient: ImgurClient) {
        self.redditClient = redditClient
        self.imgurClient = imgurClient
        self.username = redditClient.getUsername()
    }
}

extension HomeViewModel {
    func fetchPosts(completion: @escaping (String?) -> Void) {
        if pokemonGoAfter != nil || pokemonGoSnapAfter != nil {
            fetching = true
            redditClient.fetchGoAndSnapPosts(pokemonGoAfter: pokemonGoAfter, pokemonGoSnapAfter: pokemonGoSnapAfter, sort: sort.rawValue, topOption: topOption) { result in
                self.fetching = false
                switch result {
                case .success(let posts, let nextPokemonGoSnapAfter, let nextPokemonGoAfter):
                    self.posts.append(contentsOf: posts)
                    self.pokemonGoSnapAfter = nextPokemonGoSnapAfter
                    self.pokemonGoAfter = nextPokemonGoAfter
                    completion(nil)
                case .error(let error):
                    completion(error)
                }
            }
        }
    }

    fileprivate func removePost(id: String) {
        var index = -1
        for (idx, post) in posts.enumerated() where id == post.id {
            index = idx
            break
        }
        if index > -1 {
            posts.remove(at: index)
        }
    }

    func deletePost(id: String, completion: @escaping (String?) -> Void) {
        let postId = "t3_\(id)"
        redditClient.delete(id: postId) { result in
            switch result {
            case .success:
                self.removePost(id: id)
                completion(nil)
            case .error(let error):
                completion(error)
            }
        }
    }
    
    func reportPost(id: String, subReddit: String, reason: String, completion: @escaping (String?) -> Void) {
        let postId = "t3_\(id)"
        redditClient.report(subReddit: subReddit, id: postId, reason: reason) { result in
            switch result {
            case .success:
                self.removePost(id: id)
                completion(nil)
            case .error(let error):
                completion(error)
            }
        }
    }
    
    func votePost(index: Int, direction: Int, completion: @escaping (String?) -> Void) {
        let post = posts[index]
        if direction == 0 {
            if let liked = post.liked {
                if liked {
                    post.liked = nil
                    post.score -= 1
                } else {
                    post.liked = nil
                    post.score += 1
                }
            }
        } else if direction == 1 {
            post.liked = true
            post.score += 1
        } else {
            post.liked = false
            post.score -= 1
        }
        posts[index] = post
        redditClient.votePost(subReddit: post.subReddit, postId: post.id, direction: direction) { _ in}
    }
}

extension HomeViewModel {
    func checkUserStatus() {
        let previousUsername = username
        username = redditClient.getUsername()
        if previousUsername != username {
            posts = [Post]()
            pokemonGoAfter = ""
            pokemonGoSnapAfter = ""
        }
    }
    
    func changeSort(sort: SortOptions, topOption: String?) {
        self.sort = sort
        self.topOption = topOption
        posts = [Post]()
        pokemonGoAfter = ""
        pokemonGoSnapAfter = ""
    }
    
    func changeLayout(layout: ListLayoutOptions) {
        listLayoutOption = layout
    }
    
    func fetchRules() {
        redditClient.fetchRules(subReddit: RedditConsts.subredditName) { _ in}
        redditClient.fetchRules(subReddit: RedditConsts.pokemonGoSubredditName) { _ in}
    }
}
