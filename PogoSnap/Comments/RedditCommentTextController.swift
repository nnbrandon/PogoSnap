//
//  RedditCommentTextController.swift
//  PogoSnap
//
//  Created by Brandon Nguyen on 12/8/20.
//

import UIKit

class RedditCommentTextController: UIViewController {
    
    var post: Post?
    var updateComments: ((Comment, String?) -> Void)?
    var parentCommentId: String?
    var parentDepth: Int?
    var parentCommentContent: String? {
        didSet {
            if let parentCommentContent = parentCommentContent {
                parentContentLabel.text = parentCommentContent
            }
        }
    }
    var parentCommentAuthor: String? {
        didSet {
            if let parentCommentAuthor = parentCommentAuthor {
                usernameLabel.text = "u/\(parentCommentAuthor)"
            }
        }
    }
    
    let closeButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("𝗫", for: .normal)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 20)
        button.setTitleColor(.red, for: .normal)
        button.addTarget(self, action: #selector(handleClose), for: .touchUpInside)
        return button
    }()
    
    let commentLabel: UILabel = {
        let label = UILabel()
        label.text = "Comment"
        label.font = UIFont.boldSystemFont(ofSize: 18)
        return label
    }()
    
    let submitButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Submit", for: .normal)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        button.setTitleColor(.red, for: .normal)
        button.addTarget(self, action: #selector(handleSubmit), for: .touchUpInside)
        return button
    }()
    
    let commentTextField: UITextView = {
        let textField = UITextView()
        textField.font = UIFont.systemFont(ofSize: 18)
        textField.text = "Write Comment"
        textField.textColor = .lightGray
        textField.selectedRange = NSRange(location: 0, length: 0)
        return textField
    }()
    
    let usernameLabel: UILabel = {
        let lbl = UILabel()
        lbl.textColor = .gray
        lbl.font = RedditConstants.metadataFont
        lbl.textAlignment = .left
        return lbl
    }()
    
    let parentContentLabel: UILabel = {
        let lbl = UILabel()
        lbl.lineBreakMode = .byWordWrapping
        lbl.font = RedditConstants.textFont
        lbl.numberOfLines = 0
        lbl.textAlignment = .left
        return lbl
    }()
    
    let activityIndicatorView: UIActivityIndicatorView = {
        let activityView = UIActivityIndicatorView()
        return activityView
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        if traitCollection.userInterfaceStyle == .light {
            view.backgroundColor = .white
            commentTextField.backgroundColor = .white
        } else {
            view.backgroundColor = UIColor(red: 26/255, green: 26/255, blue: 27/255, alpha: 1)
            commentTextField.backgroundColor = UIColor(red: 26/255, green: 26/255, blue: 27/255, alpha: 1)
        }
        commentTextField.delegate = self
        commentTextField.becomeFirstResponder()
                
        view.addSubview(closeButton)
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.topAnchor.constraint(equalTo: view.topAnchor, constant: 10).isActive = true
        closeButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 8).isActive = true

        view.addSubview(commentLabel)
        commentLabel.translatesAutoresizingMaskIntoConstraints = false
        commentLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: 16).isActive = true
        commentLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        
        view.addSubview(submitButton)
        submitButton.translatesAutoresizingMaskIntoConstraints = false
        submitButton.topAnchor.constraint(equalTo: view.topAnchor, constant: 10).isActive = true
        submitButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -8).isActive = true
        
        view.addSubview(activityIndicatorView)
        activityIndicatorView.translatesAutoresizingMaskIntoConstraints = false
        activityIndicatorView.topAnchor.constraint(equalTo: view.topAnchor, constant: 12).isActive = true
        activityIndicatorView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24).isActive = true

        view.addSubview(commentTextField)
        commentTextField.translatesAutoresizingMaskIntoConstraints = false
        commentTextField.topAnchor.constraint(equalTo: submitButton.topAnchor, constant: 90).isActive = true
        commentTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 8).isActive = true
        commentTextField.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        commentTextField.heightAnchor.constraint(equalToConstant: 160).isActive = true
        
        view.addSubview(usernameLabel)
        usernameLabel.translatesAutoresizingMaskIntoConstraints = false
        usernameLabel.topAnchor.constraint(equalTo: commentTextField.bottomAnchor, constant: 50).isActive = true
        usernameLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 8).isActive = true
        
        view.addSubview(parentContentLabel)
        parentContentLabel.translatesAutoresizingMaskIntoConstraints = false
        parentContentLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 8).isActive = true
        parentContentLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -8).isActive = true
        parentContentLabel.topAnchor.constraint(equalTo: usernameLabel.bottomAnchor, constant: 8).isActive = true
    }
    
    @objc func handleClose() {
        dismiss(animated: true, completion: nil)
    }
    
    @objc func handleSubmit() {
        let authenticated = RedditClient.sharedInstance.isUserAuthenticated()
        if !authenticated {
            DispatchQueue.main.async {
                showErrorToast(controller: self, message: "You need to be signed in to comment", seconds: 1.0)
            }
        } else if commentTextField.text == "Write Comment" {
            DispatchQueue.main.async {
                showErrorToast(controller: self, message: "Enter a comment", seconds: 1.0)
            }
        } else {
            if let username = RedditClient.sharedInstance.getUsername(), let body = commentTextField.text, let post = post {
                let postId = post.id
                DispatchQueue.main.async {
                    self.activityIndicatorView.startAnimating()
                    self.submitButton.isHidden = true
                }
                var parentId = "t3_\(postId)"
                if let parentCommentId = parentCommentId {
                    parentId = "t1_\(parentCommentId)"
                }
                RedditClient.sharedInstance.postComment(parentId: parentId, text: body) { (errorOccured, commentId) in
                    if !errorOccured {
                        var depth = 0
                        if let parentDepth = self.parentDepth {
                            depth = parentDepth + 1
                        }
                        let comment = Comment(author: username, body: body, depth: depth, replies: [Comment](), id: commentId ?? "", isAuthorPost: false, created_utc: Date().timeIntervalSince1970)
                        self.updateComments?(comment, self.parentCommentId)
                        generatorImpactOccured()
                        DispatchQueue.main.async {
                            self.dismiss(animated: true, completion: nil)
                        }
                    } else {
                        generatorImpactOccured()
                        DispatchQueue.main.async {
                            self.activityIndicatorView.stopAnimating()
                            self.submitButton.isHidden = false
                            showErrorToast(controller: self, message: "Unable to post comment", seconds: 0.5)
                        }
                    }
                }
            }
        }
    }
}

extension RedditCommentTextController: UITextViewDelegate {
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if text.isEmpty {
            let updatedText = (textView.text as NSString).replacingCharacters(in: range, with: text)
            if updatedText.isEmpty {
                textView.text = "Write Comment"
                textView.textColor = .lightGray
                textView.selectedRange = NSRange(location: 0, length: 0)
            }
        } else {
            if textView.text == "Write Comment" {
                textView.text = ""
            }
            if traitCollection.userInterfaceStyle == .light {
                textView.textColor = .black
            } else {
                textView.textColor = .white
            }
        }
        return true
    }
}
