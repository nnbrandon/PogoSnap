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
        // Tableview style
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
                        tableView.scrollToRow(at: IndexPath(row: selectedIndex + 1, section: indexPath.section), at: UITableView.ScrollPosition.middle, animated: false)
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
    
    @objc func handleComment() {
        if !commentsViewModel.authenticated {
            guard let navController = navigationController else {return}
            DispatchQueue.main.async {
                showErrorToast(controller: navController, message: "You need to sign in to comment", seconds: 3.0)
            }
        } else {
            let textController = RedditCommentTextController()
            textController.postId = postViewModel.id
            textController.subReddit = postViewModel.subReddit
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
    
    func didTapUsername(username: String) {
        let userProfileController = UserProfileController()
        userProfileController.usernameProp = username
        navigationController?.pushViewController(userProfileController, animated: true)
    }
    
    func didTapReply(parentCommentId: String, parentCommentContent: String, parentCommentAuthor: String, parentDepth: Int) {
        let textController = RedditCommentTextController()
        textController.postId = postViewModel.id
        textController.subReddit = postViewModel.subReddit
        textController.updateComments = updateComments
        textController.parentCommentId = parentCommentId
        textController.parentCommentContent = parentCommentContent
        textController.parentCommentAuthor = parentCommentAuthor
        textController.parentDepth = parentDepth
        present(textController, animated: true, completion: nil)
    }
    
    func didTapMoreChildren(children: [String]) {
//        guard let post = post else {
//            return
//        }
//        let postId = "t3_" + post.id
//        let childrenQuery = children.joined(separator: ",")
//        guard let url = URL(string: "https://www.reddit.com/api/morechildren.json?api_type=json&limit_children=false&link_id=\(postId)&children=\(childrenQuery)") else {
//            return
//        }
//
//        URLSession.shared.dataTask(with: url) { data, response, _ in
//            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200, let data = data {
//                let moreReplies = self.extractMoreReplies(data: data)
//                self.addMoreReplies(moreReplies: moreReplies, children: children)
//            } else {
//                DispatchQueue.main.async {
//                    if let navController = self.navigationController {
//                        showErrorToast(controller: navController, message: "Unable to retrieve comments", seconds: 1.0)
//                    }
//                }
//            }
//        }.resume()
    }
    
    func didTapOptions(commentId: String, author: String) {
//        generatorImpactOccured()
//        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: getCurrentInterfaceForAlerts())
//        alertController.addAction(UIAlertAction(title: "Report", style: .default, handler: { _ in
//
//            if !RedditService.sharedInstance.isUserAuthenticated() {
//                DispatchQueue.main.async {
//                    if let navController = self.navigationController {
//                        showErrorToast(controller: navController, message: "You need to be signed in to report", seconds: 1.0)
//                    }
//                }
//                return
//            }
//
//            let reportOptionsController = UIAlertController(title: nil, message: nil, preferredStyle: getCurrentInterfaceForAlerts())
//            reportOptionsController.addAction(UIAlertAction(title: "r/PokemonGoSnap Rules", style: .default, handler: { _ in
//
//                let subredditRulesController = UIAlertController(title: nil, message: nil, preferredStyle: getCurrentInterfaceForAlerts())
//                if let subredditRules = self.defaults?.stringArray(forKey: "PokemonGoSnapRules") {
//                    for rule in subredditRules {
//                        subredditRulesController.addAction(UIAlertAction(title: rule, style: .default, handler: { action in
//                            if let reason = action.title {
//                                self.reportComment(commentId: commentId, reason: reason)
//                            }
//                        }))
//                    }
//                }
//                subredditRulesController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
//                self.present(subredditRulesController, animated: true, completion: nil)
//            }))
//
//            reportOptionsController.addAction(UIAlertAction(title: "Spam or Abuse", style: .default, handler: { _ in
//                let siteRulesController = UIAlertController(title: nil, message: nil, preferredStyle: getCurrentInterfaceForAlerts())
//                if let siteRules = self.defaults?.stringArray(forKey: "SiteRules") {
//                    for rule in siteRules {
//                        siteRulesController.addAction(UIAlertAction(title: rule, style: .default, handler: { action in
//                            if let reason = action.title {
//                                self.reportComment(commentId: commentId, reason: reason)
//                            }
//                        }))
//                    }
//                }
//                siteRulesController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
//                self.present(siteRulesController, animated: true, completion: nil)
//            }))
//
//            reportOptionsController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
//
//            self.present(reportOptionsController, animated: true, completion: nil)
//        }))
//        if let username = RedditService.sharedInstance.getUsername(), username == author {
//            alertController.addAction(UIAlertAction(title: "Delete", style: .destructive, handler: { _ in
//                self.deleteComment(commentId: commentId)
//            }))
//        }
//        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
//
//        present(alertController, animated: true, completion: nil)
    }
    
//    private func deleteComment(commentId: String) {
//        let cid = "t1_\(commentId)"
//        RedditService.sharedInstance.delete(id: cid) { result in
//            switch result {
//            case .success:
//                self.removeComment(commentId: commentId)
//                DispatchQueue.main.async {
//                    generatorImpactOccured()
//                    if let navController = self.navigationController {
//                        showSuccessToast(controller: navController, message: "Deleted", seconds: 0.5)
//                    }
//                }
//            case .error:
//                DispatchQueue.main.async {
//                    generatorImpactOccured()
//                    if let navController = self.navigationController {
//                        showErrorToast(controller: navController, message: "Could not delete the comment", seconds: 0.5)
//                    }
//                }
//            }
//        }
//    }
    
    private func reportComment(commentId: String, reason: String) {
//        guard let post = post else {return}
//        let commentId = "t1_\(commentId)"
//        RedditClient.sharedInstance.report(subReddit: post.subReddit, id: commentId, reason: reason) { result in
//            switch result {
//            case .success:
//                DispatchQueue.main.async {
//                    generatorImpactOccured()
//                    if let navController = self.navigationController {
//                        showSuccessToast(controller: navController, message: "Reported", seconds: 0.5)
//                    }
//                }
//            case .error:
//                DispatchQueue.main.async {
//                    generatorImpactOccured()
//                    if let navController = self.navigationController {
//                        showErrorToast(controller: navController, message: "Could not report the post", seconds: 0.5)
//                    }
//                }
//            }
//        }
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
