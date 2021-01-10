//
//  SearchPostsController.swift
//  PogoSnap
//
//  Created by Brandon Nguyen on 1/9/21.
//

import UIKit

class SearchPostsController: PostCollectionController {

    var searchText = ""
    var after: String? = ""

    let cellId = "cellId"
    let footerId = "footerId"

    let activityIndicatorView: UIActivityIndicatorView = {
        let activityView = UIActivityIndicatorView()
        return activityView
    }()
    let footerView = UIActivityIndicatorView()

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
        pinCollectionView(to: view)

        collectionView.delegate = self
        collectionView.dataSource = self

        collectionView.register(UserProfileCell.self, forCellWithReuseIdentifier: cellId)
        collectionView.register(CollectionViewFooterView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter, withReuseIdentifier: footerId)
        (collectionView.collectionViewLayout as? UICollectionViewFlowLayout)?.footerReferenceSize = CGSize(width: collectionView.bounds.width, height: 50)

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
            RedditClient.sharedInstance.searchPosts(query: searchText, after: after) { result in
                switch result {
                case .success(let posts, let nextAfter):
                    DispatchQueue.main.async {
                        self.activityIndicatorView.stopAnimating()
                    }
                    var nextPosts = self.posts
                    for post in posts {
                        if !nextPosts.contains(post) {
                            nextPosts.append(post)
                        }
                    }
                    if self.posts != nextPosts {
                        self.posts = nextPosts
                    }
                    self.after = nextAfter
                case .error:
                    DispatchQueue.main.async {
                        showErrorToast(controller: self, message: "Failed to retrieve user's posts", seconds: 1.0)
                        self.activityIndicatorView.stopAnimating()
                    }
                }
            }
        } else {
            activityIndicatorView.stopAnimating()
        }
    }
}

extension SearchPostsController: UICollectionViewDelegateFlowLayout, UICollectionViewDataSource {

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return getSpacingForCells()
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return getSpacingForCells()
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = (view.frame.width - 2) / 3
        return CGSize(width: width, height: width)
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return posts.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellId, for: indexPath) as? UserProfileCell else {
            return UICollectionViewCell()
        }
        
        cell.photoImageView.image = UIImage()
        let post = posts[indexPath.row]
        cell.post = post
        cell.index = indexPath.row
        cell.delegate = self
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if indexPath.row == posts.count - 3 {
            searchPosts()
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        if kind == UICollectionView.elementKindSectionFooter {
            let footer = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: footerId, for: indexPath)
            footer.addSubview(footerView)
            footerView.frame = CGRect(x: 0, y: 0, width: collectionView.bounds.width, height: 50)
            return footer
        }
        return UICollectionReusableView()
    }
}
