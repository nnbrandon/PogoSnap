//
//  PostsController.swift
//  PogoSnap
//
//  Created by Brandon Nguyen on 1/15/21.
//

import UIKit
import IGListKit

class PostsController: UIViewController {

    var viewModel: BasePostsViewModelProtocol!
    
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
    
    func pinCollectionView(superview: UIView) {
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.topAnchor.constraint(equalTo: superview.topAnchor).isActive = true
        collectionView.leadingAnchor.constraint(equalTo: superview.leadingAnchor).isActive = true
        collectionView.trailingAnchor.constraint(equalTo: superview.trailingAnchor).isActive = true
        collectionView.bottomAnchor.constraint(equalTo: superview.bottomAnchor).isActive = true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if traitCollection.userInterfaceStyle == .light {
            collectionView.backgroundColor = .white
        } else {
            collectionView.backgroundColor = RedditConsts.redditDarkMode
        }
        
        view.addSubview(collectionView)
        adapter.collectionView = collectionView
        adapter.dataSource = self
        adapter.scrollViewDelegate = self
        collectionView.refreshControl = refreshControl
        
        view.addSubview(activityIndicatorView)
        activityIndicatorView.translatesAutoresizingMaskIntoConstraints = false
        activityIndicatorView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        activityIndicatorView.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
    }
    
    func fetchPosts() {
        viewModel.fetchPosts { error in
            DispatchQueue.main.async {
                self.refreshControl.endRefreshing()
                self.activityIndicatorView.stopAnimating()
            }
            if let error = error {
                DispatchQueue.main.async {
                    showErrorToast(controller: self, message: error, seconds: 3.0)
                }
            } else {
                self.adapter.performUpdates(animated: true, completion: nil)
            }
        }
    }
    
    @objc private func refreshPosts() {
        if viewModel.postsIsEmpty() {
            activityIndicatorView.startAnimating()
        }
        fetchPosts()
    }
    
    private func deletePost(id: String) {
        viewModel.deletePost(id: id) { error in
            guard let navController = self.navigationController else {return}
            if let error = error {
                DispatchQueue.main.async {
                    showErrorToast(controller: navController, message: error, seconds: 2.0)
                }
            } else {
                DispatchQueue.main.async {
                    showSuccessToast(controller: navController, message: "Deleted", seconds: 2.0)
                }
            }
        }
    }
    
