//
//  PostListController.swift
//  PogoSnap
//
//  Created by Brandon Nguyen on 12/14/20.
//

import UIKit
import IGListKit

/**
 An abstract view controller to conform to when you need to deal with anything related
 to Reddit posts. This view controller already conforms to the PostViewDelegate and implements
 basic functionality of tapping a comment, username, image, options, and upvote/downvote.
 
 View Controllers that do conform to this must make sure to add the data source to the adapter and
 must conform and implement ListAdapterDataSource.
 */
class PostCollectionController: UIViewController {
    
    lazy var posts = [ListDiffable]() {
        didSet {
            DispatchQueue.main.async {
                self.adapter.performUpdates(animated: true, completion: nil)
            }
        }
    }
    var pokemonGoAfter: String? = ""
    var pokemonGoSnapAfter: String? = ""
    var listLayoutOption = ListLayoutOptions.card

    let collectionView = UICollectionView(frame: .zero, collectionViewLayout: ListCollectionViewLayout(stickyHeaders: false, scrollDirection: .vertical, topContentInset: 0, stretchToEdge: false))
    lazy var adapter: ListAdapter = {
      return ListAdapter(
      updater: ListAdapterUpdater(),
      viewController: self,
      workingRangeSize: 10)
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(collectionView)
    }
    
    public func pinCollectionView(to superView: UIView) {
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.topAnchor.constraint(equalTo: superView.topAnchor).isActive = true
        collectionView.leadingAnchor.constraint(equalTo: superView.leadingAnchor).isActive = true
        collectionView.trailingAnchor.constraint(equalTo: superView.trailingAnchor).isActive = true
        collectionView.bottomAnchor.constraint(equalTo: superView.bottomAnchor).isActive = true
    }

    private func votePost(subReddit: String, id: String, direction: Int, index: Int) {
        RedditClient.sharedInstance.votePost(subReddit: subReddit, postId: id, direction: direction) { _ in}
    }
    
    private func deletePost(id: String) {
        let postId = "t3_\(id)"
        RedditClient.sharedInstance.delete(id: postId) { result in
            switch result {
            case .success:
                var indexFound = -1
                for (index, post) in self.posts.enumerated() {
                    if let post = post as? Post, post.id == id {
                        indexFound = index
                        break
                    }
                }
                if indexFound > -1 {
                    self.posts.remove(at: indexFound)
                    DispatchQueue.main.async {
                        generatorImpactOccured()
                        if let navController = self.navigationController {
                            showSuccessToast(controller: navController, message: "Deleted", seconds: 0.5)
                        }
                    }
                }
            case .error:
                DispatchQueue.main.async {
                    generatorImpactOccured()
                    if let navController = self.navigationController {
                        showErrorToast(controller: navController, message: "Could not delete the post", seconds: 0.5)
                    }
                }
            }
        }
    }
    
    private func reportPost(subReddit: String, id: String, reason: String) {
        let postId = "t3_\(id)"
        RedditClient.sharedInstance.report(subReddit: subReddit, id: postId, reason: reason) { result in
            switch result {
            case .success:
                DispatchQueue.main.async {
                    generatorImpactOccured()
                    if let navController = self.navigationController {
                        showSuccessToast(controller: navController, message: "Reported", seconds: 0.5)
                    }
                }
            case .error:
                DispatchQueue.main.async {
                    generatorImpactOccured()
                    if let navController = self.navigationController {
                        showErrorToast(controller: navController, message: "Could not report the post", seconds: 0.5)
                    }
                }
            }
        }
    }
}

extension PostCollectionController: PostViewDelegate, ProfileImageDelegate {

