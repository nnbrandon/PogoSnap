//
//  BasePostsProtocol.swift
//  PogoSnap
//
//  Created by Brandon Nguyen on 1/15/21.
//

import Foundation

protocol BasePostsViewModelProtocol: class {
    
    var listLayoutOption: ListLayoutOptions { get }
    var sort: SortOptions { get }
    var topOption: String? { get }
    var fetching: Bool { get }

    func getPosts() -> [Post]
    
    func getPost(index: Int) -> Post
    
    func canDelete(post: Post) -> Bool
    
    func postsIsEmpty() -> Bool
    
    func checkUserStatus()

    func fetchPosts(completion: @escaping (String?) -> Void)
    
    func fetchRules()

    func removePost(id: String)

    func deletePost(id: String, completion: @escaping (String?) -> Void)
    
    func reportPost(id: String, subReddit: String, reason: String, completion: @escaping (String?) -> Void)
    
    func isUserAuthenticated() -> Bool
    
    func getSubredditRules(subReddit: String) -> [String]
    
    func getSiteRules() -> [String]
    
    func changeSort(sort: SortOptions, topOption: String?)
    
    func changeLayout(layout: ListLayoutOptions)
    
}
