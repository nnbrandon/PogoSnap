//
//  ControlPost.swift
//  PogoSnap
//
//  Created by Brandon Nguyen on 11/17/20.
//

import UIKit
import IGListKit

class ControlCell: UICollectionViewCell, ListBindable {

    let controlView = ControlView()
    weak var controlViewDelegate: ControlViewDelegate?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(controlView)
        controlView.translatesAutoresizingMaskIntoConstraints = false
        controlView.topAnchor.constraint(equalTo: topAnchor).isActive = true
        controlView.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        controlView.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        controlView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func bindViewModel(_ viewModel: Any) {
        guard let viewModel = viewModel as? ControlViewModel else {return}
        controlView.controlViewModel = viewModel
        controlView.controlViewDelegate = controlViewDelegate
    }
}
