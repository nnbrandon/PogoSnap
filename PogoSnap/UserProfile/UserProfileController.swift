//
//  UserProfileViewController.swift
//  PogoSnap
//
//  Created by Brandon Nguyen on 11/15/20.
//

import UIKit

class UserProfileController: UICollectionViewController, PostViewDelegate, ProfileImageDelegate {

    struct Const {
        static let cellId = "cellId"
        static let headerId = "headerId"
        static let username = "username"
    }

    var usernameProp: String?
    var icon_imgProp: String? {
        didSet {
            DispatchQueue.main.async {
                self.collectionView.collectionViewLayout.invalidateLayout()
            }
        }
    }
    var posts = [Post]() {
        didSet {
            DispatchQueue.main.async {
                self.collectionView.reloadData()
            }
        }
    }
    var after: String? = ""
    let defaults = UserDefaults(suiteName: "group.com.PogoSnap")

    
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
        if traitCollection.userInterfaceStyle == .light {
            collectionView.backgroundColor = .white
        }
        collectionView.register(UserProfileHeader.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: Const.headerId)
        collectionView.register(UserProfileCell.self, forCellWithReuseIdentifier: Const.cellId)
        collectionView.refreshControl = refreshControl
        
        view.addSubview(activityIndicatorView)
        activityIndicatorView.translatesAutoresizingMaskIntoConstraints = false
        activityIndicatorView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        activityIndicatorView.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        
        if let imgurList = ImgurClient.sharedInstance.getImageUrlList() {
            print(imgurList)
        }
        
        if let usernameProp = usernameProp {
            // Check if we are looking at someone else's profile
            if posts.isEmpty {
                print("fetching user posts... from usernameProp")
                activityIndicatorView.startAnimating()
                RedditClient.fetchUserAbout(username: usernameProp) { (_, icon_img) in
                    self.icon_imgProp = icon_img
                }
                fetchUserPosts(username: usernameProp)
            }
        } else if RedditClient.sharedInstance.getUsername() == nil {
            // user is not signed in
            showSignInVC()
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        if RedditClient.sharedInstance.getUsername() == nil, RedditClient.sharedInstance.isUserAuthenticated() {
            // Fetch username and me information
            if children.count > 0 {
                let viewControllers:[UIViewController] = children
                viewControllers.last?.willMove(toParent: nil)
                viewControllers.last?.removeFromParent()
                viewControllers.last?.view.removeFromSuperview()
                collectionView.isHidden = false
                if traitCollection.userInterfaceStyle == .dark {
                    let barButton = UIBarButtonItem(image: UIImage(named: "gear")?.withRenderingMode(.alwaysTemplate), style: .plain, target: self, action: #selector(handleOptions))
                    barButton.tintColor = .white
                    navigationItem.rightBarButtonItem = barButton
                } else {
                    navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(named: "gear")?.withRenderingMode(.alwaysOriginal), style: .plain, target: self, action: #selector(handleOptions))
                }
            }
            RedditClient.sharedInstance.fetchMe { (username, icon_img) in
                DispatchQueue.main.async {
                    self.collectionView.reloadData()
                    self.activityIndicatorView.startAnimating()
                }
                print("fetching user posts after signing in...")
                self.fetchUserPosts(username: username)
            }
        } else if let username = RedditClient.sharedInstance.getUsername(), usernameProp == nil {
            if traitCollection.userInterfaceStyle == .dark {
                let barButton = UIBarButtonItem(image: UIImage(named: "gear")?.withRenderingMode(.alwaysTemplate), style: .plain, target: self, action: #selector(handleOptions))
                barButton.tintColor = .white
                navigationItem.rightBarButtonItem = barButton
            } else {
                navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(named: "gear")?.withRenderingMode(.alwaysOriginal), style: .plain, target: self, action: #selector(handleOptions))
            }
            if posts.isEmpty || posts.count == 1 {
                print("fetching user posts...")
                activityIndicatorView.startAnimating()
                RedditClient.sharedInstance.fetchMe { (_, icon_img) in
                    DispatchQueue.main.async {
                        self.collectionView.reloadData()
                        self.activityIndicatorView.startAnimating()
                    }
                    print("fetching user posts after fetching me...")
                    self.fetchUserPosts(username: username)
                }
            }
        }
    }
    
    private func fetchUserPosts(username: String) {
        if let after = after {
            RedditClient.sharedInstance.fetchUserPosts(username: username, after: after) { posts, nextAfter in
                DispatchQueue.main.async {
                    self.activityIndicatorView.stopAnimating()
                }
                var nextPosts = self.posts
                for post in posts {
                    if !nextPosts.contains(post) {
                        nextPosts.append(post)
                    }
                }
                if self.posts != nextPosts {
                    self.posts = nextPosts
                }
                self.after = nextAfter
            }
        } else {
            activityIndicatorView.stopAnimating()
        }
    }
    
    @objc private func handleOptions() {
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alertController.addAction(UIAlertAction(title: "Manage Imgur uploads", style: .default, handler: { (_) in
            let viewController = ImgurTableController()
            viewController.hidesBottomBarWhenPushed = true
            self.navigationController?.pushViewController(viewController, animated: true)
        }))
        alertController.addAction(UIAlertAction(title: "Log out", style: .destructive, handler: { (_) in
            RedditClient.sharedInstance.deleteCredentials()
            self.posts = [Post]()
            self.after = ""
            self.showSignInVC()
        }))
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        present(alertController, animated: true, completion: nil)
    }
    
    @objc private func refreshPosts() {
        activityIndicatorView.startAnimating()
        var username = ""
        if let usernameProp = usernameProp {
            username = usernameProp
        } else if let signedInUser = RedditClient.sharedInstance.getUsername() {
            username = signedInUser
        }
        
        RedditClient.sharedInstance.fetchUserPosts(username: username, after: "") { posts, nextAfter in
            DispatchQueue.main.async {
                self.activityIndicatorView.stopAnimating()
                self.refreshControl.endRefreshing()
            }
            self.posts = posts
            self.after = nextAfter
        }
    }
    
    private func showSignInVC() {
        navigationItem.rightBarButtonItem = nil
        collectionView.isHidden = true
        let signInVC = SignInController()
        addChild(signInVC)
        view.addSubview(signInVC.view)
        signInVC.didMove(toParent: self)
    }
    
    func didTapImageGallery(post: Post, index: Int) {
        var height = 8 + 8 + 50 + 40 + view.frame.width
        let title = post.title
        let titleEstimatedHeight = title.height(withConstrainedWidth: view.frame.width - 16, font: UIFont.boldSystemFont(ofSize: 16))
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
        print(post)
    }
    
    func didTapComment(post: Post, index: Int) {}
    
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
                    showErrorToast(controller: self, message: "You need to be signed in to report", seconds: 1.0)
                }
                return
            }
            
