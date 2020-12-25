//
//  RedditCommentCell.swift
//  PogoSnap
//
//  Created by Brandon Nguyen on 11/24/20.
//

import UIKit

protocol CommentDelegate: class {
    func didTapUsername(username: String)
    func didTapReply(parentCommentId: String, parentCommentContent: String, parentCommentAuthor: String, parentDepth: Int)
    func didTapOptions(commentId: String, author: String)
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
    
    var created: TimeInterval? {
        didSet {
            if let created = created {
                content.created = created
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
            backgroundColor = RedditConsts.backgroundColor
            commentMarginColor = RedditConsts.commentMarginColor
            rootCommentMarginColor = RedditConsts.rootCommentMarginColor
            indentationIndicatorColor = RedditConsts.identationColor
        } else {
            backgroundColor = RedditConsts.redditDarkMode
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
    var created: TimeInterval? {
        didSet {
            if let created = created, let userText = usernameLabel.text {
                let date = Date(timeIntervalSince1970: created)
                let userTextWithDate = "\(userText)・\(date.timeAgoSinceDate())"
                usernameLabel.text = userTextWithDate
            }
        }
    }
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
    
    weak var delegate: CommentDelegate?

    let controlView = UIView()
    
    let contentLabel: UILabel = {
        let lbl = UILabel()
        lbl.lineBreakMode = .byWordWrapping
        lbl.font = RedditConsts.textFont
        lbl.numberOfLines = 0
        lbl.textAlignment = .left
        return lbl
    }()
    
    lazy var usernameLabel: UILabel = {
        let lbl = UILabel()
        lbl.font = RedditConsts.metadataFont
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
        if traitCollection.userInterfaceStyle == .light {
            btn.setTitleColor(RedditConsts.lightControlsColor, for: .normal)
            btn.tintColor = RedditConsts.lightControlsColor
        } else {
            btn.setTitleColor(RedditConsts.darkControlsColor, for: .normal)
            btn.tintColor = RedditConsts.darkControlsColor
        }
        btn.setImage(UIImage(named: "exprt")?.withRenderingMode(.alwaysTemplate), for: .normal)
        btn.addTarget(self, action: #selector(handleReply), for: .touchUpInside)
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
            topSeparatorView.backgroundColor = RedditConsts.sepColor
            bottomSeparatorView.backgroundColor = RedditConsts.sepColor
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
