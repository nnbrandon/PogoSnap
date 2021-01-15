//
//  PostListSectionController.swift
//  PogoSnap
//
//  Created by Brandon Nguyen on 1/9/21.
//

import UIKit
import IGListKit

class PostListSectionController: ListBindingSectionController<Post>,
                                 ListBindingSectionControllerDataSource, ListSupplementaryViewSource, ControlViewDelegate {
    // MARK: State
    var sort: SortOptions!
    var topOption: String?
    var listLayoutOption: ListLayoutOptions!
    var localLikeCount: Int?
    var localLiked: Bool?
    
    weak var postViewDelegate: PostViewDelegate?
    weak var homeHeaderDelegate: HomeHeaderDelegate?
    weak var profileImageDelegate: ProfileImageDelegate?
    
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
          PostViewModel(post: post, index: section, authenticated: RedditClient.sharedInstance.isUserAuthenticated()),
            ControlViewModel(likeCount: localLikeCount ?? post.score, commentCount: post.numComments, liked: localLiked ?? post.liked, authenticated: RedditClient.sharedInstance.isUserAuthenticated())
        ]
        return results
    }
    
    func sectionController(_ sectionController: ListBindingSectionController<ListDiffable>, cellForViewModel viewModel: Any, at index: Int) -> UICollectionViewCell & ListBindable {
//        switch listLayoutOption {
//        case .card:
        if viewModel is PostViewModel {
            guard let cell = collectionContext!.dequeueReusableCell(of: HomePostCell.self, for: self, at: index) as? HomePostCell else {
                fatalError()
            }
            return cell
        } else if viewModel is ControlViewModel {
            guard let cell = collectionContext!.dequeueReusableCell(of: ControlCell.self, for: self, at: index) as? ControlCell else {
                fatalError()
            }
            cell.controlViewDelegate = self
            return cell
        }
        guard let cell = collectionContext!.dequeueReusableCell(of: HomePostCell.self, for: self, at: index) as? HomePostCell else {
            fatalError()
        }
        return cell
//        case .gallery:
//            guard let cell = collectionContext!.dequeueReusableCell(of: UserProfileCell.self, for: self, at: index) as? UserProfileCell
//            else {
//                fatalError()
//            }
//            cell.photoImageView.image = UIImage()
//            cell.post = post
//            cell.index = section
//            cell.delegate = profileImageDelegate
//            return cell
//        case .none:
//            fatalError()
//        }
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
//                var height = 8 + 50 + 40 + imageFrameHeight
                var height = 8 + 40 + imageFrameHeight
                let title = postViewModel.titleText
                let titleEstimatedHeight = title.height(withConstrainedWidth: width - 16, font: UIFont.boldSystemFont(ofSize: 16))
                height += titleEstimatedHeight
                return CGSize(width: width, height: height)
            } else if viewModel is ControlViewModel {
                return CGSize(width: width, height: 50)
            }
        case .gallery:
            let newWidth = (width - 2) / 3
            return CGSize(width: newWidth, height: newWidth)
        case .none:
            fatalError()
        }
        return CGSize(width: 0, height: 0)
    }
    
    func didTapVote(direction: Int) {
        if direction == 0 {
            if let liked = localLiked ?? object?.liked {
                if liked {
                    localLiked = nil
                    localLikeCount = (localLikeCount ?? object?.score ?? 0) - 1
                } else {
                    localLiked = nil
                    localLikeCount = (localLikeCount ?? object?.score ?? 0) + 1
                }
            }
        } else if direction == 1 {
            localLiked = true
            localLikeCount = (localLikeCount ?? object?.score ?? 0) + 1
        } else {
            localLiked = false
            localLikeCount = (localLikeCount ?? object?.score ?? 0) - 1
        }
        update(animated: true, completion: nil)
    }
}
