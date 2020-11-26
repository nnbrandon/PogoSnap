////
////  CommentsController.swift
////  PogoSnap
////
////  Created by Brandon Nguyen on 11/20/20.
////
//
//import UIKit
//
//class CommentsController: UICollectionViewController, UICollectionViewDelegateFlowLayout {
//
//    var commentsLink: String?
//
//    var comments = [Comment]() {
//        didSet {
//            DispatchQueue.main.async {
//                self.collectionView.reloadData()
//            }
//        }
//    }
//
//    let cellId = "cellId"
//
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        navigationItem.title = "Comments"
//
//        collectionView.backgroundColor = .white
//        collectionView.register(CommentCell.self, forCellWithReuseIdentifier: cellId)
//        collectionView.alwaysBounceVertical = true
//        collectionView.keyboardDismissMode = .interactive
//
//        fetchComments()
//    }
//
//    let commentTextField: UITextField = {
//        let textField = UITextField()
//        textField.placeholder = "Enter Comment"
//        return textField
//    }()
//
//    lazy var containerView: UIView = {
//        let containerview = UIView()
//        containerview.backgroundColor = .white
//        containerview.frame = CGRect(x: 0, y: 0, width: 100, height: 75)
//
//
//        let submitButton = UIButton(type: .system)
//        submitButton.setTitle("Submit", for: .normal)
//        submitButton.setTitleColor(.black, for: .normal)
//        submitButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 14)
//        submitButton.addTarget(self, action: #selector(handleSubmit), for: .touchUpInside)
//
//        containerview.addSubview(submitButton)
//        submitButton.translatesAutoresizingMaskIntoConstraints = false
//        submitButton.topAnchor.constraint(equalTo: containerview.topAnchor).isActive = true
//        submitButton.trailingAnchor.constraint(equalTo: containerview.trailingAnchor, constant: -20).isActive = true
//        submitButton.bottomAnchor.constraint(equalTo: containerview.bottomAnchor).isActive = true
//        submitButton.widthAnchor.constraint(equalToConstant: 50).isActive = true
//
//        containerview.addSubview(commentTextField)
//        commentTextField.translatesAutoresizingMaskIntoConstraints = false
//        commentTextField.topAnchor.constraint(equalTo: containerview.topAnchor).isActive = true
//        commentTextField.leadingAnchor.constraint(equalTo: containerview.leadingAnchor, constant: 20).isActive = true
//        commentTextField.trailingAnchor.constraint(equalTo: submitButton.leadingAnchor).isActive = true
//        commentTextField.bottomAnchor.constraint(equalTo: containerview.bottomAnchor).isActive = true
//
//        let topDividerView = UIView()
//        topDividerView.backgroundColor = UIColor.lightGray
//        containerview.addSubview(topDividerView)
//        topDividerView.translatesAutoresizingMaskIntoConstraints = false
//        topDividerView.topAnchor.constraint(equalTo: commentTextField.topAnchor).isActive = true
//        topDividerView.leadingAnchor.constraint(equalTo: containerview.leadingAnchor).isActive = true
//        topDividerView.trailingAnchor.constraint(equalTo: containerview.trailingAnchor).isActive = true
//        topDividerView.heightAnchor.constraint(equalToConstant: 0.5).isActive = true
//
//        return containerview
//    }()
//
//
//    override var inputAccessoryView: UIView? {
//        get {
//            return containerView
//        }
//    }
//
//    override var canBecomeFirstResponder: Bool {
//        return true
//    }
//
//    @objc func handleSubmit() {
//        print("handle submit: ", commentTextField.text ?? "")
//    }
//
//    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
//        return comments.count
//    }
//
//    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
//        let frame = CGRect(x: 0, y: 0, width: view.frame.width, height: 50)
//        let dummyCell = CommentCell(frame: frame)
//        dummyCell.comment = comments[indexPath.row]
//        dummyCell.layoutIfNeeded()
//
//        let targetSize = CGSize(width: view.frame.width, height: 1000)
//        let estimatedSize = dummyCell.systemLayoutSizeFitting(targetSize)
//
//        let height = max(8 + 8 + 10, estimatedSize.height)
//        return CGSize(width: view.frame.width, height: height)
//    }
//
//    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
//        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellId, for: indexPath) as! CommentCell
//        let comment = comments[indexPath.row]
//        cell.comment = comment
//
//        return cell
//    }
//
//    fileprivate func extractReplies(commentReplies: Reply) -> [Comment] {
//        var replies = [Comment]()
//
//        switch commentReplies {
//        case .string( _):
//            break
//        case .redditCommentResponse(let commentResponse):
//            let children = commentResponse.data.children
//            for child in children {
//                guard let redditComment = child.data else {break}
//                let author = redditComment.author ?? ""
//                let body = redditComment.body ?? ""
//                let depth = redditComment.depth ?? 0
//
//                var cReplies = [Comment]()
//                if let commentReplies = redditComment.replies {
//                    cReplies = extractReplies(commentReplies: commentReplies)
//                }
//                let comment = Comment(author: author, body: body, depth: depth, replies: cReplies, isAuthorPost: false)
//                replies.append(comment)
//            }
//        }
//
//        return replies
//    }
//
//    fileprivate func extractComments(data: Data) -> [Comment] {
//        var comments = [Comment]()
//        do {
//            let decoded = try JSONDecoder().decode([RedditCommentResponse].self, from: data)
//            for (index, commentResponse) in decoded.enumerated() {
//                if index == 0 {
//                    // Original post
//                    let children = commentResponse.data.children
//                    if let child = children.first {
//                        guard let authorRedditPost = child.data else {continue}
//                        let author = authorRedditPost.author ?? ""
//                        let title = authorRedditPost.title ?? ""
//                        let depth = authorRedditPost.depth ?? 0
//
//                        let comment = Comment(author: author, body: title, depth: depth, replies: [Comment](), isAuthorPost: true)
//                        comments.append(comment)
//                    }
//                } else {
//                    let children = commentResponse.data.children
//                    for child in children {
//                        guard let redditComment = child.data else {continue}
//                        let author = redditComment.author ?? ""
//                        let body = redditComment.body ?? ""
//                        let depth = redditComment.depth ?? 0
//
//                        var replies = [Comment]()
//                        if let commentReplies = redditComment.replies {
//                            replies = extractReplies(commentReplies: commentReplies)
//                        }
//
//                        let comment = Comment(author: author, body: body, depth: depth, replies: replies, isAuthorPost: false)
//                        print(comment)
//                        comments.append(comment)
//                    }
//                }
//            }
//        } catch {print(error)}
//        return comments
//    }
//
//    fileprivate func fetchComments() {
//        if let commentsLink = commentsLink, let url = URL(string: commentsLink) {
//                URLSession.shared.dataTask(with: url) { data, response, error in
//                    if let data = data {
//                        let comments = self.extractComments(data: data)
//                        self.comments = comments
//                    }
//                }.resume()
//        }
//    }
//}
