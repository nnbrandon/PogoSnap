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

    var posts = [Post]() {
        didSet {
            DispatchQueue.main.async {
                self.collectionView.reloadData()
            }
        }
    }
    var after = ""
    
    let cellId = "cellId"
    let keychain = Keychain(service: "com.PogoSnap")

    override func viewDidLoad() {
        super.viewDidLoad()
        
        collectionView.backgroundColor = .white
        collectionView.register(UserProfileHeader.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: "headerId")
        collectionView.register(UserProfileCell.self, forCellWithReuseIdentifier: cellId)
        
        if keychain["accessToken"] == nil {
            showSignInVC()
        } else {
            navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(named: "gear")?.withRenderingMode(.alwaysOriginal), style: .plain, target: self, action: #selector(handleLogout))
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        if let username = keychain["username"] {
            if posts.isEmpty {
                print("fetching user posts...")
                fetchUserPosts(username: username)
            }
        } else if let accessToken = keychain["accessToken"] {
            if children.count > 0 {
                let viewControllers:[UIViewController] = children
                viewControllers.last?.willMove(toParent: nil)
                viewControllers.last?.removeFromParent()
                viewControllers.last?.view.removeFromSuperview()
                collectionView.isHidden = false
                navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(named: "gear")?.withRenderingMode(.alwaysOriginal), style: .plain, target: self, action: #selector(handleLogout))
            }
            print("going to fetch me info and accessToken = " + accessToken)
            var meRequest = URLRequest(url: URL(string: RedditClient.Const.meEndpoint)!)
            meRequest.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
            meRequest.setValue(RedditClient.Const.userAgent, forHTTPHeaderField: "User-Agent")
            URLSession.shared.dataTask(with: meRequest) { data, response, error in
                if let data = data {
                    do {
                        let decoded = try JSONDecoder().decode(RedditMeResponse.self, from: data)
                        self.keychain["username"] = decoded.name
                        self.keychain["icon_img"] = decoded.icon_img
                        DispatchQueue.main.async {
                            self.collectionView.reloadData()
                        }
                        self.fetchUserPosts(username: decoded.name)
                    } catch {
                        print(error)
                    }
                    
                }
            }.resume()
        }
    }
    
    fileprivate func fetchUserPosts(username: String) {
        //            let redditUrl = "https://www.reddit.com/r/Pokemongosnap/search.json?q=author:\(username)&restrict_sr=t&sort=new&after=\(after)"
        
        // For testing purposes
        let redditUrl = "https://www.reddit.com/r/Pogosnap/search.json?q=author:\(username)&restrict_sr=t&sort=new&after=\(after)"

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
            self.keychain["accessToken"] = nil
            self.keychain["refreshToken"] = nil
            self.keychain["username"] = nil
            self.keychain["icon_img"] = nil
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
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellId, for: indexPath) as! UserProfileCell
        
        cell.photoImageView.image = UIImage()
        let post = posts[indexPath.row]
        cell.post = post
        
        return cell
    }
    
    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "headerId", for: indexPath) as! UserProfileHeader

        if let username = keychain["username"], let icon_img = keychain["icon_img"] {
            header.username = username
            header.icon_img = icon_img
        }
        
        return header
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return CGSize(width: view.frame.width, height: 200)
    }
}
