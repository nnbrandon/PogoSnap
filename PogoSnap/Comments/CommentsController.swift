//
//  CommentsController.swift
//  PogoSnap
//
//  Created by Brandon Nguyen on 11/24/20.
//

import UIKit
import Foundation

/// ViewController displaying expandable comments.
open class CommentsController: UITableViewController, UIGestureRecognizerDelegate {

    /// The list of comments correctly displayed in the tableView (in linearized form)
    var linearizedComments: [Comment] = []
    var currentlyDisplayed: [Comment] {
        get {
            return linearizedComments
        } set(value) {
            if fullyExpanded {
                linearizeComments(comments: value, linearizedComments: &linearizedComments)
            } else {
                linearizedComments = value
            }
        }
    }
    
    /// If true, when a cell is expanded, the tableView will scroll to make the new cells visible
    open var makeExpandedCellsVisible: Bool = true
        
    open var fullyExpanded: Bool = false {
        didSet {
            if fullyExpanded {
                self.linearizeCurrentlyDisplayedComs()
            }
        }
    }
        
    override open func viewDidLoad() {
        super.viewDidLoad()
        
        // Tableview style
        tableView.separatorStyle = UITableViewCell.SeparatorStyle.none

        if #available(iOS 11.0, *) {
            tableView.estimatedRowHeight = 0
            tableView.estimatedSectionFooterHeight = 0
            tableView.estimatedSectionHeaderHeight = 0
        } else {
            tableView.rowHeight = UITableView.automaticDimension
            tableView.estimatedRowHeight = 400.0
        }
        
