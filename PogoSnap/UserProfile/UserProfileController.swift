//
//  UserProfileViewController.swift
//  PogoSnap
//
//  Created by Brandon Nguyen on 11/15/20.
//

import UIKit
import IGListKit

class UserProfileController: UIViewController {

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
    var usernameProp: String?
    var icon_imgProp: String?
    var fetching = false
    
    let collectionView = UICollectionView(frame: .zero, collectionViewLayout: ListCollectionViewLayout(stickyHeaders: false, scrollDirection: .vertical, topContentInset: 0, stretchToEdge: false))
     lazy var adapter: ListAdapter = {
       return ListAdapter(
       updater: ListAdapterUpdater(),
       viewController: self,
       workingRangeSize: 10)
     }()

    let refreshControl: UIRefreshControl = {
        let control = UIRefreshControl()
        control.addTarget(self, action: #selector(refreshPosts), for: .valueChanged)
        return control
    }()
    let activityIndicatorView: UIActivityIndicatorView = {
        let activityView = UIActivityIndicatorView()
        return activityView
    }()
    let footerView = UIActivityIndicatorView()

    override func viewDidLoad() {
        super.viewDidLoad()
        if traitCollection.userInterfaceStyle == .light {
            view.backgroundColor = .white
            collectionView.backgroundColor = .white
        } else {
            view.backgroundColor = RedditConsts.redditDarkMode
            collectionView.backgroundColor = RedditConsts.redditDarkMode
        }

        listLayoutOption = ListLayoutOptions.gallery

        view.addSubview(collectionView)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
    
        adapter.collectionView = collectionView
        adapter.dataSource = self
        adapter.scrollViewDelegate = self
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
                activityIndicatorView.startAnimating()
                if icon_imgProp == nil {
                    RedditClient.sharedInstance.fetchUserAbout(username: usernameProp) { result in
                        switch result {
                        case .success( _, let icon_img):
                            self.addUserInformation(username: usernameProp, user_icon: icon_img)
                            self.fetchUserPosts(username: usernameProp, user_icon: icon_img)
                        case .error(let error):
                            DispatchQueue.main.async {
                                showErrorToast(controller: self, message: error, seconds: 1.0)
                            }
                            self.addUserInformation(username: usernameProp, user_icon: self.icon_imgProp)
                            self.fetchUserPosts(username: usernameProp, user_icon: self.icon_imgProp)
                        }
                    }
                } else {
                    self.addUserInformation(username: usernameProp, user_icon: icon_imgProp)
                    fetchUserPosts(username: usernameProp, user_icon: icon_imgProp)
                }
            }
        } else if RedditClient.sharedInstance.getUsername() == nil {
            // user is not signed in
            showSignInVC()
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if RedditClient.sharedInstance.getUsername() == nil, RedditClient.sharedInstance.isUserAuthenticated() {
            // Fetch username and me information
            if !children.isEmpty {
                let viewControllers: [UIViewController] = children
                viewControllers.last?.willMove(toParent: nil)
                viewControllers.last?.removeFromParent()
                viewControllers.last?.view.removeFromSuperview()
                collectionView.isHidden = false
            }
            RedditClient.sharedInstance.fetchMe { result in
                switch result {
                case .success(let username, let icon_img):
                    DispatchQueue.main.async {
                        self.activityIndicatorView.startAnimating()
                    }
                    self.addUserInformation(username: username, user_icon: icon_img)
                    self.fetchUserPosts(username: username, user_icon: icon_img)
                case .error(let error):
                    DispatchQueue.main.async {
                        showErrorToast(controller: self, message: error, seconds: 1.0)
                    }
                }
            }
        } else if let username = RedditClient.sharedInstance.getUsername(), usernameProp == nil {
            if posts.isEmpty || posts.count == 1 {
                activityIndicatorView.startAnimating()
                RedditClient.sharedInstance.fetchMe { _ in}
                let user_icon = RedditClient.sharedInstance.getIconImg()
                addUserInformation(username: username, user_icon: user_icon)
                fetchUserPosts(username: username, user_icon: user_icon)
            }
        }
    }
    
    private func addUserInformation(username: String, user_icon: String?) {
        let user = User(username: username, user_icon: user_icon)
        posts.insert(user, at: 0)
    }
    
