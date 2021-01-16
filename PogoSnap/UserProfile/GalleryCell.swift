//
//  UserProfileCell.swift
//  PogoSnap
//
//  Created by Brandon Nguyen on 11/26/20.
//

import UIKit
import IGListKit

class GalleryCell: UICollectionViewCell, ListBindable {
        
    var photoImageUrl: String! {
        didSet {
            photoImageView.loadImage(urlString: photoImageUrl)
        }
    }
    var index: Int?
    weak var galleryImageDelegate: GalleryImageDelegate?
    
    lazy var photoImageView: CustomImageView = {
        let imageView = CustomImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        
        imageView.isUserInteractionEnabled = true
        let guestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleImage))
        imageView.addGestureRecognizer(guestureRecognizer)
        
        return imageView
    }()
    
    @objc private func handleImage() {
        guard let index = index else {return}
        galleryImageDelegate?.didTapImageGallery(index: index)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        addSubview(photoImageView)
        photoImageView.translatesAutoresizingMaskIntoConstraints = false
        photoImageView.heightAnchor.constraint(equalTo: heightAnchor).isActive = true
        photoImageView.widthAnchor.constraint(equalTo: widthAnchor).isActive = true
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func bindViewModel(_ viewModel: Any) {
        guard let viewModel = viewModel as? GalleryViewModel else {return}
        photoImageUrl = viewModel.photoImageUrl
    }
}
