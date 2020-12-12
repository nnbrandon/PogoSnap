//
//  UploadImageViewController.swift
//  PogoSnapShareExtension
//
//  Created by Brandon Nguyen on 12/6/20.
//

import UIKit

class UploadImageViewController: UIViewController {
    
    var selectedImage: UIImage? {
        didSet {
            photoImageView.image = selectedImage
        }
    }
    var onClose: (() -> Void)?

    let activityIndicatorView: UIActivityIndicatorView = {
        let activityView = UIActivityIndicatorView()
        return activityView
    }()

    let photoImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        return imageView
    }()
    
    let textField: UITextField = {
        let tf = UITextField()
        tf.font = UIFont.systemFont(ofSize: 18)
        tf.placeholder = "Enter title"
        return tf
    }()
    
    let progressView: UIProgressView = {
        let bar = UIProgressView(progressViewStyle: .bar)
        bar.setProgress(0, animated: false)
        return bar
    }()
    
    let closeButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("𝗫", for: .normal)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 20)
        button.setTitleColor(.red, for: .normal)
        button.addTarget(self, action: #selector(handleClose), for: .touchUpInside)
        return button
    }()
    
    let uploadLabel: UILabel = {
        let label = UILabel()
        label.text = "Upload Image"
        label.font = UIFont.boldSystemFont(ofSize: 18)
        return label
    }()
    
    let submitButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Submit", for: .normal)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        button.setTitleColor(.red, for: .normal)
        button.addTarget(self, action: #selector(handleShare), for: .touchUpInside)
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if traitCollection.userInterfaceStyle == .light {
            view.backgroundColor = UIColor(red: 240/255, green: 240/255, blue: 240/255, alpha: 1)
        } else {
            view.backgroundColor = .black
        }
        
        view.addSubview(progressView)
        progressView.translatesAutoresizingMaskIntoConstraints = false
        progressView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        progressView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        progressView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        progressView.heightAnchor.constraint(equalToConstant: 5).isActive = true
        
        view.addSubview(closeButton)
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.topAnchor.constraint(equalTo: progressView.bottomAnchor, constant: 10).isActive = true
        closeButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 8).isActive = true

        view.addSubview(uploadLabel)
        uploadLabel.translatesAutoresizingMaskIntoConstraints = false
        uploadLabel.topAnchor.constraint(equalTo: progressView.bottomAnchor, constant: 16).isActive = true
        uploadLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        
        view.addSubview(submitButton)
        submitButton.translatesAutoresizingMaskIntoConstraints = false
        submitButton.topAnchor.constraint(equalTo: progressView.bottomAnchor, constant: 10).isActive = true
        submitButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -8).isActive = true
        
        view.addSubview(activityIndicatorView)
        activityIndicatorView.translatesAutoresizingMaskIntoConstraints = false
        activityIndicatorView.topAnchor.constraint(equalTo: progressView.bottomAnchor, constant: 12).isActive = true
        activityIndicatorView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24).isActive = true
        
        textField.delegate = self
        textField.becomeFirstResponder()
        setupImageAndTextViews()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        onClose?()
    }
    
    fileprivate func setupImageAndTextViews() {
        let containerView = UIView()
        if traitCollection.userInterfaceStyle == .light {
            containerView.backgroundColor = .white
        } else {
            containerView.backgroundColor = .black
        }
        view.addSubview(containerView)
        
        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.topAnchor.constraint(equalTo: closeButton.bottomAnchor, constant: 30).isActive = true
        containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        containerView.heightAnchor.constraint(equalToConstant: 100).isActive = true
        
        containerView.addSubview(photoImageView)
        photoImageView.translatesAutoresizingMaskIntoConstraints = false
        photoImageView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 8).isActive = true
        photoImageView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -8).isActive = true
        photoImageView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 8).isActive = true
        photoImageView.widthAnchor.constraint(equalToConstant: 84).isActive = true
        
        containerView.addSubview(textField)
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 8).isActive = true
        textField.leadingAnchor.constraint(equalTo: photoImageView.trailingAnchor, constant: 8).isActive = true
        textField.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: 4).isActive = true
    }
    
    @objc func handleClose() {
        DispatchQueue.main.async {
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    @objc func handleShare() {
        print("Sharing photo")
        if let title = textField.text, title.isEmpty {
            showErrorToast(controller: self, message: "Enter a title", seconds: 0.5)
        } else {
            DispatchQueue.main.async {
                self.activityIndicatorView.startAnimating()
                self.submitButton.isHidden = true
            }
            if RedditClient.sharedInstance.getUsername() == nil {
                showErrorToast(controller: self, message: "You need to be signed in to upload a photo", seconds: 1.0)
                submitButton.isHidden = false
            } else {
                if let image = photoImageView.image, let title = textField.text {
                    activityIndicatorView.startAnimating()
                    progressView.setProgress(0.5, animated: true)
                    ImgurClient.sharedInstance.uploadImageToImgur(image: image) { (imageSource, errorOccured) in
                        if errorOccured {
                            DispatchQueue.main.async {
                                self.progressView.setProgress(0.0, animated: true)
                                self.submitButton.isHidden = false
                                self.activityIndicatorView.stopAnimating()
                                showErrorToast(controller: self, message: "Unable to upload image", seconds: 1.0)
                            }
                            return
                        } else {
                            DispatchQueue.main.async {
                                self.progressView.setProgress(0.7, animated: true)
                            }
                        }
                        guard let imageSource = imageSource else {return}
                        RedditClient.sharedInstance.submitImageLink(link: imageSource.url, text: title) { (errors, postData) in
                            if postData != nil {
                                DispatchQueue.main.async {
                                    self.progressView.setProgress(1, animated: true)
                                    generatorImpactOccured()
                                    self.activityIndicatorView.stopAnimating()
                                    showSuccessToastAndDismiss(controller: self, message: "Image upload success", seconds: 0.5)
                                }
                            } else {
                                DispatchQueue.main.async {
                                    self.progressView.setProgress(0, animated: true)
                                    generatorImpactOccured()
                                    self.activityIndicatorView.stopAnimating()
                                    self.submitButton.isHidden = false
                                    showErrorToast(controller: self, message: "Image upload failed", seconds: 1.0)
                                }
                            }
                        }
                    }
                }
            }
        }
    }

}

extension UploadImageViewController: UITextFieldDelegate {
    override var canBecomeFirstResponder: Bool {
        return true
    }

    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        return true
    }
}

