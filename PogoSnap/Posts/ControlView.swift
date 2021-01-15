//
//  ControlView.swift
//  PogoSnap
//
//  Created by Brandon Nguyen on 1/14/21.
//

import UIKit

class ControlView: UIView {
    
    var commentFlag = false
    var addCommentFunc: (() -> Void)?
    
    var likeCount: String = "0" {
        didSet {
            likeLabel.text = likeCount
        }
    }
    var commentCount: String = "" {
        didSet {
            commentLabel.text = commentCount
        }
    }
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
    
    let voteView = UIView()
    
    lazy var commentView: UIView = {
       let view = UIView()
       view.isUserInteractionEnabled = true
       view.isUserInteractionEnabled = true
       let guestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleComment))
       view.addGestureRecognizer(guestureRecognizer)
       return view
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
    
    @objc private func handleComment() {
        if !commentFlag {
//            delegate?.didTapComment(postViewModel: postViewModel)
        } else {
            addCommentFunc?()
        }
    }
    
    @objc func handleUpvote() {
        generatorImpactOccured()
        var direction = 0
        if liked == nil {
            direction = 1
        } else if let liked = liked {
            direction = liked ? 0 : 1
        }
//        if postViewModel.isUserAuthenticated && !postViewModel.postArchived {
//            if direction == 1 {
//                liked = true
//            } else {
//                liked = nil
//            }
//        }
//        delegate?.didTapVote(postViewModel: postViewModel, direction: direction, authenticated: authenticated, archived: postViewModel.archived)
//        postViewModel.votePost(direction: direction)
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
//        if postViewModel.isUserAuthenticated && !postViewModel.postArchived {
//            if direction == -1 {
//                liked = false
//            } else {
//                liked = nil
//            }
//        }
//        delegate?.didTapVote(postViewModel: postViewModel, direction: direction, authenticated: authenticated, archived: postViewModel.archived)
//        postViewModel.votePost(direction: direction)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)

        addSubview(voteView)
        voteView.translatesAutoresizingMaskIntoConstraints = false
        voteView.topAnchor.constraint(equalTo: topAnchor).isActive = true
        voteView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 72).isActive = true
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
        commentView.topAnchor.constraint(equalTo: topAnchor).isActive = true
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
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
