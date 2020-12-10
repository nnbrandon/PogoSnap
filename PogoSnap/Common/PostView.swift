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
    func didTapVote(post: Post, direction: Int, index: Int, authenticated: Bool, archived: Bool)
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
                
                if let postLiked = post.liked {
                    if postLiked {
                        liked = true
                    } else {
                        liked = false
                    }
                } else {
                    liked = nil
                }
            }
        }
    }
    var delegate: PostViewDelegate?
    var index: Int?
    var liked: Bool? {
        didSet {
            if liked == nil {
                upvoteButton.tintColor = RedditConstants.controlsColor
                downvoteButton.tintColor = RedditConstants.controlsColor
            } else if let liked = liked {
                if liked {
                    upvoteButton.tintColor = UIColor.red
                    downvoteButton.tintColor = RedditConstants.controlsColor
                } else {
                    upvoteButton.tintColor = RedditConstants.controlsColor
                    downvoteButton.tintColor = UIColor.red
                }
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
        button.setTitleColor(.gray, for: .normal)
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
    
    lazy var upvoteButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(named: "upvte")?.withRenderingMode(.alwaysTemplate), for: .normal)
        button.tintColor = RedditConstants.controlsColor
        button.addTarget(self, action: #selector(handleUpvote), for: .touchUpInside)
        button.contentEdgeInsets = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        return button
    }()
    
    lazy var downvoteButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(named: "downvte")?.withRenderingMode(.alwaysTemplate), for: .normal)
        button.tintColor = RedditConstants.controlsColor
        button.addTarget(self, action: #selector(handleDownvote), for: .touchUpInside)
        button.contentEdgeInsets = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        return button
    }()
    
    let likeLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.boldSystemFont(ofSize: 12)
        return label
    }()
    
    lazy var commentLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.boldSystemFont(ofSize: 12)
        return label
    }()
    
    lazy var commentButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(named: "comment")?.withRenderingMode(.alwaysTemplate), for: .normal)
        button.tintColor = .gray
        button.addTarget(self, action: #selector(handleComment), for: .touchUpInside)
        return button
    }()
    
    lazy var commentView: UIView = {
       let view = UIView()
       view.isUserInteractionEnabled = true
       view.isUserInteractionEnabled = true
       let guestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleComment))
       view.addGestureRecognizer(guestureRecognizer)
       return view
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
    
    @objc func handleUpvote() {
        guard let post = post, let index = index else {return}
        generatorImpactOccured()
        let authenticated = RedditClient.sharedInstance.isUserAuthenticated()
        var direction = 0
        if liked == nil {
            direction = 1
        } else if let liked = liked {
            direction = liked ? 0 : 1
        }
        if authenticated && !post.archived {
            if direction == 1 {
                liked = true
            } else {
                liked = nil
            }
        }
        delegate?.didTapVote(post: post, direction: direction, index: index, authenticated: authenticated, archived: post.archived)
    }
    
    @objc func handleDownvote() {
        guard let post = post, let index = index else {return}
        generatorImpactOccured()
        let authenticated = RedditClient.sharedInstance.isUserAuthenticated()
        var direction = 0
        if liked == nil {
            direction = -1
        } else if let liked = liked {
            direction = liked ? -1 : 0
        }
        if authenticated && !post.archived {
            if direction == -1 {
                liked = false
            } else {
                liked = nil
            }
        }
        delegate?.didTapVote(post: post, direction: direction, index: index, authenticated: authenticated, archived: post.archived)
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
                
        let voteView = UIView()
        addSubview(voteView)
        voteView.translatesAutoresizingMaskIntoConstraints = false
        voteView.heightAnchor.constraint(equalToConstant: 50).isActive = true
        voteView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 72).isActive = true
        voteView.topAnchor.constraint(equalTo: photoImageSlideshow.bottomAnchor).isActive = true
        voteView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        voteView.addSubview(upvoteButton)
        voteView.addSubview(likeLabel)
        voteView.addSubview(downvoteButton)
        
        upvoteButton.translatesAutoresizingMaskIntoConstraints = false
        upvoteButton.topAnchor.constraint(equalTo: voteView.topAnchor).isActive = true
        upvoteButton.leadingAnchor.constraint(equalTo: voteView.leadingAnchor).isActive = true
        upvoteButton.bottomAnchor.constraint(equalTo: voteView.bottomAnchor).isActive = true
        
        likeLabel.translatesAutoresizingMaskIntoConstraints = false
        likeLabel.leadingAnchor.constraint(equalTo: upvoteButton.trailingAnchor, constant: 16).isActive = true
        likeLabel.topAnchor.constraint(equalTo: voteView.topAnchor).isActive = true
        likeLabel.bottomAnchor.constraint(equalTo: voteView.bottomAnchor).isActive = true
        
        downvoteButton.translatesAutoresizingMaskIntoConstraints = false
        downvoteButton.leadingAnchor.constraint(equalTo: likeLabel.trailingAnchor, constant: 16).isActive = true
        downvoteButton.topAnchor.constraint(equalTo: voteView.topAnchor).isActive = true
        downvoteButton.bottomAnchor.constraint(equalTo: voteView.bottomAnchor).isActive = true
        downvoteButton.trailingAnchor.constraint(equalTo: voteView.trailingAnchor).isActive = true
        
        addSubview(commentView)
        commentView.translatesAutoresizingMaskIntoConstraints = false
        commentView.heightAnchor.constraint(equalToConstant: 50).isActive = true
        commentView.topAnchor.constraint(equalTo: photoImageSlideshow.bottomAnchor).isActive = true
        commentView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -72).isActive = true
        commentView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        commentView.addSubview(commentButton)
        commentView.addSubview(commentLabel)
        
        commentButton.translatesAutoresizingMaskIntoConstraints = false
        commentButton.leadingAnchor.constraint(equalTo: commentView.leadingAnchor).isActive = true
        commentButton.topAnchor.constraint(equalTo: commentView.topAnchor).isActive = true
        commentButton.bottomAnchor.constraint(equalTo: commentView.bottomAnchor).isActive = true
        
        commentLabel.translatesAutoresizingMaskIntoConstraints = false
        commentLabel.leadingAnchor.constraint(equalTo: commentButton.trailingAnchor, constant: 16).isActive = true
        commentLabel.trailingAnchor.constraint(equalTo: commentView.trailingAnchor).isActive = true
        commentLabel.topAnchor.constraint(equalTo: commentView.topAnchor).isActive = true
        commentLabel.bottomAnchor.constraint(equalTo: commentView.bottomAnchor).isActive = true
        
        addSubview(dots)
        dots.translatesAutoresizingMaskIntoConstraints = false
        dots.bottomAnchor.constraint(equalTo: photoImageSlideshow.bottomAnchor, constant: -8).isActive = true
        dots.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
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
