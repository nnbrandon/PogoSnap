//
//  RedditCommentsControllers.swift
//  PogoSnap
//
//  Created by Brandon Nguyen on 11/24/20.
//

import UIKit

class RedditCommentsController: UITableViewController, UIGestureRecognizerDelegate, CommentDelegate {

    var commentsViewModel: CommentsViewModel! {
        didSet {
            if commentsViewModel.archived {
                navigationItem.title = "Archived"
                addButton.isHidden = true
            }
        }
    }

    var postViewModel: PostViewModel! {
        didSet {
            postControlView.postViewModel = postViewModel
        }
    }
    var controlViewModel: ControlViewModel! {
        didSet {
            controlViewModel.fromPostControlView = true
            postControlView.addCommentFunc = handleComment
            postControlView.controlViewModel = controlViewModel
        }
    }
    weak var postViewDelegate: PostViewDelegate? {
        didSet {
            postControlView.postViewDelegate = postViewDelegate
        }
    }
    weak var controlViewDelegate: ControlViewDelegate? {
        didSet {
            postControlView.controlViewDelegate = controlViewDelegate
        }
    }
    weak var basePostDelegate: BasePostsDelegate? {
        didSet {
            postControlView.basePostDelegate = basePostDelegate
        }
    }
    private let commentCellId = "redditCommentCellId"

    let addButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setImage(UIImage(named: "comment-60")?.withRenderingMode(.alwaysOriginal), for: .normal)
        btn.addTarget(self, action: #selector(handleComment), for: .touchUpInside)
        return btn
    }()
    let activityIndicatorView: UIActivityIndicatorView = {
        let spinner = UIActivityIndicatorView()
        spinner.startAnimating()
        return spinner
    }()

    let postControlView = PostControlView()

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.separatorStyle = UITableViewCell.SeparatorStyle.none

