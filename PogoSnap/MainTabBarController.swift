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
            tabBar.barTintColor = UIColor(red: 26/255, green: 26/255, blue: 27/255, alpha: 1)
            tabBar.tintColor = .white
            tabBar.isTranslucent = false
        }
        
        setupViewControllers()
    }
    
    private func setupViewControllers() {
        // home icon
        let homeController = HomeController(collectionViewLayout: UICollectionViewFlowLayout())
        homeController.view.backgroundColor = .white
        let homeNavController = UINavigationController(rootViewController: homeController)
        homeNavController.tabBarItem.image = UIImage(named: "home_unselected")
        homeNavController.tabBarItem.selectedImage = UIImage(named: "home_selected")

        let profileVC = UserProfileController(collectionViewLayout: UICollectionViewFlowLayout())
        let profileNavController = UINavigationController(rootViewController: profileVC)
        profileNavController.tabBarItem.image = UIImage(named: "profile_unselected")
        profileNavController.tabBarItem.selectedImage = UIImage(named: "profile_selected")
        
        if traitCollection.userInterfaceStyle == .dark {
            homeNavController.navigationBar.barTintColor = UIColor(red: 26/255, green: 26/255, blue: 27/255, alpha: 1)
            homeNavController.navigationBar.tintColor = .white

            profileNavController.navigationBar.barTintColor = UIColor(red: 26/255, green: 26/255, blue: 27/255, alpha: 1)
            profileNavController.navigationBar.tintColor = .white
        } else {
            homeNavController.navigationBar.tintColor = .black
            profileNavController.navigationBar.tintColor = .black
        }

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
                        homeController.collectionView.scrollToItem(at: IndexPath(item: 0, section: 0), at: .bottom, animated: true)
                    }
                }
            }
        }
        if index == 1 {
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
