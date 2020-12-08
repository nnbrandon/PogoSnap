//
//  MainTabBarController.swift
//  PogoSnap
//
//  Created by Brandon Nguyen on 11/15/20.
//

import UIKit
import YPImagePicker

class MainTabBarController: UITabBarController, ShareDelegate {

    var user: String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        delegate = self
        view.backgroundColor = .white
        
        setupViewControllers()
    }
    
    private func setupViewControllers() {
        // home icon
        let homeController = HomeController(collectionViewLayout: UICollectionViewFlowLayout())
        homeController.view.backgroundColor = .white
        let homeNavController = UINavigationController(rootViewController: homeController)
        homeNavController.tabBarItem.image = UIImage(named: "home_unselected")
        homeNavController.tabBarItem.selectedImage = UIImage(named: "home_selected")
        
        // plus icon
        let plusController = UIViewController()
        plusController.view.backgroundColor = .white
        let plusNavController = UINavigationController(rootViewController: plusController)
        plusNavController.tabBarItem.image = UIImage(named: "plus_unselected")
        plusNavController.tabBarItem.selectedImage = UIImage(named: "plus_unselected")

        let profileVC = UserProfileController(collectionViewLayout: UICollectionViewFlowLayout())
        let profileNavController = UINavigationController(rootViewController: profileVC)
        profileNavController.tabBarItem.image = UIImage(named: "profile_unselected")
        profileNavController.tabBarItem.selectedImage = UIImage(named: "profile_selected")
        
        tabBar.tintColor = .black
        
        viewControllers = [homeNavController, plusNavController, profileNavController]
    }
    
    func imageSubmitted(image: UIImage, title: String) {
        // Add image to home and user profile controllers since it takes Reddit about 30 seconds
        // to show on user feed
        guard let author = RedditClient.sharedInstance.getUsername() else {return}

        selectedIndex = 0
        DispatchQueue.main.async {
            if let viewControllers = self.viewControllers, let homeNavController = viewControllers.first as? UINavigationController, let userNavController = viewControllers.last as? UINavigationController, let homeController = homeNavController.viewControllers[0] as? HomeController, let userController = userNavController.viewControllers[0] as? UserProfileController {
                
                let progressView = homeNavController.view.subviews.last as? UIProgressView
                progressView?.setProgress(0.5, animated: true)
                
                ImgurClient.uploadImageToImgur(image: image) { (imageSource, imageUrlDelete) in
                    DispatchQueue.main.async {
                        progressView?.setProgress(0.9, animated: true)
                    }
                    RedditClient.sharedInstance.submitImageLink(link: imageSource.url, text: title) { (errors, postData) in
                        DispatchQueue.main.async {
                            progressView?.setProgress(1.0, animated: true)
                        }
                        var message = "Image upload failed 𝗫"
                        if let postData = postData, let commentsLink = postData.url, let postId = postData.id {
                            message = "Image upload success ✓"
                            let post = Post(author: author, title: title, imageSources: [imageSource], score: 1, numComments: 0, commentsLink: commentsLink, archived: false, id: postId)
                            homeController.posts.insert(post, at: 0)
                            userController.posts.insert(post, at: 0)
                        }
                        DispatchQueue.main.async {
                            generatorImpactOccured()
                            showToast(controller: self, message: message, seconds: 1.0, dismissAfter: false)
                            progressView?.setProgress(0, animated: true)
                        }
                    }
                }
            }
        }
    }
    
}

extension MainTabBarController: UITabBarControllerDelegate {
    func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {
        let index = viewControllers?.firstIndex(of: viewController)
        if index == 0 {
            if let nav = viewController as? UINavigationController, let homeController = nav.viewControllers[0] as? HomeController {
                if homeController.isViewLoaded && (homeController.view.window != nil) && homeController.children.isEmpty {
                    let visibleIndexes = homeController.collectionView.indexPathsForVisibleItems
                    if !visibleIndexes.isEmpty {
                        homeController.collectionView.scrollToItem(at: IndexPath (item: 0, section: 0), at: .bottom, animated: true)
                    }
                }
            }
        } else if index == 1 {
            var config = YPImagePickerConfiguration()
            config.screens = [.library]
            config.shouldSaveNewPicturesToAlbum = false
            let picker = YPImagePicker(configuration: config)
            picker.didFinishPicking { [unowned picker] items, cancelled in
                if cancelled {
                    picker.dismiss(animated: true, completion: nil)
                }
                if let photo = items.singlePhoto {
                    let sharePhotoVC = SharePhotoController()
                    sharePhotoVC.delegate = self
                    sharePhotoVC.selectedImage = photo.image
                    picker.pushViewController(sharePhotoVC, animated: true)
                }
            }
            present(picker, animated: true, completion: nil)
            return false
        }
        return true
    }
}
