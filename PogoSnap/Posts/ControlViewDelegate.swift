//
//  ControlCellDelegate.swift
//  PogoSnap
//
//  Created by Brandon Nguyen on 1/15/21.
//

import Foundation

protocol ControlViewDelegate: class {
    func didTapVote(direction: Int)
    func didTapComment()
}
