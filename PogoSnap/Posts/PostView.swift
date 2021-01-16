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
            
            if postViewModel.aspectFit {
                slideShowBottomConstraint?.isActive = false
            }
            
            if postViewModel.hideDots {
                dots.isHidden = true
                dots.numberOfPages = 0
            } else {
                dots.isHidden = false
                dots.numberOfPages = postViewModel.imageSources.count
            }

            if let userIconURL = postViewModel.userIconString {
                usernameIcon.loadImage(urlString: userIconURL)
            }
        }
    }
    weak var postViewDelegate: PostViewDelegate?
    weak var basePostsDelegate: BasePostsDelegate?
        
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
    
    @objc private func handleTitle() {
//        if !commentFlag {
//            delegate?.didTapComment(postViewModel: postViewModel)
//        }
    }
    
    @objc private func handleUsername() {
        postViewDelegate?.didTapUsername(username: postViewModel.author, userIconURL: postViewModel.userIconString)
    }
    
    @objc private func handleImage() {
        postViewDelegate?.didTapImage(imageSources: postViewModel.imageSources, position: dots.currentPage)
    }
    
    @objc func handleOptions() {
        generatorImpactOccured()
        basePostsDelegate?.didTapOptions(index: postViewModel.index)
    }
    
    private var slideShowBottomConstraint: NSLayoutConstraint?
    
    public func resetView() {
        for index in 0..<photoImageSlideshow.subviews.count {
            if let imageView = photoImageSlideshow.subviews[index] as? CustomImageView {
                imageView.image = nil
            }
        }
        photoImageSlideshow.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.width + UIScreen.main.bounds.width/2)
        slideShowBottomConstraint?.isActive = true
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
                
        photoImageSlideshow.delegate = self
        addSubview(photoImageSlideshow)
        photoImageSlideshow.translatesAutoresizingMaskIntoConstraints = false
        photoImageSlideshow.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8).isActive = true
        photoImageSlideshow.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        photoImageSlideshow.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        photoImageSlideshow.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        
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
