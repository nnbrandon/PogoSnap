//
//  RedditCommentsControllers.swift
//  PogoSnap
//
//  Created by Brandon Nguyen on 11/24/20.
//

import UIKit

class RedditCommentsController: CommentsController, CommentDelegate, UITextFieldDelegate {

    var post: Post? {
        didSet {
            if let post = post {
                postView.post = post
            }
        }
    }
    var index: Int? {
        didSet {
            if let index = index {
                postView.index = index
            }
        }
    }
    var delegate: PostViewDelegate? {
        didSet {
            if let delegate = delegate {
                postView.delegate = delegate
            }
        }
    }
    var commentsLink: String?
    var archived = false {
        didSet {
            if archived {
                navigationItem.title = "Archived"
            }
        }
    }
    
    private let commentCellId = "redditCommentCellId"
    var comments: [Comment] = [] {
        didSet {
            currentlyDisplayed = comments
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
    }

    let defaults = UserDefaults.standard
    
    let postView = PostView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(RedditCommentCell.self, forCellReuseIdentifier: commentCellId)
        tableView.backgroundColor = #colorLiteral(red: 0.9686660171, green: 0.9768124223, blue: 0.9722633958, alpha: 1)
        tableView.keyboardDismissMode = .interactive
        tableView.alwaysBounceVertical = true
        tableView.tableHeaderView = postView
        postView.commentFlag = true

        commentTextField.delegate = self
        fullyExpanded = true
        fetchComments()
    }
    
    override open func commentsView(_ tableView: UITableView, commentCellForModel commentModel: Comment, atIndexPath indexPath: IndexPath) -> CommentCell {
        let commentCell = tableView.dequeueReusableCell(withIdentifier: commentCellId, for: indexPath) as! RedditCommentCell
        let comment = currentlyDisplayed[indexPath.row]
        commentCell.depth = comment.depth
        commentCell.commentContent = comment.body
        commentCell.author = comment.author
        commentCell.isFolded = comment.isFolded && !isCellExpanded(indexPath: indexPath)
        commentCell.delegate = self
        return commentCell
    }
    
