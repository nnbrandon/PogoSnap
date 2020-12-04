//
//  RedditCommentCell.swift
//  PogoSnap
//
//  Created by Brandon Nguyen on 11/24/20.
//

import UIKit

struct RedditConstants {
    static let sepColor = #colorLiteral(red: 0.9686660171, green: 0.9768124223, blue: 0.9722633958, alpha: 1)
    static let backgroundColor = #colorLiteral(red: 0.9961144328, green: 1, blue: 0.9999337792, alpha: 1)
    static let commentMarginColor = RedditConstants.backgroundColor
    static let rootCommentMarginColor = #colorLiteral(red: 0.9332661033, green: 0.9416968226, blue: 0.9327681065, alpha: 1)
    static let identationColor = #colorLiteral(red: 0.929128468, green: 0.9298127294, blue: 0.9208832383, alpha: 1)
    static let metadataFont = UIFont.boldSystemFont(ofSize: 14)
    static let metadataColor = UIColor.black
    static let textFont = UIFont.systemFont(ofSize: 14, weight: .regular)
    static let textColor = UIColor.black
}

class RedditCommentCell: CommentCell {
    
    private var content:RedditCommentView {
        get {
            return commentViewContent as! RedditCommentView
        }
    }
    
    open var commentContent: String! {
        get {
            return content.commentContent
        } set(value) {
            content.commentContent = value
        }
    }
    
    open var author: String! {
        get {
            return content.author
        } set(value) {
            content.author = value
        }
    }
    
    open var imageSources: [ImageSource]? {
        get {
            return content.imageSources
        } set(value) {
            content.imageSources = value
        }
    }
    
    open var isFolded: Bool {
        get {
            return content.isFolded
        } set(value) {
            content.isFolded = value
        }
    }
    
    open var isAuthorPost: Bool {
        get {
            return content.isAuthorPost
        } set(value) {
            content.isAuthorPost = value
        }
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        commentViewContent = RedditCommentView()
        backgroundColor = RedditConstants.backgroundColor
        commentMarginColor = RedditConstants.commentMarginColor
        rootCommentMargin = 8
        rootCommentMarginColor = RedditConstants.rootCommentMarginColor
        indentationIndicatorColor = RedditConstants.identationColor
        commentMargin = 0
        isIndentationIndicatorsExtended = true
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}

protocol RedditCommentViewDelegate {
    func didTapUsername(username: String)
}

class RedditCommentView: UIView, UIScrollViewDelegate {
    
    var commentContent: String = "" {
        didSet {
            contentLabel.text = commentContent
        }
    }
    
    var author: String = "" {
        didSet {
            usernameLabel.text = "\(author)"
        }
    }

    var isFolded: Bool = false {
        didSet {
            if isFolded {
                fold()
            } else {
                unfold()
            }
        }
    }
    
    var isAuthorPost: Bool = false {
        didSet {
            if !isAuthorPost {
                photoImageSlideshow.removeFromSuperview()
                dots.removeFromSuperview()
            } else {
                controlView.removeFromSuperview()
                contentLabel.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
            }
        }
    }
    
    var imageSources: [ImageSource]? {
        didSet {
            if let imageSources = imageSources {
                if imageSources.count == 1 {
                    dots.isHidden = true
                }
                photoImageSlideshow.imageSources = imageSources
            }
        }
    }

    let controlView = UIView()
    
    let contentLabel: UILabel = {
        let lbl = UILabel()
        lbl.textColor = RedditConstants.textColor
        lbl.lineBreakMode = .byWordWrapping
        lbl.font = RedditConstants.textFont
        lbl.numberOfLines = 0
        lbl.textAlignment = .left
        return lbl
    }()
    
    let usernameLabel: UILabel = {
        let lbl = UILabel()
        lbl.textColor = RedditConstants.metadataColor
        lbl.font = RedditConstants.metadataFont
        lbl.textAlignment = .left
//        lbl.isUserInteractionEnabled = true
//        let guestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleUsername))
//        lbl.addGestureRecognizer(guestureRecognizer)
        return lbl
    }()
    
    lazy var photoImageSlideshow: ImageSlideshow = {
        let slideShow = ImageSlideshow(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.width))
        slideShow.isUserInteractionEnabled = true
        //        let guestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleImage))
        //        slideShow.addGestureRecognizer(guestureRecognizer)
        return slideShow
    }()
    
