////
////  SearchController.swift
////  PogoSnap
////
////  Created by Brandon Nguyen on 12/9/20.
////
//
//import UIKit
//
//class SearchController: UICollectionViewController, PostViewDelegate, ProfileImageDelegate {
//
//    struct Const {
//        static let cellId = "cellId"
//        static let headerId = "headerId"
//    }
//    var posts = [Post]() {
//        didSet {
//            DispatchQueue.main.async {
//                self.collectionView.reloadData()
//            }
//        }
//    }
//    var after: String? = ""
//    var previousText = ""
//    var searchController = UISearchController(searchResultsController: nil)
//
//
//    let refreshControl: UIRefreshControl = {
//        let control = UIRefreshControl()
////        control.addTarget(self, action: #selector(refreshPosts), for: .valueChanged)
//        return control
//    }()
//    let activityIndicatorView: UIActivityIndicatorView = {
//        let activityView = UIActivityIndicatorView()
//        return activityView
//    }()
//
//    override func viewDidLoad() {
//        super.viewDidLoad()
//
//        collectionView.backgroundColor = .white
//        collectionView.register(UserProfileCell.self, forCellWithReuseIdentifier: Const.cellId)
//        collectionView.refreshControl = refreshControl
//
//        searchController.searchBar.delegate = self
//        searchController.hidesNavigationBarDuringPresentation = false
//        searchController.obscuresBackgroundDuringPresentation = false
//        navigationItem.searchController = searchController
//        navigationItem.hidesSearchBarWhenScrolling = false
//
//        view.addSubview(activityIndicatorView)
//        activityIndicatorView.translatesAutoresizingMaskIntoConstraints = false
//        activityIndicatorView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
//        activityIndicatorView.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
//    }
//
//    func didTapImageGallery(post: Post, index: Int) {
//        var height = 8 + 8 + 50 + 40 + view.frame.width
//        let title = post.title
//        let titleEstimatedHeight = title.height(withConstrainedWidth: view.frame.width - 16, font: UIFont.boldSystemFont(ofSize: 16))
//        height += titleEstimatedHeight
//
//        let redditCommentsController = RedditCommentsController()
//        redditCommentsController.hidesBottomBarWhenPushed = true
//        redditCommentsController.commentsLink = post.commentsLink
//        redditCommentsController.archived = post.archived
//        redditCommentsController.post = post
//        redditCommentsController.index = index
//        redditCommentsController.postView.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: height)
//        redditCommentsController.delegate = self
//        navigationController?.pushViewController(redditCommentsController, animated: true)
//        print(post)
//    }
//
//    func didTapComment(post: Post, index: Int) {}
//
//    func didTapUsername(username: String) {
//
//    }
//
//    func didTapImage(imageSources: [ImageSource], position: Int) {
//
//    }
//
//    func didTapOptions(post: Post) {
//
//    }
//
//    func didTapVote(post: Post, direction: Int, index: Int, authenticated: Bool, archived: Bool) {
//
//    }
//}
//
//extension SearchController: UICollectionViewDelegateFlowLayout {
//
//    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
//        return 1
//    }
//
//    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
//        return 1
//    }
//
//    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
//        let width = (view.frame.width - 2) / 3
//        return CGSize(width: width, height: width)
//    }
//
//    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
//        return posts.count
//    }
//
//    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
//        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: Const.cellId, for: indexPath) as! UserProfileCell
//
//        cell.photoImageView.image = UIImage()
//        let post = posts[indexPath.row]
//        cell.post = post
//        cell.index = indexPath.row
//        cell.delegate = self
//
//        return cell
//    }
//
//    override func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
//        if indexPath.row == posts.count - 3 {
////            if let usernameProp = usernameProp {
////                fetchUserPosts(username: usernameProp)
////            } else if let username = RedditClient.sharedInstance.getUsername() {
////                fetchUserPosts(username: username)
////            }
//        }
//    }
//}
//
////extension SearchController: UISearchBarDelegate {
////
////    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
////        guard let text = searchBar.text else {return}
////        if text != previousText {
////            after = ""
////            posts = []
////            previousText = text
////        }
////        activityIndicatorView.startAnimating()
////        if let after = after {
////            RedditClient.sharedInstance.searchPosts(query: text, after: after) { (posts, nextAfter) in
////                DispatchQueue.main.async {
////                    self.activityIndicatorView.stopAnimating()
////                }
////                var nextPosts = self.posts
////                for post in posts {
////                    if !nextPosts.contains(post) {
////                        nextPosts.append(post)
////                    }
////                }
////                if self.posts != nextPosts {
////                    self.posts = nextPosts
////                }
////                self.after = nextAfter
////            }
////        } else {
////            activityIndicatorView.stopAnimating()
////        }
////    }
////}
