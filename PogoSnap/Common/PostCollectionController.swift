//
//  PostListController.swift
//  PogoSnap
//
//  Created by Brandon Nguyen on 12/14/20.
//

import UIKit

class PostCollectionController: UICollectionViewController {
    
    var posts = [Post]() {
        didSet {
            DispatchQueue.main.async {
                self.collectionView.reloadData()
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    private func votePost(id: String, direction: Int, index: Int) {
        RedditClient.sharedInstance.votePost(postId: id, direction: direction) { _ in}
    }
    
    private func deletePost(id: String) {
        let postId = "t3_\(id)"
        RedditClient.sharedInstance.delete(id: postId) { errorOccured in
            if errorOccured {
                DispatchQueue.main.async {
                    generatorImpactOccured()
                    if let navController = self.navigationController {
                        showErrorToast(controller: navController, message: "Could not delete the post", seconds: 0.5)
                    }
                }
            } else {
                if let index = self.posts.firstIndex(where: { post -> Bool in post.id == id}) {
                    self.posts.remove(at: index)
                    DispatchQueue.main.async {
                        generatorImpactOccured()
                        if let navController = self.navigationController {
                            showSuccessToast(controller: navController, message: "Deleted", seconds: 0.5)
                        }
                    }
                }
            }
        }
    }
    
    private func reportPost(id: String, reason: String) {
        let postId = "t3_\(id)"
        RedditClient.sharedInstance.report(id: postId, reason: reason) { (errors, _) in
            if errors.isEmpty {
                DispatchQueue.main.async {
                    generatorImpactOccured()
                    if let navController = self.navigationController {
                        showSuccessToast(controller: navController, message: "Reported", seconds: 0.5)
                    }
                }
            } else {
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
        var height = 8 + 8 + 50 + 40 + view.frame.width
        let title = posts[index].title
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
    
    func didTapUsername(username: String) {
        let userProfileController = UserProfileController(collectionViewLayout: UICollectionViewFlowLayout())
        userProfileController.usernameProp = username
        navigationController?.pushViewController(userProfileController, animated: true)
    }
    
    func didTapImage(imageSources: [ImageSource], position: Int) {
        let fullScreen = FullScreenImageController()
        fullScreen.imageSources = imageSources
        fullScreen.position = position
        present(fullScreen, animated: true, completion: nil)
    }
    
    func didTapOptions(post: Post) {
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alertController.addAction(UIAlertAction(title: "Report", style: .default, handler: { _ in
            
            if !RedditClient.sharedInstance.isUserAuthenticated() {
                DispatchQueue.main.async {
                    if let navController = self.navigationController {
                        showErrorToast(controller: navController, message: "You need to be signed in to report", seconds: 1.0)
                    }
                }
                return
            }
            
            let reportOptionsController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
            reportOptionsController.addAction(UIAlertAction(title: "r/PokemonGoSnap Rules", style: .default, handler: { _ in
                
                let subredditRulesController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
                let subredditRules = RedditClient.sharedInstance.getSubredditRules()
                for rule in subredditRules {
                    subredditRulesController.addAction(UIAlertAction(title: rule, style: .default, handler: { action in
                        if let reason = action.title {
                            print(reason)
                            self.reportPost(id: post.id, reason: reason)
                        }
                    }))
                }
                subredditRulesController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
                self.present(subredditRulesController, animated: true, completion: nil)
            }))
                        
            reportOptionsController.addAction(UIAlertAction(title: "Spam or Abuse", style: .default, handler: { _ in
                let siteRulesController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
                let siteRules = RedditClient.sharedInstance.getSiteRules()
                for rule in siteRules {
                    siteRulesController.addAction(UIAlertAction(title: rule, style: .default, handler: { action in
                        if let reason = action.title {
                            print(reason)
                            self.reportPost(id: post.id, reason: reason)
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
            if direction == 0 {
                if let liked = posts[index].liked {
                    if liked {
                        posts[index].liked = nil
                        posts[index].score -= 1
                    } else {
                        posts[index].liked = nil
                        posts[index].score += 1
                    }
                }
            } else if direction == 1 {
                posts[index].liked = true
                posts[index].score += 1
            } else {
                posts[index].liked = false
                posts[index].score -= 1
            }
            votePost(id: post.id, direction: direction, index: index)
        }
    }
    
    func didTapImageGallery(post: Post, index: Int) {
        var height = 8 + 8 + 50 + 40 + view.frame.width
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
