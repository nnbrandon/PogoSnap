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
        return true
    }
}
