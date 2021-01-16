//
//  HomeViewModel.swift
//  PogoSnap
//
//  Created by Brandon Nguyen on 1/12/21.
//

import Foundation
import IGListKit

class HomeViewModel {
    
    // MARK: - Properties
    private let redditClient: RedditService
    private var imgurClient: ImgurClient
    private var posts = [Post]()
    private var pokemonGoAfter: String? = ""
    private var pokemonGoSnapAfter: String? = ""
    var listLayoutOption = ListLayoutOptions.card
    var sort = SortOptions.hot
    var topOption: String?
    var fetching = false

    var username: String?

    init(redditClient: RedditService, imgurClient: ImgurClient) {
        self.redditClient = redditClient
        self.imgurClient = imgurClient
        self.username = redditClient.getUsername()
    }
    
    func userStatusChanged() -> Bool {
        let previousUsername = username
        username = redditClient.getUsername()
        if previousUsername != username {
            posts = [Post]()
            pokemonGoAfter = ""
            pokemonGoSnapAfter = ""
            return true
        }
        return false
    }
}

extension HomeViewModel {
    func postsIsEmpty() -> Bool {
        return posts.isEmpty || posts.count <= 3
    }
    
    func getPosts() -> [Post] {
        return posts
    }
    
    func getPost(index: Int) -> Post {
        return posts[index]
    }

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

    func removePost(id: String) {
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
        redditClient.fetchRules(subReddit: RedditConsts.pokemonGoSnapSubredditName) { _ in}
        redditClient.fetchRules(subReddit: RedditConsts.pokemonGoSubredditName) { _ in}
    }
    
    func getSubredditRules(subReddit: String) -> [String] {
        return redditClient.getSubredditRules(subReddit: subReddit)
    }
    
    func getSiteRules() -> [String] {
        return redditClient.getSiteRules()
    }
    
    func isUserAuthenticated() -> Bool {
        return redditClient.isUserAuthenticated()
    }
    
    func canDelete(post: Post) -> Bool {
        return post.author == username
    }
}
