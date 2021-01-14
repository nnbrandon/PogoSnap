//
//  RedditCommentsControllers.swift
//  PogoSnap
//
//  Created by Brandon Nguyen on 11/24/20.
//

import UIKit

class RedditCommentsController: CommentsController, CommentDelegate {

//    var post: Post? {
//        didSet {
//            if let post = post {
//                postView.post = post
//            }
//        }
//    }
//    var index: Int? {
//        didSet {
//            if let index = index {
//                postView.index = index
//            }
//        }
//    }
//    var delegate: PostViewDelegate? {
//        didSet {
//            if let delegate = delegate {
//                postView.delegate = delegate
//            }
//        }
//    }
    var commentsLink: String?
    var archived = false {
        didSet {
            if archived {
                navigationItem.title = "Archived"
                addButton.isHidden = true
            }
        }
    }
    let defaults = UserDefaults(suiteName: "group.com.PogoSnap")

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
    let activityIndicatorView: UIActivityIndicatorView = {
        let spinner = UIActivityIndicatorView()
        spinner.startAnimating()
        return spinner
    }()
    
    let postView = PostView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(RedditCommentCell.self, forCellReuseIdentifier: commentCellId)
        if traitCollection.userInterfaceStyle == .light {
            tableView.backgroundColor = #colorLiteral(red: 0.9686660171, green: 0.9768124223, blue: 0.9722633958, alpha: 1)
        } else {
            tableView.backgroundColor = RedditConsts.redditDarkMode
        }
        tableView.alwaysBounceVertical = true
        tableView.tableHeaderView = postView
        postView.commentFlag = true
        postView.addCommentFunc = addCommentFunc
        
