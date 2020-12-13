//
//  ImgurCell.swift
//  PogoSnap
//
//  Created by Brandon Nguyen on 12/10/20.
//

import UIKit

class ImgurCell: UITableViewCell {
    
    var imageUrlDelete: ImageUrlDelete? {
        didSet {
            if let imageUrlDelete = imageUrlDelete {
                imgurLabel.text = imageUrlDelete.url
                photoImageView.loadImage(urlString: imageUrlDelete.url)
            }
        }
    }
    
    let photoImageView: CustomImageView = {
        let imageView = CustomImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        return imageView
    }()
    let imgurLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 12)
        label.numberOfLines = 0
        label.adjustsFontSizeToFitWidth = true
        return label
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        addSubview(photoImageView)
        photoImageView.translatesAutoresizingMaskIntoConstraints = false
        photoImageView.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        photoImageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12).isActive = true
        photoImageView.heightAnchor.constraint(equalToConstant: 80).isActive = true
        photoImageView.widthAnchor.constraint(equalTo: photoImageView.heightAnchor, multiplier: 16/9).isActive = true

        addSubview(imgurLabel)
        imgurLabel.translatesAutoresizingMaskIntoConstraints = false
        imgurLabel.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        imgurLabel.leadingAnchor.constraint(equalTo: photoImageView.trailingAnchor, constant: 20).isActive = true
        imgurLabel.heightAnchor.constraint(equalToConstant: 80).isActive = true
        imgurLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8).isActive = true
    }
    
    @objc func handleDelete() {    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
