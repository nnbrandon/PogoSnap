//
//  GeneratorImpact.swift
//  PogoSnap
//
//  Created by Brandon Nguyen on 12/7/20.
//

import UIKit

let generator = UIImpactFeedbackGenerator(style: .heavy)
func generatorImpactOccured() {
    generator.impactOccurred()
}
