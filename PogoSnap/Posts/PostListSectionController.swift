//
//  PostListSectionController.swift
//  PogoSnap
//
//  Created by Brandon Nguyen on 1/9/21.
//

import UIKit
import IGListKit

class PostListSectionController: ListBindingSectionController<ListDiffable>,
                                 ListBindingSectionControllerDataSource, ListSupplementaryViewSource {
    // MARK: State
    var sort: SortOptions!
    var topOption: String?
    var listLayoutOption: ListLayoutOptions!
    var authenticated: Bool = false
    var localLikeCount: Int?
    var localLiked: Bool?

    weak var homeHeaderDelegate: HomeHeaderDelegate?
    weak var basePostsDelegate: BasePostsDelegate?
    
    override init() {
        super.init()
        supplementaryViewSource = self
        dataSource = self
    }

    func supportedElementKinds() -> [String] {
        return [UICollectionView.elementKindSectionHeader]
    }

    func viewForSupplementaryElement(ofKind elementKind: String, at index: Int) -> UICollectionReusableView {
        if section == 0 && elementKind == UICollectionView.elementKindSectionHeader {
            guard let header = collectionContext?.dequeueReusableSupplementaryView(ofKind: elementKind, for: self, class: HomeHeader.self, at: index) as? HomeHeader else {
                fatalError()
            }
            header.sortOption = sort
            if let topOption = topOption {
                header.topOption = TopOptions(rawValue: topOption)
            }
            header.listLayoutOption = listLayoutOption
            header.delegate = homeHeaderDelegate
            return header
        }
        return UICollectionReusableView()
    }

    func sizeForSupplementaryView(ofKind elementKind: String, at index: Int) -> CGSize {
        if section == 0, elementKind == UICollectionView.elementKindSectionHeader {
            return CGSize(width: UIScreen.main.bounds.width, height: 35)
        }
        return CGSize(width: 0, height: 0)
    }
    
    func sectionController(_ sectionController: ListBindingSectionController<ListDiffable>, viewModelsFor object: Any) -> [ListDiffable] {
        guard let post = object as? Post else {fatalError()}
        let results: [ListDiffable] = [
          PostViewModel(post: post, index: section, authenticated: RedditService.sharedInstance.isUserAuthenticated()),
            ControlViewModel(likeCount: localLikeCount ?? post.score, commentCount: post.numComments, liked: localLiked ?? post.liked, authenticated: RedditService.sharedInstance.isUserAuthenticated()),
            GalleryViewModel(photoImageUrl: post.imageSources.first?.url)
        ]
        return results
    }
    
    func sectionController(_ sectionController: ListBindingSectionController<ListDiffable>, cellForViewModel viewModel: Any, at index: Int) -> UICollectionViewCell & ListBindable {
        switch listLayoutOption {
        case .card:
            if viewModel is PostViewModel {
                guard let cell = collectionContext!.dequeueReusableCell(of: PostViewCell.self, for: self, at: index) as? PostViewCell else {
                    fatalError()
                }
                cell.postViewDelegate = self
                cell.basePostsDelegate = basePostsDelegate
                return cell
            } else if viewModel is ControlViewModel {
                guard let cell = collectionContext!.dequeueReusableCell(of: ControlCell.self, for: self, at: index) as? ControlCell else {
                    fatalError()
                }
                cell.controlViewDelegate = self
                return cell
            }
            guard let cell = collectionContext!.dequeueReusableCell(of: PostViewCell.self, for: self, at: index) as? PostViewCell else {
                fatalError()
            }
            return cell
        case .gallery:
            guard let cell = collectionContext!.dequeueReusableCell(of: GalleryCell.self, for: self, at: index) as? GalleryCell else {
                fatalError()
            }
            cell.controlViewDelegate = self
            return cell
        case .none:
            fatalError()
        }
    }
    
    func sectionController(_ sectionController: ListBindingSectionController<ListDiffable>, sizeForViewModel viewModel: Any, at index: Int) -> CGSize {
        let width = UIScreen.main.bounds.width
        switch listLayoutOption {
        case .card:
            if let postViewModel = viewModel as? PostViewModel {
                var imageFrameHeight = width
                if !postViewModel.aspectFit {
                    imageFrameHeight += width/2
                }
                var height = 8 + 30 + imageFrameHeight
                let title = postViewModel.titleText
                let titleEstimatedHeight = title.height(withConstrainedWidth: width - 16, font: UIFont.boldSystemFont(ofSize: 16))
                height += titleEstimatedHeight
                return CGSize(width: width, height: height)
            } else if viewModel is ControlViewModel {
                return CGSize(width: width, height: 50)
            }
        case .gallery:
            if viewModel is GalleryViewModel {
                let newWidth = (width - 2) / 3
                return CGSize(width: newWidth, height: newWidth)
            }
        case .none:
            fatalError()
        }
        return CGSize(width: 0, height: 0)
    }
}

