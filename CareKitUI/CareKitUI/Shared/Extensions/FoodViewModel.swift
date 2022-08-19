//
//  File.swift
//  
//
//  Created by Johan Sellström on 2022-08-09.
//

import Foundation
import HealthKit

public struct FoodViewModel: Identifiable, Equatable {
    
    private let healthStore = HKHealthStore()
    public let id = UUID()
    public let energyUUID: UUID? // Can be used to update via delete
    public var name: String
    public var score: Double? // can not be computed directly
    public var date: Date
    public var startGlucose: Double
    public var endGlucose: Double?
    public var glucosePeak: Double?
    public var glucoseDelta: Double?
    public var timeToBaseline: Double?

    public let index: Int
    
    static public func == (lhs: FoodViewModel, rhs: FoodViewModel) -> Bool {
        return lhs.name == rhs.name && lhs.date == rhs.date && lhs.score == rhs.score
    }
    
    public init(name: String, date: Date = Date(), score: Double? = nil, startGlucose: Double = 0.0, endGlucose: Double? = nil, glucosePeak: Double? = nil, glucoseDelta: Double? = nil, timeToBaseline: Double? = nil, index: Int, energyUUID: UUID? = nil) {
        self.name = name
        self.date = date
        self.score = score
        self.index = index
        
        self.startGlucose = startGlucose
        self.endGlucose = endGlucose

        self.glucosePeak = glucosePeak
        self.glucoseDelta = glucoseDelta
        
        self.timeToBaseline = timeToBaseline
        self.energyUUID = energyUUID
    }
    
    public func getScore() -> Int {
        return 5
    }
    
    public func update(with score: Double, startGlucose: Double, endGlucose: Double, glucosePeak: Double, glucoseDelta: Double, timeToBaseline: Double?) {
        
        print("FOODSCORE: update score \(score) startGlucose \(startGlucose) endGlucose \(endGlucose) glucosePeak \(glucosePeak) glucoseDelta \(glucoseDelta) timeToBaseline \(timeToBaseline)")
        
        //let newModel = FoodViewModel(name: self.name, date: self.date, score: score, startGlucose: startGlucose, glucosePeak: glucosePeak, glucoseDelta: glucoseDelta, index: self.index)
        
        let metadata: Dictionary<String, String> = [
            HKMetadataKeyFoodType: self.name,
            "HKMetadataKeyFoodScore": String(score),
            "HKMetadataKeyFoodStart": String(startGlucose),
            "HKMetadataKeyFoodEnd": String(endGlucose),
            "HKMetadataKeyFoodPeak": String(glucosePeak),
            "HKMetadataKeyFoodDelta": String(glucoseDelta),
            "HKMetadataKeyFoodTimeToBase": timeToBaseline != nil ? String(timeToBaseline!): ""
        ]
        
        let energyQuantityConsumed = HKQuantity(unit: HKUnit.joule(), doubleValue: 0.0)
        let energyConsumedType = HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.dietaryEnergyConsumed)!
        let energyConsumedSample = HKQuantitySample(type: energyConsumedType, quantity: energyQuantityConsumed, start: self.date, end: self.date, metadata: metadata)
        let energyConsumedSamples: Set<HKSample> = [energyConsumedSample]
        let foodType = HKCorrelationType.correlationType(forIdentifier: HKCorrelationTypeIdentifier.food)!
        let energyType = HKObjectType.quantityType(forIdentifier: .dietaryEnergyConsumed)!

        let foodCorrelation = HKCorrelation(type: foodType, start: self.date, end: self.date, objects: energyConsumedSamples, metadata: metadata)
        print("FOODSCORE: foodCorrelation \(foodCorrelation)")
        
        
        healthStore.save(foodCorrelation) { (success, error) in
            if let error = error {
                print("FOODSCORE: update \(error)")
            } else {
                print("FOODSCORE: update Saved \(foodCorrelation.metadata)")
               // Now delete the previous sample
                if let uuid = self.energyUUID {
                    let predicate = HKQuery.predicateForObject(with: uuid)
                    let query = HKSampleQuery(sampleType: energyType, predicate: predicate, limit: 0, sortDescriptors: nil) { query, samples, error in
                        if let samples = samples, !samples.isEmpty {
                            self.healthStore.delete(samples) { success, error in
                                if let error = error {
                                    print("FOODSCORE: update fail \(error)")
                                } else {
                                    print("FOODSCORE: update deleted \(samples.count) samples")
                                }
                            }
                        } else {
                            print("FOODSCORE: update no samples found")
                        }
                    }
                    healthStore.execute(query)
                } else {
                    print("FOODSCORE: self.energyUUID \(self.energyUUID)")

                }
            }
        }
        
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
        return entries
    }
    
}
