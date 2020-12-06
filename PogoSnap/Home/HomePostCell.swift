//
//  HomePostCell.swift
//  PogoSnap
//
//  Created by Brandon Nguyen on 11/17/20.
//

import UIKit

class HomePostCell: UICollectionViewCell {
    let postView = PostView()
    var post: Post? {
        didSet {
            if let post = post {
                postView.post = post
            }
        }
    }
        
    var delegate: PostViewDelegate? {
        didSet {
            if let delegate = delegate {
                postView.delegate = delegate
            }
        }
    }
    var index: Int? {
        didSet {
            if let index = index {
                postView.index = index
            }
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(postView)
        postView.translatesAutoresizingMaskIntoConstraints = false
        postView.topAnchor.constraint(equalTo: topAnchor).isActive = true
        postView.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        postView.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        postView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
