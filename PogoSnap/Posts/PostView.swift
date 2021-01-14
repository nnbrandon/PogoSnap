//
//  PostView.swift
//  PogoSnap
//
//  Created by Brandon Nguyen on 12/3/20.
//

import UIKit

class PostView: UIView {

    var postViewModel: PostViewModel! {
        didSet {
            photoImageSlideshow.imageSources = postViewModel.imageSources
            headerLabel.text = postViewModel.headerText
            titleLabel.text = postViewModel.titleText
            likeLabel.text = postViewModel.likeCount
            commentLabel.text = postViewModel.commentCount
            
            if postViewModel.aspectFit {
                slideShowBottomConstraint?.isActive = false
                voteTopConstraint?.isActive = true
            }
            
            if postViewModel.hideDots {
                dots.isHidden = true
                dots.numberOfPages = 0
            } else {
                dots.isHidden = false
                dots.numberOfPages = postViewModel.imageSources.count
            }
            
            if let postLiked = postViewModel.liked {
                if postLiked {
                    liked = true
                } else {
                    liked = false
                }
            } else {
                liked = nil
            }

            if let userIconURL = postViewModel.userIconURL {
                usernameIcon.loadImage(urlString: userIconURL)
            }
        }
    }
    var commentFlag = false
    var addCommentFunc: (() -> Void)?
    var liked: Bool? {
        didSet {
            if liked == nil {
                if traitCollection.userInterfaceStyle == .light {
                    upvoteButton.tintColor = RedditConsts.lightControlsColor
                    downvoteButton.tintColor = RedditConsts.lightControlsColor
                } else {
                    upvoteButton.tintColor = RedditConsts.darkControlsColor
                    downvoteButton.tintColor = RedditConsts.darkControlsColor
                }
            } else if let liked = liked {
                if liked {
                    upvoteButton.tintColor = UIColor.red
                    if traitCollection.userInterfaceStyle == .light {
                        downvoteButton.tintColor = RedditConsts.lightControlsColor
                    } else {
                        downvoteButton.tintColor = RedditConsts.darkControlsColor
                    }
                } else {
                    if traitCollection.userInterfaceStyle == .light {
                        upvoteButton.tintColor = RedditConsts.lightControlsColor
                    } else {
                        upvoteButton.tintColor = RedditConsts.darkControlsColor
                    }
                    downvoteButton.tintColor = UIColor.red
                }
            }
        }
    }
        
