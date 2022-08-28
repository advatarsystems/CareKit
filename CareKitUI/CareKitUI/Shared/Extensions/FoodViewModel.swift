//
//  File.swift
//  
//
//  Created by Johan Sellström on 2022-08-09.
//

import Foundation
import HealthKit

public struct Metadata {
    let value: [String:String]
    func toValues() -> (Double, Double) {
        return (1.0,2.0)
    }
}

enum OCKFoodViewModelError: Error, LocalizedError {

    case missing(_ item: String)
 
    var errorDescription: String? {
        switch self {
        case .missing(let item): return "Missing item \(item)"
        }
    }
}

public struct FoodViewModel: Identifiable, Equatable {
    
    private let healthStore = HKHealthStore()
    public var id = UUID()
    public var name: String
    public var score: Double? // can not be computed directly
    public var date: Date
    public var startGlucose: Double
    public var endGlucose: Double?
    public var glucosePeak: Double?
    public var glucoseDelta: Double?
    public var timeToBaseline: Double?
    public var glucoseAverage: Double?
    public var glucoseVariability: Double?
    public var timeInRange: Double?

    public var index: Int
    
    static public func == (lhs: FoodViewModel, rhs: FoodViewModel) -> Bool {
        return lhs.name == rhs.name && lhs.date == rhs.date && lhs.score == rhs.score
    }
    
    public init(uuidString: String? = nil , name: String, date: Date = Date(), score: Double? = nil, startGlucose: Double = 0.0, endGlucose: Double? = nil, glucosePeak: Double? = nil, glucoseDelta: Double? = nil, timeToBaseline: Double? = nil, glucoseAverage: Double? = nil, glucoseVariability: Double? = nil, timeInRange: Double? = nil, index: Int) {
        
        if let uuidString = uuidString, let uuid = UUID(uuidString: uuidString) {
            id = uuid
        }
        
        self.name = name
        self.date = date
        self.score = score
        self.index = index
        
        self.startGlucose = startGlucose
        self.endGlucose = endGlucose

        self.glucosePeak = glucosePeak
        self.glucoseDelta = glucoseDelta
        
        self.timeToBaseline = timeToBaseline
        self.glucoseAverage = glucoseAverage
        self.glucoseVariability = glucoseVariability
        self.timeInRange = timeInRange
        
    }
    
    public init(_ date: Date, metadata: [[String:Any]], startGlucose: Double = 0.0, endGlucose: Double? = nil, index: Int)  throws {
        
        var name: String?
        var score: Double?
        var glucosePeak: Double?
        var glucoseDelta: Double?
        var timeToBaseline: Double?
        var glucoseAverage: Double?
        var glucoseVariability: Double?
        var timeInRange: Double?
        
        var id: UUID?

        for metadataItem in metadata {
            
            if let nameString = metadataItem[HKMetadataKeyFoodType] as? String {
                name = nameString.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            }
            
            if let scoreString = metadataItem["HKMetadataKeyFoodScore"] as? String {
                score = Double(scoreString)?.roundToPlaces(places: 0)
            }
            
            if let glucosePeakString = metadataItem["HKMetadataKeyFoodPeak"] as? String {
                glucosePeak = Double(glucosePeakString)?.roundToPlaces(places: 0)
            }
            
            if let glucoseDeltaString = metadataItem["HKMetadataKeyFoodDelta"] as? String {
                glucoseDelta = Double(glucoseDeltaString)?.roundToPlaces(places: 0)
            }
            
            if let timeToBaselineString = metadataItem["HKMetadataKeyFoodTimeToBase"] as? String {
                timeToBaseline = Double(timeToBaselineString)?.roundToPlaces(places: 0)
            }
            
            if let average = metadataItem["HKMetadataKeyFoodAverage"] as? String {
                glucoseAverage = Double(average)?.roundToPlaces(places: 0)
            }
  
            if let variability = metadataItem["HKMetadataKeyFoodVariability"] as? String {
                glucoseVariability = Double(variability)?.roundToPlaces(places: 0)
            }
 
            if let inRange = metadataItem["HKMetadataKeyFoodInRange"] as? String {
                timeInRange = Double(inRange)?.roundToPlaces(places: 0)
            }

            if let idString = metadataItem[HKMetadataKeyExternalUUID] as? String {
                id = UUID(uuidString: idString)
            }
        }
        
        if let name = name {
            self.init(name: name, date: date, index: index)
        } else {
            throw OCKFoodViewModelError.missing("name")
        }
        if let uuid = id {
            self.id = uuid
        } else {
            self.id = UUID()
        }
        self.score = score
        self.glucosePeak = glucosePeak
        self.glucoseDelta = glucoseDelta
        self.timeToBaseline = timeToBaseline
        self.glucoseAverage = glucoseAverage
        self.glucoseVariability = glucoseVariability
        self.timeInRange = timeInRange
        self.index = index
        self.startGlucose = startGlucose
        self.endGlucose = endGlucose
        self.date = date
        
    }
    