    func didTapComment(post: Post, index: Int) {
        var imageFrameHeight = view.frame.width
        if !post.aspectFit {
            imageFrameHeight += view.frame.width/2
        }
        var height = 8 + 50 + 40 + imageFrameHeight
        let title = post.title
        let titleEstimatedHeight = title.height(withConstrainedWidth: view.frame.width - 16, font: UIFont.boldSystemFont(ofSize: 18))
        height += titleEstimatedHeight
        
        let redditCommentsController = RedditCommentsController()
        redditCommentsController.hidesBottomBarWhenPushed = true
        redditCommentsController.commentsLink = post.commentsLink
        redditCommentsController.archived = post.archived
        redditCommentsController.post = post
        redditCommentsController.index = index
        redditCommentsController.postView.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: height)
        redditCommentsController.delegate = self
        navigationController?.pushViewController(redditCommentsController, animated: true)
    }
    
    func didTapUsername(username: String, user_icon: String?) {
        let userProfileController = UserProfileController()
        userProfileController.usernameProp = username
        userProfileController.icon_imgProp = user_icon
        navigationController?.pushViewController(userProfileController, animated: true)
    }
    
    func didTapImage(imageSources: [ImageSource], position: Int) {
        let fullScreen = FullScreenImageController()
        fullScreen.imageSources = imageSources
        fullScreen.position = position
        present(fullScreen, animated: true, completion: nil)
    }
    
    func didTapOptions(post: Post) {
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: getCurrentInterfaceForAlerts())
        alertController.addAction(UIAlertAction(title: "Report", style: .default, handler: { _ in
            
            if !RedditClient.sharedInstance.isUserAuthenticated() {
                DispatchQueue.main.async {
                    if let navController = self.navigationController {
                        showErrorToast(controller: navController, message: "You need to be signed in to report", seconds: 1.0)
                    }
                }
                return
            }
            
            let reportOptionsController = UIAlertController(title: nil, message: nil, preferredStyle: getCurrentInterfaceForAlerts())
            reportOptionsController.addAction(UIAlertAction(title: "r/\(post.subReddit) Rules", style: .default, handler: { _ in
                
                let subredditRulesController = UIAlertController(title: nil, message: nil, preferredStyle: getCurrentInterfaceForAlerts())
                let subredditRules = RedditClient.sharedInstance.getSubredditRules(subReddit: post.subReddit)
                for rule in subredditRules {
                    subredditRulesController.addAction(UIAlertAction(title: rule, style: .default, handler: { action in
                        if let reason = action.title {
                            self.reportPost(subReddit: post.subReddit, id: post.id, reason: reason)
                        }
                    }))
                }
                subredditRulesController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
                self.present(subredditRulesController, animated: true, completion: nil)
            }))
                        
            reportOptionsController.addAction(UIAlertAction(title: "Spam or Abuse", style: .default, handler: { _ in
                let siteRulesController = UIAlertController(title: nil, message: nil, preferredStyle: getCurrentInterfaceForAlerts())
                let siteRules = RedditClient.sharedInstance.getSiteRules()
                for rule in siteRules {
                    siteRulesController.addAction(UIAlertAction(title: rule, style: .default, handler: { action in
                        if let reason = action.title {
                            self.reportPost(subReddit: post.subReddit, id: post.id, reason: reason)
                        }
                    }))
                }
                siteRulesController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
                self.present(siteRulesController, animated: true, completion: nil)
            }))
            
            reportOptionsController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            self.present(reportOptionsController, animated: true, completion: nil)
        }))
        if let username = RedditClient.sharedInstance.getUsername(), username == post.author {
            alertController.addAction(UIAlertAction(title: "Delete", style: .destructive, handler: { _ in
                self.deletePost(id: post.id)
            }))
        }
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        present(alertController, animated: true, completion: nil)
    }
    
    func didTapVote(post: Post, direction: Int, index: Int, authenticated: Bool, archived: Bool) {
        if !authenticated {
            DispatchQueue.main.async {
                if let navController = self.navigationController {
                    showErrorToast(controller: navController, message: "You need to be signed in to like", seconds: 1.0)
                }
            }
        } else if archived {
            DispatchQueue.main.async {
                if let navController = self.navigationController {
                    showErrorToast(controller: navController, message: "This post has been archived", seconds: 1.0)
                }
            }
        } else {
//            if direction == 0 {
//                if let liked = posts[index].liked {
//                    if liked {
//                        posts[index].liked = nil
//                        posts[index].score -= 1
//                    } else {
//                        posts[index].liked = nil
//                        posts[index].score += 1
//                    }
//                }
//            } else if direction == 1 {
//                posts[index].liked = true
//                posts[index].score += 1
//            } else {
//                posts[index].liked = false
//                posts[index].score -= 1
//            }
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
            adapter.reloadObjects([post])
//            adapter.reloadObjects([posts[index]])
            votePost(subReddit: post.subReddit, id: post.id, direction: direction, index: index)
        }
    }
    
    func didTapImageGallery(post: Post, index: Int) {
        var imageFrameHeight = view.frame.width
        if !post.aspectFit {
            imageFrameHeight += view.frame.width/2
        }
        var height = 8 + 30 + 50 + imageFrameHeight
        let title = post.title
        let titleEstimatedHeight = title.height(withConstrainedWidth: view.frame.width - 16, font: UIFont.boldSystemFont(ofSize: 18))
        height += titleEstimatedHeight
        
        let redditCommentsController = RedditCommentsController()
        redditCommentsController.hidesBottomBarWhenPushed = true
        redditCommentsController.commentsLink = post.commentsLink
        redditCommentsController.archived = post.archived
        redditCommentsController.post = post
        redditCommentsController.index = index
        redditCommentsController.postView.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: height)
        redditCommentsController.delegate = self
        navigationController?.pushViewController(redditCommentsController, animated: true)
    }
}
