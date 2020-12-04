//
//  UserProfileViewController.swift
//  PogoSnap
//
//  Created by Brandon Nguyen on 11/15/20.
//

import UIKit
import OAuthSwift
import KeychainAccess

class UserProfileController: UICollectionViewController {
    
    struct Const {
        static let cellId = "cellId"
        static let headerId = "headerId"
        static let username = "username"
    }

    var usernameProp: String?
    var posts = [Post]() {
        didSet {
            DispatchQueue.main.async {
                self.collectionView.reloadData()
            }
        }
    }
    var after: String? = ""
    
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
        
        collectionView.backgroundColor = .white
        collectionView.register(UserProfileHeader.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: Const.headerId)
        collectionView.register(UserProfileCell.self, forCellWithReuseIdentifier: Const.cellId)
        collectionView.refreshControl = refreshControl
        
        view.addSubview(activityIndicatorView)
        activityIndicatorView.translatesAutoresizingMaskIntoConstraints = false
        activityIndicatorView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        activityIndicatorView.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        
        if let usernameProp = usernameProp {
            // Check if we are looking at someone else's profile
            if posts.isEmpty {
                print("fetching user posts... from usernameProp")
                activityIndicatorView.startAnimating()
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
                navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(named: "gear")?.withRenderingMode(.alwaysOriginal), style: .plain, target: self, action: #selector(handleLogout))
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
            navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(named: "gear")?.withRenderingMode(.alwaysOriginal), style: .plain, target: self, action: #selector(handleLogout))
            if posts.isEmpty {
                print("fetching user posts...")
                activityIndicatorView.startAnimating()
                fetchUserPosts(username: username)
            }
        }
    }
    
    fileprivate func fetchUserPosts(username: String) {
        if let after = after {
            let redditUrl = usernameProp != nil ? "https://www.reddit.com/r/\(RedditClient.Const.subredditName)/search.json?q=author:\(username)&restrict_sr=t&sort=new&after=\(after)" : "https://www.reddit.com/r/\(RedditClient.Const.subredditName)/search.json?q=author:\(username)&restrict_sr=t&sort=new&after=\(after)"
            
            RedditClient.sharedInstance.fetchUserPosts(url: redditUrl, after: after) { posts, nextAfter in
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
    
    @objc private func handleLogout() {
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
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
        var url = ""

        if let usernameProp = usernameProp {
            url = "https://www.reddit.com/r/\(RedditClient.Const.subredditName)/search.json?q=author:\(usernameProp)&restrict_sr=t&sort=new&after="
        } else if let username = RedditClient.sharedInstance.getUsername() {
            url = "https://www.reddit.com/r/\(RedditClient.Const.subredditName)/search.json?q=author:\(username)&restrict_sr=t&sort=new"
        }
        
        RedditClient.sharedInstance.fetchUserPosts(url: url, after: "") { posts, nextAfter in
            DispatchQueue.main.async {
                self.activityIndicatorView.stopAnimating()
                self.refreshControl.endRefreshing()
            }
            self.posts = posts
            self.after = nextAfter
        }
    }
    
    fileprivate func showSignInVC() {
        navigationItem.rightBarButtonItem = nil
        collectionView.isHidden = true
        let signInVC = SignInController()
        addChild(signInVC)
        view.addSubview(signInVC.view)
        signInVC.didMove(toParent: self)
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
        
        return cell
    }
    
    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: Const.headerId, for: indexPath) as! UserProfileHeader

        if let usernameProp = usernameProp {
            header.username = usernameProp
        } else if let username = RedditClient.sharedInstance.getUsername() {
            header.username = username
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
