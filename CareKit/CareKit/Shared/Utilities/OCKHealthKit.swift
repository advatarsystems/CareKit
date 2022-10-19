//
//  File.swift
//  
//
//  Created by Johan Sellström on 2022-10-18.
//

import Foundation


import SwiftUI
import Charts
import HealthKit
import CareKitUI
import DateToolsSwift

public typealias MyChartPoints = [MyChartPoint]

public struct Characteristica: Codable {
    
    let dateOfBirth: Date?
    let weight: Double?
    let height: Double?
    let gender: HKBiologicalSex.RawValue?
    
    var age: Int? {
        if let age = dateOfBirth?.chunkBetween(date: Date()) {
            return age.years
        } else {
            return nil
        }
    }
    
    /// Returns age in years if it is available in HKHealthStore
    public static func age() -> Int? {
        if let birthdayComponents = try? HKHealthStore().dateOfBirthComponents() {
            let dateOfBirth = NSCalendar.current.date(from:  birthdayComponents)
            if let age = dateOfBirth?.chunkBetween(date: Date()) {
                return age.years
            } else {
                return nil
            }
        } else {
            return nil
        }
    }
    
    public init() async throws {
        let healthStore = HKHealthStore()
        let birthdayComponents = try healthStore.dateOfBirthComponents()
        self.dateOfBirth = NSCalendar.current.date(from:  birthdayComponents)
        let biologicalSex = try healthStore.biologicalSex().biologicalSex
        self.gender = biologicalSex.rawValue
        self.weight = await OCKHealthKit.getQuantity(identifier: .bodyMass)
        self.height = await OCKHealthKit.getQuantity(identifier: .height)
    }
}

public enum GoalsType: String, Codable {
    case budget = "Budget"
    case limit = "Limit"
    case range = "Range"
    case minimum = "Minimum"
}

public struct Goal: Codable {
    public let type: GoalsType
    public let low: Double?
    public let high: Double?
}

extension Goal: Equatable {
    public static func == (lhs: Goal, rhs: Goal) -> Bool {
        return lhs.type == rhs.type && lhs.low == rhs.low && lhs.high == rhs.high
    }
}

public struct Goals: Codable {
    
    let steps: Goal?
    let dietaryEnergyConsumed: Goal?
    
    /// Set all defaults to the defaults
    
    public init(characteristica: Characteristica) {
        self.steps = Goal(type: .minimum, low: 5000.0, high: nil)
        self.dietaryEnergyConsumed = Goal(type: .budget, low: 1000.0, high: 2500.0)
    }
    
    /// This does not take inte account characteristics such as gender, age, weight and height
    public init(_ useDefaults: Bool = true) async throws {
        if useDefaults {
            //let characteristica = try await Characteristica()
            self.steps = Goal(type: .minimum, low: 5000.0, high: nil)
            self.dietaryEnergyConsumed = Goal(type: .budget, low: 1000.0, high: 2500.0)
        } else if let characteristica = try? await Characteristica(){
            logger.info("characteristica \(characteristica)")
            self.steps = Goal(type: .minimum, low: 5000.0, high: nil)
            self.dietaryEnergyConsumed = Goal(type: .budget, low: 1000.0, high: 2500.0)
        } else {
            fatalError()
        }
    }
}

public extension HKQuantityTypeIdentifier {
    
    static var allNutritionCases: [HKQuantityTypeIdentifier] {
        return [ .bloodGlucose, .dietaryVitaminA, .dietaryVitaminC, .dietaryVitaminD , .dietaryVitaminE, .dietaryVitaminK, .dietaryVitaminB12, .dietaryNiacin, .dietaryVitaminB6, .dietaryThiamin, .dietaryPantothenicAcid, .dietaryFolate, .dietaryBiotin ]
    }
    
