//
//  FullScreenImageView.swift
//  PogoSnap
//
//  Created by Brandon Nguyen on 11/27/20.
//

import UIKit

class FullScreenImageController: UIViewController {

    var position = 0 {
        didSet {
            dots.currentPage = position
            let offSet = CGPoint(x: photoImageSlideshow.frame.width * CGFloat(position), y: 0)
            photoImageSlideshow.setContentOffset(offSet, animated: true)
        }
    }

    var imageUrls: [String]? {
        didSet {
            if let imageUrls = imageUrls {
                photoImageSlideshow.imageUrls = imageUrls
                if imageUrls.count > 1 {
                    dots.numberOfPages = imageUrls.count
                } else {
                    dots.isHidden = true
                }
            }
        }
    }
    
    let closeButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("𝗫", for: .normal)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 20)
        button.setTitleColor(.white, for: .normal)
        button.addTarget(self, action: #selector(handleClose), for: .touchUpInside)
        return button
    }()
    
    let dots: UIPageControl = {
        let pageControl = UIPageControl()
        pageControl.currentPage = 0
        pageControl.pageIndicatorTintColor = .lightGray
        pageControl.currentPageIndicatorTintColor = .darkGray
        pageControl.tintColor = .lightGray
        return pageControl
    }()
    
    let photoImageSlideshow: ImageSlideshow = {
        let slideShow = ImageSlideshow(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height))
        slideShow.fitImage = true
        return slideShow
    }()
    
    @objc func handleClose() {
        dismiss(animated: true, completion: nil)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .black
        
        photoImageSlideshow.delegate = self
        view.addSubview(photoImageSlideshow)
        photoImageSlideshow.translatesAutoresizingMaskIntoConstraints = false
        photoImageSlideshow.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        photoImageSlideshow.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        photoImageSlideshow.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        photoImageSlideshow.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        
        view.addSubview(closeButton)
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        closeButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 8).isActive = true
        
        view.addSubview(dots)
        dots.translatesAutoresizingMaskIntoConstraints = false
        dots.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        dots.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -50).isActive = true
    }
}

extension FullScreenImageController: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let pageNumber = round(photoImageSlideshow.contentOffset.x / photoImageSlideshow.frame.size.width)
        dots.currentPage = Int(pageNumber)
    }
}
