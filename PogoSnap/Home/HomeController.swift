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
        cell.post = posts[indexPath.item]
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
        if let url = URL(string: redditUrl) {
            URLSession.shared.dataTask(with: url) { data, response, error in
                if let data = data {
                    do {
                        var posts = [Post]()

                        let decoded = try JSONDecoder().decode(RedditPostResponse.self, from: data)
                        if let after = decoded.data.after, self.after != after {
                            self.after = after
                        }
                        for child in decoded.data.children {
                            let redditPost = child.data
                            var imageUrl = ""
                            if let preview = redditPost.preview {
                                if preview.images.count != 0 {
                                    let sourceUrl = preview.images[0].source.url
                                    imageUrl = sourceUrl.replacingOccurrences(of: "amp;", with: "")
                                }
                            } else if let mediaData = redditPost.media_metadata {
                                if mediaData.mediaImages.count != 0 {
                                    let sourceUrl = mediaData.mediaImages[0]
                                    imageUrl = sourceUrl.replacingOccurrences(of: "amp;", with: "")
                                }
                            } else {
                                // If it does not contain images at all, do not append
                                continue
                            }
                            let commentsLink = "https://www.reddit.com/r/PokemonGoSnap/comments/" + redditPost.id + ".json"
                            let post = Post(author: redditPost.author, title: redditPost.title, imageUrl: imageUrl, score: redditPost.score, numComments: redditPost.num_comments, commentsLink: commentsLink)
                            posts.append(post)
                        }
                        self.posts.append(contentsOf: posts)
                    } catch {print(error)}
                }
            }.resume()
        }
    }
}
