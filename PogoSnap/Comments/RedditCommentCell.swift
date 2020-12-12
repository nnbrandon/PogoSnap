//
//  RedditCommentCell.swift
//  PogoSnap
//
//  Created by Brandon Nguyen on 11/24/20.
//

import UIKit

protocol CommentDelegate {
    func didTapUsername(username: String)
    func didTapReply(parentCommentId: String, parentCommentContent: String, parentCommentAuthor: String, parentDepth: Int)
    func didTapOptions(commentId: String, author: String)
}

struct RedditConstants {
    static let sepColor = #colorLiteral(red: 0.9686660171, green: 0.9768124223, blue: 0.9722633958, alpha: 1)
    static let darkSepColor = UIColor.darkGray
    static let backgroundColor = #colorLiteral(red: 0.9961144328, green: 1, blue: 0.9999337792, alpha: 1)
    static let commentMarginColor = RedditConstants.backgroundColor
    static let rootCommentMarginColor = #colorLiteral(red: 0.9332661033, green: 0.9416968226, blue: 0.9327681065, alpha: 1)
    static let identationColor = #colorLiteral(red: 0.929128468, green: 0.9298127294, blue: 0.9208832383, alpha: 1)
    static let metadataFont = UIFont.boldSystemFont(ofSize: 14)
    static let textFont = UIFont.systemFont(ofSize: 14, weight: .medium)
    static let controlsColor = #colorLiteral(red: 0.7295756936, green: 0.733242631, blue: 0.7375010848, alpha: 1)
}

class RedditCommentCell: CommentCell {
    
    private var content: RedditCommentView {
        get {
            return commentViewContent!
        }
    }
    
    var commentId: String? {
        didSet {
            if let commentId = commentId {
                content.commentId = commentId
            }
        }
    }
    
    var commentDepth: Int? {
        didSet {
            if let commentDepth = commentDepth {
                content.commentDepth = commentDepth
            }
        }
    }
    
    var delegate: CommentDelegate? {
        didSet {
            if let delegate = delegate {
                content.delegate = delegate
            }
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
    
    open var isFolded: Bool {
        get {
            return content.isFolded
        } set(value) {
            content.isFolded = value
        }
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        commentViewContent = RedditCommentView()
        if traitCollection.userInterfaceStyle == .light {
            backgroundColor = RedditConstants.backgroundColor
            commentMarginColor = RedditConstants.commentMarginColor
            rootCommentMarginColor = RedditConstants.rootCommentMarginColor
            indentationIndicatorColor = RedditConstants.identationColor
        } else {
            commentMarginColor = .darkGray
            rootCommentMarginColor = .black
            indentationIndicatorColor = .darkGray
        }
        rootCommentMargin = 8
        commentMargin = 0
        isIndentationIndicatorsExtended = true
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}

class RedditCommentView: UIView, UIScrollViewDelegate {
    
    var commentId: String?
    var commentDepth: Int?
    var commentContent: String = "" {
        didSet {
            contentLabel.text = commentContent
        }
    }
    
    var author: String = "" {
        didSet {
            usernameLabel.text = "u/\(author)"
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
    
    var delegate: CommentDelegate?

    let controlView = UIView()
    
    let contentLabel: UILabel = {
        let lbl = UILabel()
        lbl.lineBreakMode = .byWordWrapping
        lbl.font = RedditConstants.textFont
        lbl.numberOfLines = 0
        lbl.textAlignment = .left
        return lbl
    }()
    
    lazy var usernameLabel: UILabel = {
        let lbl = UILabel()
        lbl.font = RedditConstants.metadataFont
        lbl.textAlignment = .left
        lbl.textColor = .gray
        
        lbl.isUserInteractionEnabled = true
        let guestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleUsername))
        lbl.addGestureRecognizer(guestureRecognizer)
        
        return lbl
    }()
    
    lazy var optionsButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("●●●", for: .normal)
        button.setTitleColor(.gray, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 5)
        button.addTarget(self, action: #selector(handleOptions), for: .touchUpInside)
        return button
    }()
    
    lazy var replyButton: UIButton = {
        let btn = UIButton()
        btn.setTitle(" Reply", for: .normal)
        btn.titleLabel?.font = UIFont.systemFont(ofSize: 12, weight: .semibold)
        btn.setTitleColor(RedditConstants.controlsColor, for: .normal)
        btn.setImage(UIImage(named: "exprt")?.withRenderingMode(.alwaysTemplate), for: .normal)
        btn.addTarget(self, action: #selector(handleReply), for: .touchUpInside)
        btn.tintColor = RedditConstants.controlsColor
        return btn
    }()
    
    @objc func handleUsername() {
        delegate?.didTapUsername(username: author)
    }
    
    @objc func handleOptions() {
        if let commentId = commentId {
            delegate?.didTapOptions(commentId: commentId, author: author)
        }
    }
    
    @objc func handleReply() {
        if let commentId = commentId, let commentDepth = commentDepth {
            delegate?.didTapReply(parentCommentId: commentId, parentCommentContent: commentContent, parentCommentAuthor: author, parentDepth: commentDepth)
        }
    }
    
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
        usernameLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10).isActive = true
        
        addSubview(contentLabel)
        contentLabel.translatesAutoresizingMaskIntoConstraints = false
        contentLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10).isActive = true
        contentLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10).isActive = true
        contentLabel.topAnchor.constraint(equalTo: usernameLabel.bottomAnchor, constant: 8).isActive = true
        contentHeightConstraint = contentLabel.heightAnchor.constraint(equalToConstant: 0)
        
        setupControlView()
        
        addSubview(controlView)
        controlView.translatesAutoresizingMaskIntoConstraints = false
        controlView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10).isActive = true
        controlView.topAnchor.constraint(equalTo: contentLabel.bottomAnchor, constant: 5).isActive = true
        controlView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -10).isActive = true
        controlBarHeightConstraint = controlView.heightAnchor.constraint(equalToConstant: 0)

        addSubview(optionsButton)
        optionsButton.translatesAutoresizingMaskIntoConstraints = false
        optionsButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8).isActive = true
        optionsButton.bottomAnchor.constraint(equalTo: controlView.bottomAnchor).isActive = true
        optionsButton.topAnchor.constraint(equalTo: controlView.topAnchor).isActive = true
        
        addSubview(replyButton)
        replyButton.translatesAutoresizingMaskIntoConstraints = false
        replyButton.trailingAnchor.constraint(equalTo: optionsButton.leadingAnchor, constant: -8).isActive = true
        replyButton.bottomAnchor.constraint(equalTo: controlView.bottomAnchor).isActive = true
        replyButton.topAnchor.constraint(equalTo: controlView.topAnchor).isActive = true
    }
    

    private func setupControlView() {
        let topSeparatorView = UIView()
        let bottomSeparatorView = UIView()
        if traitCollection.userInterfaceStyle == .light {
            topSeparatorView.backgroundColor = RedditConstants.sepColor
            bottomSeparatorView.backgroundColor = RedditConstants.sepColor
        } else {
//            topSeparatorView.backgroundColor = RedditConstants.darkSepColor
//            bottomSeparatorView.backgroundColor = RedditConstants.darkSepColor
        }
        
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
}
