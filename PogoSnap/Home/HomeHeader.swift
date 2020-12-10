//
//  HomeHeaderCell.swift
//  PogoSnap
//
//  Created by Brandon Nguyen on 12/9/20.
//

import UIKit

enum SortOptions: String {
    case new
    case best
    case hot
}

enum ListLayoutOptions: String {
    case card
    case gallery
}

class HomeHeader: UICollectionViewCell {
    
    var sortOption: SortOptions? {
        didSet {
            if let sortOption = sortOption {
                switch sortOption {
                case .best:
                    sortButton.setTitle(" Best Posts", for: .normal)
                    sortButton.setImage(UIImage(named: "best-20")?.withRenderingMode(.alwaysTemplate), for: .normal)
                case .new:
                    sortButton.setTitle(" New Posts", for: .normal)
                    sortButton.setImage(UIImage(named: "new-20")?.withRenderingMode(.alwaysTemplate), for: .normal)
                case .hot:
                    sortButton.setTitle(" Hot Posts", for: .normal)
                    sortButton.setImage(UIImage(named: "hot-20")?.withRenderingMode(.alwaysTemplate), for: .normal)
                }
            }
        }
    }
    var listLayoutOption: ListLayoutOptions? {
        didSet {
            if let listLayoutOption = listLayoutOption {
                switch listLayoutOption {
                case .card:
                    listLayoutButton.setImage(UIImage(named: "card-20")?.withRenderingMode(.alwaysTemplate), for: .normal)
                case .gallery:
                    listLayoutButton.setImage(UIImage(named: "gallery-20")?.withRenderingMode(.alwaysTemplate), for: .normal)
                }
            }
        }
    }
    var changeSort: (() -> Void)?
    var changeLayout: (() -> Void)?
    
    lazy var sortButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle(" Hot Posts", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 12, weight: .semibold)
        button.setTitleColor(RedditConstants.controlsColor, for: .normal)
        button.setImage(UIImage(named: "hot-20")?.withRenderingMode(.alwaysTemplate), for: .normal)
        button.tintColor = .gray
        button.addTarget(self, action: #selector(handleSort), for: .touchUpInside)
        return button
    }()
    
    lazy var listLayoutButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(named: "card-20")?.withRenderingMode(.alwaysTemplate), for: .normal)
        button.tintColor = .gray
        button.addTarget(self, action: #selector(handleList), for: .touchUpInside)
        return button
    }()

    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        addSubview(sortButton)
        sortButton.translatesAutoresizingMaskIntoConstraints = false
        sortButton.topAnchor.constraint(equalTo: topAnchor, constant: 8).isActive = true
        sortButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8).isActive = true
        
        addSubview(listLayoutButton)
        listLayoutButton.translatesAutoresizingMaskIntoConstraints = false
        listLayoutButton.topAnchor.constraint(equalTo: topAnchor, constant: 8).isActive = true
        listLayoutButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8).isActive = true
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc func handleSort() {
        changeSort?()
    }
    
    @objc func handleList() {
        changeLayout?()
    }
}