//
//  SharePhotoController.swift
//  PogoSnap
//
//  Created by Brandon Nguyen on 11/17/20.
//

import UIKit

protocol ShareDelegate: class {
    func imageSubmitted(image: UIImage, title: String)
}

class SharePhotoController: UIViewController {
    
    var selectedImage: UIImage? {
        didSet {
            photoImageView.image = selectedImage
        }
    }
    
    weak var delegate: ShareDelegate?

    let photoImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        return imageView
    }()
    
    let textField: UITextView = {
        let tf = UITextView()
        tf.font = UIFont.systemFont(ofSize: 18)
        tf.text = "Write Title"
        tf.textColor = .lightGray
        tf.selectedRange = NSRange(location: 0, length: 0)
        return tf
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if traitCollection.userInterfaceStyle == .light {
            view.backgroundColor = UIColor(red: 240/255, green: 240/255, blue: 240/255, alpha: 1)
            textField.backgroundColor = .white
        } else {
            view.backgroundColor = UIColor(red: 26/255, green: 26/255, blue: 27/255, alpha: 1)
            textField.backgroundColor = UIColor(red: 26/255, green: 26/255, blue: 27/255, alpha: 1)
        }
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Share", style: .plain, target: self, action: #selector(handleShare))
                
        textField.delegate = self
        textField.becomeFirstResponder()
        setupImageAndTextViews()
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    fileprivate func setupImageAndTextViews() {
        let containerView = UIView()
        if traitCollection.userInterfaceStyle == .light {
            containerView.backgroundColor = .white
        } else {
            containerView.backgroundColor = UIColor(red: 26/255, green: 26/255, blue: 27/255, alpha: 1)
        }
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
        
        containerView.addSubview(textField)
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.topAnchor.constraint(equalTo: containerView.topAnchor).isActive = true
        textField.leadingAnchor.constraint(equalTo: photoImageView.trailingAnchor, constant: 8).isActive = true
        textField.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: 4).isActive = true
        textField.heightAnchor.constraint(equalToConstant: 80).isActive = true
    }
    
    @objc func handleShare() {
        if let title = textField.text, title.isEmpty || title == "Write Title" {
            DispatchQueue.main.async {
                showErrorToast(controller: self, message: "Enter a title", seconds: 0.5)
            }
        } else {
            if !ImgurClient.sharedInstance.canUpload() {
                DispatchQueue.main.async {
                    showErrorToast(controller: self, message: "You've reached the maximum number of uploads for today (3)", seconds: 2.0)
                }
                return
            } else {
                navigationItem.rightBarButtonItem?.isEnabled = false
                if let image = photoImageView.image, let title = textField.text {
                    delegate?.imageSubmitted(image: image, title: title)
                    dismiss(animated: true, completion: nil)
                }
            }
        }
    }
}

extension SharePhotoController: UITextViewDelegate {
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if text.isEmpty {
            let updatedText = (textView.text as NSString).replacingCharacters(in: range, with: text)
            if updatedText.isEmpty {
                textView.text = "Write Title"
                textView.textColor = .lightGray
                textView.selectedRange = NSRange(location: 0, length: 0)
            }
        } else {
            if textView.text == "Write Title" {
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