    public func getScore() -> Int {
        return 5
    }
    
    public func update(with score: Double, startGlucose: Double, endGlucose: Double, glucosePeak: Double, glucoseDelta: Double, timeToBaseline: Double?, glucoseAverage:  Double, glucoseVariability: Double, timeInRange: Double) {
        
        print("FOODSCORE: update score \(score) startGlucose \(startGlucose) endGlucose \(endGlucose) glucosePeak \(glucosePeak) glucoseDelta \(glucoseDelta) timeToBaseline \(String(describing: timeToBaseline))")
        
        //let newModel = FoodViewModel(name: self.name, date: self.date, score: score, startGlucose: startGlucose, glucosePeak: glucosePeak, glucoseDelta: glucoseDelta, index: self.index)
        
        let metadata: Dictionary<String, String> = [
            HKMetadataKeyFoodType: self.name,
            HKMetadataKeyExternalUUID: UUID().uuidString, // Make it a new one so we can delete the old
            "HKMetadataKeyFoodScore": String(score),
            "HKMetadataKeyFoodStart": String(startGlucose),
            "HKMetadataKeyFoodEnd": String(endGlucose),
            "HKMetadataKeyFoodPeak": String(glucosePeak),
            "HKMetadataKeyFoodDelta": String(glucoseDelta),
            "HKMetadataKeyFoodTimeToBase": timeToBaseline != nil ? String(timeToBaseline!): "",
            "HKMetadataKeyFoodAverage": String(glucoseAverage),
            "HKMetadataKeyFoodVariability": String(glucoseVariability),
            "HKMetadataKeyFoodInRange": String(timeInRange)
        ]
        
        let energyQuantityConsumed = HKQuantity(unit: HKUnit.joule(), doubleValue: 0.0)
        let energyConsumedType = HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.dietaryEnergyConsumed)!
        let energyConsumedSample = HKQuantitySample(type: energyConsumedType, quantity: energyQuantityConsumed, start: self.date, end: self.date, metadata: metadata)
        //let energyConsumedSamples: Set<HKSample> = [energyConsumedSample]
        
        //let foodType = HKCorrelationType.correlationType(forIdentifier: HKCorrelationTypeIdentifier.food)!
        //let foodCorrelation = HKCorrelation(type: foodType, start: self.date, end: self.date, objects: energyConsumedSamples, metadata: metadata)
        
        //print("FOODSCORE: foodCorrelation \(foodCorrelation)")
        
        healthStore.save(energyConsumedSample) { (success, error) in
            if let error = error {
                print("FOODSCORE: update \(error)")
            } else {
                print("ADDFOOD: update Saved \(String(describing: energyConsumedSample.metadata))")
               // Now delete the previous sample
                
                let predicate = HKQuery.predicateForObjects(withMetadataKey: HKMetadataKeyExternalUUID, allowedValues: [self.id.uuidString])
                
                let query = HKSampleQuery(sampleType: energyConsumedType, predicate: predicate, limit: 0, sortDescriptors: nil) { query, samples, error in
                    if let samples = samples, !samples.isEmpty {
                        self.healthStore.delete(samples) { success, error in
                            if let error = error {
                                print("ADDFOOD: update fail \(error)")
                            } else {
                                print("ADDFOOD: update deleted \(samples.count) samples")
                            }
                        }
                    } else {
                        print("ADDFOOD: update no samples found")
                    }
                }
                healthStore.execute(query)
                
            }
        }
        
    }
    
    static public func get(on date: Date? = nil, unique: Bool = false) -> ([FoodViewModel]) {
        
        var entries = [FoodViewModel]()
        var cache = [String]()
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
        
        let energyType = HKObjectType.quantityType(forIdentifier: .dietaryEnergyConsumed)!
        let query = HKSampleQuery(sampleType: energyType, predicate: predicate, limit: 0, sortDescriptors: nil) { query, samples, error in

            guard let samples = samples, error == nil else {
                return
            }
 
            for (index,sample) in samples.enumerated() {
                let startDate = sample.startDate
                if let metadata = sample.metadata, let foodType = metadata[HKMetadataKeyFoodType] as? String {
                    
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
