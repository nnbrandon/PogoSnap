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
        static let icon_img = "icon_img"
        static let accessToken = "accessToken"
        static let refreshToken = "refreshToken"
    }

    var usernameProp: String?
    var posts = [Post]() {
        didSet {
            DispatchQueue.main.async {
                self.collectionView.reloadData()
            }
        }
    }
    var after = ""

    let keychain = Keychain(service: "com.PogoSnap")
    let defaults = UserDefaults.standard

    override func viewDidLoad() {
        super.viewDidLoad()
        
        collectionView.backgroundColor = .white
        collectionView.register(UserProfileHeader.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: Const.headerId)
        collectionView.register(UserProfileCell.self, forCellWithReuseIdentifier: Const.cellId)
        
        if keychain[Const.accessToken] == nil {
            showSignInVC()
        } else {
            if usernameProp == nil {
                navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(named: "gear")?.withRenderingMode(.alwaysOriginal), style: .plain, target: self, action: #selector(handleLogout))
            }
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        if let usernameProp = usernameProp {
            if posts.isEmpty {
                print("fetching user posts... from usernameProp")
                fetchUserPosts(username: usernameProp)
            }
        } else if let username = defaults.string(forKey: Const.username) {
            if posts.isEmpty {
                print("fetching user posts...")
                fetchUserPosts(username: username)
            }
        } else if let accessToken = keychain[Const.accessToken], usernameProp == nil {
            if children.count > 0 {
                let viewControllers:[UIViewController] = children
                viewControllers.last?.willMove(toParent: nil)
                viewControllers.last?.removeFromParent()
                viewControllers.last?.view.removeFromSuperview()
                collectionView.isHidden = false
                navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(named: "gear")?.withRenderingMode(.alwaysOriginal), style: .plain, target: self, action: #selector(handleLogout))
            }
            
            print("going to fetch me info and accessToken = " + accessToken)
            RedditClient.fetchMe(accessToken: accessToken) { response in
                self.defaults.setValue(response.name, forKey: Const.username)
                self.defaults.setValue(response.icon_img, forKey: Const.icon_img)
                DispatchQueue.main.async {
                    self.collectionView.reloadData()
                }
                self.fetchUserPosts(username: response.name)
            }
        }
    }
    
    fileprivate func fetchUserPosts(username: String) {
            //            let redditUrl = "https://www.reddit.com/r/Pokemongosnap/search.json?q=author:\(username)&restrict_sr=t&sort=new&after=\(after)"
        
            // For testing purposes
            //            let redditUrl = "https://www.reddit.com/r/Pogosnap/search.json?q=author:\(username)&restrict_sr=t&sort=new&after=\(after)"
        
        let redditUrl = usernameProp != nil ? "https://www.reddit.com/r/Pokemongosnap/search.json?q=author:\(username)&restrict_sr=t&sort=new&after=\(after)" : "https://www.reddit.com/r/Pogosnap/search.json?q=author:\(username)&restrict_sr=t&sort=new&after=\(after)"

        RedditClient.fetchPosts(url: redditUrl, after: after) { posts, nextAfter in
            var nextPosts = self.posts
            for post in posts {
                if !nextPosts.contains(post) {
                    nextPosts.append(post)
                }
            }
            if self.posts != nextPosts {
                print("new posts")
                self.posts = nextPosts
            }
            
            if let nextAfter = nextAfter {
                self.after = nextAfter
            }
        }
    }
    
    @objc func handleLogout() {
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alertController.addAction(UIAlertAction(title: "Log out", style: .destructive, handler: { (_) in
            self.keychain[Const.accessToken] = nil
            self.keychain[Const.refreshToken] = nil
            self.defaults.removeObject(forKey: Const.username)
            self.defaults.removeObject(forKey: Const.username)
            self.posts = [Post]()
            self.after = ""
            self.showSignInVC()
        }))
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        present(alertController, animated: true, completion: nil)
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
        } else if let username = defaults.string(forKey: Const.username), let icon_img = defaults.string(forKey: Const.icon_img) {
            header.username = username
            header.icon_img = icon_img
        }
        
        return header
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return CGSize(width: view.frame.width, height: 200)
    }
    
    override func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if indexPath.row == posts.count - 5 {
            if let usernameProp = usernameProp {
                fetchUserPosts(username: usernameProp)
            } else if let username = defaults.string(forKey: Const.username) {
                fetchUserPosts(username: username)
            }
        }
    }
}
