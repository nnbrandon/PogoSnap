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
        return tf
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if traitCollection.userInterfaceStyle == .light {
            view.backgroundColor = UIColor(red: 240/255, green: 240/255, blue: 240/255, alpha: 1)
            textField.textColor = .black
            textField.backgroundColor = .white
        } else {
            view.backgroundColor = .black
            textField.textColor = .white
            textField.backgroundColor = .black
        }
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Share", style: .plain, target: self, action: #selector(handleShare))
                
        textField.becomeFirstResponder()
        setupImageAndTextViews()
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
        containerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).isActive = true
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
        if let title = textField.text, title.isEmpty {
            DispatchQueue.main.async {
                showErrorToast(controller: self, message: "Enter a title", seconds: 0.5)
            }
        } else {
            navigationItem.rightBarButtonItem?.isEnabled = false
            if let image = photoImageView.image, let title = textField.text {
                delegate?.imageSubmitted(image: image, title: title)
                dismiss(animated: true, completion: nil)
            }
        }
    }
}