    func unit() -> HKUnit {
        switch self {
        case .bodyMass:
            return .gramUnit(with: .kilo)
        case .height:
            return .meterUnit(with: .centi)
        case .dietaryVitaminA, .dietaryVitaminC, .dietaryVitaminD , .dietaryVitaminE, .dietaryVitaminK, .dietaryVitaminB12, .dietaryNiacin, .dietaryVitaminB6, .dietaryThiamin, .dietaryPantothenicAcid, .dietaryFolate, .dietaryBiotin:
            return .gramUnit(with: .micro)
        case .dietaryCholesterol:
            return .gramUnit(with: .milli)
        case .dietaryEnergyConsumed, .basalEnergyBurned, .activeEnergyBurned:
            return .kilocalorie()
        case .dietaryCopper, .dietaryIodine, .dietaryManganese, .dietaryMolybdenum, .dietaryIron:
            return .gramUnit(with: .micro)
        case .bloodGlucose:
            return HKUnit.moleUnit(with: .milli, molarMass: HKUnitMolarMassBloodGlucose).unitDivided(by: HKUnit.liter())
        case .stepCount:
            return .count()
        default:
            return .gram()
        }
    }
    
    // TODO: Mark up all
    func typeOfGoal() -> GoalsType {
        switch self {
        case .dietaryEnergyConsumed:
            return .budget
        default: return .limit
        }
    }
    
    func statisticsOptions() -> HKStatisticsOptions {
        switch self {
        case .bloodGlucose: return .discreteAverage
        default:
            return .cumulativeSum
        }
    }
    
    func name() -> String {
        switch self {
        case .bloodGlucose: return "Blood Glucose"
        case .dietaryEnergyConsumed: return "Calories"
        case .dietaryCarbohydrates: return "Carbohydrates"
        case .dietaryFiber: return "Fiber"
        case .dietarySugar: return "Sugar"
        case .dietaryFatTotal: return "Fat"
        case .dietaryFatMonounsaturated: return "Monounsaturated Fat"
        case .dietaryFatPolyunsaturated: return "Polyunsaturated Fat"
        case .dietaryFatSaturated: return "Saturated Fat"
        case .dietaryCholesterol: return "Cholesterol"
        case .dietaryProtein: return"Protein"
        case .dietaryVitaminA: return "VitaminA"
        case .dietaryThiamin: return "Thiamin"
        case .dietaryRiboflavin: return "Riboflavin"
        case .dietaryNiacin: return "Niacin"
        case .dietaryPantothenicAcid: return "Pantothenic Acid"
        case .dietaryVitaminB6: return "Vitamin B6"
        case .dietaryBiotin: return "Biotin"
        case .dietaryVitaminB12: return "Vitamin B12"
        case .dietaryVitaminC: return "Vitamin C"
        case .dietaryVitaminD: return "Vitamin D"
        case .dietaryVitaminE: return "Vitamin E"
        case .dietaryVitaminK: return "Vitamin K"
        case .dietaryFolate: return "Folate"
        case .dietaryCalcium: return "Calcium"
        case .dietaryChloride: return "Chloride"
        case .dietaryIron: return "Iron"
        case .dietaryMagnesium: return "Magnesium"
        case .dietaryPhosphorus: return "Phosphorus"
        case .dietaryPotassium: return "Potassium"
        case .dietarySodium: return "Sodium"
        case .dietaryZinc: return "Zinc"
        case .dietaryWater: return "Water"
        case .dietaryCaffeine: return "Caffeine"
        case .dietaryChromium: return "Chromium"
        case .dietaryCopper: return "Copper"
        case .dietaryIodine: return "Iodine"
        case .dietaryManganese: return "Manganese"
        case .dietaryMolybdenum: return "Molybdenum"
        case .dietarySelenium: return "Selenium"
        default: return "Unhandled"
        }
    }
    
    // FIXME: What to do about target values? These are really the budget but we will not be able to modify them easily. What are sensible defaults?. We need to figure out age, weight etc in order to set these the first time.

