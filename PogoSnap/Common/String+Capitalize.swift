//
//  String+Capitalize.swift
//  PogoSnap
//
//  Created by Brandon Nguyen on 12/14/20.
//

import Foundation

extension String {
    func capitalizingFirstLetter() -> String {
      return prefix(1).uppercased() + self.lowercased().dropFirst()
    }

    mutating func capitalizeFirstLetter() {
      self = self.capitalizingFirstLetter()
    }
}