    private func fetchUserPosts(username: String, user_icon: String?) {
        fetching = true
        RedditClient.sharedInstance.fetchGoAndSnapUserPosts(username: username, user_icon: user_icon, pokemonGoAfter: pokemonGoAfter, pokemonGoSnapAfter: pokemonGoSnapAfter) { result in
            self.fetching = false
            switch result {
            case .success(let posts, let nextPokemonGoAfter, let nextPokemonGoSnapAfter):
                DispatchQueue.main.async {
                    self.refreshControl.endRefreshing()
                    self.activityIndicatorView.stopAnimating()
                }
                self.posts.append(contentsOf: posts)
                self.pokemonGoSnapAfter = nextPokemonGoSnapAfter
                self.pokemonGoAfter = nextPokemonGoAfter
            case .error:
                DispatchQueue.main.async {
                    showErrorToast(controller: self, message: "Failed to retrieve user's posts", seconds: 3.0)
                    self.activityIndicatorView.stopAnimating()
                }
            }
        }
    }
    
    @objc private func handleOptions() {
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: getCurrentInterfaceForAlerts())
        alertController.addAction(UIAlertAction(title: "Manage Imgur uploads", style: .default, handler: { (_) in
            let viewController = ImgurTableController()
            viewController.hidesBottomBarWhenPushed = true
            self.navigationController?.pushViewController(viewController, animated: true)
        }))
        if RedditClient.sharedInstance.getUsername() != nil {
            alertController.addAction(UIAlertAction(title: "Log out", style: .destructive, handler: { (_) in
                RedditClient.sharedInstance.deleteCredentials()
                self.posts = [ListDiffable]()
                self.pokemonGoAfter = ""
                self.pokemonGoSnapAfter = ""
                self.showSignInVC()
            }))
        }
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        present(alertController, animated: true, completion: nil)
    }
    
    @objc private func refreshPosts() {
        activityIndicatorView.startAnimating()
        var username = ""
        var user_icon: String?
        if let usernameProp = usernameProp {
            username = usernameProp
            user_icon = icon_imgProp
        } else if let signedInUser = RedditClient.sharedInstance.getUsername() {
            username = signedInUser
            user_icon = RedditClient.sharedInstance.getIconImg()
        }
        
        fetchUserPosts(username: username, user_icon: user_icon)
    }
    
    private func showSignInVC() {
        collectionView.isHidden = true
        let signInVC = SignInController()
        addChild(signInVC)
        view.addSubview(signInVC.view)
        signInVC.view.translatesAutoresizingMaskIntoConstraints = false
        signInVC.view.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        signInVC.view.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        signInVC.view.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        signInVC.view.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        signInVC.didMove(toParent: self)
    }
}

extension UserProfileController: ListAdapterDataSource {
    func objects(for listAdapter: ListAdapter) -> [ListDiffable] {
        return posts
    }
    
    func listAdapter(_ listAdapter: ListAdapter, sectionControllerFor object: Any) -> ListSectionController {
        if (object as? User) != nil {
            let userSectionController = UserSectionController()
            if traitCollection.userInterfaceStyle == .dark {
                userSectionController.userHeaderDarkMode = true
            }
            return userSectionController
        } else {
            let postListSectionController = PostListSectionController()
//            postListSectionController.postViewDelegate = self
//            postListSectionController.profileImageDelegate = self
            postListSectionController.listLayoutOption = listLayoutOption
            return postListSectionController
        }
    }
    
    func emptyView(for listAdapter: ListAdapter) -> UIView? {
        return nil
    }
}

extension UserProfileController: UIScrollViewDelegate {
    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        let distance = scrollView.contentSize.height - (targetContentOffset.pointee.y + scrollView.bounds.height)
        if !fetching && distance < 200 {
            if pokemonGoAfter != nil || pokemonGoSnapAfter != nil {
                if let user = posts.first as? User {
                    fetchUserPosts(username: user.username, user_icon: user.user_icon)
                }
//                if let usernameProp = self.usernameProp {
//                    fetchUserPosts(username: usernameProp, user_icon: self.icon_imgProp)
//                } else if let username = RedditClient.sharedInstance.getUsername() {
//                    fetchUserPosts(username: username, user_icon: RedditClient.sharedInstance.getIconImg())
//                }
            }
        }
    }
}
