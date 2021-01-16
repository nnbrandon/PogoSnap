//
//  GalleryViewModel.swift
//  PogoSnap
//
//  Created by Brandon Nguyen on 1/15/21.
//

import Foundation
import IGListKit

class GalleryViewModel: ListDiffable {

    let photoImageUrl: String?
    
    init(photoImageUrl: String?) {
        self.photoImageUrl = photoImageUrl
    }
    
    func diffIdentifier() -> NSObjectProtocol {
        return "gallery" as NSObjectProtocol
    }
    
    func isEqual(toDiffableObject object: ListDiffable?) -> Bool {
        guard let object = object as? GalleryViewModel else {return false}
        return photoImageUrl == object.photoImageUrl
    }
    
}