        view.addSubview(addButton)
        addButton.translatesAutoresizingMaskIntoConstraints = false
        addButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20).isActive = true
        addButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -10).isActive = true
        view.bringSubviewToFront(addButton)
        
        activityIndicatorView.startAnimating()
        activityIndicatorView.frame = CGRect(x: 0, y: 0, width: tableView.frame.width, height: 44)
        tableView.tableFooterView = activityIndicatorView

        fullyExpanded = true
        fetchComments()
    }
    
    override open func commentsView(_ tableView: UITableView, commentCellForModel commentModel: Comment, atIndexPath indexPath: IndexPath) -> CommentCell {
        guard let commentCell = tableView.dequeueReusableCell(withIdentifier: commentCellId, for: indexPath) as? RedditCommentCell else {
            return CommentCell()
        }
        let comment = currentlyDisplayed[indexPath.row]
        
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
        commentCell.isFolded = comment.isFolded && !isCellExpanded(indexPath: indexPath)
        commentCell.delegate = self
        return commentCell
    }
    
    func addCommentFunc() {
        handleComment()
    }
    
    @objc func handleComment() {
        if RedditClient.sharedInstance.getUsername() == nil {
            DispatchQueue.main.async {
                if let navController = self.navigationController {
                    showErrorToast(controller: navController, message: "You need to sign in to comment", seconds: 0.5)
                }
            }
        } else {
//            if let post = post {
//                let textController = RedditCommentTextController()
//                textController.post = post
//                textController.updateComments = updateComments
//                present(textController, animated: true, completion: nil)
//            }
        }
    }
    
    fileprivate func extractReplies(commentReplies: Reply) -> [Comment] {
        var replies = [Comment]()

        switch commentReplies {
        case .string:
            break
        case .redditCommentResponse(let commentResponse):
            let children = commentResponse.data.children
            for child in children {
                guard let redditComment = child.data else {break}
                let author = redditComment.author ?? ""
                let body = redditComment.body ?? ""
                let depth = redditComment.depth ?? 0
                let commentId = redditComment.id ?? ""
                let created_utc = redditComment.created_utc ?? Date().timeIntervalSince1970
                
                if let count = redditComment.count, count == 0 {
                    // on more
                    continue
                }

                var cReplies = [Comment]()
                if let commentReplies = redditComment.replies {
                    cReplies = extractReplies(commentReplies: commentReplies)
                }
                let comment = Comment(author: author, body: body, depth: depth, replies: cReplies, id: commentId, isAuthorPost: false, created_utc: created_utc, count: redditComment.count, name: redditComment.name, parent_id: redditComment.parent_id, children: redditComment.children)
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
                        let commentId = redditComment.id ?? ""
                        let created_utc = redditComment.created_utc ?? Date().timeIntervalSince1970

                        var replies = [Comment]()
                        if let commentReplies = redditComment.replies {
                            replies = extractReplies(commentReplies: commentReplies)
                        }

                        let comment = Comment(author: author, body: body, depth: depth, replies: replies, id: commentId, isAuthorPost: false, created_utc: created_utc, count: redditComment.count, name: redditComment.name, parent_id: redditComment.parent_id, children: redditComment.children)
                        comments.append(comment)
                    }
                }
            }
        } catch let error {
            print(error)
        }
        return comments
    }

    private func fetchComments() {
        activityIndicatorView.startAnimating()
        if let commentsLink = commentsLink, let url = URL(string: commentsLink) {
            URLSession.shared.dataTask(with: url) { data, response, _ in
                DispatchQueue.main.async {
                    self.activityIndicatorView.stopAnimating()
                }
                if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200, let data = data {
                    let comments = self.extractComments(data: data)
                    self.comments = comments
                } else {
                    DispatchQueue.main.async {
                        if let navController = self.navigationController {
                            showErrorToast(controller: navController, message: "Unable to retrieve comments", seconds: 1.0)
                        }
                    }
                }
            }.resume()
        }
    }
    
    private func extractMoreReplies(data: Data) -> [Comment] {
        var comments = [Comment]()
        do {
            let decoded = try JSONDecoder().decode(RedditMoreChildrentResponse.self, from: data)
            if let things = decoded.json.data?.things {
                for thing in things {
                    let redditComment = thing.data
                    let author = redditComment.author ?? ""
                    let body = redditComment.body ?? ""
                    let depth = redditComment.depth ?? 0
                    let commentId = redditComment.id ?? ""
                    let created_utc = redditComment.created_utc ?? Date().timeIntervalSince1970

                    var replies = [Comment]()
                    if let commentReplies = redditComment.replies {
                        replies = extractReplies(commentReplies: commentReplies)
                    }

                    let comment = Comment(author: author, body: body, depth: depth, replies: replies, id: commentId, isAuthorPost: false, created_utc: created_utc, count: redditComment.count, name: redditComment.name, parent_id: redditComment.parent_id, children: redditComment.children)
                    comments.append(comment)
                }
            }
        } catch let error {
            print(error)
        }
        return comments
    }
    
    public func updateComments(comment: Comment, parentCommentId: String?) {
        DispatchQueue.main.async {
            if let navController = self.navigationController {
                showSuccessToast(controller: navController, message: "Comment posted", seconds: 1.0)
            }
        }
        if let parentCommentId = parentCommentId {
            addReply(reply: comment, parentCommentId: parentCommentId)
        } else {
            comments.append(comment)
        }
    }
    
    func didTapUsername(username: String) {
        let userProfileController = UserProfileController()
        userProfileController.usernameProp = username
        navigationController?.pushViewController(userProfileController, animated: true)
    }
    
    func didTapReply(parentCommentId: String, parentCommentContent: String, parentCommentAuthor: String, parentDepth: Int) {
//        if let post = post {
//            let textController = RedditCommentTextController()
//            textController.post = post
//            textController.updateComments = updateComments
//            textController.parentCommentId = parentCommentId
//            textController.parentCommentContent = parentCommentContent
//            textController.parentCommentAuthor = parentCommentAuthor
//            textController.parentDepth = parentDepth
//            present(textController, animated: true, completion: nil)
//        }
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
        generatorImpactOccured()
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: getCurrentInterfaceForAlerts())
        alertController.addAction(UIAlertAction(title: "Report", style: .default, handler: { _ in
            
            if !RedditClient.sharedInstance.isUserAuthenticated() {
                DispatchQueue.main.async {
                    if let navController = self.navigationController {
                        showErrorToast(controller: navController, message: "You need to be signed in to report", seconds: 1.0)
                    }
                }
                return
            }
            
            let reportOptionsController = UIAlertController(title: nil, message: nil, preferredStyle: getCurrentInterfaceForAlerts())
            reportOptionsController.addAction(UIAlertAction(title: "r/PokemonGoSnap Rules", style: .default, handler: { _ in
                
                let subredditRulesController = UIAlertController(title: nil, message: nil, preferredStyle: getCurrentInterfaceForAlerts())
                if let subredditRules = self.defaults?.stringArray(forKey: "PokemonGoSnapRules") {
                    for rule in subredditRules {
                        subredditRulesController.addAction(UIAlertAction(title: rule, style: .default, handler: { action in
                            if let reason = action.title {
                                self.reportComment(commentId: commentId, reason: reason)
                            }
                        }))
                    }
                }
                subredditRulesController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
                self.present(subredditRulesController, animated: true, completion: nil)
            }))
                        
            reportOptionsController.addAction(UIAlertAction(title: "Spam or Abuse", style: .default, handler: { _ in
                let siteRulesController = UIAlertController(title: nil, message: nil, preferredStyle: getCurrentInterfaceForAlerts())
                if let siteRules = self.defaults?.stringArray(forKey: "SiteRules") {
                    for rule in siteRules {
                        siteRulesController.addAction(UIAlertAction(title: rule, style: .default, handler: { action in
                            if let reason = action.title {
                                self.reportComment(commentId: commentId, reason: reason)
                            }
                        }))
                    }
                }
                siteRulesController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
                self.present(siteRulesController, animated: true, completion: nil)
            }))
            
            reportOptionsController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            
            self.present(reportOptionsController, animated: true, completion: nil)
        }))
        if let username = RedditClient.sharedInstance.getUsername(), username == author {
            alertController.addAction(UIAlertAction(title: "Delete", style: .destructive, handler: { _ in
                self.deleteComment(commentId: commentId)
            }))
        }
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        present(alertController, animated: true, completion: nil)
    }
    
    private func deleteComment(commentId: String) {
        let cid = "t1_\(commentId)"
        RedditClient.sharedInstance.delete(id: cid) { result in
            switch result {
            case .success:
                self.removeComment(commentId: commentId)
                DispatchQueue.main.async {
                    generatorImpactOccured()
                    if let navController = self.navigationController {
                        showSuccessToast(controller: navController, message: "Deleted", seconds: 0.5)
                    }
                }
            case .error:
                DispatchQueue.main.async {
                    generatorImpactOccured()
                    if let navController = self.navigationController {
                        showErrorToast(controller: navController, message: "Could not delete the comment", seconds: 0.5)
                    }
                }
            }
        }
    }
    
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
        if !archived {
            let bottomEdge = scrollView.contentOffset.y + scrollView.frame.size.height
            if bottomEdge >= scrollView.contentSize.height && linearizedComments.count > 2 {
                addButton.isHidden = true
            } else {
                addButton.isHidden = false
            }
        }
    }
}