    let dots: UIPageControl = {
        let pageControl = UIPageControl()
        pageControl.currentPage = 0
        pageControl.pageIndicatorTintColor = .lightGray
        pageControl.currentPageIndicatorTintColor = .darkGray
        pageControl.tintColor = .lightGray
        return pageControl
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setLayout()
    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func fold() {
        contentHeightConstraint?.isActive = true
        controlBarHeightConstraint?.isActive = true
        controlView.isHidden = true
    }
    private func unfold() {
        contentHeightConstraint?.isActive = false
        controlBarHeightConstraint?.isActive = false
        controlView.isHidden = false
    }
    private var contentHeightConstraint: NSLayoutConstraint?
    private var controlBarHeightConstraint: NSLayoutConstraint?
    
    
    private func setLayout() {
        
        addSubview(usernameLabel)
        usernameLabel.translatesAutoresizingMaskIntoConstraints = false
        usernameLabel.topAnchor.constraint(equalTo: topAnchor, constant: 10).isActive = true
        usernameLabel.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 10).isActive = true
        
        addSubview(contentLabel)
        contentLabel.translatesAutoresizingMaskIntoConstraints = false
        contentLabel.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 10).isActive = true
        contentLabel.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -10).isActive = true
        contentLabel.topAnchor.constraint(equalTo: usernameLabel.bottomAnchor, constant: 3).isActive = true
        contentHeightConstraint = contentLabel.heightAnchor.constraint(equalToConstant: 0)
        
        addSubview(photoImageSlideshow)
        photoImageSlideshow.translatesAutoresizingMaskIntoConstraints = false
        photoImageSlideshow.topAnchor.constraint(equalTo: contentLabel.bottomAnchor, constant: 3).isActive = true
        photoImageSlideshow.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        photoImageSlideshow.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        photoImageSlideshow.heightAnchor.constraint(equalTo: widthAnchor, multiplier: 1).isActive = true
        photoImageSlideshow.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -5).isActive = true
        
//        addSubview(dots)
//        dots.translatesAutoresizingMaskIntoConstraints = false
//        dots.topAnchor.constraint(equalTo: photoImageSlideshow.bottomAnchor).isActive = true
//        dots.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
//        dots.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -5).isActive = true
//        dots.heightAnchor.constraint(equalToConstant: 50).isActive = true
        
        setupControlView()
        
        addSubview(controlView)
        controlView.translatesAutoresizingMaskIntoConstraints = false
        controlView.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -10).isActive = true
        controlView.topAnchor.constraint(equalTo: contentLabel.bottomAnchor, constant: 5).isActive = true
        controlView.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -10).isActive = true
        controlBarHeightConstraint = controlView.heightAnchor.constraint(equalToConstant: 0)
    }
    

    private func setupControlView() {
        let topSeparatorView = UIView()
        topSeparatorView.backgroundColor = RedditConstants.sepColor
        let bottomSeparatorView = UIView()
        bottomSeparatorView.backgroundColor = RedditConstants.sepColor
        
        controlView.addSubview(topSeparatorView)
        controlView.addSubview(bottomSeparatorView)
        
        topSeparatorView.translatesAutoresizingMaskIntoConstraints = false
        bottomSeparatorView.translatesAutoresizingMaskIntoConstraints = false
        
        topSeparatorView.bottomAnchor.constraint(equalTo: controlView.bottomAnchor).isActive = true
        topSeparatorView.topAnchor.constraint(equalTo: controlView.topAnchor).isActive = true
        topSeparatorView.widthAnchor.constraint(equalToConstant: 2/UIScreen.main.scale).isActive = true
        topSeparatorView.trailingAnchor.constraint(equalTo: controlView.leadingAnchor, constant: -10).isActive = true
        
        bottomSeparatorView.bottomAnchor.constraint(equalTo: controlView.bottomAnchor).isActive = true
        bottomSeparatorView.topAnchor.constraint(equalTo: controlView.topAnchor).isActive = true
        bottomSeparatorView.widthAnchor.constraint(equalToConstant: 2/UIScreen.main.scale).isActive = true
        bottomSeparatorView.trailingAnchor.constraint(equalTo: controlView.leadingAnchor, constant: -10).isActive = true
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let pageNumber = round(photoImageSlideshow.contentOffset.x / photoImageSlideshow.frame.size.width)
        dots.currentPage = Int(pageNumber)
    }
}
