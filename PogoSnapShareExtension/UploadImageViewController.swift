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
    
    let textView: UITextView = {
        let tv = UITextView()
        tv.backgroundColor = .white
        tv.textColor = UIColor.black
        tv.font = UIFont.systemFont(ofSize: 14)
        return tv
    }()
    
    let shareButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Share", for: .normal)
        button.addTarget(self, action: #selector(handleShare), for: .touchUpInside)
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(red: 240/255, green: 240/255, blue: 240/255, alpha: 1)
                
        view.addSubview(activityIndicatorView)
        activityIndicatorView.translatesAutoresizingMaskIntoConstraints = false
        activityIndicatorView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        activityIndicatorView.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        
        view.addSubview(shareButton)
        shareButton.translatesAutoresizingMaskIntoConstraints = false
        shareButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        shareButton.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        
        setupImageAndTextViews()
    }
    
    fileprivate func setupImageAndTextViews() {
        let containerView = UIView()
        containerView.backgroundColor = .white
        view.addSubview(containerView)
        
        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        containerView.heightAnchor.constraint(equalToConstant: 100).isActive = true
        
        containerView.addSubview(photoImageView)
        photoImageView.translatesAutoresizingMaskIntoConstraints = false
        photoImageView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 8).isActive = true
        photoImageView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -8).isActive = true
        photoImageView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 8).isActive = true
        photoImageView.widthAnchor.constraint(equalToConstant: 84).isActive = true
        
        containerView.addSubview(textView)
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.topAnchor.constraint(equalTo: containerView.topAnchor).isActive = true
        textView.leadingAnchor.constraint(equalTo: photoImageView.trailingAnchor).isActive = true
        textView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: 4).isActive = true
        textView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor).isActive = true
    }
    
    @objc func handleShare() {
        print("Sharing photo")
        navigationItem.rightBarButtonItem?.isEnabled = false
        if let image = photoImageView.image, let title = textView.text {
            activityIndicatorView.startAnimating()
            ImgurClient.uploadImageToImgur(image: image) { (imageSource, imageUrlDelete) in
                RedditClient.sharedInstance.submitImageLink(link: imageSource.url, text: title) { (errors, postData) in
                    var message = ""
                    if let _ = postData {
                        message = "Image upload success ✓"
                    } else {
                        message = "Image upload failed 𝗫"
                    }
                    DispatchQueue.main.async {
                        self.activityIndicatorView.stopAnimating()
                        showToast(controller: self, message: message, seconds: 1.0, dismissAfter: true)
                    }
                }
            }
        }
    }

}