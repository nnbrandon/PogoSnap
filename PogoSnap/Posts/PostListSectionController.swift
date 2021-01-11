//
//  PostListSectionController.swift
//  PogoSnap
//
//  Created by Brandon Nguyen on 1/9/21.
//

import UIKit
import IGListKit

class PostListSectionController: ListSectionController, ListSupplementaryViewSource {
    var post: Post!
    var sort: SortOptions!
    var topOption: String?
    var listLayoutOption: ListLayoutOptions!
    
    var showUserHeader = false
    var userHeaderDarkMode = false
    var username: String?
    var icon_img: String?
    
    weak var postViewDelegate: PostViewDelegate?
    weak var homeHeaderDelegate: HomeHeaderDelegate?
    weak var profileImageDelegate: ProfileImageDelegate?
    
    override init() {
        super.init()
        supplementaryViewSource = self
    }

    func supportedElementKinds() -> [String] {
        return [UICollectionView.elementKindSectionHeader, UICollectionView.elementKindSectionFooter]
    }

    func viewForSupplementaryElement(ofKind elementKind: String, at index: Int) -> UICollectionReusableView {
        if section == 0 && elementKind == UICollectionView.elementKindSectionHeader {
            if showUserHeader {
                guard let header = collectionContext?.dequeueReusableSupplementaryView(ofKind: elementKind, for: self, class: UserProfileHeader.self, at: index) as? UserProfileHeader else {
                    fatalError()
                }
                header.darkMode = userHeaderDarkMode
                header.username = username
                header.icon_img = icon_img
                return header
            } else {
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
        }
        return UICollectionReusableView()
    }

    func sizeForSupplementaryView(ofKind elementKind: String, at index: Int) -> CGSize {
        if section == 0, elementKind == UICollectionView.elementKindSectionHeader {
            if showUserHeader {
                return CGSize(width: UIScreen.main.bounds.width, height: 200)
            } else {
                return CGSize(width: UIScreen.main.bounds.width, height: 35)
            }
        }
        return CGSize(width: 0, height: 0)
    }
    
    override func sizeForItem(at index: Int) -> CGSize {
        let width = UIScreen.main.bounds.width
        switch listLayoutOption {
        case .card:
            var imageFrameHeight = width
            if !post.aspectFit {
                imageFrameHeight += width/2
            }
            var height = 8 + 50 + 40 + imageFrameHeight
            let title = post.title
            let titleEstimatedHeight = title.height(withConstrainedWidth: width - 16, font: UIFont.boldSystemFont(ofSize: 16))
            height += titleEstimatedHeight
            return CGSize(width: width, height: height)
        case .gallery:
            let newWidth = (width - 2) / 3
            return CGSize(width: newWidth, height: newWidth)
        case .none:
            fatalError()
        }
    }
    
    override func cellForItem(at index: Int) -> UICollectionViewCell {
        switch listLayoutOption {
        case .card:
            guard let cell = collectionContext!.dequeueReusableCell(of: HomePostCell.self, for: self, at: index) as? HomePostCell else {
                fatalError()
            }
            cell.post = post
            cell.index = section
            cell.delegate = postViewDelegate
            return cell
        case .gallery:
            guard let cell = collectionContext!.dequeueReusableCell(of: UserProfileCell.self, for: self, at: index) as? UserProfileCell
            else {
                fatalError()
            }
            cell.photoImageView.image = UIImage()
            cell.post = post
            cell.index = section
            cell.delegate = profileImageDelegate
            return cell
        case .none:
            fatalError()
        }
    }
        
    override func didUpdate(to object: Any) {
        post = object as? Post
    }
}
