//
//  HomeController.swift
//  PogoSnap
//
//  Created by Brandon Nguyen on 11/17/20.
//

import UIKit
import IGListKit
import YPImagePicker

class HomeController: PostsController {
    
    override func viewDidLoad() {
        viewModel = HomeViewModel(redditClient: RedditClient.sharedInstance, imgurClient: ImgurClient.sharedInstance)

        super.viewDidLoad()
        
        pinCollectionView(superview: view)
                
        navigationItem.title = "PogoSnap"
        if traitCollection.userInterfaceStyle == .light {
            let barButton = UIBarButtonItem(image: UIImage(named: "plus_unselected")?.withRenderingMode(.alwaysTemplate), style: .plain, target: self, action: #selector(handleAdd))
            barButton.tintColor = .darkGray
            navigationItem.rightBarButtonItem = barButton
        } else {
            let barButton = UIBarButtonItem(image: UIImage(named: "plus_unselected")?.withRenderingMode(.alwaysTemplate), style: .plain, target: self, action: #selector(handleAdd))
            barButton.tintColor = .white
            navigationItem.rightBarButtonItem = barButton
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        viewModel.checkUserStatus()
        if viewModel.postsIsEmpty() {
            viewModel.fetchRules()
            fetchPosts()
        }
    }
    
    @objc func handleAdd() {
        if RedditClient.sharedInstance.getUsername() == nil {
            DispatchQueue.main.async {
                if let navController = self.navigationController {
                    showErrorToast(controller: navController, message: "You need to sign in to upload an image", seconds: 0.5)
                }
            }
        } else {
            var config = YPImagePickerConfiguration()
            config.screens = [.library]
            config.showsPhotoFilters = false
            config.shouldSaveNewPicturesToAlbum = false
            let picker = YPImagePicker(configuration: config)
            if traitCollection.userInterfaceStyle == .dark {
                picker.navigationBar.barTintColor = RedditConsts.redditDarkMode
                picker.view.backgroundColor = RedditConsts.redditDarkMode
            }
            picker.didFinishPicking { [unowned picker] items, cancelled in
                if cancelled {
                    picker.dismiss(animated: true, completion: nil)
                }
                if let photo = items.singlePhoto {
                    let sharePhotoVC = SharePhotoController()
//                    sharePhotoVC.delegate = self
                    sharePhotoVC.selectedImage = photo.image
                    picker.pushViewController(sharePhotoVC, animated: true)
                }
            }
            present(picker, animated: true, completion: nil)
        }
    }
}


//extension HomeController: ShareDelegate {
//    func imageSubmitted(image: UIImage, title: String) {
//        guard let author = RedditClient.sharedInstance.getUsername() else {return}
//
//        if let navController = self.navigationController {
//            let progressView = navController.view.subviews.last as? UIProgressView
//            progressView?.setProgress(0.5, animated: true)
//
//            ImgurClient.sharedInstance.uploadImageToImgur(image: image) { result in
//                switch result {
//                case .success(let imageSource):
//                    DispatchQueue.main.async {
//                        progressView?.setProgress(0.9, animated: true)
//                    }
//                    guard let imageSource = imageSource else {return}
//                    RedditClient.sharedInstance.submitImageLink(link: imageSource.url, text: title) { result in
//                        DispatchQueue.main.async {
//                            progressView?.setProgress(1.0, animated: true)
//                        }
//                        var message = ""
//                        switch result {
//                        case .success(let postData):
//                            if let postData = postData, let postId = postData.id {
//                                ImgurClient.sharedInstance.incrementUploadCount()
//                                message = "Image upload success"
//                                let commentsLink = "https://www.reddit.com/r/\(RedditConsts.subredditName)/comments/" + postId + ".json"
//                                let aspectFit = imageSource.width >= imageSource.height
//                                let post = Post(author: author, title: title, imageSources: [imageSource], score: 1, numComments: 0, commentsLink: commentsLink, archived: false, id: postId, created_utc: Date().timeIntervalSince1970, liked: true, aspectFit: aspectFit, user_icon: RedditClient.sharedInstance.getIconImg(), subReddit: RedditConsts.subredditName)
//                                self.posts.insert(post, at: 0)
//                                DispatchQueue.main.async {
//                                    if let userNavController = self.tabBarController?.viewControllers?.last as? UINavigationController, let userProfileController = userNavController.viewControllers.first as? UserProfileController {
//                                        userProfileController.posts.insert(post, at: 0)
//                                    }
//                                }
//                            }
//                        case .error:
//                            message = "Image upload failed"
//                        }
//                        DispatchQueue.main.async {
//                            self.collectionView.scrollToItem(at: IndexPath(row: 0, section: 0), at: .top, animated: true)
//                            generatorImpactOccured()
//                            if let navController = self.navigationController {
//                                showImageToast(controller: navController, message: message, image: image, seconds: 10.0)
//                            }
//                            progressView?.setProgress(0, animated: true)
//                        }
//                    }
//
//                case .error(let error):
//                    DispatchQueue.main.async {
//                        progressView?.setProgress(0.0, animated: true)
//                        generatorImpactOccured()
//                        if let navController = self.navigationController {
//                            showErrorToast(controller: navController, message: error, seconds: 10.0)
//                        }
//                    }
//                    return
//                }
//            }
//        }
//    }
//}