    let commentTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "Enter Comment"
        return textField
    }()
    
    lazy var textView: UIView = {
        let containerview = UIView()
        containerview.backgroundColor = .white
        containerview.frame = CGRect(x: 0, y: 0, width: 100, height: 75)


        let submitButton = UIButton(type: .system)
        submitButton.setTitle("Submit", for: .normal)
        submitButton.setTitleColor(.black, for: .normal)
        submitButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 14)
        submitButton.addTarget(self, action: #selector(handleSubmit), for: .touchUpInside)

        containerview.addSubview(submitButton)
        submitButton.translatesAutoresizingMaskIntoConstraints = false
        submitButton.topAnchor.constraint(equalTo: containerview.topAnchor).isActive = true
        submitButton.trailingAnchor.constraint(equalTo: containerview.trailingAnchor, constant: -20).isActive = true
        submitButton.bottomAnchor.constraint(equalTo: containerview.bottomAnchor).isActive = true
        submitButton.widthAnchor.constraint(equalToConstant: 50).isActive = true

        containerview.addSubview(commentTextField)
        commentTextField.translatesAutoresizingMaskIntoConstraints = false
        commentTextField.topAnchor.constraint(equalTo: containerview.topAnchor).isActive = true
        commentTextField.leadingAnchor.constraint(equalTo: containerview.leadingAnchor, constant: 20).isActive = true
        commentTextField.trailingAnchor.constraint(equalTo: submitButton.leadingAnchor).isActive = true
        commentTextField.bottomAnchor.constraint(equalTo: containerview.bottomAnchor).isActive = true

        let topDividerView = UIView()
        topDividerView.backgroundColor = UIColor.lightGray
        containerview.addSubview(topDividerView)
        topDividerView.translatesAutoresizingMaskIntoConstraints = false
        topDividerView.topAnchor.constraint(equalTo: commentTextField.topAnchor).isActive = true
        topDividerView.leadingAnchor.constraint(equalTo: containerview.leadingAnchor).isActive = true
        topDividerView.trailingAnchor.constraint(equalTo: containerview.trailingAnchor).isActive = true
        topDividerView.heightAnchor.constraint(equalToConstant: 0.5).isActive = true

        return containerview
    }()
    
    override var inputAccessoryView: UIView? {
        get {
            if archived {
                return nil
            } else {
                return textView
            }
        }
    }

    override var canBecomeFirstResponder: Bool {
        return true
    }
    
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        return true
    }

    @objc func handleSubmit() {
        print("handle submit: ", commentTextField.text ?? "")
        let authenticated = RedditClient.sharedInstance.isUserAuthenticated()
        if !authenticated {
            DispatchQueue.main.async {
                showToast(controller: self, message: "You need to be signed in to comment", seconds: 1.5, dismissAfter: false)
            }
        } else {
            if let username = RedditClient.sharedInstance.getUsername(), let body = commentTextField.text, let post = post {
                let postId = post.id
                DispatchQueue.main.async {
                    self.commentTextField.text = nil
                    self.commentTextField.resignFirstResponder()
                }
                RedditClient.sharedInstance.postComment(postId: postId, text: body) { (errorOccured, commentId) in
                    if !errorOccured {
                        print("posted comment!")
                        let comment = Comment(author: username, body: body, depth: 0, replies: [Comment](), id: commentId ?? "", isAuthorPost: false)
                        print(comment)
                        self.comments.append(comment)
                        generatorImpactOccured()
                        DispatchQueue.main.async {
                            showToast(controller: self, message: "Submitted ✓", seconds: 0.3, dismissAfter: false)
                        }
                    }
                }
            }
        }
    }
    
    fileprivate func extractReplies(commentReplies: Reply) -> [Comment] {
        var replies = [Comment]()

        switch commentReplies {
        case .string( _):
            break
        case .redditCommentResponse(let commentResponse):
            let children = commentResponse.data.children
            for child in children {
                guard let redditComment = child.data else {break}
                let author = redditComment.author ?? ""
                let body = redditComment.body ?? ""
                let depth = redditComment.depth ?? 0
                let id = redditComment.id ?? ""

                var cReplies = [Comment]()
                if let commentReplies = redditComment.replies {
                    cReplies = extractReplies(commentReplies: commentReplies)
                }
                let comment = Comment(author: author, body: body, depth: depth, replies: cReplies, id: id, isAuthorPost: false)
                replies.append(comment)
            }
        }

        return replies
    }

    private func extractComments(data: Data) -> [Comment] {
        var comments = [Comment]()
        do {
            let decoded = try JSONDecoder().decode([RedditCommentResponse].self, from: data)
            for (index, commentResponse) in decoded.enumerated() {
                if index == 0 {
                    continue
                } else {
                    let children = commentResponse.data.children
                    for child in children {
                        guard let redditComment = child.data else {continue}
                        let author = redditComment.author ?? ""
                        let body = redditComment.body ?? ""
                        let depth = redditComment.depth ?? 0
                        let id = redditComment.id ?? ""

                        var replies = [Comment]()
                        if let commentReplies = redditComment.replies {
                            replies = extractReplies(commentReplies: commentReplies)
                        }

                        let comment = Comment(author: author, body: body, depth: depth, replies: replies, id: id, isAuthorPost: false)
                        print(comment)
                        comments.append(comment)
                    }
                }
            }
        } catch {print(error)}
        return comments
    }

    private func fetchComments() {
        if let commentsLink = commentsLink, let url = URL(string: commentsLink) {
                URLSession.shared.dataTask(with: url) { data, response, error in
                    if let data = data {
                        let comments = self.extractComments(data: data)
                        self.comments = comments
                    }
                }.resume()
        }
    }
    
    func didTapUsername(username: String) {
        let userProfileController = UserProfileController(collectionViewLayout: UICollectionViewFlowLayout())
        userProfileController.usernameProp = username
        navigationController?.pushViewController(userProfileController, animated: true)
        print(username)
    }
}
