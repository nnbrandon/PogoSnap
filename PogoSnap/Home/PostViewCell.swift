//
//  HomePostCell.swift
//  PogoSnap
//
//  Created by Brandon Nguyen on 11/17/20.
//

import UIKit
import IGListKit

class PostViewCell: UICollectionViewCell, ListBindable {

    let postView = PostView()
    weak var postViewDelegate: PostViewDelegate?
    
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
    
    override func prepareForReuse() {
        postView.resetView()
    }
    
    func bindViewModel(_ viewModel: Any) {
        guard let viewModel = viewModel as? PostViewModel else {return}
        postView.postViewModel = viewModel
        postView.postViewDelegate = postViewDelegate
    }
}