    /*
     
     Dietary Reference Intakes (DRI): Set of four reference values: Estimated Average Requirements (EAR), Recommended Dietary Allowances (RDA), Adequate Intakes (AI) and Tolerable Upper Intake Levels (UL).


     Electrolytes: Includes sodium, chloride, potassium, and inorganic sulfate.

     Elements (Minerals): Includes arsenic, boron, calcium, chromium, copper, fluoride, iodine, iron, magnesium, manganese, molybdenum, nickel, phosphorus, selenium, silicon, vanadium and zinc.
     
    Estimated Average Requirement (EAR): The average daily nutrient intake level estimated to meet the requirement of half the healthy individuals in a particular life stage and gender group.

    Estimated Energy Requirement (EER): The average dietary energy intake that is predicted to maintain energy balance in a healthy adult of a defined age, gender, weight, height, and level of physical activity consistent with good health.
     */
    
    /// A general description
    func dietaryReferenceIntake() -> String {
        return ""
    }

    func estimatedAverageRequirement() -> Double {
        return 0.0
    }
    
    func recommendedDietaryAllowance() -> Double {
        return 0.0
    }
    
    func adequateIntake() -> Double {
        return 0.0
    }
    
    func tolerableUpperIntakeLevel() -> Double {
        return 0.0
    }

    
    func description() -> String {
        switch self {
        case .stepCount: return "A walk a day keeps the doctor away, especially as you age and become more inactive."
        case .dietaryEnergyConsumed: return "It has been scientfically proven that caloric restriction promotes longevity and demotes weight gain."
        case .dietaryCarbohydrates: return "Too many carbs might increase the risk of diabetes 2 and pre-mature aging."
        case .dietaryFiber: return "Fiber is important to keep you regular and to feed your gut microbiome. Also, it slows down digestion and regulates your blood sugar."
        case .dietarySugar: return "You should probably always try to minimize sugar."
        case .dietaryFatTotal: return "Depending on your diet, go low or high."
        case .dietaryFatMonounsaturated: return "Monounsaturated fats can help reduce bad cholesterol levels in your blood which can lower your risk of heart disease and stroke."
        case .dietaryFatPolyunsaturated: return "Polyunsaturated fats can help reduce bad cholesterol levels in your blood which can lower your risk of heart disease and stroke."
        case .dietaryFatSaturated: return "Saturated fats are bad for your health in several ways: Heart disease risk. Your body needs healthy fats for energy and other functions. But too much saturated fat can cause cholesterol to build up in your arteries. On a Keto diet it is less of a problem."
        case .dietaryCholesterol: return "Some types of cholesterol (HDL) are essential for good health. Your body needs cholesterol to perform important jobs, such as making hormones and building cells."
        case .dietaryProtein: return "Protein is an important part of a healthy diet. Proteins are made up of chemical 'building blocks' called amino acids. Your body uses amino acids to build and repair muscles and bones and to make hormones and enzymes. They can also be used as an energy source."
        case .dietaryVitaminA: return "Vitamin A is important for normal vision, the immune system, reproduction, and growth and development."
        case .dietaryThiamin: return  "Thiamin (vitamin B-1) helps the body generate energy from nutrients."
        case .dietaryRiboflavin: return "Antioxidants, such as riboflavin, can fight free radicals and may reduce or help prevent some of the damage they cause."
        case .dietaryNiacin: return "Niacin (B3) helps keep your nervous system, digestive system and skin healthy."
        case .dietaryPantothenicAcid: return "Pantothenic acid (B5) helps turn the food you eat into the energy you need."
        case .dietaryVitaminB6: return "Vitamin B6 (pyridoxine) is important for normal brain development and for keeping the nervous system and immune system healthy."
        case .dietaryBiotin: return "Biotin helps your body use enzymes and carry nutrients throughout the body."
        case .dietaryVitaminB12: return "Vitamin B12 is a nutrient that helps keep your body's blood and nerve cells healthy and helps make DNA, the genetic material in all of your cells."
        case .dietaryVitaminC: return "Vitamin C is an antioxidant that helps protect your cells against the effects of free radicals."
        case .dietaryVitaminD: return "Vitamin D helps regulate the amount of calcium and phosphate in the body."
        case .dietaryVitaminE: return "Vitamin E is a nutrient that's important to vision, reproduction, and the health of your blood, brain and skin. Vitamin E also has antioxidant properties."
        case .dietaryVitaminK: return  "Vitamin K helps to make various proteins that are needed for blood clotting and the building of bones."
        case .dietaryFolate: return "Folate (vitamin B-9) is important in red blood cell formation and for healthy cell growth and function."
        case .dietaryCalcium: return "Your body needs calcium to build and maintain strong bones. Your heart, muscles and nerves also need calcium to function properly."
        case .dietaryChloride: return "Chloride is needed to keep the proper balance of body fluids. It is an essential part of digestive (stomach) juices."
        case .dietaryIron: return "Iron is important in making red blood cells, which carry oxygen around the body."
        case .dietaryMagnesium: return "Magnesium plays many crucial roles in the body, such as supporting muscle and nerve function and energy production."
        case .dietaryPhosphorus: return "Phosphorus is needed for the growth, maintenance, and repair of all tissues and cells, and for the production of the genetic building blocks, DNA and RNA."
        case .dietaryPotassium: return "Potassium is necessary for the normal functioning of all cells. It regulates the heartbeat, ensures proper function of the muscles and nerves, and is vital for synthesizing protein and metabolizing carbohydrates."
        case .dietarySodium: return "Your body needs a small amount of sodium to work properly, but too much sodium can be bad for your health."
        case .dietaryZinc: return "Zinc helps your immune system and metabolism function. Zinc is also important to wound healing and your sense of taste and smell."
        case .dietaryWater: return "Your body is mostly made up of water and it is essential to stay well hydrated"
        case .dietaryCaffeine: return "In moderate amounts, consuming caffeine may actually reduce your risk of heart disease."
        case .dietaryChromium: return "Chromium is an essential trace mineral. There are two forms: trivalent chromium, which is safe for humans, and hexavalent chromium, which is a toxin."
        case .dietaryCopper: return "Your body uses copper to carry out many important functions, including making energy, connective tissues, and blood vessels. Copper also helps maintain the nervous and immune systems, and activates genes. Your body also needs copper for brain development."
        case .dietaryIodine: return "Your body uses copper to carry out many important functions, including making energy, connective tissues, and blood vessels. Copper also helps maintain the nervous and immune systems, and activates genes. Your body also needs copper for brain development."
        case .dietaryManganese: return "Manganese helps the body form connective tissue, bones, blood clotting factors, and sex hormones. It also plays a role in fat and carbohydrate metabolism, calcium absorption, and blood sugar regulation. Manganese is also necessary for normal brain and nerve function."
        case .dietaryMolybdenum: return "Your body uses molybdenum to process proteins and genetic material like DNA. Molybdenum also helps break down drugs and toxic substances that enter the body."
        case .dietarySelenium: return "Selenium is an essential component of various enzymes and proteins, called selenoproteins, that help to make DNA and protect against cell damage and infections; these proteins are also involved in reproduction and the metabolism of thyroid hormones."
        default: return "Unhandled"
        }
    }
}

