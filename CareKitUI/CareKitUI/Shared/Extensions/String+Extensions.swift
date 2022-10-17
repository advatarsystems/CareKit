//
//  File.swift
//  
//
//  Created by Johan Sellström on 2022-10-17.
//

import Foundation

public extension String {
    
    // FIXME: Can this be simplified?
    // "🔥"
    func subtitle() -> String {
        return String(self.replacingOccurrences(of: " - ", with: ": ").replacingOccurrences(of: "Calories: ", with: "\u{24D4} ").replacingOccurrences(of: "g | ", with: " ").replacingOccurrences(of: "kcal | ", with: " ").replacingOccurrences(of: "Fat: ", with: "\u{24D5} ").replacingOccurrences(of: "Carbs: ", with: "\u{24D2} ").replacingOccurrences(of: "Protein: ", with: "\u{24DF} ").dropLast())
        
        //replacingOccurrences(of: "g", with: "")
    }
}
