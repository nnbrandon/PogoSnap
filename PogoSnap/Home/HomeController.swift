//
//  HomeController.swift
//  PogoSnap
//
//  Created by Brandon Nguyen on 11/17/20.
//

import UIKit

class HomeController: UICollectionViewController, UICollectionViewDelegateFlowLayout, HomePostCellDelegate {

    var posts = [Post]() {
        didSet {
            DispatchQueue.main.async {
                self.collectionView.reloadData()
            }
        }
    }
    var after = ""
    
    let cellId = "cellId"
    

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "PogoSnap"
        collectionView.backgroundColor = .white
        collectionView.register(HomePostCell.self, forCellWithReuseIdentifier: cellId)

        fetchPosts()
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        var height: CGFloat = 16 // title label
        height += view.frame.width
        height += 50
        height += 60
        return CGSize(width: view.frame.width, height: height)
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return posts.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellId, for: indexPath) as! HomePostCell
        cell.photoImageView.image = UIImage()
        cell.post = posts[indexPath.row]
        cell.delegate = self
        
        return cell
    }
    
    override func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if indexPath.row == posts.count - 5 {
            fetchPosts()
        }
    }
    
    func didTapComment(post: Post) {
        let redditCommentsController = RedditCommentsController()
        redditCommentsController.hidesBottomBarWhenPushed = true
        redditCommentsController.commentsLink = post.commentsLink
        navigationController?.pushViewController(redditCommentsController, animated: true)
        print(post)
    }
    
    fileprivate func fetchPosts() {
        let redditUrl = "https://www.reddit.com/r/Pokemongosnap/new.json?sort=new&after=" + after
        RedditClient.fetchPosts(url: redditUrl, after: after) { posts, nextAfter in
            self.posts.append(contentsOf: posts)
            if let nextAfter = nextAfter {
                self.after = nextAfter
            }
        }
    }
}
