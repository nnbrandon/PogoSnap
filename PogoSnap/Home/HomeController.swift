//
//  HomeController.swift
//  PogoSnap
//
//  Created by Brandon Nguyen on 11/17/20.
//

import UIKit
import IGListKit
import YPImagePicker

class HomeController: UIViewController {

    var homeViewModel: HomeViewModel!

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
        
        homeViewModel = HomeViewModel(redditClient: RedditClient.sharedInstance, imgurClient: ImgurClient.sharedInstance)
        
        navigationItem.title = "PogoSnap"
        if traitCollection.userInterfaceStyle == .light {
            collectionView.backgroundColor = .white
            let barButton = UIBarButtonItem(image: UIImage(named: "plus_unselected")?.withRenderingMode(.alwaysTemplate), style: .plain, target: self, action: #selector(handleAdd))
            barButton.tintColor = .darkGray
            navigationItem.rightBarButtonItem = barButton
        } else {
            collectionView.backgroundColor = RedditConsts.redditDarkMode
            let barButton = UIBarButtonItem(image: UIImage(named: "plus_unselected")?.withRenderingMode(.alwaysTemplate), style: .plain, target: self, action: #selector(handleAdd))
            barButton.tintColor = .white
            navigationItem.rightBarButtonItem = barButton
        }
        
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
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        homeViewModel.checkUserStatus()
        if homeViewModel.postsIsEmpty {
            homeViewModel.fetchRules()
            fetchPosts()
        }
    }
    
    private func fetchPosts() {
        homeViewModel.fetchPosts { error in
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
        if homeViewModel.postsIsEmpty {
            activityIndicatorView.startAnimating()
        }
        fetchPosts()
    }
    
    @objc func handleAdd() {
        if RedditClient.sharedInstance.getUsername() == nil {
            DispatchQueue.main.async {
                if let navController = self.navigationController {
                    showErrorToast(controller: navController, message: "You need to sign in to upload an image", seconds: 0.5)
                }
            }
        } else {
            var config = YPImagePickerConfiguration()
            config.screens = [.library]
            config.showsPhotoFilters = false
            config.shouldSaveNewPicturesToAlbum = false
            let picker = YPImagePicker(configuration: config)
            if traitCollection.userInterfaceStyle == .dark {
                picker.navigationBar.barTintColor = RedditConsts.redditDarkMode
                picker.view.backgroundColor = RedditConsts.redditDarkMode
            }
            picker.didFinishPicking { [unowned picker] items, cancelled in
                if cancelled {
                    picker.dismiss(animated: true, completion: nil)
                }
                if let photo = items.singlePhoto {
                    let sharePhotoVC = SharePhotoController()
//                    sharePhotoVC.delegate = self
                    sharePhotoVC.selectedImage = photo.image
                    picker.pushViewController(sharePhotoVC, animated: true)
                }
            }
            present(picker, animated: true, completion: nil)
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
    
    private func reportPost(id: String, subReddit: String, reason: String) {
        homeViewModel.reportPost(id: id, subReddit: subReddit, reason: reason) { error in
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
    
    private func deletePost(id: String) {
        homeViewModel.deletePost(id: id) { error in
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
    
    private func votePost(index: Int, direction: Int) {
        homeViewModel.votePost(index: index, direction: direction) { error in
            guard let navController = self.navigationController  else {return}
            if let error = error {
                DispatchQueue.main.async {
                    showErrorToast(controller: navController, message: error, seconds: 2.0)
                }
            } else {
                self.adapter.performUpdates(animated: true, completion: nil)
            }
        }
    }
}

extension HomeController: PostViewDelegate {
    func showComments(post: Post, index: Int) {
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

    func showFullImages(imageSources: [ImageSource], position: Int) {
        let fullScreen = FullScreenImageController()
        fullScreen.imageSources = imageSources
        fullScreen.position = position
        present(fullScreen, animated: true, completion: nil)
    }
    
    func votePost(index: Int, direction: Int, authenticated: Bool, archived: Bool) {
        guard let navController = self.navigationController  else {
            return
        }

        if !authenticated {
            showErrorToast(controller: navController, message: "You need to be signed in to vote", seconds: 2.0)
        } else if archived {
            showErrorToast(controller: navController, message: "This post has been archived", seconds: 2.0)
        } else {
            votePost(index: index, direction: direction)
        }
    }
    
    func showOptions(id: String, subReddit: String, subRedditRules: [String], siteRules: [String], authenticated: Bool, canDelete: Bool) {
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
        if canDelete {
            alertController.addAction(UIAlertAction(title: "Delete", style: .destructive, handler: { _ in
                self.deletePost(id: id)
            }))
        }
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))

        present(alertController, animated: true, completion: nil)
    }
}

extension HomeController: ProfileImageDelegate {
    func didTapImageGallery(post: Post, index: Int) {
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

extension HomeController: ListAdapterDataSource {
    func objects(for listAdapter: ListAdapter) -> [ListDiffable] {
        return homeViewModel.posts
    }
    
    func listAdapter(_ listAdapter: ListAdapter, sectionControllerFor object: Any) -> ListSectionController {
        let postListSectionController = PostListSectionController()
        postListSectionController.postViewDelegate = self
        postListSectionController.homeHeaderDelegate = self
        postListSectionController.profileImageDelegate = self
        postListSectionController.sort = homeViewModel.sort
        postListSectionController.topOption = homeViewModel.topOption
        postListSectionController.listLayoutOption = homeViewModel.listLayoutOption
        return postListSectionController
    }
    
    func emptyView(for listAdapter: ListAdapter) -> UIView? {
        return nil
    }
}

extension HomeController: UIScrollViewDelegate {
    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        let distance = scrollView.contentSize.height - (targetContentOffset.pointee.y + scrollView.bounds.height)
        if !homeViewModel.fetching && distance < 200 {
            fetchPosts()
        }
    }
}

extension HomeController: HomeHeaderDelegate {
    func changeSort() {
        generatorImpactOccured()

        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: getCurrentInterfaceForAlerts())
        alertController.addAction(UIAlertAction(title: "Hot", style: .default, handler: { _ in
            self.homeViewModel.changeSort(sort: SortOptions.hot, topOption: nil)
            self.adapter.performUpdates(animated: true, completion: nil)
            DispatchQueue.main.async {
                self.activityIndicatorView.startAnimating()
            }
            self.fetchPosts()
        }))
        alertController.addAction(UIAlertAction(title: "New", style: .default, handler: { _ in
            self.homeViewModel.changeSort(sort: SortOptions.new, topOption: nil)
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
                    self.homeViewModel.changeSort(sort: SortOptions.top, topOption: topOption)
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
            self.homeViewModel.changeLayout(layout: .card)
            self.adapter.reloadData(completion: nil)
        }))
        alertController.addAction(UIAlertAction(title: "Gallery", style: .default, handler: { _ in
            self.homeViewModel.changeLayout(layout: .gallery)
            self.adapter.reloadData(completion: nil)
        }))
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        present(alertController, animated: true, completion: nil)
    }
}

//extension HomeController: ShareDelegate {
//    func imageSubmitted(image: UIImage, title: String) {
//        guard let author = RedditClient.sharedInstance.getUsername() else {return}
//
//        if let navController = self.navigationController {
//            let progressView = navController.view.subviews.last as? UIProgressView
//            progressView?.setProgress(0.5, animated: true)
//
//            ImgurClient.sharedInstance.uploadImageToImgur(image: image) { result in
//                switch result {
//                case .success(let imageSource):
//                    DispatchQueue.main.async {
//                        progressView?.setProgress(0.9, animated: true)
//                    }
//                    guard let imageSource = imageSource else {return}
//                    RedditClient.sharedInstance.submitImageLink(link: imageSource.url, text: title) { result in
//                        DispatchQueue.main.async {
//                            progressView?.setProgress(1.0, animated: true)
//                        }
//                        var message = ""
//                        switch result {
//                        case .success(let postData):
//                            if let postData = postData, let postId = postData.id {
//                                ImgurClient.sharedInstance.incrementUploadCount()
//                                message = "Image upload success"
//                                let commentsLink = "https://www.reddit.com/r/\(RedditConsts.subredditName)/comments/" + postId + ".json"
//                                let aspectFit = imageSource.width >= imageSource.height
//                                let post = Post(author: author, title: title, imageSources: [imageSource], score: 1, numComments: 0, commentsLink: commentsLink, archived: false, id: postId, created_utc: Date().timeIntervalSince1970, liked: true, aspectFit: aspectFit, user_icon: RedditClient.sharedInstance.getIconImg(), subReddit: RedditConsts.subredditName)
//                                self.posts.insert(post, at: 0)
//                                DispatchQueue.main.async {
//                                    if let userNavController = self.tabBarController?.viewControllers?.last as? UINavigationController, let userProfileController = userNavController.viewControllers.first as? UserProfileController {
//                                        userProfileController.posts.insert(post, at: 0)
//                                    }
//                                }
//                            }
//                        case .error:
//                            message = "Image upload failed"
//                        }
//                        DispatchQueue.main.async {
//                            self.collectionView.scrollToItem(at: IndexPath(row: 0, section: 0), at: .top, animated: true)
//                            generatorImpactOccured()
//                            if let navController = self.navigationController {
//                                showImageToast(controller: navController, message: message, image: image, seconds: 10.0)
//                            }
//                            progressView?.setProgress(0, animated: true)
//                        }
//                    }
//
//                case .error(let error):
//                    DispatchQueue.main.async {
//                        progressView?.setProgress(0.0, animated: true)
//                        generatorImpactOccured()
//                        if let navController = self.navigationController {
//                            showErrorToast(controller: navController, message: error, seconds: 10.0)
//                        }
//                    }
//                    return
//                }
//            }
//        }
//    }
//}
