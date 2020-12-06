//
//  PostView.swift
//  PogoSnap
//
//  Created by Brandon Nguyen on 12/3/20.
//

import UIKit

protocol PostViewDelegate {
    func didTapComment(post: Post, index: Int)
    func didTapUsername(username: String)
    func didTapImage(imageSources: [ImageSource], position: Int)
    func didTapOptions(post: Post)
    func didTapLike(post: Post, direction: Int, index: Int, authenticated: Bool, archived: Bool)
}

class PostView: UIView {

    var post: Post? {
        didSet {
            if let post = post {
                photoImageSlideshow.imageSources = post.imageSources
                usernameLabel.text = "u/" + post.author
                
                let titleText = NSAttributedString(string: post.title, attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 16)])
                titleLabel.attributedText = titleText
                
                likeLabel.text = String(post.score)
                
                commentLabel.text = String(post.numComments)
                
                if post.imageSources.count > 1 {
                    dots.isHidden = false
                    dots.numberOfPages = post.imageSources.count
                } else {
                    dots.isHidden = true
                }
                
                if let postLiked = post.liked, postLiked {
                    liked = true
                } else {
                    liked = false
                }
            }
        }
    }
    var delegate: PostViewDelegate?
    var index: Int?
    var liked = false {
        didSet {
            if liked {
                likeButton.setImage(UIImage(named: "like_selected")?.withRenderingMode(.alwaysOriginal), for: .normal)
            } else {
                likeButton.setImage(UIImage(named: "like_unselected")?.withRenderingMode(.alwaysOriginal), for: .normal)
            }
        }
    }
    var commentFlag = false
        
    let dots: UIPageControl = {
        let pageControl = UIPageControl()
        pageControl.currentPage = 0
        pageControl.pageIndicatorTintColor = .lightGray
        pageControl.currentPageIndicatorTintColor = .darkGray
        pageControl.tintColor = .lightGray
        return pageControl
    }()
    
    lazy var optionsButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("●●●", for: .normal)
        button.setTitleColor(.black, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 5)
        button.addTarget(self, action: #selector(handleOptions), for: .touchUpInside)
        return button
    }()
        
    lazy var photoImageSlideshow: ImageSlideshow = {
        let slideShow = ImageSlideshow(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.width))
        slideShow.isUserInteractionEnabled = true
        let guestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleImage))
        slideShow.addGestureRecognizer(guestureRecognizer)
        return slideShow
    }()
    
    lazy var usernameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.boldSystemFont(ofSize: 14)
        label.isUserInteractionEnabled = true
        let guestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleUsername))
        label.addGestureRecognizer(guestureRecognizer)
        return label
    }()
    
    lazy var likeButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(named: "like_unselected")?.withRenderingMode(.alwaysOriginal), for: .normal)
        button.addTarget(self, action: #selector(handleLike), for: .touchUpInside)
        return button
    }()
    
    let likeLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.boldSystemFont(ofSize: 12)
        return label
    }()
    
    let commentLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.boldSystemFont(ofSize: 12)
        return label
    }()
    
    lazy var commentButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(named: "comment")?.withRenderingMode(.alwaysOriginal), for: .normal)
        button.addTarget(self, action: #selector(handleComment), for: .touchUpInside)
        return button
    }()
    
    lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        return label
    }()
    
    @objc fileprivate func handleComment() {
        guard let post = post, let index = index else {return}
        if !commentFlag {
            delegate?.didTapComment(post: post, index: index)
        }
    }
    
    @objc fileprivate func handleUsername() {
        guard let post = post else {return}
        delegate?.didTapUsername(username: post.author)
    }
    
    @objc fileprivate func handleImage() {
        guard let post = post else {return}
        delegate?.didTapImage(imageSources: post.imageSources, position: dots.currentPage)
    }
    
    @objc func handleOptions() {
        guard let post = post else {return}
        delegate?.didTapOptions(post: post)
    }
    
    @objc func handleLike() {
        guard let post = post, let index = index else {return}
        let authenticated = RedditClient.sharedInstance.isUserAuthenticated()
        let direction = liked ? 0 : 1
        if authenticated && !post.archived {
            liked = !liked
        }
        delegate?.didTapLike(post: post, direction: direction, index: index, authenticated: authenticated, archived: post.archived)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        let usernameStackView = UIStackView(arrangedSubviews: [usernameLabel])
        addSubview(usernameStackView)
        usernameStackView.translatesAutoresizingMaskIntoConstraints = false
        usernameStackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8).isActive = true
        usernameStackView.heightAnchor.constraint(equalToConstant: 50).isActive = true
        
        let optionsStackView = UIStackView(arrangedSubviews: [optionsButton])
        addSubview(optionsStackView)
        optionsStackView.translatesAutoresizingMaskIntoConstraints = false
        optionsStackView.leadingAnchor.constraint(equalTo: usernameStackView.trailingAnchor).isActive = true
        optionsStackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8).isActive = true
        optionsStackView.heightAnchor.constraint(equalToConstant: 50).isActive = true
        
        addSubview(titleLabel)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.topAnchor.constraint(equalTo: usernameStackView.bottomAnchor).isActive = true
        titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8).isActive = true
        titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8).isActive = true
        
        photoImageSlideshow.delegate = self
        addSubview(photoImageSlideshow)
        photoImageSlideshow.translatesAutoresizingMaskIntoConstraints = false
        photoImageSlideshow.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8).isActive = true
        photoImageSlideshow.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        photoImageSlideshow.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        photoImageSlideshow.heightAnchor.constraint(equalTo: widthAnchor, multiplier: 1).isActive = true
                
        let likeCommentStackView = UIStackView(arrangedSubviews: [likeButton, likeLabel, commentButton, commentLabel])
        likeCommentStackView.distribution = .fillEqually
        addSubview(likeCommentStackView)
        likeCommentStackView.translatesAutoresizingMaskIntoConstraints = false
        likeCommentStackView.topAnchor.constraint(equalTo: photoImageSlideshow.bottomAnchor).isActive = true
        likeCommentStackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8).isActive = true
        likeCommentStackView.widthAnchor.constraint(equalToConstant: 120).isActive = true
        likeCommentStackView.heightAnchor.constraint(equalToConstant: 50).isActive = true
        likeCommentStackView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        
        let dotsStackView = UIStackView(arrangedSubviews: [dots])
        addSubview(dotsStackView)
        dotsStackView.translatesAutoresizingMaskIntoConstraints = false
        dotsStackView.topAnchor.constraint(equalTo: photoImageSlideshow.bottomAnchor).isActive = true
        dotsStackView.leadingAnchor.constraint(equalTo: likeCommentStackView.trailingAnchor).isActive = true
        dotsStackView.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        dotsStackView.heightAnchor.constraint(equalToConstant: 50).isActive = true
        dotsStackView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension PostView: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let pageNumber = round(photoImageSlideshow.contentOffset.x / photoImageSlideshow.frame.size.width)
        dots.currentPage = Int(pageNumber)
    }
}