    private func reportPost(id: String, subReddit: String, reason: String) {
        viewModel.reportPost(id: id, subReddit: subReddit, reason: reason) { error in
            guard let navController = self.navigationController else {return}
            if let error = error {
                DispatchQueue.main.async {
                    showErrorToast(controller: navController, message: error, seconds: 2.0)
                }
            } else {
                DispatchQueue.main.async {
                    showSuccessToast(controller: navController, message: "Reported", seconds: 2.0)
                }
            }
        }
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
            action = UIAlertAction(title: title, style: .default, handler: { _ in
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

extension PostsController: ListAdapterDataSource {
    func objects(for listAdapter: ListAdapter) -> [ListDiffable] {
        return viewModel.getPosts()
    }
    
    func listAdapter(_ listAdapter: ListAdapter, sectionControllerFor object: Any) -> ListSectionController {
        let postListSectionController = PostListSectionController()
        postListSectionController.postViewDelegate = self
        postListSectionController.homeHeaderDelegate = self
        postListSectionController.galleryImageDelegate = self
        postListSectionController.controlViewDelegate = self
        postListSectionController.sort = viewModel.sort
        postListSectionController.topOption = viewModel.topOption
        postListSectionController.listLayoutOption = viewModel.listLayoutOption
        postListSectionController.authenticated = viewModel.isUserAuthenticated()
        return postListSectionController
    }
    
    func emptyView(for listAdapter: ListAdapter) -> UIView? {
        return nil
    }
}

extension PostsController: HomeHeaderDelegate {
    func changeSort() {
        generatorImpactOccured()

        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: getCurrentInterfaceForAlerts())
        alertController.addAction(UIAlertAction(title: "Hot", style: .default, handler: { _ in
            self.viewModel.changeSort(sort: SortOptions.hot, topOption: nil)
            self.adapter.performUpdates(animated: true, completion: nil)
            DispatchQueue.main.async {
                self.activityIndicatorView.startAnimating()
            }
            self.fetchPosts()
        }))
        alertController.addAction(UIAlertAction(title: "New", style: .default, handler: { _ in
            self.viewModel.changeSort(sort: SortOptions.new, topOption: nil)
            self.adapter.performUpdates(animated: true, completion: nil)
            DispatchQueue.main.async {
                self.activityIndicatorView.startAnimating()
            }
            self.fetchPosts()
        }))
        alertController.addAction(UIAlertAction(title: "Top", style: .default, handler: { _ in
            let topAlertController = UIAlertController(title: nil, message: nil, preferredStyle: getCurrentInterfaceForAlerts())
            for option in TopOptions.allCases {
                var title = ""
                switch option {
                case .hour:
                    title = "Now"
                case .day:
                    title = "Today"
                case .week:
                    title = "This Week"
                case .month:
                    title = "This Month"
                case .year:
                    title = "This Year"
                case .all:
                    title = "All Time"
                }
                topAlertController.addAction(UIAlertAction(title: title, style: .default, handler: { action in
                    guard let action = action.title else {return}
                    var topOption = ""
                    if action == "Now" {
                        topOption = "hour"
                    } else if action == "Today" {
                        topOption = "day"
                    } else if action == "This Week" {
                        topOption = "week"
                    } else if action == "This Month" {
                        topOption = "month"
                    } else if action == "This Year" {
                        topOption = "year"
                    } else if action == "All Time" {
                        topOption = "all"
                    }
                    self.viewModel.changeSort(sort: SortOptions.top, topOption: topOption)
                    self.adapter.performUpdates(animated: true, completion: nil)
                    DispatchQueue.main.async {
                        self.activityIndicatorView.startAnimating()
                    }
                    self.fetchPosts()
                }))
            }
            topAlertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            self.present(topAlertController, animated: true, completion: nil)
        }))
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        present(alertController, animated: true, completion: nil)
    }
    
    func changeLayout() {
        generatorImpactOccured()

        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: getCurrentInterfaceForAlerts())
        alertController.addAction(UIAlertAction(title: "Card", style: .default, handler: { _ in
            self.viewModel.changeLayout(layout: .card)
            self.adapter.reloadData(completion: nil)
        }))
        alertController.addAction(UIAlertAction(title: "Gallery", style: .default, handler: { _ in
            self.viewModel.changeLayout(layout: .gallery)
            self.adapter.reloadData(completion: nil)
        }))
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        present(alertController, animated: true, completion: nil)
    }
}

extension PostsController: PostViewDelegate {
    func didTapUsername(username: String, userIconURL: String?) {
        let userProfileController = UserProfileController()
        userProfileController.usernameProp = username
        userProfileController.icon_imgProp = userIconURL
        navigationController?.pushViewController(userProfileController, animated: true)
    }
    
    func didTapImage(imageSources: [ImageSource], position: Int) {
        let fullScreen = FullScreenImageController()
        fullScreen.imageSources = imageSources
        fullScreen.position = position
        present(fullScreen, animated: true, completion: nil)
    }

    func didTapOptions(index: Int) {
        let post = viewModel.getPost(index: index)
        let id = post.id
        let subReddit = post.subReddit
        let authenticated = viewModel.isUserAuthenticated()
        let subRedditRules = viewModel.getSubredditRules(subReddit: subReddit)
        let siteRules = viewModel.getSiteRules()
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
        if viewModel.canDelete(post: post) {
            alertController.addAction(UIAlertAction(title: "Delete", style: .destructive, handler: { _ in
                self.deletePost(id: id)
            }))
        }
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))

        present(alertController, animated: true, completion: nil)
    }
}

extension PostsController: GalleryImageDelegate {
    func didTapImageGallery(index: Int) {
        let post = viewModel.getPost(index: index)
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
//        redditCommentsController.post = post
//        redditCommentsController.index = index
        redditCommentsController.postView.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: height)
//        redditCommentsController.delegate = self
        navigationController?.pushViewController(redditCommentsController, animated: true)
    }
}

extension PostsController: ControlViewDelegate {
    func didTapVoteUserNotAuthed() {
        guard let navController = navigationController else {return}
        showErrorToast(controller: navController, message: "You need to be signed in to vote", seconds: 2.0)
    }
    
    func didTapComments(index: Int) {
        let post = viewModel.getPost(index: index)
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
//        redditCommentsController.post = post
//        redditCommentsController.index = index
        redditCommentsController.postView.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: height)
//        redditCommentsController.delegate = self
        navigationController?.pushViewController(redditCommentsController, animated: true)
    }
}

extension PostsController: UIScrollViewDelegate {
    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        let distance = scrollView.contentSize.height - (targetContentOffset.pointee.y + scrollView.bounds.height)
        if !viewModel.fetching && distance < 200 {
            fetchPosts()
        }
    }
}