            let reportOptionsController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
            reportOptionsController.addAction(UIAlertAction(title: "r/PokemonGoSnap Rules", style: .default, handler: { _ in
                
                let subredditRulesController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
                if let subredditRules = self.defaults?.stringArray(forKey: "PokemonGoSnapRules") {
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
                if let siteRules = self.defaults?.stringArray(forKey: "SiteRules")  {
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
        if let username = RedditClient.sharedInstance.getUsername(), username == post.author {
            alertController.addAction(UIAlertAction(title: "Delete", style: .destructive, handler: { _ in
                self.deletePost(postId: post.id)
            }))
        }
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        present(alertController, animated: true, completion: nil)
    }
    
    func didTapVote(post: Post, direction: Int, index: Int, authenticated: Bool, archived: Bool) {
        if !authenticated {
            DispatchQueue.main.async {
                showErrorToast(controller: self, message: "You need to be signed in to like", seconds: 1.0)
            }
        } else if archived {
            DispatchQueue.main.async {
                showErrorToast(controller: self, message: "This post has been archived", seconds: 1.0)
            }
        } else {
            if direction == 0 {
                posts[index].liked = nil
                posts[index].score -= 1
            } else if direction == 1 {
                posts[index].liked = true
                posts[index].score += 1
            } else {
                posts[index].liked = false
                posts[index].score -= 1
            }
            votePost(postId: post.id, direction: direction, index: index)
        }
    }
    
    private func reportPost(postId: String, reason: String) {
        let postId = "t3_\(postId)"
        RedditClient.sharedInstance.report(id: postId, reason: reason) { (errors, _) in
            if errors.isEmpty {
                DispatchQueue.main.async {
                    generatorImpactOccured()
                    if let commentController = self.navigationController?.viewControllers.last as? RedditCommentsController {
                        showSuccessToast(controller: commentController, message: "Reported", seconds: 0.5)
                    }
                }
            } else {
                DispatchQueue.main.async {
                    generatorImpactOccured()
                    if let commentController = self.navigationController?.viewControllers.last as? RedditCommentsController {
                        showSuccessToast(controller: commentController, message: "Could not report", seconds: 0.5)
                    }
                }
            }
        }
    }
    
    private func deletePost(postId: String) {
        let id = "t3_\(postId)"
        RedditClient.sharedInstance.delete(id: id) { errorOccured in
            if errorOccured {
                DispatchQueue.main.async {
                    generatorImpactOccured()
                    if let commentController = self.navigationController?.viewControllers.last as? RedditCommentsController {
                        showErrorToast(controller: commentController, message: "Could not delete the post", seconds: 0.5)
                    }
                }
            } else {
                if let index = self.posts.firstIndex(where: { post -> Bool in post.id == postId}) {
                    self.posts.remove(at: index)
                    DispatchQueue.main.async {
                        generatorImpactOccured()
                        if let commentController = self.navigationController?.viewControllers.last as? RedditCommentsController {
                            showSuccessToast(controller: commentController, message: "Deleted", seconds: 0.5)
                        }
                    }
                }
            }
        }
    }
    
    private func votePost(postId: String, direction: Int, index: Int) {
        RedditClient.sharedInstance.votePost(postId: postId, direction: direction) { success in
            if !success {
                self.posts[index].liked = direction == 1 ? nil : true
            }
        }
    }
}

extension UserProfileController: UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = (view.frame.width - 2) / 3
        return CGSize(width: width, height: width)
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return posts.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: Const.cellId, for: indexPath) as! UserProfileCell
        
        cell.photoImageView.image = UIImage()
        let post = posts[indexPath.row]
        cell.post = post
        cell.index = indexPath.row
        cell.delegate = self
        
        return cell
    }
    
    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: Const.headerId, for: indexPath) as! UserProfileHeader
        if traitCollection.userInterfaceStyle == .dark {
            header.darkMode = true
        } else {
            header.darkMode = false
        }

        if let usernameProp = usernameProp {
            header.username = usernameProp
            header.icon_img = icon_imgProp
        } else if let username = RedditClient.sharedInstance.getUsername(), let icon_img = RedditClient.sharedInstance.getIconImg() {
            header.username = username
            header.icon_img = icon_img
        }
        
        return header
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return CGSize(width: view.frame.width, height: 200)
    }
    
    override func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if indexPath.row == posts.count - 3 {
            if let usernameProp = usernameProp {
                fetchUserPosts(username: usernameProp)
            } else if let username = RedditClient.sharedInstance.getUsername() {
                fetchUserPosts(username: username)
            }
        }
    }
}
