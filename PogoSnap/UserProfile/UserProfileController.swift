//
//  UserProfileViewController.swift
//  PogoSnap
//
//  Created by Brandon Nguyen on 11/15/20.
//

import UIKit

class UserProfileController: PostCollectionController {

    struct Const {
        static let cellId = "cellId"
        static let headerId = "headerId"
        static let username = "username"
    }

    var usernameProp: String?
    var icon_imgProp: String? {
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
        if traitCollection.userInterfaceStyle == .light {
            view.backgroundColor = .white
            collectionView.backgroundColor = .white
        }
        collectionView.register(UserProfileHeader.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: Const.headerId)
        collectionView.register(UserProfileCell.self, forCellWithReuseIdentifier: Const.cellId)
        collectionView.refreshControl = refreshControl
        
        view.addSubview(activityIndicatorView)
        activityIndicatorView.translatesAutoresizingMaskIntoConstraints = false
        activityIndicatorView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        activityIndicatorView.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        
        if usernameProp == nil {
            if traitCollection.userInterfaceStyle == .dark {
                let barButton = UIBarButtonItem(image: UIImage(named: "gear")?.withRenderingMode(.alwaysTemplate), style: .plain, target: self, action: #selector(handleOptions))
                barButton.tintColor = .white
                navigationItem.rightBarButtonItem = barButton
            } else {
                let barButton = UIBarButtonItem(image: UIImage(named: "gear")?.withRenderingMode(.alwaysTemplate), style: .plain, target: self, action: #selector(handleOptions))
                barButton.tintColor = .darkGray
                navigationItem.rightBarButtonItem = barButton
            }
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
            if !children.isEmpty {
                let viewControllers: [UIViewController] = children
                viewControllers.last?.willMove(toParent: nil)
                viewControllers.last?.removeFromParent()
                viewControllers.last?.view.removeFromSuperview()
                collectionView.isHidden = false
            }
            RedditClient.sharedInstance.fetchMe { (username, _) in
                DispatchQueue.main.async {
                    self.collectionView.reloadData()
                    self.activityIndicatorView.startAnimating()
                }
                print("fetching user posts after signing in...")
                self.fetchUserPosts(username: username)
            }
        } else if let username = RedditClient.sharedInstance.getUsername(), usernameProp == nil {
            if posts.isEmpty || posts.count == 1 {
                print("fetching user posts...")
                activityIndicatorView.startAnimating()
                RedditClient.sharedInstance.fetchMe { (_, _) in}
                fetchUserPosts(username: username)
            }
        }
    }
    
    private func fetchUserPosts(username: String) {
        if let after = after {
            RedditClient.sharedInstance.fetchUserPosts(username: username, after: after) { posts, nextAfter, errorOccured in
                if errorOccured {
                    DispatchQueue.main.async {
                        showErrorToast(controller: self, message: "Failed to retrieve user's posts", seconds: 1.0)
                        self.activityIndicatorView.stopAnimating()
                    }
                } else {
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
        if RedditClient.sharedInstance.getUsername() != nil {
            alertController.addAction(UIAlertAction(title: "Log out", style: .destructive, handler: { (_) in
                RedditClient.sharedInstance.deleteCredentials()
                self.posts = [Post]()
                self.after = ""
                self.showSignInVC()
            }))
        }
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
        
        RedditClient.sharedInstance.fetchUserPosts(username: username, after: "") { posts, nextAfter, errorOccured in
            DispatchQueue.main.async {
                self.activityIndicatorView.stopAnimating()
                self.refreshControl.endRefreshing()
            }
            if errorOccured {
                DispatchQueue.main.async {
                    if let navController = self.navigationController {
                        showErrorToast(controller: navController, message: "Failed to retrieve user's posts", seconds: 1.0)
                    }
                }
            } else {
                self.posts = posts
                self.after = nextAfter
            }
        }
    }
    
    private func showSignInVC() {
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
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: Const.cellId, for: indexPath) as? UserProfileCell else {
            return UICollectionViewCell()
        }
        
        cell.photoImageView.image = UIImage()
        let post = posts[indexPath.row]
        cell.post = post
        cell.index = indexPath.row
        cell.delegate = self
        
        return cell
    }
    
    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        guard let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: Const.headerId, for: indexPath) as? UserProfileHeader else {
            return UICollectionReusableView()
        }
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
