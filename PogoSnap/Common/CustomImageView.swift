//
//  CustomImageView.swift
//  PogoSnap
//
//  Created by Brandon Nguyen on 11/17/20.
//

import UIKit

var cache = NSCache<NSString, UIImage>()

class CustomImageView: UIImageView {
    
    var lastURLUsedToLoadImage: String?
    
    func loadImage(urlString: String) {
        backgroundColor = .lightGray
        lastURLUsedToLoadImage = urlString
        
        if let cachedImage = cache.object(forKey: NSString(string: urlString)) {
            self.image = cachedImage
            return
        }
        
        guard let url = URL(string: urlString) else { return }
        
        URLSession.shared.dataTask(with: url) { (data, response, err) in
            if let err = err {
                print("Failed to fetch post image:", err)
                return
            }
            
            if url.absoluteString != self.lastURLUsedToLoadImage {
                return
            }
            
            guard let imageData = data else { return }
            
            let photoImage = UIImage(data: imageData)
            
            cache.setObject(photoImage!, forKey: NSString(string: urlString))
            
            DispatchQueue.main.async {
                self.image = photoImage
            }
            
            }.resume()
    }
}
