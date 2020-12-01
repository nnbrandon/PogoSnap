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
    func didTapImage(imageSources: [ImageSource], position: Int)
    func didTapOptions(post: Post)
}

class HomePostCell: UICollectionViewCell {
    
    // If user's image width is bigger than the height, do scaleAspectFit, otherwise scaleAspectFill
    
    var delegate: HomePostCellDelegate?

    var post: Post? {
        didSet {
            if let post = post {
                photoImageSlideshow.imageSources = post.imageSources
                usernameLabel.text = "u/" + post.author
                
                let titleText = NSMutableAttributedString(string: post.author + " ", attributes: [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 14)])
                titleText.append(NSAttributedString(string: post.title, attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 14)]))
                titleLabel.attributedText = titleText
                
                likeLabel.text = String(post.score)
                
                commentLabel.text = String(post.numComments)
                
                if post.imageSources.count > 1 {
                    dots.isHidden = false
                    dots.numberOfPages = post.imageSources.count
                } else {
                    dots.isHidden = true
                }
                
                if let liked = post.liked, liked {
                    likeButton.setImage(UIImage(named: "like_selected")?.withRenderingMode(.alwaysOriginal), for: .normal)
                } else {
                    likeButton.setImage(UIImage(named: "like_unselected")?.withRenderingMode(.alwaysOriginal), for: .normal)
                }
            }
        }
    }
        
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
        label.lineBreakMode = .byWordWrapping
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
    
    @objc fileprivate func handleImage() {
        guard let post = post else {return}
        delegate?.didTapImage(imageSources: post.imageSources, position: dots.currentPage)
    }
    
    @objc func handleOptions() {
        guard let post = post else {return}
        delegate?.didTapOptions(post: post)
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
        
        photoImageSlideshow.delegate = self
        addSubview(photoImageSlideshow)
        photoImageSlideshow.translatesAutoresizingMaskIntoConstraints = false
        photoImageSlideshow.topAnchor.constraint(equalTo: usernameStackView.bottomAnchor, constant: 8).isActive = true
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
        
        let dotsStackView = UIStackView(arrangedSubviews: [dots])
        addSubview(dotsStackView)
        dotsStackView.translatesAutoresizingMaskIntoConstraints = false
        dotsStackView.topAnchor.constraint(equalTo: photoImageSlideshow.bottomAnchor).isActive = true
        dotsStackView.leadingAnchor.constraint(equalTo: likeCommentStackView.trailingAnchor).isActive = true
        dotsStackView.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        dotsStackView.heightAnchor.constraint(equalToConstant: 50).isActive = true
        
        addSubview(titleLabel)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.topAnchor.constraint(equalTo: likeCommentStackView.bottomAnchor).isActive = true
        titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8).isActive = true
        titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8).isActive = true
        titleLabel.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension HomePostCell: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let pageNumber = round(photoImageSlideshow.contentOffset.x / photoImageSlideshow.frame.size.width)
        dots.currentPage = Int(pageNumber)
    }
}
