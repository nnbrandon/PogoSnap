//
//  ImageSlideshow.swift
//  PogoSnap
//
//  Created by Brandon Nguyen on 11/27/20.
//

import UIKit

class ImageSlideshow: UIScrollView {
    
    var imageSources: [ImageSource]? {
        didSet {
            if let imageSources = imageSources {
                for (index, imageSource) in imageSources.enumerated() {
                    let xPosition = UIScreen.main.bounds.width * CGFloat(index)
                    let imageView = CustomImageView(frame: CGRect(x: xPosition, y: 0, width: frame.width, height: frame.height))
                    if fitImage {
                        imageView.contentMode = .scaleAspectFit
                    } else {
                        if imageSource.width > imageSource.height {
                            imageView.contentMode = .scaleAspectFit
                        } else {
                            imageView.contentMode = .scaleAspectFill
                        }
                    }
                    imageView.clipsToBounds = true
                    imageView.loadImage(urlString: imageSource.url)
                    contentSize.width = frame.width * CGFloat(index + 1)
                    addSubview(imageView)
                }
            }
        }
    }
    var fitImage = false

    override init(frame: CGRect) {
        super.init(frame: frame)
        
        isPagingEnabled = true
        showsVerticalScrollIndicator = false
        showsHorizontalScrollIndicator = false
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