    let dots: UIPageControl = {
        let pageControl = UIPageControl()
        pageControl.currentPage = 0
        pageControl.pageIndicatorTintColor = .gray
        pageControl.currentPageIndicatorTintColor = .white
        pageControl.tintColor = .white
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
        let slideShow = ImageSlideshow(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.width + UIScreen.main.bounds.width/2))
        slideShow.isUserInteractionEnabled = true
        let guestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleImage))
        slideShow.addGestureRecognizer(guestureRecognizer)
        return slideShow
    }()
    
    lazy var usernameIcon: CustomImageView = {
        let imageView = CustomImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 30 / 2
        
        imageView.isUserInteractionEnabled = true
        let guestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleUsername))
        imageView.addGestureRecognizer(guestureRecognizer)
        return imageView
    }()
    
    lazy var headerLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.boldSystemFont(ofSize: 14)
        if traitCollection.userInterfaceStyle == .light {
            label.textColor = RedditConsts.lightControlsColor
        } else {
            label.textColor = RedditConsts.darkControlsColor
        }

        label.isUserInteractionEnabled = true
        let guestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleUsername))
        label.addGestureRecognizer(guestureRecognizer)
        return label
    }()
    
    let voteView = UIView()
    
    lazy var upvoteButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(named: "upvte")?.withRenderingMode(.alwaysTemplate), for: .normal)
        button.addTarget(self, action: #selector(handleUpvote), for: .touchUpInside)
        button.contentEdgeInsets = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        return button
    }()
    
    lazy var downvoteButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(named: "downvte")?.withRenderingMode(.alwaysTemplate), for: .normal)
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
        if traitCollection.userInterfaceStyle == .light {
            button.tintColor = RedditConsts.lightControlsColor
        } else {
            button.tintColor = RedditConsts.darkControlsColor
        }
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
        
        label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        
        label.isUserInteractionEnabled = true
        let guestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTitle))
        label.addGestureRecognizer(guestureRecognizer)
        return label
    }()
    
    @objc private func handleComment() {
        if !commentFlag {
//            delegate?.didTapComment(postViewModel: postViewModel)
        } else {
            addCommentFunc?()
        }
    }
    
    @objc private func handleTitle() {
        if !commentFlag {
//            delegate?.didTapComment(postViewModel: postViewModel)
        }
    }
    
    @objc private func handleUsername() {
//        delegate?.didTapUsername(username: postViewModel.author, userIconURL: postViewModel.userIconURL)
    }
    
    @objc private func handleImage() {
//        delegate?.didTapImage(imageSources: postViewModel.imageSources, position: dots.currentPage)
        postViewModel.showFullImages(position: dots.currentPage)
    }
    
    @objc func handleOptions() {
        generatorImpactOccured()
//        delegate?.didTapOptions(postViewModel: postViewModel)
        postViewModel.showOptions()
    }
    
    @objc func handleUpvote() {
        generatorImpactOccured()
        var direction = 0
        if liked == nil {
            direction = 1
        } else if let liked = liked {
            direction = liked ? 0 : 1
        }
        if postViewModel.isUserAuthenticated && !postViewModel.postArchived {
            if direction == 1 {
                liked = true
            } else {
                liked = nil
            }
        }
//        delegate?.didTapVote(postViewModel: postViewModel, direction: direction, authenticated: authenticated, archived: postViewModel.archived)
        postViewModel.votePost(direction: direction)
    }
    
    @objc func handleDownvote() {
        generatorImpactOccured()
//        let authenticated = RedditClient.sharedInstance.isUserAuthenticated()
        var direction = 0
        if liked == nil {
            direction = -1
        } else if let liked = liked {
            direction = liked ? -1 : 0
        }
        if postViewModel.isUserAuthenticated && !postViewModel.postArchived {
            if direction == -1 {
                liked = false
            } else {
                liked = nil
            }
        }
//        delegate?.didTapVote(postViewModel: postViewModel, direction: direction, authenticated: authenticated, archived: postViewModel.archived)
        postViewModel.votePost(direction: direction)
    }
    
    private var slideShowBottomConstraint: NSLayoutConstraint?
    private var voteTopConstraint: NSLayoutConstraint?
    
    public func resetView() {
        for index in 0..<photoImageSlideshow.subviews.count {
            if let imageView = photoImageSlideshow.subviews[index] as? CustomImageView {
                imageView.image = nil
            }
        }
        photoImageSlideshow.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.width + UIScreen.main.bounds.width/2)
        slideShowBottomConstraint?.isActive = true
        voteTopConstraint?.isActive = false
        
        dots.currentPage = 0
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        
        addSubview(usernameIcon)
        usernameIcon.translatesAutoresizingMaskIntoConstraints = false
        usernameIcon.topAnchor.constraint(equalTo: topAnchor).isActive = true
        usernameIcon.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8).isActive = true
        usernameIcon.heightAnchor.constraint(equalToConstant: 30).isActive = true
        usernameIcon.widthAnchor.constraint(equalToConstant: 30).isActive = true

        addSubview(headerLabel)
        headerLabel.translatesAutoresizingMaskIntoConstraints = false
        headerLabel.topAnchor.constraint(equalTo: topAnchor).isActive = true
        headerLabel.leadingAnchor.constraint(equalTo: usernameIcon.trailingAnchor, constant: 8).isActive = true
        headerLabel.heightAnchor.constraint(equalToConstant: 30).isActive = true

        addSubview(optionsButton)
        optionsButton.translatesAutoresizingMaskIntoConstraints = false
        optionsButton.topAnchor.constraint(equalTo: topAnchor).isActive = true
        optionsButton.leadingAnchor.constraint(equalTo: headerLabel.trailingAnchor).isActive = true
        optionsButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8).isActive = true
        optionsButton.heightAnchor.constraint(equalToConstant: 30).isActive = true
        
        addSubview(titleLabel)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.topAnchor.constraint(equalTo: usernameIcon.bottomAnchor, constant: 8).isActive = true
        titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8).isActive = true
        titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8).isActive = true
                
        addSubview(voteView)
        voteView.translatesAutoresizingMaskIntoConstraints = false
        voteView.heightAnchor.constraint(equalToConstant: 50).isActive = true
        voteTopConstraint = voteView.topAnchor.constraint(equalTo: photoImageSlideshow.bottomAnchor)
        voteView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 72).isActive = true
        voteView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        voteView.addSubview(upvoteButton)
        voteView.addSubview(likeLabel)
        voteView.addSubview(downvoteButton)
        
        photoImageSlideshow.delegate = self
        addSubview(photoImageSlideshow)
        photoImageSlideshow.translatesAutoresizingMaskIntoConstraints = false
        photoImageSlideshow.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8).isActive = true
        photoImageSlideshow.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        photoImageSlideshow.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        
        slideShowBottomConstraint = photoImageSlideshow.bottomAnchor.constraint(equalTo: voteView.topAnchor)
        
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
        dots.bottomAnchor.constraint(equalTo: photoImageSlideshow.bottomAnchor, constant: -16).isActive = true
        dots.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        
        if traitCollection.userInterfaceStyle == .light {
            dots.currentPageIndicatorTintColor = .black
        } else {
            dots.currentPageIndicatorTintColor = .white
        }
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