        let longPressGesture: UILongPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(self.handleLongPress))
        longPressGesture.minimumPressDuration = 0.2
        longPressGesture.delegate = self
        tableView.addGestureRecognizer(longPressGesture)
    }
    
    @objc func handleLongPress(_ gestureRecognizer: UILongPressGestureRecognizer) {
        if gestureRecognizer.state == .began {
            let touchPoint = gestureRecognizer.location(in: tableView)
            if let indexPath = tableView.indexPathForRow(at: touchPoint) {
                let selectedCom: Comment = linearizedComments[indexPath.row]
                let selectedIndex = indexPath.row
                
                if !selectedCom.replies.isEmpty { // if expandable
                    if isCellExpanded(indexPath: indexPath) {
                        // collapse
                        var nCellsToDelete = 0
                        repeat {
                            nCellsToDelete += 1
                        } while (linearizedComments.count > selectedIndex+nCellsToDelete+1 && linearizedComments[selectedIndex+nCellsToDelete+1].depth > selectedCom.depth)
                        
                        linearizedComments.removeSubrange(Range(uncheckedBounds: (lower: selectedIndex+1, upper: selectedIndex+nCellsToDelete+1)))
                        var indexPaths: [IndexPath] = []
                        for index in 0..<nCellsToDelete {
                            indexPaths.append(IndexPath(row: selectedIndex+index+1, section: indexPath.section))
                        }
                        tableView.deleteRows(at: indexPaths, with: .bottom)
                    } else {
                        // expand
                        var toShow: [Comment] = []
                        if fullyExpanded {
                            linearizeComments(comments: selectedCom.replies, linearizedComments: &toShow)
                        } else {
                            toShow = selectedCom.replies
                        }
                        linearizedComments.insert(contentsOf: toShow, at: selectedIndex+1)
                        var indexPaths: [IndexPath] = []
                        for index in 0..<toShow.count {
                            indexPaths.append(IndexPath(row: selectedIndex+index+1, section: indexPath.section))
                        }
                        tableView.insertRows(at: indexPaths, with: .bottom)
                        
                        if makeExpandedCellsVisible {
                            tableView.scrollToRow(at: IndexPath(row: selectedIndex+1, section: indexPath.section), at: UITableView.ScrollPosition.middle, animated: false)
                        }
                    }
                }
            }
        }
    }
    
    /**
     Helper function that takes a list of root comments and turn it in
     a linearized list of all the root + children comments.
     - Parameters:
         - comments: The input, nested, list of comments
         - linearizedComments: a reference to the list that will contain the comments
         - sort: a function that is applied recursively on each sub-list of comments
     */
    func linearizeComments(comments: [Comment], linearizedComments: inout [Comment]) {
        for comm in comments {
            let containsComment = linearizedComments.contains { (comment) -> Bool in
                if comment == comm {
                    return true
                } else {
                    return false
                }
            }
            if !containsComment {
                linearizedComments.append(comm)
            }
            linearizeComments(comments: comm.replies, linearizedComments: &linearizedComments)
        }
    }
    
    func addReply(reply: Comment, parentCommentId: String) {
        var index = 0
        for (idx, comment) in linearizedComments.enumerated() where comment.id == parentCommentId {
            index = idx + 1
        }
        linearizedComments.insert(reply, at: index)
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }
    
    func addMoreReplies(moreReplies: [Comment]) {
        guard let parentId = moreReplies.first?.parent_id else {return}
        var index = 0
        for (idx, comment) in linearizedComments.enumerated() {
            if let commentParentId = comment.parent_id, comment.children != nil, commentParentId == parentId {
                index = idx
            }
        }
        var replaced = false
        for reply in moreReplies {
            if replaced {
                linearizedComments.insert(reply, at: index)
            } else {
                linearizedComments[index] = reply
                replaced = true
            }
            index += 1
        }
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }

    func removeComment(commentId: String) {
        if let index = linearizedComments.firstIndex(where: { comment -> Bool in comment.id == commentId}) {
            linearizedComments[index].author = "[deleted]"
            linearizedComments[index].body = "[deleted]"
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
    }

    /// Linearize the comments in _currentlyDisplayed.
    public func linearizeCurrentlyDisplayedComs() {
        var linearizedComs: [Comment] = []
        linearizeComments(comments: linearizedComments, linearizedComments: &linearizedComs)
        linearizedComments = linearizedComs
    }
    
    override open func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return currentlyDisplayed.count
    }
    
    override open func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    override open func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    override open func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedCom: Comment = linearizedComments[indexPath.row]
        let selectedIndex = indexPath.row

        if !selectedCom.replies.isEmpty { // if expandable
            if !isCellExpanded(indexPath: indexPath) {
                // expand
                var toShow: [Comment] = []
                if fullyExpanded {
                    linearizeComments(comments: selectedCom.replies, linearizedComments: &toShow)
                } else {
                    toShow = selectedCom.replies
                }
                linearizedComments.insert(contentsOf: toShow, at: selectedIndex+1)
                var indexPaths: [IndexPath] = []
                for index in 0..<toShow.count {
                    indexPaths.append(IndexPath(row: selectedIndex+index+1, section: indexPath.section))
                }
                tableView.insertRows(at: indexPaths, with: .bottom)

                if makeExpandedCellsVisible {
                    tableView.scrollToRow(at: IndexPath(row: selectedIndex+1, section: indexPath.section), at: UITableView.ScrollPosition.middle, animated: false)
                }
            }
        }
    }
    
    open override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let comment = currentlyDisplayed[indexPath.row]
        let commentCell = commentsView(tableView, commentCellForModel: comment, atIndexPath: indexPath)
        return commentCell
    }
    
    func commentsView(_ tableView: UITableView, commentCellForModel commentModel: Comment, atIndexPath indexPath: IndexPath) -> CommentCell {
        return CommentCell()
    }
    
    open func isCellExpanded(indexPath: IndexPath) -> Bool {
        let com: Comment = linearizedComments[indexPath.row]
        return linearizedComments.count > indexPath.row+1 &&  // if not last cell
            linearizedComments[indexPath.row+1].depth > com.depth // if replies are displayed
    }
}