public extension HKQuantitySample {
    func unit() -> HKUnit {
        let typeIdentifier = HKQuantityTypeIdentifier(rawValue: self.quantityType.identifier)
        return typeIdentifier.unit()
    }
    
    func name() -> String {
        let typeIdentifier = HKQuantityTypeIdentifier(rawValue: self.quantityType.identifier)
        return loc(typeIdentifier.name())
    }
    
    func typeOfGoal() -> GoalsType {
        let typeIdentifier = HKQuantityTypeIdentifier(rawValue: self.quantityType.identifier)
        return typeIdentifier.typeOfGoal()
    }
}

public struct OCKHealthKit {
    
    // TODO: From now on always provide both async and sync versions of functions!
    
    public static func getQuantity(identifier: HKQuantityTypeIdentifier) async -> Double? {
        await withCheckedContinuation { continuation in
            getQuantity(identifier: identifier, completion: continuation.resume)
        }
    }

    public static func getQuantity(identifier: HKQuantityTypeIdentifier, completion: @escaping (Double?) -> Void) {
        let quantityType = HKObjectType.quantityType(forIdentifier: identifier)!
        let query = HKSampleQuery(sampleType: quantityType, predicate: nil, limit: 0, sortDescriptors: nil) { query, samples, error in
            completion((samples as? [HKQuantitySample])?.last?.quantity.doubleValue(for: identifier.unit()))
        }
        HKHealthStore().execute(query)
    }

