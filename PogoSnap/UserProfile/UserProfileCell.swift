//
//  UserProfileCell.swift
//  PogoSnap
//
//  Created by Brandon Nguyen on 11/26/20.
//

import UIKit

protocol ProfileImageDelegate: class {
    func didTapImageGallery(post: Post, index: Int)
}

class UserProfileCell: UICollectionViewCell {
    
    var post: Post? {
        didSet {
            if let post = post {
                if !post.imageSources.isEmpty {
                    photoImageView.loadImage(urlString: post.imageSources[0].url)
                }
            }
        }
    }
    weak var delegate: ProfileImageDelegate?
    var index: Int?
    
    lazy var photoImageView: CustomImageView = {
        let imageView = CustomImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        
        imageView.isUserInteractionEnabled = true
        let guestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleImage))
        imageView.addGestureRecognizer(guestureRecognizer)
        
        return imageView
    }()
    
    @objc private func handleImage() {
        guard let post = post, let index = index else {return}
        delegate?.didTapImageGallery(post: post, index: index)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        addSubview(photoImageView)
        photoImageView.translatesAutoresizingMaskIntoConstraints = false
        photoImageView.heightAnchor.constraint(equalTo: heightAnchor).isActive = true
        photoImageView.widthAnchor.constraint(equalTo: widthAnchor).isActive = true
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
