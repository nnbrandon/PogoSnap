//
//  PostView.swift
//  PogoSnap
//
//  Created by Brandon Nguyen on 12/3/20.
//

import UIKit

class PostControlView: UIView {
    
    var postViewModel: PostViewModel! {
        didSet {
            postView.postViewModel = postViewModel
        }
    }
    var controlViewModel: ControlViewModel! {
        didSet {
            controlViewModel.fromPostControlView = true
            controlView.controlViewModel = controlViewModel
        }
    }
    weak var postViewDelegate: PostViewDelegate? {
        didSet {
            postView.postViewDelegate = postViewDelegate
        }
    }
    weak var controlViewDelegate: ControlViewDelegate? {
        didSet {
            controlView.controlViewDelegate = controlViewDelegate
        }
    }
    weak var basePostDelegate: BasePostsDelegate? {
        didSet {
            postView.basePostsDelegate = basePostDelegate
        }
    }
    
    let postView = PostView()
    let controlView = ControlView()

    override init(frame: CGRect) {
        super.init(frame: frame)

        addSubview(postView)
        postView.translatesAutoresizingMaskIntoConstraints = false
        postView.topAnchor.constraint(equalTo: topAnchor).isActive = true
        postView.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        postView.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true

        addSubview(controlView)
        controlView.translatesAutoresizingMaskIntoConstraints = false
        controlView.heightAnchor.constraint(equalToConstant: 50).isActive = true
        controlView.topAnchor.constraint(equalTo: postView.bottomAnchor).isActive = true
        controlView.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        controlView.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        controlView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
