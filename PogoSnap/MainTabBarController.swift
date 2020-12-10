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
        view.backgroundColor = .white
        tabBar.barTintColor = .white
        tabBar.isTranslucent = false
        
        setupViewControllers()
    }
    
    private func setupViewControllers() {
        // home icon
        let homeController = HomeController(collectionViewLayout: UICollectionViewFlowLayout())
        homeController.view.backgroundColor = .white
        let homeNavController = UINavigationController(rootViewController: homeController)
        homeNavController.tabBarItem.image = UIImage(named: "home_unselected")
        homeNavController.tabBarItem.selectedImage = UIImage(named: "home_selected")
        
//        // search icon
//        let searchController = SearchController(collectionViewLayout: UICollectionViewFlowLayout())
//        let searchNavController = UINavigationController(rootViewController: searchController)
//        let searchTabBarItem = UITabBarItem(tabBarSystemItem: .search, tag: 1)
//        searchTabBarItem.imageInsets = UIEdgeInsets(top:6,left:0,bottom:-6,right:0)
//        searchTabBarItem.titlePositionAdjustment = UIOffset(horizontal: 0, vertical: 300*20)
//        searchNavController.tabBarItem = searchTabBarItem

        let profileVC = UserProfileController(collectionViewLayout: UICollectionViewFlowLayout())
        let profileNavController = UINavigationController(rootViewController: profileVC)
        profileNavController.tabBarItem.image = UIImage(named: "profile_unselected")
        profileNavController.tabBarItem.selectedImage = UIImage(named: "profile_selected")
        
        tabBar.tintColor = .black
        
        viewControllers = [homeNavController, profileNavController]
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
        }
        if index == 1 {
            if let nav = viewController as? UINavigationController, let profileController = nav.viewControllers[0] as? UserProfileController {
                if profileController.isViewLoaded && (profileController.view.window != nil) && profileController.children.isEmpty {
                    let visibleIndexes = profileController.collectionView.indexPathsForVisibleItems
                    if !visibleIndexes.isEmpty {
                        profileController.collectionView.scrollToItem(at: IndexPath (item: 0, section: 0), at: .bottom, animated: true)
                    }
                }
            }
        }
        return true
    }
}
