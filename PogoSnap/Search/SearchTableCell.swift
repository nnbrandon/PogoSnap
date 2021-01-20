//
//  SearchTableCell.swift
//  PogoSnap
//
//  Created by Brandon Nguyen on 1/8/21.
//

import UIKit

class SearchTableCell: UITableViewCell {
    
    var index = 0 {
        didSet {
            if index < 2 {
                if traitCollection.userInterfaceStyle == .dark {
                    let image = UIImage(named: "search-7")?.withRenderingMode(.alwaysTemplate)
                    let tintedImage = image?.withTintColor(.white)
                    searchImageView.image = tintedImage
                } else {
                    searchImageView.image = UIImage(named: "search-7")
                }
            } else {
                if traitCollection.userInterfaceStyle == .dark {
                    let image = UIImage(named: "profile_selected")?.withRenderingMode(.alwaysTemplate)
                    let tintedImage = image?.withTintColor(.white)
                    searchImageView.image = tintedImage
                } else {
                    searchImageView.image = UIImage(named: "profile_selected")
                }
            }
        }
    }
    var searchText = "" {
        didSet {
            searchLabel.text = searchText
        }
    }

    let searchImageView: UIImageView = {
        let iv = UIImageView()
        iv.image = UIImage(named: "search-7")
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        return iv
    }()
    let searchLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        return label
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        if traitCollection.userInterfaceStyle == .light {
            backgroundColor = .white
        } else {
            backgroundColor = RedditConsts.redditDarkMode
        }
        
        addSubview(searchImageView)
        searchImageView.translatesAutoresizingMaskIntoConstraints = false
        searchImageView.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        searchImageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12).isActive = true
        searchImageView.heightAnchor.constraint(equalToConstant: 20).isActive = true
        searchImageView.widthAnchor.constraint(equalToConstant: 20).isActive = true
        
        addSubview(searchLabel)
        searchLabel.translatesAutoresizingMaskIntoConstraints = false
        searchLabel.translatesAutoresizingMaskIntoConstraints = false
        searchLabel.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        searchLabel.leadingAnchor.constraint(equalTo: searchImageView.trailingAnchor, constant: 20).isActive = true
        searchLabel.heightAnchor.constraint(equalToConstant: 80).isActive = true
        searchLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8).isActive = true
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
