////
////  CommentCell.swift
////  PogoSnap
////
////  Created by Brandon Nguyen on 11/21/20.
////
//
//import UIKit
//
//class OldCommentCell: UICollectionViewCell {
//
//    var comment: Comment? {
//        didSet {
//            if let author = comment?.author, let body = comment?.body, let isAuthorPost = comment?.isAuthorPost {
//                let titleText = NSMutableAttributedString(string: author + " ", attributes: [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 14)])
//                titleText.append(NSAttributedString(string: body, attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 14)]))
//                textLabel.attributedText = titleText
//
//                if isAuthorPost {
//                    let bottomDividerView = UIView()
//                    bottomDividerView.backgroundColor = UIColor.lightGray
//                    addSubview(bottomDividerView)
//                    bottomDividerView.translatesAutoresizingMaskIntoConstraints = false
//                    bottomDividerView.topAnchor.constraint(equalTo: textLabel.bottomAnchor, constant: 10).isActive = true
//                    bottomDividerView.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
//                    bottomDividerView.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
//                    bottomDividerView.heightAnchor.constraint(equalToConstant: 0.5).isActive = true
//                }
//            }
//        }
//    }
//
//    let textLabel: UILabel = {
//        let label = UILabel()
//        label.font = UIFont.systemFont(ofSize: 14)
//        label.numberOfLines = 0
//        return label
//    }()
//
//    override init(frame: CGRect) {
//        super.init(frame: frame)
//        backgroundColor = .white
//
//        addSubview(textLabel)
//        textLabel.translatesAutoresizingMaskIntoConstraints = false
//        textLabel.topAnchor.constraint(equalTo: topAnchor, constant: 6).isActive = true
//        textLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 4).isActive = true
//        textLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -4).isActive = true
//        textLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -4).isActive = true
//    }
//
//    required init?(coder: NSCoder) {
//        fatalError("init(coder:) has not been implemented")
//    }
//}
