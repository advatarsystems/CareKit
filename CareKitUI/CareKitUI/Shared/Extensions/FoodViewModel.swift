//
//  File.swift
//  
//
//  Created by Johan Sellström on 2022-08-09.
//

import Foundation
import HealthKit

public struct FoodViewModel: Identifiable {
    
    public let id = UUID()
    public var name: String
    public var score: Double? // can not be computed directly
    public var date: Date
    public var startGlucose: Double
    public let index: Int
    public init(name: String, date: Date = Date(), score: Double? = nil, startGlucose: Double? = nil, index: Int) {
        self.name = name
        self.date = date
        self.score = score
        self.index = index
        if let startGlucose = startGlucose {
            self.startGlucose = startGlucose
        } else { // Figure it out
            self.startGlucose = 5.0
        }
    }
    
    public func getScore() -> Int {
        return 5
    }
    
    static public func get(on date: Date? = nil, unique: Bool = false) -> ([FoodViewModel]) {
        
        var entries = [FoodViewModel]()
        var cache = [String]()
        let foodType = HKCorrelationType.correlationType(forIdentifier: HKCorrelationTypeIdentifier.food)!
        let group = DispatchGroup()

        var predicate: NSPredicate?
        let startDate: Date?
        let endDate: Date?
               
        if let date = date {
            startDate = Calendar.current.startOfDay(for: date)
            let oneday: TimeInterval = 24*60*60
            endDate = startDate?.addingTimeInterval(oneday)
            predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options:[.strictStartDate, .strictEndDate])
        }
        
        let query = HKCorrelationQuery(type: foodType, predicate: predicate, samplePredicates: nil) { query, correlations, error in
            guard let correlations = correlations, error == nil else {
                group.leave()
                return
            }
            for (index,correlation) in correlations.enumerated() {
                let startDate = correlation.startDate
                if let metadata = correlation.metadata, let foodType = metadata[HKMetadataKeyFoodType] as? String {
                    
                    let trimmedAndLowercased = foodType.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                    let entry = FoodViewModel(name: trimmedAndLowercased, date: startDate, score: 1.0, index: index)
                    
                    if unique {
                        if !cache.contains(trimmedAndLowercased) {
                            entries.append(entry)
                            cache.append(trimmedAndLowercased)
                        }
                    } else {
                        entries.append(entry)
                    }
                }
            }
            defer { group.leave() }
            cache = cache.sorted()
            if unique {
                entries = entries.sorted { a, b in
                    return a.name > b.name
                }
            }
        }
        group.enter()
        HKHealthStore().execute(query)
        group.wait()
       //group.wait(timeout: .distantFuture)
        return entries
    }
    
}
