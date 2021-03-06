//
//  MainTabBarController.swift
//  PogoSnap
//
//  Created by Brandon Nguyen on 11/15/20.
//

import UIKit
import YPImagePicker

class MainTabBarController: UITabBarController {

    var user: String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        delegate = self
        if traitCollection.userInterfaceStyle == .light {
            tabBar.barTintColor = .white
            tabBar.tintColor = .black
            tabBar.isTranslucent = false
        } else {
            tabBar.barTintColor = RedditConsts.redditDarkMode
            tabBar.tintColor = .white
            tabBar.isTranslucent = false
        }
        
        setupViewControllers()
    }
    
    private func setupViewControllers() {
        // home icon
        let homeController = HomeController()
        homeController.view.backgroundColor = .white
        let homeNavController = UINavigationController(rootViewController: homeController)
        homeNavController.tabBarItem.image = UIImage(named: "home_unselected")
        homeNavController.tabBarItem.selectedImage = UIImage(named: "home_selected")
        
        // search icon
//        let searchController = SearchController()
//        let searchNavController = UINavigationController(rootViewController: searchController)
//        let searchTabBarItem = UITabBarItem(tabBarSystemItem: .search, tag: 1)
//        searchTabBarItem.imageInsets = UIEdgeInsets(top: 6, left: 0, bottom: -6, right: 0)
//        searchTabBarItem.titlePositionAdjustment = UIOffset(horizontal: 0, vertical: 300*20)
//        searchNavController.tabBarItem = searchTabBarItem

        let profileVC = UserProfileController()
        let profileNavController = UINavigationController(rootViewController: profileVC)
        profileNavController.tabBarItem.image = UIImage(named: "profile_unselected")
        profileNavController.tabBarItem.selectedImage = UIImage(named: "profile_selected")
        
        if traitCollection.userInterfaceStyle == .dark {
            homeNavController.navigationBar.barTintColor = RedditConsts.redditDarkMode
            homeNavController.navigationBar.tintColor = .white
            
//            searchNavController.navigationBar.barTintColor = RedditConsts.redditDarkMode
//            searchNavController.navigationBar.tintColor = .white

            profileNavController.navigationBar.barTintColor = RedditConsts.redditDarkMode
            profileNavController.navigationBar.tintColor = .white
        } else {
            homeNavController.navigationBar.tintColor = .black
//            searchNavController.navigationBar.tintColor = .black
            profileNavController.navigationBar.tintColor = .black
        }

//        viewControllers = [homeNavController, searchNavController, profileNavController]
        viewControllers = [homeNavController, profileNavController]
    }
}

extension MainTabBarController: UITabBarControllerDelegate {
    func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {
        let index = viewControllers?.firstIndex(of: viewController)
        if index == 0 {
            if let nav = viewController as? UINavigationController, let homeController = nav.viewControllers[0] as? HomeController {
                if homeController.isViewLoaded && (homeController.view.window != nil) && homeController.children.isEmpty {
                    nav.setNavigationBarHidden(false, animated: true)
                    if let attributes = homeController.collectionView.collectionViewLayout.layoutAttributesForSupplementaryView(ofKind: UICollectionView.elementKindSectionHeader, at: IndexPath(item: 0, section: 0)) {
                        homeController.collectionView.setContentOffset(CGPoint(x: 0, y: attributes.frame.origin.y - homeController.collectionView.contentInset.top), animated: true)
                    }
                }
            }
        }
        if index == 1 {
//            if let nav = viewController as? UINavigationController, let searchController = nav.viewControllers[0] as? SearchController {
//                if searchController.isViewLoaded && (searchController.view.window != nil) && searchController.children.isEmpty {
//                    searchController.searchController.searchBar.becomeFirstResponder()
//                }
//            }
        }
        if index == 2 {
            if let nav = viewController as? UINavigationController, let profileController = nav.viewControllers[0] as? UserProfileController {
                if profileController.isViewLoaded && (profileController.view.window != nil) && profileController.children.isEmpty {
                    let visibleIndexes = profileController.collectionView.indexPathsForVisibleItems
                    if !visibleIndexes.isEmpty {
                        profileController.collectionView.scrollToItem(at: IndexPath(item: 0, section: 0), at: .bottom, animated: true)
                    }
                }
            }
        }
        return true
    }
}
