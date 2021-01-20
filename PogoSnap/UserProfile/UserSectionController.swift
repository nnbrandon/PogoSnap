//
//  UserSectionController.swift
//  PogoSnap
//
//  Created by Brandon Nguyen on 1/9/21.
//

import UIKit
import IGListKit

class UserSectionController: ListSectionController {
    var user: User!
    var userHeaderDarkMode = false

    func supportedElementKinds() -> [String] {
        return []
    }
    
    override func sizeForItem(at index: Int) -> CGSize {
        return CGSize(width: UIScreen.main.bounds.width, height: 200)
    }
    
    override func cellForItem(at index: Int) -> UICollectionViewCell {
        guard let header = collectionContext?.dequeueReusableCell(of: UserProfileHeader.self, for: self, at: index) as? UserProfileHeader else {
            fatalError()
        }
        header.darkMode = userHeaderDarkMode
        header.username = user.username
        header.icon_img = user.user_icon
        return header
    }
        
    override func didUpdate(to object: Any) {
        user = object as? User
    }
}
