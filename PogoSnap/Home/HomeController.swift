//
//  HomeController.swift
//  PogoSnap
//
//  Created by Brandon Nguyen on 11/17/20.
//

import UIKit
import YPImagePicker

class HomeController: UICollectionViewController, PostViewDelegate, ShareDelegate, ProfileImageDelegate {

    var posts = [Post]() {
        didSet {
            DispatchQueue.main.async {
                self.collectionView.reloadData()
            }
        }
    }
    var after: String? = ""
    var sort = SortOptions.best
    var listLayoutOption = ListLayoutOptions.card
    var userSignFlag: String?
    var lastContentOffset: CGFloat = 0.0

    let cardCellId = "cardCellId"
    let galleryCellId = "galleryCellId"
    let footerId = "footerId"
    let headerId = "headerId"
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
    let footerView = UIActivityIndicatorView(style: UIActivityIndicatorView.Style.medium)
    let addButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setImage(UIImage(named: "add-60")?.withRenderingMode(.alwaysOriginal), for: .normal)
        btn.addTarget(self, action: #selector(handleAdd), for: .touchUpInside)
        return btn
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "PogoSnap"
        if traitCollection.userInterfaceStyle == .light {
            collectionView.backgroundColor = .white
        }
        collectionView.register(HomePostCell.self, forCellWithReuseIdentifier: cardCellId)
        collectionView.register(UserProfileCell.self, forCellWithReuseIdentifier: galleryCellId)
        collectionView.refreshControl = refreshControl
        collectionView.register(HomeHeader.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: headerId)
        collectionView.register(CollectionViewFooterView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter, withReuseIdentifier: footerId)
        (collectionView.collectionViewLayout as? UICollectionViewFlowLayout)?.headerReferenceSize = CGSize(width: collectionView.bounds.width, height: 35)
        (collectionView.collectionViewLayout as? UICollectionViewFlowLayout)?.footerReferenceSize = CGSize(width: collectionView.bounds.width, height: 50)

        view.addSubview(activityIndicatorView)
        activityIndicatorView.translatesAutoresizingMaskIntoConstraints = false
        activityIndicatorView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        activityIndicatorView.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        
        view.addSubview(addButton)
        addButton.translatesAutoresizingMaskIntoConstraints = false
        addButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20).isActive = true
        addButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -10).isActive = true
        view.bringSubviewToFront(addButton)
        
        userSignFlag = RedditClient.sharedInstance.getUsername()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        let previousUserSignFlag = userSignFlag
        userSignFlag = RedditClient.sharedInstance.getUsername()
        if previousUserSignFlag != userSignFlag {
            print("user sign state changed, resetting posts and fetching new posts")
            posts = [Post]()
            after = ""
        }
        if posts.isEmpty || posts.count == 1 {
            activityIndicatorView.startAnimating()
            fetchRules()
            fetchPosts()
        }
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        collectionView.collectionViewLayout.invalidateLayout()
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
                if let liked = posts[index].liked {
                    if liked {
                        posts[index].liked = nil
                        posts[index].score -= 1
                    } else {
                        posts[index].liked = nil
                        posts[index].score += 1
                    }
                }
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
    
    func didTapComment(post: Post, index: Int) {
        var height = 8 + 8 + 50 + 40 + view.frame.width
        let title = posts[index].title
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
    
    private func reportPost(postId: String, reason: String) {
        let postId = "t3_\(postId)"
        RedditClient.sharedInstance.report(id: postId, reason: reason) { (errors, _) in
            if errors.isEmpty {
                DispatchQueue.main.async {
                    generatorImpactOccured()
                    if let commentController = self.navigationController?.viewControllers.last as? RedditCommentsController {
                        showSuccessToast(controller: commentController, message: "Reported", seconds: 0.5)
                    } else {
                        showSuccessToast(controller: self, message: "Reported", seconds: 0.5)
                    }
                }
            } else {
                DispatchQueue.main.async {
                    generatorImpactOccured()
                    showErrorToast(controller: self, message: "Could not report the post", seconds: 0.5)
                    if let commentController = self.navigationController?.viewControllers.last as? RedditCommentsController {
                        showErrorToast(controller: commentController, message: "Could not report the post", seconds: 0.5)
                    } else {
                        showErrorToast(controller: self, message: "Could not report the post", seconds: 0.5)
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
                    showErrorToast(controller: self, message: "Could not delete the post", seconds: 0.5)
                    if let commentController = self.navigationController?.viewControllers.last as? RedditCommentsController {
                        showErrorToast(controller: commentController, message: "Could not delete the post", seconds: 0.5)
                    } else {
                        showErrorToast(controller: self, message: "Could not delete the post", seconds: 0.5)
                    }
                }
            } else {
                if let index = self.posts.firstIndex(where: { post -> Bool in post.id == postId}) {
                    self.posts.remove(at: index)
                    DispatchQueue.main.async {
                        generatorImpactOccured()
                        if let commentController = self.navigationController?.viewControllers.last as? RedditCommentsController {
                            showSuccessToast(controller: commentController, message: "Deleted", seconds: 0.5)
                        } else {
                            showSuccessToast(controller: self, message: "Deleted", seconds: 0.5)
                        }
                    }
                }
            }
        }
    }
    
    private func votePost(postId: String, direction: Int, index: Int) {
        RedditClient.sharedInstance.votePost(postId: postId, direction: direction) { _ in}
    }
    
    private func fetchPosts() {
        print("fetching posts...")
        if let after = after {
            print(sort.rawValue)
            RedditClient.sharedInstance.fetchPosts(after: after, sort: sort.rawValue) { posts, nextAfter in
                DispatchQueue.main.async {
                    self.activityIndicatorView.stopAnimating()
                    self.footerView.stopAnimating()
                }
                self.posts.append(contentsOf: posts)
                self.after = nextAfter
            }
        } else {
            activityIndicatorView.stopAnimating()
            footerView.stopAnimating()
        }
    }
    
    private func fetchRules() {
        print("fetching rules...")
        RedditClient.fetchRules { rules in
            let subredditRules = rules.rules.map { subRedditRule in
                subRedditRule.short_name
            }
            let siteRules = rules.site_rules
            
            self.defaults?.setValue(subredditRules, forKey: "PokemonGoSnapRules")
            self.defaults?.setValue(siteRules, forKey: "SiteRules")
        }
    }
    
    func imageSubmitted(image: UIImage, title: String) {
        guard let author = RedditClient.sharedInstance.getUsername() else {return}

        if let navController = self.navigationController {
            let progressView = navController.view.subviews.last as? UIProgressView
            progressView?.setProgress(0.5, animated: true)
            
            ImgurClient.sharedInstance.uploadImageToImgur(image: image) { (imageSource, errorOccured) in
                if errorOccured {
                    DispatchQueue.main.async {
                        progressView?.setProgress(0.0, animated: true)
                        showErrorToast(controller: self, message: "Unable to upload image to Imgur", seconds: 1.0)
                    }
                    return
                } else {
                    DispatchQueue.main.async {
                        progressView?.setProgress(0.9, animated: true)
                    }
                }
                guard let imageSource = imageSource else {return}
                RedditClient.sharedInstance.submitImageLink(link: imageSource.url, text: title) { (errors, postData) in
                    DispatchQueue.main.async {
                        progressView?.setProgress(1.0, animated: true)
                    }
                    var message = "Image upload failed"
                    if let postData = postData, let postId = postData.id {
                        message = "Image upload success"
                        let commentsLink = "https://www.reddit.com/r/\(RedditClient.Const.subredditName)/comments/" + postId + ".json"
                        let post = Post(author: author, title: title, imageSources: [imageSource], score: 1, numComments: 0, commentsLink: commentsLink, archived: false, id: postId, liked: true)
                        self.posts.insert(post, at: 0)
                        DispatchQueue.main.async {
                            if let userNavController = self.tabBarController?.viewControllers?.last as? UINavigationController, let userProfileController = userNavController.viewControllers.first as? UserProfileController {
                                userProfileController.posts.insert(post, at: 0)
                            }
                        }
                    }
                    DispatchQueue.main.async {
                        self.collectionView.scrollToItem(at: IndexPath(row: 0, section: 0), at: .top, animated: true)
                        generatorImpactOccured()
                        showImageToast(controller: self, message: message, image: image, seconds: 2.0)
                        progressView?.setProgress(0, animated: true)
                    }
                }
            }
        }
    }
    
    @objc private func refreshPosts() {
        print("refreshing posts")
        if posts.isEmpty {
            activityIndicatorView.startAnimating()
        }
        RedditClient.sharedInstance.fetchPosts(after: "", sort: sort.rawValue) { posts, nextAfter in
            DispatchQueue.main.async {
                self.refreshControl.endRefreshing()
                self.activityIndicatorView.stopAnimating()
            }
            if self.posts != posts {
                print("settings posts after refresh")
                self.posts = posts
                self.after = nextAfter
            }
        }
    }
    
    private func changeSort() {
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alertController.addAction(UIAlertAction(title: "Best", style: .default, handler: { _ in
            self.sort = SortOptions.best
            self.posts = []
            self.after = ""
            DispatchQueue.main.async {
                self.activityIndicatorView.startAnimating()
            }
            self.fetchPosts()
        }))
        alertController.addAction(UIAlertAction(title: "Hot", style: .default, handler: { _ in
            self.sort = SortOptions.hot
            self.posts = []
            self.after = ""
            DispatchQueue.main.async {
                self.activityIndicatorView.startAnimating()
            }
            self.fetchPosts()
        }))
        alertController.addAction(UIAlertAction(title: "New", style: .default, handler: { _ in
            self.sort = SortOptions.new
            self.posts = []
            self.after = ""
            DispatchQueue.main.async {
                self.activityIndicatorView.startAnimating()
            }
            self.fetchPosts()
        }))
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        present(alertController, animated: true, completion: nil)
    }
    
    private func changeLayout() {
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alertController.addAction(UIAlertAction(title: "Card", style: .default, handler: { _ in
            self.listLayoutOption = .card
            DispatchQueue.main.async {
                self.collectionView.reloadData()
            }
        }))
        alertController.addAction(UIAlertAction(title: "Gallery", style: .default, handler: { _ in
            self.listLayoutOption = .gallery
            DispatchQueue.main.async {
                self.collectionView.reloadData()
            }
        }))
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        present(alertController, animated: true, completion: nil)
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
            config.shouldSaveNewPicturesToAlbum = false
            let picker = YPImagePicker(configuration: config)
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

extension HomeController: UICollectionViewDelegateFlowLayout {
    
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if (scrollView.contentOffset.y < lastContentOffset) {
            //Scrolling up
            addButton.isHidden = false
        } else if (scrollView.contentOffset.y > lastContentOffset) {
            //Scrolling down
            addButton.isHidden = true
        }
        lastContentOffset = scrollView.contentOffset.y
    }
    
    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        if kind == UICollectionView.elementKindSectionHeader {
            let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: headerId, for: indexPath) as! HomeHeader
            header.sortOption = sort
            header.changeSort = changeSort
            header.listLayoutOption = listLayoutOption
            header.changeLayout = changeLayout
            return header
        }
         if kind == UICollectionView.elementKindSectionFooter {
             let footer = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: footerId, for: indexPath)
             footer.addSubview(footerView)
             footerView.frame = CGRect(x: 0, y: 0, width: collectionView.bounds.width, height: 50)
             return footer
         }
         return UICollectionReusableView()
     }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        switch listLayoutOption {
        case .card:
            var height = 8 + 8 + 50 + 40 + view.frame.width
            let title = posts[indexPath.row].title
            let titleEstimatedHeight = title.height(withConstrainedWidth: view.frame.width - 16, font: UIFont.boldSystemFont(ofSize: 16))
            height += titleEstimatedHeight
            return CGSize(width: view.frame.width, height: height)
        case .gallery:
            let width = (view.frame.width - 2) / 3
            return CGSize(width: width, height: width)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        switch listLayoutOption {
        case .card:
            return 10
        case .gallery:
            return 1
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        switch listLayoutOption {
        case .card:
            return 10
        case .gallery:
            return 1
        }
    }

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return posts.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        switch listLayoutOption {
        case .card:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cardCellId, for: indexPath) as! HomePostCell
            for index in 0..<cell.postView.photoImageSlideshow.subviews.count {
                let imageView = cell.postView.photoImageSlideshow.subviews[index] as! CustomImageView
                imageView.image = UIImage()
            }
            cell.post = posts[indexPath.row]
            cell.index = indexPath.row
            cell.delegate = self
            
            return cell
        case .gallery:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: galleryCellId, for: indexPath) as! UserProfileCell
            cell.photoImageView.image = UIImage()
            let post = posts[indexPath.row]
            cell.post = post
            cell.index = indexPath.row
            cell.delegate = self
        
            return cell
        }
    }
    
    override func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if indexPath.row == posts.count - 8, after != nil {
            footerView.startAnimating()
            fetchPosts()
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
