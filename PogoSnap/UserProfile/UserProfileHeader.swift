//
//  UserProfileHeader.swift
//  PogoSnap
//
//  Created by Brandon Nguyen on 11/15/20.
//

import UIKit

class UserProfileHeader: UICollectionViewCell {
    
    var username: String? {
        didSet {
            if let username = username {
                usernameLabel.text = username
            }
        }
    }
//    var icon_img: String? {
//        didSet {
//            if let icon_img = icon_img {
//                profileImageView.loadImage(urlString: icon_img)
//            }
//        }
//    }

    let profileImageView: CustomImageView = {
       let imageView = CustomImageView()
        imageView.image = UIImage(named: "PikachuReddit")
        return imageView
    }()
    
    let gridButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(named: "grid"), for: .normal)
        button.tintColor = UIColor(white: 0, alpha: 0.2)
        return button
    }()
    
    let listButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(named: "list"), for: .normal)
        button.tintColor = UIColor(white: 0, alpha: 0.2)
        return button
    }()
    
    let bookmarkButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(named: "ribbon"), for: .normal)
        button.tintColor = UIColor(white: 0, alpha: 0.2)
        return button
    }()

    
    let usernameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.boldSystemFont(ofSize: 14)
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
            
        addSubview(profileImageView)
        profileImageView.translatesAutoresizingMaskIntoConstraints = false
        profileImageView.topAnchor.constraint(equalTo: topAnchor, constant: 12).isActive = true
        profileImageView.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        profileImageView.heightAnchor.constraint(equalToConstant: 80).isActive = true
        profileImageView.widthAnchor.constraint(equalToConstant: 80).isActive = true
        profileImageView.layer.cornerRadius = 80 / 2
        profileImageView.clipsToBounds = true
        
        setupBottomToolBar()
        
        addSubview(usernameLabel)
        usernameLabel.translatesAutoresizingMaskIntoConstraints = false
        usernameLabel.topAnchor.constraint(equalTo: profileImageView.bottomAnchor, constant: 4).isActive = true
        usernameLabel.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        usernameLabel.bottomAnchor.constraint(equalTo: gridButton.topAnchor).isActive = true
    }
    
    fileprivate func setupBottomToolBar() {
        //        let stackView = UIStackView(arrangedSubviews: [gridButton, listButton])
        let stackView = UIStackView(arrangedSubviews: [gridButton])
        addSubview(stackView)
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        stackView.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        stackView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        stackView.heightAnchor.constraint(equalToConstant: 50).isActive = true
        
        let topDividerView = UIView()
        topDividerView.backgroundColor = UIColor.lightGray
        addSubview(topDividerView)
        topDividerView.translatesAutoresizingMaskIntoConstraints = false
        topDividerView.topAnchor.constraint(equalTo: stackView.topAnchor).isActive = true
        topDividerView.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        topDividerView.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        topDividerView.heightAnchor.constraint(equalToConstant: 0.5).isActive = true
        
        let bottomDividerView = UIView()
        bottomDividerView.backgroundColor = UIColor.lightGray
        addSubview(bottomDividerView)
        bottomDividerView.translatesAutoresizingMaskIntoConstraints = false
        bottomDividerView.topAnchor.constraint(equalTo: stackView.bottomAnchor).isActive = true
        bottomDividerView.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        bottomDividerView.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        bottomDividerView.heightAnchor.constraint(equalToConstant: 0.5).isActive = true
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
