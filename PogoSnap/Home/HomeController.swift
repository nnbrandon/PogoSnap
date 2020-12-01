//
//  HomeController.swift
//  PogoSnap
//
//  Created by Brandon Nguyen on 11/17/20.
//

import UIKit
import KeychainAccess

class HomeController: UICollectionViewController, HomePostCellDelegate {

    var posts = [Post]() {
        didSet {
            DispatchQueue.main.async {
                self.collectionView.reloadData()
            }
        }
    }
    var after: String? = ""
    var userSignFlag: String?

    
    let cellId = "cellId"
    let defaults = UserDefaults.standard
    let refreshControl: UIRefreshControl = {
        let control = UIRefreshControl()
        control.addTarget(self, action: #selector(refreshPosts), for: .valueChanged)
        return control
    }()
    let activityIndicatorView: UIActivityIndicatorView = {
        let activityView = UIActivityIndicatorView()
        return activityView
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "PogoSnap"
        collectionView.backgroundColor = .white
        collectionView.register(HomePostCell.self, forCellWithReuseIdentifier: cellId)
        collectionView.refreshControl = refreshControl
        
        view.addSubview(activityIndicatorView)
        activityIndicatorView.translatesAutoresizingMaskIntoConstraints = false
        activityIndicatorView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        activityIndicatorView.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true

        userSignFlag = RedditClient.sharedInstance.getUsername()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        let previousUserSignFlag = userSignFlag
        userSignFlag = RedditClient.sharedInstance.getUsername()
        if previousUserSignFlag != userSignFlag {
            print("user sign state changed, resetting posts and fetching new posts")
            posts = [Post]()
            after = ""
        }
        if posts.isEmpty {
            fetchRules()
            fetchPosts()
        }
    }
    
    func didTapComment(post: Post) {
        let redditCommentsController = RedditCommentsController()
        redditCommentsController.hidesBottomBarWhenPushed = true
        redditCommentsController.commentsLink = post.commentsLink
        redditCommentsController.archived = post.archived
        navigationController?.pushViewController(redditCommentsController, animated: true)
        print(post)
    }
    
    func didTapUsername(username: String) {
        let userProfileController = UserProfileController(collectionViewLayout: UICollectionViewFlowLayout())
        userProfileController.usernameProp = username
        navigationController?.pushViewController(userProfileController, animated: true)
        print(username)
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
                    showToast(controller: self, message: "You need to be signed in to report", seconds: 1.5)
                }
                return
            }
            
            let reportOptionsController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
            reportOptionsController.addAction(UIAlertAction(title: "r/PokemonGoSnap Rules", style: .default, handler: { _ in
                
                let subredditRulesController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
                if let subredditRules = self.defaults.stringArray(forKey: "PokemonGoSnapRules") {
                    for rule in subredditRules {
                        subredditRulesController.addAction(UIAlertAction(title: rule, style: .default, handler: { action in
                            if let reason = action.title {
                                print(reason)
                                self.reportPost(postId: post.id, reason: reason)
                            }
                        }))
                    }
                }
                subredditRulesController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
                self.present(subredditRulesController, animated: true, completion: nil)
            }))
                        
            reportOptionsController.addAction(UIAlertAction(title: "Spam or Abuse", style: .default, handler: { _ in
                let siteRulesController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
                if let siteRules = self.defaults.stringArray(forKey: "SiteRules")  {
                    for rule in siteRules {
                        siteRulesController.addAction(UIAlertAction(title: rule, style: .default, handler: { action in
                            if let reason = action.title {
                                print(reason)
                                self.reportPost(postId: post.id, reason: reason)
                            }
                        }))
                    }
                }
                siteRulesController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
                self.present(siteRulesController, animated: true, completion: nil)
            }))
            
            reportOptionsController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            self.present(reportOptionsController, animated: true, completion: nil)
        }))
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        present(alertController, animated: true, completion: nil)
    }
    
    private func reportPost(postId: String, reason: String) {
        RedditClient.sharedInstance.reportPost(postId: postId, reason: reason) { errors in
            if errors.isEmpty {
                print("reported!")
                DispatchQueue.main.async {
                    showToast(controller: self, message: "Reported ✓", seconds: 0.5)
                }
            }
        }
    }
    
    private func fetchPosts() {
        print("fetching posts...")
        activityIndicatorView.startAnimating()
        if let after = after {
            RedditClient.sharedInstance.fetchPosts(after: after) { posts, nextAfter in
                DispatchQueue.main.async {
                    self.activityIndicatorView.stopAnimating()
                }
                self.posts.append(contentsOf: posts)
                self.after = nextAfter
            }
        } else {
            activityIndicatorView.stopAnimating()
        }
    }
    
    private func fetchRules() {
        print("fetching rules...")
        RedditClient.fetchRules { rules in
            let subredditRules = rules.rules.map { subRedditRule in
                subRedditRule.short_name
            }
            let siteRules = rules.site_rules
            
            self.defaults.setValue(subredditRules, forKey: "PokemonGoSnapRules")
            self.defaults.setValue(siteRules, forKey: "SiteRules")
        }
    }
    
    @objc private func refreshPosts() {
        print("refreshing posts")
        activityIndicatorView.startAnimating()
        RedditClient.sharedInstance.fetchPosts(after: "") { posts, nextAfter in
            DispatchQueue.main.async {
                self.refreshControl.endRefreshing()
                self.activityIndicatorView.stopAnimating()
            }
            if self.posts != posts {
                print("settings posts after refresh")
                self.posts = posts
                self.after = nextAfter
            }
        }
    }
}

extension HomeController: UICollectionViewDelegateFlowLayout {
        
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        var height = 8 + 8 + 50 + 40 + view.frame.width
        let title = posts[indexPath.row].title
        let titleEstimatedHeight = title.height(withConstrainedWidth: view.frame.width - 16, font: UIFont.boldSystemFont(ofSize: 14))
        height += titleEstimatedHeight
        return CGSize(width: view.frame.width, height: height)
    }

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return posts.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellId, for: indexPath) as! HomePostCell
        for index in 0..<cell.photoImageSlideshow.subviews.count {
            let imageView = cell.photoImageSlideshow.subviews[index] as! CustomImageView
            imageView.image = UIImage()
        }

        cell.post = posts[indexPath.row]
        cell.delegate = self
        
        return cell
    }
    
    override func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if indexPath.row == posts.count - 5, after != nil {
            fetchPosts()
        }
    }
}
