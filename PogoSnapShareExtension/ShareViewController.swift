//
//  ShareViewController.swift
//  PogoSnapShareExtension
//
//  Created by Brandon Nguyen on 12/5/20.
//

import UIKit
import MobileCoreServices

class ShareViewController: UIViewController {
    
    override func viewDidLoad() {
        if let item = self.extensionContext!.inputItems[0] as? NSExtensionItem {
            if item.attachments != nil {
                                
                for itemProvider in item.attachments! {
                    if itemProvider.hasItemConformingToTypeIdentifier(kUTTypeJPEG as String) {
                        itemProvider.loadItem(forTypeIdentifier: kUTTypeJPEG as String) { [unowned self] (imageData, error) in
                            if let url = imageData as? URL, let item = try? Data(contentsOf: url) {
                                let image = UIImage(data: item)
                                let sharePhotoController = UploadImageViewController()
                                sharePhotoController.selectedImage = image
                                DispatchQueue.main.async {
                                    self.present(sharePhotoController, animated: true, completion: nil)
                                }
                            } else if let item = imageData as? Data {
                                let image = UIImage(data: item)
                                let sharePhotoController = UploadImageViewController()
                                sharePhotoController.selectedImage = image
                                DispatchQueue.main.async {
                                    self.present(sharePhotoController, animated: true, completion: nil)
                                }
                            }
                        }
                    }
                    
                    if itemProvider.hasItemConformingToTypeIdentifier("public.image") {
                        itemProvider.loadItem(forTypeIdentifier: "public.image", options: nil, completionHandler: { (data, error) -> Void in
                            if data is UIImage {
                                let image = data as? UIImage
                                let sharePhotoController = UploadImageViewController()
                                sharePhotoController.selectedImage = image
                                DispatchQueue.main.async {
                                    self.present(sharePhotoController, animated: true, completion: nil)
                                }
                            }
                        })
                    }
                }
            }
        }
    }

}
