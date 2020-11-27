//
//  HomePostCell.swift
//  PogoSnap
//
//  Created by Brandon Nguyen on 11/17/20.
//

import UIKit

protocol HomePostCellDelegate {
    func didTapComment(post: Post)
    func didTapUsername(username: String)
}

class HomePostCell: UICollectionViewCell {
    
    var delegate: HomePostCellDelegate?
        
    var post: Post? {
        didSet {
            if let post = post {
                if !post.imageUrl.isEmpty {
                    photoImageView.loadImage(urlString: post.imageUrl)
                }
                
                usernameLabel.text = "u/" + post.author
                
                let titleText = NSMutableAttributedString(string: post.author + " ", attributes: [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 14)])
                titleText.append(NSAttributedString(string: post.title, attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 14)]))
                titleLabel.attributedText = titleText
                
                likeLabel.text = String(post.score)
                
                commentLabel.text = String(post.numComments)
            }
        }
    }
    
    let photoImageView: CustomImageView = {
        let imageView = CustomImageView()
//        imageView.contentMode = .scaleAspectFit
        // make it so that when you click, you get full image
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        return imageView
    }()
    
    lazy var usernameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.boldSystemFont(ofSize: 14)
        label.isUserInteractionEnabled = true
        let guestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleUsername))
        label.addGestureRecognizer(guestureRecognizer)
        return label
    }()
    
    let likeButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(named: "like_unselected")?.withRenderingMode(.alwaysOriginal), for: .normal)
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
        label.isUserInteractionEnabled = true
        let guestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleUsername))
        label.addGestureRecognizer(guestureRecognizer)
        return label
    }()
    
    @objc fileprivate func handleComment() {
        guard let post = post else {return}
        delegate?.didTapComment(post: post)
    }
    
    @objc fileprivate func handleUsername() {
        guard let post = post else {return}
        delegate?.didTapUsername(username: post.author)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        addSubview(usernameLabel)
        usernameLabel.translatesAutoresizingMaskIntoConstraints = false
        usernameLabel.topAnchor.constraint(equalTo: topAnchor, constant: 8).isActive = true
        usernameLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8).isActive = true
        
        addSubview(photoImageView)
        photoImageView.translatesAutoresizingMaskIntoConstraints = false
        photoImageView.topAnchor.constraint(equalTo: usernameLabel.bottomAnchor, constant: 8).isActive = true
        photoImageView.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        photoImageView.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        photoImageView.heightAnchor.constraint(equalTo: widthAnchor, multiplier: 1).isActive = true
        
        setupButtons()
        
        addSubview(titleLabel)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.topAnchor.constraint(equalTo: likeButton.bottomAnchor).isActive = true
        titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8).isActive = true
        titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8).isActive = true
        titleLabel.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
    }
    
    fileprivate func setupButtons() {
        let stackView = UIStackView(arrangedSubviews: [likeButton, likeLabel, commentButton, commentLabel])
        stackView.distribution = .fillEqually
        addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.topAnchor.constraint(equalTo: photoImageView.bottomAnchor).isActive = true
        stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8).isActive = true
        stackView.widthAnchor.constraint(equalToConstant: 120).isActive = true
        stackView.heightAnchor.constraint(equalToConstant: 50).isActive = true
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
