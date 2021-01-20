//
//  PostsViewModel.swift
//  PogoSnap
//
//  Created by Brandon Nguyen on 1/12/21.
//

import Foundation
import UIKit
import IGListKit

class PostViewModel: ListDiffable {
        
    public let imageSources: [ImageSource]
    public let index: Int
    public let headerText: String
    public let titleText: String
    public let subReddit: String
    public let hideDots: Bool
    public let aspectFit: Bool
    public let archived: Bool
    public let userIconString: String?
    public let authenticated: Bool
    public let author: String
    public let id: String
    
    init(post: Post, index: Int, authenticated: Bool) {
        self.index = index
        self.authenticated = authenticated
        
        let date = Date(timeIntervalSince1970: post.created_utc)
        imageSources = post.imageSources
        headerText = "u/\(post.author)・r/\(post.subReddit)・\(date.timeAgoSinceDate())"
        titleText = post.title
        subReddit = post.subReddit
        hideDots = post.imageSources.count <= 1
        aspectFit = post.aspectFit
        archived = post.archived
        userIconString = post.user_icon
        author = post.author
        id = post.id
    }
        
    func diffIdentifier() -> NSObjectProtocol {
        return "post" as NSObjectProtocol
    }
    
    func isEqual(toDiffableObject object: ListDiffable?) -> Bool {
        guard let object = object as? PostViewModel else { return false }
        return titleText == object.titleText && headerText == object.headerText &&
            subReddit == object.subReddit && userIconString == object.userIconString &&
            authenticated == object.authenticated
    }
}