    public static func getAverageValuesPerInterval(identifier: HKQuantityTypeIdentifier, dayInterval: Int) async  -> MyChartPoints {
        await withCheckedContinuation { continuation in
            getAverageValuesPerInterval(identifier: identifier, dayInterval: dayInterval, completion: continuation.resume)
        }
    }
    
    public static func getAverageValuesPerInterval(identifier: HKQuantityTypeIdentifier, dayInterval: Int, completion: @escaping (MyChartPoints) -> Void) {
        
        func isEnergy(_ identifier: HKQuantityTypeIdentifier) -> Bool {
            return identifier == .dietaryEnergyConsumed || identifier == .basalEnergyBurned || identifier == .activeEnergyBurned
        }
        
        func isToday(_ date: Date) -> Bool {
            return Calendar.current.startOfDay(for: date) >= Calendar.current.startOfDay(for: Date())
        }
        
        let calendar = Calendar.current
        let interval = DateComponents(day: dayInterval)
        
        let components = DateComponents(calendar: calendar,
                                        timeZone: calendar.timeZone,
                                        hour: 0)

        guard let anchorDate = calendar.nextDate(after: Date(),
                                                 matching: components,
                                                 matchingPolicy: .nextTime,
                                                 repeatedTimePolicy: .first,
                                                 direction: .backward) else {
            completion([])
            return
        }
        
        let quantityType = HKObjectType.quantityType(forIdentifier: identifier)!
   
        let query = HKStatisticsCollectionQuery(quantityType: quantityType,
                                                quantitySamplePredicate: nil,
                                                options: identifier.statisticsOptions(),
                                                anchorDate: anchorDate,
                                                intervalComponents: interval)

        query.initialResultsHandler = {
            query, results, error in
            
            // Handle errors here.
            if let error = error as? HKError {
                switch (error.code) {
                case .errorDatabaseInaccessible:
                    // HealthKit couldn't access the database because the device is locked.
                    logger.error("\(error)")
                    completion([])
                    return
                default:
                    // Handle other HealthKit errors here.
                    logger.error("\(error)")
                    completion([])
                    return
                }
            }
            
            guard let results else {
                // You should only hit this case if you have an unhandled error. Check for bugs
                // in your code that creates the query, or explicitly handle the error.
                completion([])
                return
            }
            
            print("results \(results.statistics())")
            let endDate = Date()
            
            let months = dayInterval == 1 ? 1:12
            let someTimeAgo = DateComponents(month: -months)
                
            guard let startDate = calendar.date(byAdding: someTimeAgo, to: endDate) else {
                //fatalError("*** Unable to calculate the start date ***")
                completion([])
                return
            }
            
            var points = [MyChartPoint]()
            
            // Enumerate over all the statistics objects between the start and end dates.
            results.enumerateStatistics(from: startDate, to: endDate) { (statistics, stop) in
                if identifier.statisticsOptions() == .discreteAverage, let quantity = statistics.averageQuantity() {
                    let date = statistics.startDate
                    let value = quantity.doubleValue(for: identifier.unit())
                    let point = MyChartPoint(value: value, date: date)
                    points.append(point)
                } else if identifier.statisticsOptions() == .cumulativeSum, let quantity = statistics.sumQuantity() {
                    let date = statistics.startDate
                    var value = quantity.doubleValue(for: identifier.unit())
                    // FIXME: Is this a good cut-off?
                    if identifier == .dietaryEnergyConsumed, value < 500 {
                        value = 2500.0
                    }
                    if isEnergy(identifier), isToday(date)  {
                        logger.info("SKIP: Skipping todays value for \(identifier)")
                    } else {
                        let point = MyChartPoint(value: value, date: date)
                        points.append(point)
                    }
                } else {
                    let date = statistics.startDate
                    let value: Double
                    switch identifier {
                    case .basalEnergyBurned:
                        value = 1700.0
                        let point = MyChartPoint(value: value, date: date)
                        points.append(point)
                    case .activeEnergyBurned:
                        value = 700.0
                        let point = MyChartPoint(value: value, date: date)
                        points.append(point)
                    case .dietaryEnergyConsumed:
                        value = 2500.0
                        let point = MyChartPoint(value: value, date: date)
                        points.append(point)
                    default:
                        value = 0.0
                    }
                }
            }
            // Hmm, it seems that the call is synchronous??
            completion(points)
        }
        //Thread 6: "Statistics option HKStatisticsOptionDiscreteAverage is not compatible with cumulative data type HKQuantityTypeIdentifierDietaryVitaminA"
        HKHealthStore().execute(query)
    }
    

