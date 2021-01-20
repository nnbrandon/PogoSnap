//
//  UserProfileViewController.swift
//  PogoSnap
//
//  Created by Brandon Nguyen on 11/15/20.
//

/**
 TODO: Convert this to MVVM. Super messy rn.
 */

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
                    RedditService.sharedInstance.fetchUserAbout(username: usernameProp) { result in
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
        } else if RedditService.sharedInstance.getUsername() == nil {
            // user is not signed in
            showSignInVC()
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if RedditService.sharedInstance.getUsername() == nil, RedditService.sharedInstance.isUserAuthenticated() {
            // Fetch username and me information
            if !children.isEmpty {
                let viewControllers: [UIViewController] = children
                viewControllers.last?.willMove(toParent: nil)
                viewControllers.last?.removeFromParent()
                viewControllers.last?.view.removeFromSuperview()
                collectionView.isHidden = false
            }
            RedditService.sharedInstance.fetchMe { result in
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
        } else if let username = RedditService.sharedInstance.getUsername(), usernameProp == nil {
            if posts.isEmpty || posts.count == 1 {
                activityIndicatorView.startAnimating()
                RedditService.sharedInstance.fetchMe { _ in}
                let user_icon = RedditService.sharedInstance.getIconImg()
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
        RedditService.sharedInstance.fetchGoAndSnapUserPosts(username: username, user_icon: user_icon, pokemonGoAfter: pokemonGoAfter, pokemonGoSnapAfter: pokemonGoSnapAfter) { result in
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
        if RedditService.sharedInstance.getUsername() != nil {
            alertController.addAction(UIAlertAction(title: "Log out", style: .destructive, handler: { (_) in
                RedditService.sharedInstance.deleteCredentials()
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
        } else if let signedInUser = RedditService.sharedInstance.getUsername() {
            username = signedInUser
            user_icon = RedditService.sharedInstance.getIconImg()
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
            postListSectionController.listLayoutOption = listLayoutOption
            postListSectionController.basePostsDelegate = self
            postListSectionController.authenticated = RedditService.sharedInstance.isUserAuthenticated()
            return postListSectionController
        }
    }
    
    func emptyView(for listAdapter: ListAdapter) -> UIView? {
        return nil
    }
}

extension UserProfileController: BasePostsDelegate {
    
    private func deletePost(id: String) {
        let postId = "t3_\(id)"
        RedditService.sharedInstance.delete(id: postId) { result in
            switch result {
            case .success:
                var index = -1
                for (idx, post) in self.posts.enumerated() {
                    if let post = post as? Post, post.id == id {
                        index = idx
                        break
                    }
                }
                if index > -1 {
                    self.posts.remove(at: index)
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
    
    private func reportPost(id: String, subReddit: String, reason: String) {
        let postId = "t3_\(id)"
        RedditService.sharedInstance.report(subReddit: subReddit, id: postId, reason: reason) { result in
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

    func didTapOptions(index: Int) {
        guard let post = posts[index] as? Post else { return }
        let id = post.id
        let subReddit = post.subReddit
        let authenticated = RedditService.sharedInstance.isUserAuthenticated()
        let subRedditRules = RedditService.sharedInstance.getSubredditRules(subReddit: post.subReddit)
        let siteRules = RedditService.sharedInstance.getSiteRules()
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: getCurrentInterfaceForAlerts())
        alertController.addAction(UIAlertAction(title: "Report", style: .default, handler: { _ in
            if !authenticated {
                DispatchQueue.main.async {
                    if let navController = self.navigationController {
                        showErrorToast(controller: navController, message: "You need to be signed in to report", seconds: 2.0)
                    }
                }
                return
            }
            let reportOptionsController = UIAlertController(title: nil, message: nil, preferredStyle: getCurrentInterfaceForAlerts())
            let subRedditRulesAction = self.getAlertForRules(id: id, rules: subRedditRules, subReddit: subReddit, isSubRedditRules: true)
            let siteRulesAction = self.getAlertForRules(id: id, rules: siteRules, subReddit: subReddit, isSubRedditRules: false)
            reportOptionsController.addAction(subRedditRulesAction)
            reportOptionsController.addAction(siteRulesAction)
            reportOptionsController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            self.present(reportOptionsController, animated: true, completion: nil)
        }))
        if post.author == RedditService.sharedInstance.getUsername() {
            alertController.addAction(UIAlertAction(title: "Delete", style: .destructive, handler: { _ in
                self.deletePost(id: id)
            }))
        }
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))

        present(alertController, animated: true, completion: nil)
    }
    
    private func getAlertForRules(id: String, rules: [String], subReddit: String, isSubRedditRules: Bool) -> UIAlertAction {
        var action: UIAlertAction
        if isSubRedditRules {
            action = UIAlertAction(title: "r/\(subReddit) Rules", style: .default, handler: { _ in
                let subredditRulesController = UIAlertController(title: nil, message: nil, preferredStyle: getCurrentInterfaceForAlerts())
                for rule in rules {
                    subredditRulesController.addAction(UIAlertAction(title: rule, style: .default, handler: { action in
                        if let reason = action.title {
                            self.reportPost(id: id, subReddit: subReddit, reason: reason)
                        }
                    }))
                }
                subredditRulesController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
                self.present(subredditRulesController, animated: true, completion: nil)
            })
        } else {
            action = UIAlertAction(title: "Spam or Abuse", style: .default, handler: { _ in
                let siteRulesController = UIAlertController(title: nil, message: nil, preferredStyle: getCurrentInterfaceForAlerts())
                for rule in rules {
                    siteRulesController.addAction(UIAlertAction(title: rule, style: .default, handler: { action in
                        if let reason = action.title {
                            self.reportPost(id: id, subReddit: subReddit, reason: reason)
                        }
                    }))
                }
                siteRulesController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
                self.present(siteRulesController, animated: true, completion: nil)
            })
        }
        return action
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
            }
        }
    }
}
