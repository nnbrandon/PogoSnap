//
//  ImgurTableController.swift
//  PogoSnap
//
//  Created by Brandon Nguyen on 12/10/20.
//

import UIKit

class ImgurTableController: UITableViewController {
    
    let cellId = "cellId"
    
    var imgurDeletes = [ImageUrlDelete]() {
        didSet {
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        if traitCollection.userInterfaceStyle == .light {
            view.backgroundColor = .white
        } else {
            view.backgroundColor = .black
        }
        title = "Imgur Uploads"
        tableView.register(ImgurCell.self, forCellReuseIdentifier: cellId)
        tableView.rowHeight = 100

        if let imgurDeletes = ImgurClient.sharedInstance.getImageUrlList() {
            self.imgurDeletes = imgurDeletes
        }
    }
}

extension ImgurTableController {
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return imgurDeletes.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellId) as! ImgurCell
        let imgurDelete = imgurDeletes[indexPath.row]
        
        cell.photoImageView.loadImage(urlString: imgurDelete.url)
        cell.imgurLabel.text = imgurDelete.url
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            generatorImpactOccured()
            let imgurDelete = imgurDeletes[indexPath.row]
            ImgurClient.sharedInstance.deleteImgurPhoto(imageUrlDelete: imgurDelete, imageUrlDeletes: imgurDeletes) { errorOccured in
                if errorOccured {
                    DispatchQueue.main.async {
                        if let navController = self.navigationController {
                            showErrorToast(controller: navController, message: "Failed to delete imgur upload", seconds: 0.5)
                        }
                    }
                } else {
                    generatorImpactOccured()
                    DispatchQueue.main.async {
                        if let navController = self.navigationController {
                            showSuccessToast(controller: navController, message: "Deleted imgur upload", seconds: 0.5)
                        }
                    }
                    self.imgurDeletes.remove(at: indexPath.row)
                }
            }
        }
    }
}
