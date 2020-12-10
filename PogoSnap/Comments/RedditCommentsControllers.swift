//
//  RedditCommentsControllers.swift
//  PogoSnap
//
//  Created by Brandon Nguyen on 11/24/20.
//

import UIKit

class RedditCommentsController: CommentsController, CommentDelegate {

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
                addButton.isHidden = true
            }
        }
    }
    var lastContentOffset: CGFloat = 0.0
    
    private let commentCellId = "redditCommentCellId"
    var comments: [Comment] = [] {
        didSet {
            currentlyDisplayed = comments
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
    }
    let addButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setImage(UIImage(named: "comment-60")?.withRenderingMode(.alwaysOriginal), for: .normal)
        btn.addTarget(self, action: #selector(handleComment), for: .touchUpInside)
        return btn
    }()
    
    let postView = PostView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(RedditCommentCell.self, forCellReuseIdentifier: commentCellId)
        tableView.backgroundColor = #colorLiteral(red: 0.9686660171, green: 0.9768124223, blue: 0.9722633958, alpha: 1)
        tableView.keyboardDismissMode = .interactive
        tableView.alwaysBounceVertical = true
        tableView.tableHeaderView = postView
        postView.commentFlag = true
        
        view.addSubview(addButton)
        addButton.translatesAutoresizingMaskIntoConstraints = false
        addButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20).isActive = true
        addButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -10).isActive = true
        view.bringSubviewToFront(addButton)

        fullyExpanded = true
        fetchComments()
    }
    
    override open func commentsView(_ tableView: UITableView, commentCellForModel commentModel: Comment, atIndexPath indexPath: IndexPath) -> CommentCell {
        let commentCell = tableView.dequeueReusableCell(withIdentifier: commentCellId, for: indexPath) as! RedditCommentCell
        let comment = currentlyDisplayed[indexPath.row]
        commentCell.depth = comment.depth
        commentCell.commentDepth = comment.depth
        commentCell.commentContent = comment.body
        commentCell.author = comment.author
        commentCell.commentId = comment.id
        commentCell.isFolded = comment.isFolded && !isCellExpanded(indexPath: indexPath)
        commentCell.delegate = self
        return commentCell
    }
    
    @objc func handleComment() {
        if let post = post {
            let textController = RedditCommentTextController()
            textController.post = post
            textController.updateComments = updateComments
            present(textController, animated: true, completion: nil)
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
    
    public func updateComments(comment: Comment, parentCommentId: String?) {
        if let parentCommentId = parentCommentId {
            addReply(reply: comment, parentCommentId: parentCommentId)
        } else {
            comments.append(comment)
        }
    }
    
    func didTapUsername(username: String) {
        let userProfileController = UserProfileController(collectionViewLayout: UICollectionViewFlowLayout())
        userProfileController.usernameProp = username
        navigationController?.pushViewController(userProfileController, animated: true)
        print(username)
    }
    
    func didTapReply(parentCommentId: String, parentCommentContent: String, parentCommentAuthor: String, parentDepth: Int) {
        if let post = post {
            let textController = RedditCommentTextController()
            textController.post = post
            textController.updateComments = updateComments
            textController.parentCommentId = parentCommentId
            textController.parentCommentContent = parentCommentContent
            textController.parentCommentAuthor = parentCommentAuthor
            textController.parentDepth = parentDepth
            present(textController, animated: true, completion: nil)
        }
    }
}

extension RedditCommentsController {
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if (scrollView.contentOffset.y + 5 < lastContentOffset) {
            //Scrolling up
            addButton.isHidden = false
        } else if (scrollView.contentOffset.y >= lastContentOffset) {
            //Scrolling down
            addButton.isHidden = true
        }
        lastContentOffset = scrollView.contentOffset.y
    }
}
