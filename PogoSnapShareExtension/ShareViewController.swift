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
            if let attachments = item.attachments {
                for itemProvider in attachments {
                    if itemProvider.hasItemConformingToTypeIdentifier(kUTTypeJPEG as String) {
                        itemProvider.loadItem(forTypeIdentifier: kUTTypeJPEG as String) { [unowned self] (imageData, error) in
                            if let url = imageData as? URL, let item = try? Data(contentsOf: url) {
                                let image = UIImage(data: item)
                                DispatchQueue.main.async {
                                    let sharePhotoController = UploadImageViewController()
                                    sharePhotoController.selectedImage = image
                                    sharePhotoController.onClose = self.onClose
                                    self.present(sharePhotoController, animated: true, completion: nil)
                                }
                            } else if let item = imageData as? Data {
                                let image = UIImage(data: item)
                                DispatchQueue.main.async {
                                    let sharePhotoController = UploadImageViewController()
                                    sharePhotoController.selectedImage = image
                                    sharePhotoController.onClose = self.onClose
                                    self.present(sharePhotoController, animated: true, completion: nil)
                                }
                            }
                        }
                    }
                    
                    if itemProvider.hasItemConformingToTypeIdentifier("public.image") {
                        itemProvider.loadItem(forTypeIdentifier: "public.image", options: nil, completionHandler: { (data, error) -> Void in
                            if let image = data as? UIImage {
                                DispatchQueue.main.async {
                                    let sharePhotoController = UploadImageViewController()
                                    sharePhotoController.selectedImage = image
                                    sharePhotoController.onClose = self.onClose
                                    self.present(sharePhotoController, animated: true, completion: nil)
                                }
                            } else if let data = data as? URL {
                                if let imageData = try? Data(contentsOf: data) {
                                    let image = UIImage(data: imageData)
                                    DispatchQueue.main.async {
                                        let sharePhotoController = UploadImageViewController()
                                        sharePhotoController.selectedImage = image
                                        sharePhotoController.onClose = self.onClose
                                        self.present(sharePhotoController, animated: true, completion: nil)
                                    }
                                }
                            }
                        })
                    }
                }
            }
        }
    }
    
    func onClose() {
        self.extensionContext!.completeRequest(returningItems: [], completionHandler: nil)
    }

}
