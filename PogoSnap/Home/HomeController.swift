//
//  HomeController.swift
//  PogoSnap
//
//  Created by Brandon Nguyen on 11/17/20.
//

import UIKit
import IGListKit
import YPImagePicker

class HomeController: PostCollectionController {

    var sort = SortOptions.hot
    var topOption: String?
    var userSignFlag: String?
    var fetching = false

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
    let footerView = UIActivityIndicatorView()

    override func viewDidLoad() {
        super.viewDidLoad()
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
        pinCollectionView(to: view)
        adapter.collectionView = collectionView
        adapter.dataSource = self
        adapter.scrollViewDelegate = self
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
            posts = [Post]()
            pokemonGoAfter = ""
            pokemonGoSnapAfter = ""
        }
        if posts.isEmpty || posts.count == 1 {
            activityIndicatorView.startAnimating()
            fetchRules()
            fetchPosts()
        }
    }
    
    private func fetchPosts() {
        fetching = true
        RedditClient.sharedInstance.fetchGoAndSnapPosts(pokemonGoAfter: pokemonGoAfter, pokemonGoSnapAfter: pokemonGoSnapAfter, sort: sort.rawValue, topOption: topOption) { result in
            self.fetching = false
            DispatchQueue.main.async {
                self.refreshControl.endRefreshing()
                self.activityIndicatorView.stopAnimating()
            }
            switch result {
            case .success(let posts, let nextPokemonGoSnapAfter, let nextPokemonGoAfter):
                self.posts.append(contentsOf: posts)
                self.pokemonGoSnapAfter = nextPokemonGoSnapAfter
                self.pokemonGoAfter = nextPokemonGoAfter
            case .error:
                DispatchQueue.main.async {
                    showErrorToast(controller: self, message: "Failed to retrieve posts", seconds: 3.0)
                    self.activityIndicatorView.stopAnimating()
                }
            }
        }
    }
    
    private func fetchRules() {
        RedditClient.sharedInstance.fetchRules(subReddit: RedditConsts.subredditName) { _ in}
        RedditClient.sharedInstance.fetchRules(subReddit: RedditConsts.pokemonGoSubredditName) { _ in}
    }
    
    @objc private func refreshPosts() {
        if posts.isEmpty {
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
                    sharePhotoVC.delegate = self
                    sharePhotoVC.selectedImage = photo.image
                    picker.pushViewController(sharePhotoVC, animated: true)
                }
            }
            present(picker, animated: true, completion: nil)
        }
    }
}

extension HomeController: ListAdapterDataSource {
    func objects(for listAdapter: ListAdapter) -> [ListDiffable] {
        return posts
    }
    
    func listAdapter(_ listAdapter: ListAdapter, sectionControllerFor object: Any) -> ListSectionController {
        let postListSectionController = PostListSectionController()
        postListSectionController.postViewDelegate = self
        postListSectionController.homeHeaderDelegate = self
        postListSectionController.profileImageDelegate = self
        postListSectionController.sort = sort
        postListSectionController.topOption = topOption
        postListSectionController.listLayoutOption = listLayoutOption
        return postListSectionController
    }
    
    func emptyView(for listAdapter: ListAdapter) -> UIView? {
        return nil
    }
}

extension HomeController: UIScrollViewDelegate {
    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        let distance = scrollView.contentSize.height - (targetContentOffset.pointee.y + scrollView.bounds.height)
        if !fetching && distance < 200 {
            if pokemonGoAfter != nil && pokemonGoSnapAfter != nil {
                fetchPosts()
            }
        }
    }
}

extension HomeController: HomeHeaderDelegate {
    func changeSort() {
        generatorImpactOccured()

        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: getCurrentInterfaceForAlerts())
        alertController.addAction(UIAlertAction(title: "Hot", style: .default, handler: { _ in
            self.sort = SortOptions.hot
            self.posts = []
            self.pokemonGoSnapAfter = ""
            self.pokemonGoAfter = ""
            self.topOption = nil
            DispatchQueue.main.async {
                self.activityIndicatorView.startAnimating()
            }
            self.fetchPosts()
        }))
        alertController.addAction(UIAlertAction(title: "New", style: .default, handler: { _ in
            self.sort = SortOptions.new
            self.posts = []
            self.pokemonGoSnapAfter = ""
            self.pokemonGoAfter = ""
            self.topOption = nil
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
                    self.sort = SortOptions.top
                    self.posts = []
                    self.pokemonGoSnapAfter = ""
                    self.pokemonGoAfter = ""
                    self.topOption = topOption
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
            self.listLayoutOption = .card
            self.adapter.reloadData(completion: nil)
        }))
        alertController.addAction(UIAlertAction(title: "Gallery", style: .default, handler: { _ in
            self.listLayoutOption = .gallery
            self.adapter.reloadData(completion: nil)
        }))
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        present(alertController, animated: true, completion: nil)
    }
}

extension HomeController: ShareDelegate {
    func imageSubmitted(image: UIImage, title: String) {
        guard let author = RedditClient.sharedInstance.getUsername() else {return}

        if let navController = self.navigationController {
            let progressView = navController.view.subviews.last as? UIProgressView
            progressView?.setProgress(0.5, animated: true)
            
            ImgurClient.sharedInstance.uploadImageToImgur(image: image) { result in
                switch result {
                case .success(let imageSource):
                    DispatchQueue.main.async {
                        progressView?.setProgress(0.9, animated: true)
                    }
                    guard let imageSource = imageSource else {return}
                    RedditClient.sharedInstance.submitImageLink(link: imageSource.url, text: title) { result in
                        DispatchQueue.main.async {
                            progressView?.setProgress(1.0, animated: true)
                        }
                        var message = ""
                        switch result {
                        case .success(let postData):
                            if let postData = postData, let postId = postData.id {
                                ImgurClient.sharedInstance.incrementUploadCount()
                                message = "Image upload success"
                                let commentsLink = "https://www.reddit.com/r/\(RedditConsts.subredditName)/comments/" + postId + ".json"
                                let aspectFit = imageSource.width >= imageSource.height
                                let post = Post(author: author, title: title, imageSources: [imageSource], score: 1, numComments: 0, commentsLink: commentsLink, archived: false, id: postId, created_utc: Date().timeIntervalSince1970, liked: true, aspectFit: aspectFit, user_icon: RedditClient.sharedInstance.getIconImg(), subReddit: RedditConsts.subredditName)
                                self.posts.insert(post, at: 0)
                                DispatchQueue.main.async {
                                    if let userNavController = self.tabBarController?.viewControllers?.last as? UINavigationController, let userProfileController = userNavController.viewControllers.first as? UserProfileController {
                                        userProfileController.posts.insert(post, at: 0)
                                    }
                                }
                            }
                        case .error:
                            message = "Image upload failed"
                        }
                        DispatchQueue.main.async {
                            self.collectionView.scrollToItem(at: IndexPath(row: 0, section: 0), at: .top, animated: true)
                            generatorImpactOccured()
                            if let navController = self.navigationController {
                                showImageToast(controller: navController, message: message, image: image, seconds: 10.0)
                            }
                            progressView?.setProgress(0, animated: true)
                        }
                    }
                
                case .error(let error):
                    DispatchQueue.main.async {
                        progressView?.setProgress(0.0, animated: true)
                        generatorImpactOccured()
                        if let navController = self.navigationController {
                            showErrorToast(controller: navController, message: error, seconds: 10.0)
                        }
                    }
                    return
                }
            }
        }
    }
}

public class CollectionViewFooterView: UICollectionReusableView {
    override init(frame: CGRect) {
        super.init(frame: frame)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
