//
//  RedditCommentsControllers.swift
//  PogoSnap
//
//  Created by Brandon Nguyen on 11/24/20.
//

import UIKit

class RedditCommentsController: CommentsController, UITextFieldDelegate {

    var postId: String?
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(RedditCommentCell.self, forCellReuseIdentifier: commentCellId)
        tableView.backgroundColor = #colorLiteral(red: 0.9686660171, green: 0.9768124223, blue: 0.9722633958, alpha: 1)
        tableView.keyboardDismissMode = .interactive
        tableView.alwaysBounceVertical = true
        
        let sortButton = UIBarButtonItem(title: "●●●", style: .plain, target: self, action: #selector(handleReport))
        sortButton.setTitleTextAttributes([NSAttributedString.Key.font: UIFont.systemFont(ofSize: 8), NSAttributedString.Key.foregroundColor: UIColor.black], for: .normal)
        navigationItem.rightBarButtonItem = sortButton
        
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
        commentCell.isAuthorPost = comment.isAuthorPost
        if comment.isAuthorPost, let imageSources = comment.imageSources {
            commentCell.imageSources = imageSources
        }
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
        if let username = RedditClient.sharedInstance.getUsername(), let body = commentTextField.text, let postId = postId {
            let comment = Comment(author: username, body: body, depth: 0, replies: [Comment](), isAuthorPost: false)
            DispatchQueue.main.async {
                self.commentTextField.text = nil
                self.commentTextField.resignFirstResponder()
            }
            RedditClient.sharedInstance.postComment(postId: postId, text: body) { errors in
                if errors.isEmpty {
                    print("posted comment!")
                    self.comments.append(comment)
                    DispatchQueue.main.async {
                        showToast(controller: self, message: "Submitted ✓", seconds: 0.3)
                    }
                }
            }
        }
    }
    
    @objc func handleReport() {
        guard let postId = postId else {return}
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alertController.addAction(UIAlertAction(title: "Report", style: .default, handler: { _ in
            
            if !RedditClient.sharedInstance.isUserAuthenticated() {
                DispatchQueue.main.async {
                    showToast(controller: self, message: "You need to be signed in to report", seconds: 1.5)
                }
                return
            }
            
            let reportOptionsController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
            reportOptionsController.addAction(UIAlertAction(title: "r/PokemonGoSnap Rules", style: .default, handler: { _ in
                
                let subredditRulesController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
                if let subredditRules = self.defaults.stringArray(forKey: "PokemonGoSnapRules") {
                    for rule in subredditRules {
                        subredditRulesController.addAction(UIAlertAction(title: rule, style: .default, handler: { action in
                            if let reason = action.title {
                                print(reason)
                                self.reportPost(postId: postId, reason: reason)
                            }
                        }))
                    }
                }
                subredditRulesController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
                self.present(subredditRulesController, animated: true, completion: nil)
            }))
                        
            reportOptionsController.addAction(UIAlertAction(title: "Spam or Abuse", style: .default, handler: { _ in
                let siteRulesController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
                if let siteRules = self.defaults.stringArray(forKey: "SiteRules")  {
                    for rule in siteRules {
                        siteRulesController.addAction(UIAlertAction(title: rule, style: .default, handler: { action in
                            if let reason = action.title {
                                print(reason)
                                self.reportPost(postId: postId, reason: reason)
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
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        present(alertController, animated: true, completion: nil)
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

                var cReplies = [Comment]()
                if let commentReplies = redditComment.replies {
                    cReplies = extractReplies(commentReplies: commentReplies)
                }
                let comment = Comment(author: author, body: body, depth: depth, replies: cReplies, isAuthorPost: false)
                replies.append(comment)
            }
        }

        return replies
    }

    fileprivate func extractComments(data: Data) -> [Comment] {
        var comments = [Comment]()
        do {
            let decoded = try JSONDecoder().decode([RedditCommentResponse].self, from: data)
            for (index, commentResponse) in decoded.enumerated() {
                if index == 0 {
                    // Original post
                    let children = commentResponse.data.children
                    if let child = children.first {
                        guard let authorRedditPost = child.data else {continue}
                        let author = authorRedditPost.author ?? ""
                        let title = authorRedditPost.title ?? ""
                        let depth = authorRedditPost.depth ?? 0
                        
                        var imageSources: [ImageSource]?
                        if let preview = authorRedditPost.preview {
                            if preview.images.count != 0 {
                                imageSources = preview.images.map { image in
                                    let url = image.source.url.replacingOccurrences(of: "amp;", with: "")
                                    return ImageSource(url: url, width: image.source.width, height: image.source.height)
                                }
                            }
                        } else if let mediaData = authorRedditPost.media_metadata {
                            if mediaData.mediaImages.count != 0 {
                                imageSources = mediaData.mediaImages.map { image in
                                    let url = image.url.replacingOccurrences(of: "amp;", with: "")
                                    return ImageSource(url: url, width: image.width, height: image.height)
                                }
                            }
                        }

                        let comment = Comment(author: author, body: title, depth: depth, replies: [Comment](), isAuthorPost: true, imageSources: imageSources)
                        comments.append(comment)
                    }
                } else {
                    let children = commentResponse.data.children
                    for child in children {
                        guard let redditComment = child.data else {continue}
                        let author = redditComment.author ?? ""
                        let body = redditComment.body ?? ""
                        let depth = redditComment.depth ?? 0

                        var replies = [Comment]()
                        if let commentReplies = redditComment.replies {
                            replies = extractReplies(commentReplies: commentReplies)
                        }

                        let comment = Comment(author: author, body: body, depth: depth, replies: replies, isAuthorPost: false)
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
    
    private func reportPost(postId: String, reason: String) {
        RedditClient.sharedInstance.reportPost(postId: postId, reason: reason) { errors in
            if errors.isEmpty {
                print("reported!")
                DispatchQueue.main.async {
                    showToast(controller: self, message: "Reported ✓", seconds: 0.5)
                }
            }
        }
    }
}
