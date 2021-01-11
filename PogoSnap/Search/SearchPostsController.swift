//
//  SearchPostsController.swift
//  PogoSnap
//
//  Created by Brandon Nguyen on 1/9/21.
//

import UIKit
import IGListKit

class SearchPostsController: PostCollectionController {

    var subReddit = ""
    var searchText = ""
    var after: String? = ""
    var fetching = false
    var sort = SortOptions.hot
    var topOption: String?

    let activityIndicatorView: UIActivityIndicatorView = {
        let activityView = UIActivityIndicatorView()
        return activityView
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.title = searchText

        if traitCollection.userInterfaceStyle == .light {
            view.backgroundColor = .white
            collectionView.backgroundColor = .white
        } else {
            view.backgroundColor = RedditConsts.redditDarkMode
            collectionView.backgroundColor = RedditConsts.redditDarkMode
        }

        listLayoutOption = ListLayoutOptions.gallery

        pinCollectionView(to: view)
        adapter.collectionView = collectionView
        adapter.scrollViewDelegate = self
        adapter.dataSource = self

        view.addSubview(activityIndicatorView)
        activityIndicatorView.translatesAutoresizingMaskIntoConstraints = false
        activityIndicatorView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        activityIndicatorView.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true

        if posts.isEmpty {
            activityIndicatorView.startAnimating()
            searchPosts()
        }
    }

    private func searchPosts() {
        if let after = after {
            fetching = true
            RedditClient.sharedInstance.searchPosts(subReddit: subReddit, query: searchText, after: after, sort: sort.rawValue, topOption: topOption) { result in
                self.fetching = false
                switch result {
                case .success(let posts, let nextAfter):
                    DispatchQueue.main.async {
                        self.activityIndicatorView.stopAnimating()
                    }
                    self.posts.append(contentsOf: posts)
                    self.after = nextAfter
                case .error:
                    DispatchQueue.main.async {
                        showErrorToast(controller: self, message: "Failed to retrieve posts", seconds: 3.0)
                        self.activityIndicatorView.stopAnimating()
                    }
                }
            }
        } else {
            activityIndicatorView.stopAnimating()
        }
    }
}

extension SearchPostsController: ListAdapterDataSource {
    func objects(for listAdapter: ListAdapter) -> [ListDiffable] {
        return posts
    }
    
    func listAdapter(_ listAdapter: ListAdapter, sectionControllerFor object: Any) -> ListSectionController {
        let postListSectionController = PostListSectionController()
        postListSectionController.postViewDelegate = self
        postListSectionController.profileImageDelegate = self
        postListSectionController.homeHeaderDelegate = self
        postListSectionController.sort = sort
        postListSectionController.topOption = topOption
        postListSectionController.listLayoutOption = listLayoutOption
        return postListSectionController
    }
    
    func emptyView(for listAdapter: ListAdapter) -> UIView? {
        return nil
    }
}

extension SearchPostsController: UIScrollViewDelegate {
    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        let distance = scrollView.contentSize.height - (targetContentOffset.pointee.y + scrollView.bounds.height)
        if !fetching && distance < 200 {
            if after != nil {
                searchPosts()
            }
        }
    }
}

extension SearchPostsController: HomeHeaderDelegate {
    func changeSort() {
        generatorImpactOccured()

        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: getCurrentInterfaceForAlerts())
        alertController.addAction(UIAlertAction(title: "Hot", style: .default, handler: { _ in
            self.sort = SortOptions.hot
            self.posts = []
            self.after = ""
            self.topOption = nil
            DispatchQueue.main.async {
                self.activityIndicatorView.startAnimating()
            }
            self.searchPosts()
        }))
        alertController.addAction(UIAlertAction(title: "New", style: .default, handler: { _ in
            self.sort = SortOptions.new
            self.posts = []
            self.after = ""
            self.topOption = nil
            DispatchQueue.main.async {
                self.activityIndicatorView.startAnimating()
            }
            self.searchPosts()
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
                    self.after = ""
                    self.topOption = topOption
                    DispatchQueue.main.async {
                        self.activityIndicatorView.startAnimating()
                    }
                    self.searchPosts()
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