    static func saveToHealthKit(jsonString: String, completion: @escaping (Error?) -> Void) {
        let metadata: Dictionary<String, String> = [
            HKMetadataKeyExternalUUID: UUID().uuidString,
            "HKMetadataKeyNutritionGoals": jsonString
        ]
        logger.info("metadata \(metadata)")
        let date = Date()
        let foodType = HKCorrelationType.correlationType(forIdentifier: HKCorrelationTypeIdentifier.food)!
        let foodCorrelation = HKCorrelation(type: foodType, start: date, end: date, objects: [], metadata: metadata)
    
        logger.info("foodCorrelation \(foodCorrelation)")
        HKHealthStore().save(foodCorrelation) { (success, error) in
            if let error = error {
                logger.error("\(error)")
                completion(error)
            } else {
                logger.info("Saved \(foodCorrelation) with \(success)")
                completion(nil)
            }
        }
    }
    
    static public func setGoals(goals: Goals, completion: @escaping (Error?) -> Void) {
        if let data = try? JSONEncoder().encode(goals), let jsonString = String(data: data, encoding: .utf8) {
            saveToHealthKit(jsonString: jsonString) { error in
                completion(error)
            }
        } else {
            let error = NSError()
            completion(error)
        }
    }
    
    func testSampleQuery() {
        let sampleType = HKSampleType.quantityType(forIdentifier: HKQuantityTypeIdentifier.stepCount)
        let query = HKSampleQuery.init(sampleType: sampleType!,
                                       predicate: nil,
                                       limit: HKObjectQueryNoLimit,
                                       sortDescriptors: nil) { (query, results, error) in
            
        }
        
        HKHealthStore().execute(query)
    }
    
    static public func getGoals() async  -> Goals? {
        await withCheckedContinuation { continuation in
            OCKHealthKit.getGoals(completion: continuation.resume)
        }
    }

    static public func getGoals(completion: @escaping (Goals?) -> Void) {

        Task {
            let characteristics = try await Characteristica()
            let defaultGoals = Goals(characteristica: characteristics)
            completion(defaultGoals)
        }
        completion(nil)
        
        // FIXME: Very strange compilation error here....
        // Invalid conversion from throwing function of type '(HKSampleQuery, [HKSample]?, (any Error)?) throws -> Void' to non-throwing function type '(HKSampleQuery, [HKSample]?, (any Error)?) -> Void'
        /*let foodType = HKObjectType.correlationType(forIdentifier: .food)!
        
        let query = HKSampleQuery(sampleType: foodType, predicate: nil, limit: 0, sortDescriptors: nil) {  query, samples, error in
            guard let samples = samples, error == nil else {
                logger.debug("no samples or error \(String(describing: error))")
                completion(nil)
                return
            }
            // There should only be one with the right metadata
            if samples.count > 1 {
                fatalError("Conflicting goals")
            }
            
            if let sample = samples.first, let metadata = sample.metadata, let jsonString = metadata["HKMetadataKeyNutritionGoals"] as? String, let data = jsonString.data(using: .utf8), let goals = try? JSONDecoder().decode(Goals.self, from: data) {
                completion(goals)
                return
            }
            
            if let characteristics = try Characteristica() {
                let defaultGoals = Goals(characteristica: characteristics)
                completion(defaultGoals)
            } else {
                completion(nil)
            }
        }
        HKHealthStore().execute(query)*/
    }
    
}