extension PostListSectionController: PostViewDelegate {
    func didTapUsername(username: String, userIconURL: String?) {
        let userProfileController = UserProfileController()
        userProfileController.usernameProp = username
        userProfileController.icon_imgProp = userIconURL
        viewController?.navigationController?.pushViewController(userProfileController, animated: true)
    }
    
    func didTapImage(imageSources: [ImageSource], position: Int) {
        let fullScreen = FullScreenImageController()
        fullScreen.imageSources = imageSources
        fullScreen.position = position
        viewController?.present(fullScreen, animated: true, completion: nil)
    }
}

extension PostListSectionController: ControlViewDelegate {
    func didTapVote(direction: Int) {
        if !authenticated {
            guard let navController = viewController?.navigationController else { return }
            showErrorToast(controller: navController, message: "You need to be signed in to vote", seconds: 2.0)
            return
        }
        guard let post = object as? Post else {return}
        if direction == 0 {
            if let liked = localLiked ?? post.liked {
                if liked {
                    localLiked = nil
                    localLikeCount = (localLikeCount ?? post.score) - 1
                } else {
                    localLiked = nil
                    localLikeCount = (localLikeCount ?? post.score) + 1
                }
            }
        } else if direction == 1 {
            localLiked = true
            localLikeCount = (localLikeCount ?? post.score) + 1
        } else {
            localLiked = false
            localLikeCount = (localLikeCount ?? post.score) - 1
        }
        RedditService.sharedInstance.votePost(subReddit: post.subReddit, postId: post.id, direction: direction) {_ in }
        update(animated: true, completion: nil)
    }
    
    func didTapComment() {
        guard let post = object as? Post else {return}
        let width = UIScreen.main.bounds.width
        var imageFrameHeight = width
        if !post.aspectFit {
            imageFrameHeight += width/2
        }
        var height = 8 + 30 + 50 + imageFrameHeight
        let title = post.title
        let titleEstimatedHeight = title.height(withConstrainedWidth: width - 16, font: UIFont.boldSystemFont(ofSize: 16))
        height += titleEstimatedHeight

        let redditCommentsController = RedditCommentsController()
        redditCommentsController.hidesBottomBarWhenPushed = true
        redditCommentsController.commentsLink = post.commentsLink
        redditCommentsController.archived = post.archived
        let postViewModel = PostViewModel(post: post, index: section, authenticated: authenticated)
        let controlViewModel = ControlViewModel(likeCount: localLikeCount ?? post.score, commentCount: post.numComments, liked: localLiked ?? post.liked, authenticated: authenticated)
        redditCommentsController.postViewModel = postViewModel
        redditCommentsController.controlViewModel = controlViewModel
        redditCommentsController.postControlView.frame = CGRect(x: 0, y: 0, width: width, height: height)
        redditCommentsController.postViewDelegate = self
        redditCommentsController.controlViewDelegate = self
        redditCommentsController.basePostDelegate = basePostsDelegate
        viewController?.navigationController?.pushViewController(redditCommentsController, animated: true)
    }
}