        if #available(iOS 11.0, *) {
            tableView.estimatedRowHeight = 0
            tableView.estimatedSectionFooterHeight = 0
            tableView.estimatedSectionHeaderHeight = 0
        } else {
            tableView.rowHeight = UITableView.automaticDimension
            tableView.estimatedRowHeight = 400.0
        }

        tableView.register(RedditCommentCell.self, forCellReuseIdentifier: commentCellId)
        if traitCollection.userInterfaceStyle == .light {
            tableView.backgroundColor = #colorLiteral(red: 0.9686660171, green: 0.9768124223, blue: 0.9722633958, alpha: 1)
        } else {
            tableView.backgroundColor = RedditConsts.redditDarkMode
        }
        tableView.alwaysBounceVertical = true
        tableView.tableHeaderView = postControlView
        
        view.addSubview(addButton)
        addButton.translatesAutoresizingMaskIntoConstraints = false
        addButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20).isActive = true
        addButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -10).isActive = true
        view.bringSubviewToFront(addButton)
        
        activityIndicatorView.startAnimating()
        activityIndicatorView.frame = CGRect(x: 0, y: 0, width: tableView.frame.width, height: 44)
        tableView.tableFooterView = activityIndicatorView
        
        let longPressGesture: UILongPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(self.handleLongPress))
        longPressGesture.minimumPressDuration = 0.2
        longPressGesture.delegate = self
        tableView.addGestureRecognizer(longPressGesture)
            
        fetchComments()
    }
    
    @objc func handleLongPress(_ gestureRecognizer: UILongPressGestureRecognizer) {
        if gestureRecognizer.state == .began {
            let touchPoint = gestureRecognizer.location(in: tableView)
            if let indexPath = tableView.indexPathForRow(at: touchPoint) {
                let selectedIndex = indexPath.row
                let selectedComment: Comment = commentsViewModel.getComment(selectedIndex: selectedIndex)
                
                if !selectedComment.replies.isEmpty { // if expandable
                    if commentsViewModel.isCellExpanded(selectedIndex: selectedIndex) {
                        // collapse
                        let nCellsToDelete = commentsViewModel.getNumberOfCellsToDelete(comment: selectedComment, selectedIndex: selectedIndex)
                        let indexPaths = commentsViewModel.removeCells(selectedIndex: selectedIndex, nCellsToDelete: nCellsToDelete, indexPath: indexPath)
                        tableView.deleteRows(at: indexPaths, with: .bottom)
                    } else {
                        // expand
                        let indexPaths = commentsViewModel.expandSelectedComment(selectedIndex: selectedIndex, selectedComment: selectedComment, indexPath: indexPath)
                        tableView.insertRows(at: indexPaths, with: .bottom)
                        tableView.scrollToRow(at: IndexPath(row: selectedIndex + 1, section: indexPath.section), at: UITableView.ScrollPosition.middle, animated: true)
                    }
                    DispatchQueue.main.async {
                        self.tableView.reloadData()
                    }
                }
            }
        }
    }
    
    private func fetchComments() {
        commentsViewModel.fetchComments { error in
            if let error = error {
                guard let navController = self.navigationController else {return}
                DispatchQueue.main.async {
                    self.activityIndicatorView.stopAnimating()
                    showErrorToast(controller: navController, message: error, seconds: 3.0)
                }
            } else {
                DispatchQueue.main.async {
                    self.activityIndicatorView.stopAnimating()
                    self.tableView.reloadData()
                }
            }
        }
    }
    
    @objc func handleComment() {
        if !commentsViewModel.authenticated {
            guard let navController = navigationController else {return}
            DispatchQueue.main.async {
                showErrorToast(controller: navController, message: "You need to sign in to comment", seconds: 3.0)
            }
        } else {
            let textController = RedditCommentTextController()
            textController.postId = commentsViewModel.postId
            textController.subReddit = commentsViewModel.postSubReddit
            textController.updateComments = updateComments
            present(textController, animated: true, completion: nil)
        }
    }

    public func updateComments(comment: Comment, parentCommentId: String?) {
        var indexPath: IndexPath
        if let parentCommentId = parentCommentId {
            indexPath = commentsViewModel.addReply(reply: comment, parentCommentId: parentCommentId)
        } else {
            indexPath = commentsViewModel.insertNewComment(newComment: comment)
        }
        DispatchQueue.main.async {
            guard let navController = self.navigationController else {return}
            showSuccessToast(controller: navController, message: "Comment posted", seconds: 1.0)
            self.tableView.reloadData()
            self.tableView.scrollToRow(at: indexPath, at: UITableView.ScrollPosition.middle, animated: false)
        }
    }
    
    override open func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return commentsViewModel.getCount()
    }
    
    override open func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    override open func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let comment = commentsViewModel.getComment(selectedIndex: indexPath.row)
        let commentCell = commentsView(tableView, comment: comment, atIndexPath: indexPath)
        return commentCell
    }
    
    func commentsView(_ tableView: UITableView, comment: Comment, atIndexPath indexPath: IndexPath) -> CommentCell {
        guard let commentCell = tableView.dequeueReusableCell(withIdentifier: commentCellId, for: indexPath) as? RedditCommentCell else {
            return CommentCell()
        }
        
        if let count = comment.count, comment.name != nil, comment.parent_id != nil, let children = comment.children {
            // MORE comment
            commentCell.isMore = true
            commentCell.children = children
            commentCell.count = count
        } else {
            commentCell.isMore = false
        }
        commentCell.depth = comment.depth
        commentCell.commentDepth = comment.depth
        commentCell.commentContent = comment.body
        commentCell.author = comment.author
        commentCell.created = comment.created_utc
        commentCell.commentId = comment.id
        commentCell.isFolded = comment.isFolded && !commentsViewModel.isCellExpanded(selectedIndex: indexPath.row)
        commentCell.delegate = self
        return commentCell
    }
    
    func didTapUsername(username: String) {
        let userProfileController = UserProfileController()
        userProfileController.usernameProp = username
        navigationController?.pushViewController(userProfileController, animated: true)
    }
    
    func didTapReply(parentCommentId: String, parentCommentContent: String, parentCommentAuthor: String, parentDepth: Int) {
        let textController = RedditCommentTextController()
        textController.postId = commentsViewModel.postId
        textController.subReddit = commentsViewModel.postSubReddit
        textController.updateComments = updateComments
        textController.parentCommentId = parentCommentId
        textController.parentCommentContent = parentCommentContent
        textController.parentCommentAuthor = parentCommentAuthor
        textController.parentDepth = parentDepth
        present(textController, animated: true, completion: nil)
    }
    
    func didTapMoreChildren(children: [String]) {
        commentsViewModel.getMoreChildren(children: children) { error in
            if let error = error {
                DispatchQueue.main.async {
                    guard let navController = self.navigationController else { return }
                    showErrorToast(controller: navController, message: error, seconds: 2.0)
                }
            } else {
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
            }
        }
    }
    
    func didTapOptions(commentId: String, author: String) {
        let id = commentsViewModel.postId
        let subReddit = commentsViewModel.postSubReddit
        let authenticated = commentsViewModel.authenticated
        let subRedditRules = commentsViewModel.getSubredditRules(subReddit: subReddit)
        let siteRules = commentsViewModel.getSiteRules()
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: getCurrentInterfaceForAlerts())
        alertController.addAction(UIAlertAction(title: "Report", style: .default, handler: { _ in
            if !authenticated {
                DispatchQueue.main.async {
                    if let navController = self.navigationController {
                        showErrorToast(controller: navController, message: "You need to be signed in to report", seconds: 2.0)
                    }
                }
                return
            }
            let reportOptionsController = UIAlertController(title: nil, message: nil, preferredStyle: getCurrentInterfaceForAlerts())
            let subRedditRulesAction = self.getAlertForRules(id: id, rules: subRedditRules, subReddit: subReddit, isSubRedditRules: true)
            let siteRulesAction = self.getAlertForRules(id: id, rules: siteRules, subReddit: subReddit, isSubRedditRules: false)
            reportOptionsController.addAction(subRedditRulesAction)
            reportOptionsController.addAction(siteRulesAction)
            reportOptionsController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            self.present(reportOptionsController, animated: true, completion: nil)
        }))
        if commentsViewModel.canDelete(author: author) {
            alertController.addAction(UIAlertAction(title: "Delete", style: .destructive, handler: { _ in
                self.deleteComment(commentId: commentId)
            }))
        }
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))

        present(alertController, animated: true, completion: nil)
    }
    
    private func getAlertForRules(id: String, rules: [String], subReddit: String, isSubRedditRules: Bool) -> UIAlertAction {
        var action: UIAlertAction
        if isSubRedditRules {
            action = UIAlertAction(title: "r/\(subReddit) Rules", style: .default, handler: { _ in
                let subredditRulesController = UIAlertController(title: nil, message: nil, preferredStyle: getCurrentInterfaceForAlerts())
                for rule in rules {
                    subredditRulesController.addAction(UIAlertAction(title: rule, style: .default, handler: { action in
                        if let reason = action.title {
                            self.reportComment(commentId: id, reason: reason)
                        }
                    }))
                }
                subredditRulesController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
                self.present(subredditRulesController, animated: true, completion: nil)
            })
        } else {
            action = UIAlertAction(title: "Spam or Abuse", style: .default, handler: { _ in
                let siteRulesController = UIAlertController(title: nil, message: nil, preferredStyle: getCurrentInterfaceForAlerts())
                for rule in rules {
                    siteRulesController.addAction(UIAlertAction(title: rule, style: .default, handler: { action in
                        if let reason = action.title {
                            self.reportComment(commentId: id, reason: reason)
                        }
                    }))
                }
                siteRulesController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
                self.present(siteRulesController, animated: true, completion: nil)
            })
        }
        return action
    }
    
    private func deleteComment(commentId: String) {
        commentsViewModel.deleteComment(commentId: commentId) { error in
            if let error = error {
                DispatchQueue.main.async {
                    generatorImpactOccured()
                    guard let navController = self.navigationController else { return }
                    showErrorToast(controller: navController, message: error, seconds: 2.0)
                }
            } else {
                DispatchQueue.main.async {
                    generatorImpactOccured()
                    guard let navController = self.navigationController else { return }
                    showSuccessToast(controller: navController, message: "Deleted", seconds: 2.0)
                    self.tableView.reloadData()
                }
            }
        }
    }
    
    private func reportComment(commentId: String, reason: String) {
        commentsViewModel.reportComment(commentId: commentId, reason: reason) { error in
            if let error = error {
                DispatchQueue.main.async {
                    generatorImpactOccured()
                    guard let navController = self.navigationController else { return }
                    showErrorToast(controller: navController, message: error, seconds: 2.0)
                }
            } else {
                DispatchQueue.main.async {
                    generatorImpactOccured()
                    guard let navController = self.navigationController else { return }
                    showSuccessToast(controller: navController, message: "Reported", seconds: 2.0)
                }
            }
        }
    }
}

extension RedditCommentsController {
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if !commentsViewModel.archived {
            let bottomEdge = scrollView.contentOffset.y + scrollView.frame.size.height
            if bottomEdge >= scrollView.contentSize.height && commentsViewModel.getCount() > 2 {
                addButton.isHidden = true
            } else {
                addButton.isHidden = false
            }
        }
    }
}
