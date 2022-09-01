/*
 Copyright (c) 2019, Apple Inc. All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification,
 are permitted provided that the following conditions are met:
 
 1.  Redistributions of source code must retain the above copyright notice, this
 list of conditions and the following disclaimer.
 
 2.  Redistributions in binary form must reproduce the above copyright notice,
 this list of conditions and the following disclaimer in the documentation and/or
 other materials provided with the distribution.
 
 3. Neither the name of the copyright holder(s) nor the names of any contributors
 may be used to endorse or promote products derived from this software without
 specific prior written permission. No license is granted to the trademarks of
 the copyright holders even if such marks are included in this software.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE
 FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
 OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

import Combine
import Foundation
import CareKitStore
import CareKitUI
import HealthKit
import SigmaSwiftStatistics

public struct Score: Codable {
    public let average: Double
    public let variability: Int
    public let inRange: Int
    public let score: Double
    public let peak: Double
    public let delta: Double
    public let timeToBaseline: Double
    public let timeInRange: Double
}

open class Analytics {
    
    static public func analyzeDay(glucoseValues: [MyChartPoint]) -> Score? {
        
       let doubleValues = glucoseValues.map { $0.value }
        if let startDate = glucoseValues.first?.date, let endDate = glucoseValues.last?.date, let average = Sigma.average(doubleValues), let standarDeviation = Sigma.standardDeviationSample(doubleValues) {
            let variability = standarDeviation/average*100.0
            // FIXME: Maybe heuristic a bit too fragile? But an average less than 30 mg/dl is severly hypoglycemic. On the other hand some people might be using mmol and average above 30 mmol/l (540 mg/dl). The Libre app does not show values above 21 mmol/l
            let ismmol = average < 30
     
            var avgerageInMol = average
            if !ismmol {
                avgerageInMol = avgerageInMol/18.0
            }
            
            var avgscore = 0.0
            if avgerageInMol >= 4.0 && avgerageInMol <= 6.1 {
                avgscore = 120.0 - 6.56 * avgerageInMol // 6.1 should be 80 so 80 = 120-k*6.1 k = 40/6.1
            } else if avgerageInMol > 6.1 {
                avgscore = 0.9*(90.0/16.0*avgerageInMol*avgerageInMol-450.0/4.0*avgerageInMol+1125.0/2.0)
            } else if avgerageInMol < 4.0 {
                avgscore = 100.0/16.0*avgerageInMol*avgerageInMol
            }
            
            var above = 0
            var below = 0
            var glucosePeak = -1.0
            
            for value in doubleValues {
               // print("STATISTICS: value \(value) glucosePeak \(glucosePeak)")
                if value > glucosePeak {
                    glucosePeak = value
                }
                if ismmol {
                    if value > 6.1 {
                        above += 1
                    } else if value < 4.0 {
                        below += 1
                    }
                } else {
                    if value > 110 {
                        above += 1
                    } else if value < 72 {
                        below += 1
                    }
                }
            }
            
            let ir = 100.0*Double(glucoseValues.count-above-below)/Double(glucoseValues.count)
            let s = (avgscore + (100.0-variability) + ir)/3.0
            print("ANALYTICS: startDate \(startDate) endDate \(endDate) average \(average) standarDeviation \(standarDeviation) variability \(variability) score \(s)")
            
            let score = Score(average: average, variability: Int(variability), inRange: Int(ir), score: s, peak: glucosePeak, delta: 0.0, timeToBaseline: 0.0, timeInRange: ir)
    
            return score
        }
        return nil
    }
    
    // Peak, time to baseline and delta
    
    static public func analyzeZone(glucoseValues: [MyChartPoint], date: Date) -> Score {
         
        // FIXME: Need a better model here...
        
        /*
         Time to baseline should be less than two hours aka 120 minutes. That scores 80. If the peak is super small we give 100.
         
         y(T) = 100-k*T y(120) = 80 => 80=100-k*120 k=20/120 = 1/60
         
         If it is nil, 50 points?
         
         If the peak is less than 6.1 it is 100

         */

        let startOffSet: TimeInterval = -0.5*60*60
        let zoneLength = 3.0
        let endOffSet: TimeInterval = (zoneLength+0.5)*60*60
        let startDate = date.addingTimeInterval(startOffSet)
        let endDate   = date.addingTimeInterval(endOffSet)
        let doubleValues = glucoseValues.map { ($0.date >= startDate && $0.date <= endDate) ? $0.value:nil }

        var baselineValue: Double = -1.0
        var peakValue: Double = -1.0
        var peakTime: Date?
        var baselineReturnTime: Double  = -1.0
        var startGlucose = -1.0
        // Compute baseline and the time for the peak
        for value in glucoseValues {
            if value.date >= startDate && value.date <= endDate {
                
                if value.value > peakValue {
                    peakValue = value.value
                    peakTime = value.date
                }
                
                if value.date >= date, baselineValue < 0.0 {
                    baselineValue = value.value
                }
            }
        }
        
        for value in glucoseValues {
            if let time = peakTime, value.date >= time, value.date <= endDate {
                if baselineValue > 0.0, value.value <= baselineValue, baselineReturnTime < 0.0 {
                    baselineReturnTime = value.date.timeIntervalSince(date)/60.0 // In minutes
                }
            }
        }
        
        print("ANALYTICS: peakValue \(peakValue) baselineValue \(baselineValue) baselineReturnTime \(String(describing: baselineReturnTime))")
        
        var timeScore = 50.0
        var deltaScore = 50.0
        var peakScore = 50.0

        if baselineReturnTime > 0.0 {
            timeScore = 100.0 - baselineReturnTime/60.0
        }
        
        let glucoseDelta = peakValue-baselineValue

        let ismmol = baselineValue < 30
        
        if ismmol {
            if peakValue <= 6.1 {
                peakScore = 100.0
            } else {
                peakScore = 50.0
            }
            
            if glucoseDelta <= 2 {
                deltaScore = 100.0
            } else {
                deltaScore = 50.0
            }
            
        } else {
            if peakValue <= 6.1*18.0 {
                peakScore = 100.0
            } else {
                peakScore = 50.0
            }
            if glucoseDelta <= 36.0 {
                deltaScore = 100.0
            } else {
                deltaScore = 50.0
            }
        }
        
        let s = (timeScore+peakScore+deltaScore)/3.0

        let score = Score(average: 0.0, variability: 0, inRange: 0, score: s, peak: peakValue, delta: -1.0, timeToBaseline: baselineReturnTime, timeInRange: -1.0)
        
        return score
    }

    
}

open class OCKChartTaskController: OCKTaskController {

    /// Data used to create a `CareKitUI.ChartTaskView`.
    @Published public private(set) var viewModel: ChartTaskViewModel? {
        willSet { objectWillChange.send() }
    }

    private var cancellable: AnyCancellable?

    public required init(storeManager: OCKSynchronizedStoreManager) {
        super.init(storeManager: storeManager)
        cancellable = $taskEvents.sink { taskEvents in
            self.viewModel = self.makeViewModel(from: taskEvents)
        }
    }
    
    private func makeViewModel(from taskEvents: OCKTaskEvents) -> ChartTaskViewModel? {
        guard !taskEvents.isEmpty else { return nil }

        /*
        let errorHandler: (Error) -> Void = { [weak self] error in
            self?.error = error
        }
         */
        
        var glucoseValues = [Double]()
        var pointValues = [MyChartPoint]()
        var foods = [FoodViewModel]()
        var insulins = [InsulinViewModel]()
        var activeEnergy: Double = 0.0
        var startOfDay: Date?
        
        let today = Calendar.current.startOfDay(for: Date())
        var writeScore = false
        for events in taskEvents {
            for event in events {
                if let task = event.task as? OCKHealthKitTask {
                    if task.healthKitLinkage.quantityIdentifier == HKQuantityTypeIdentifier.insulinDelivery {
                        if let outcome = event.outcome {
                            if let outcome = outcome as? OCKHealthKitOutcome, let dates = outcome.dates {
                                print("INSULIN: \(outcome)")
                                let count = outcome.values.count
                                let values = outcome.values
                                
                                for index in 0..<count {
                                    /* Not really need to mark up the chart
                                    if let metadata = outcome.metadata {
                                        let item = metadata[index]
                                        print("INSULIN: metadata \(item)")
                                    } else {
                                        print("INSULIN: no metadata")
                                    }
                                    */
                                    //let value = values[index].
                                    //let value = Int(values[index].doubleValue(for: .internationalUnit()))
                                    if let doubleValue = values[index].doubleValue {
                                        let newValue = InsulinViewModel(uuidString: nil, date: dates[index], reason: HKInsulinDeliveryReason.basal, units: Int(doubleValue), index: index)
                                        insulins.append(newValue)
                                    }
                                    
                                }
                                
                            }
                        }
                    } else if task.healthKitLinkage.quantityIdentifier == HKQuantityTypeIdentifier.bloodGlucose {
                        if let outcome = event.outcome {
                            if let outcome = outcome as? OCKHealthKitOutcome, let dates = outcome.dates {
                                let count = outcome.values.count
                                let values = outcome.values
                                //print("SYNC: dates \(dates)")
                                // Dates are descendingorder, i.e the latest is first
                                if let first = dates.first {
                                    startOfDay = Calendar.current.startOfDay(for: first)
                                    if let sod = startOfDay , sod < today {
                                        print("SYNC: startOfDay \(sod) should be final")
                                        writeScore = true
                                    }
                                }
                                print("METABOLIC: count \(count) date \(String(describing: dates.first)) \(String(describing: dates.last))")
                                for index in 0..<count {
                                    if let doubleValue = values[index].doubleValue {
                                        glucoseValues.append(doubleValue)
                                        //print("STATISTICS: \(dates[index])")
                                        let newValue = CareKitUI.MyChartPoint(value: doubleValue, date: dates[index])
                                        pointValues.append(newValue)
                                    }
                                }
                            }
                        }
                    } else if task.healthKitLinkage.quantityIdentifier == HKQuantityTypeIdentifier.dietaryEnergyConsumed {
                        var prevFood: FoodViewModel?
                        if let outcome = event.outcome {
                            if let outcome = outcome as? OCKHealthKitOutcome, let dates = outcome.dates {
                                let uuids = outcome.healthKitUUIDs
                                let count = outcome.values.count
                                for index in 0..<count {
                                     if let metadata = outcome.metadata {
                                        let item = metadata[index]
                                        //print("SCORE: metadata \(metadata) item \(item)")
                                         if let name = item["HKFoodType"] {
                                            let food = FoodViewModel(name: name, date: dates[index], score: nil, index: index)
                                             if prevFood?.name != food.name && prevFood?.date != food.date {
                                                 foods.append(food)
                                                 prevFood = food
                                             }
                                        }
                                    }
                                }
                            }
                        }
                    } else if task.healthKitLinkage.quantityIdentifier == HKQuantityTypeIdentifier.activeEnergyBurned {
                        if let outcome = event.outcome {
                            if let outcome = outcome as? OCKHealthKitOutcome, let dates = outcome.dates {
                                let count = outcome.values.count
                                let values = outcome.values
                                // FIXME: It should only be one value?
                                for index in 0..<count {
                                    if let doubleValue = values[index].doubleValue {
                                        activeEnergy = doubleValue
                                        print("ACTIVE_ENERGY: activeEnergy  \(activeEnergy )")
                                    }
                                }
                            }
                        }
                    }
                } /*else { // It is a "normal" task
                    if event.task.id == "sleep" {
                        print("SLEEP: outcome \(String(describing: event.outcome))")
                        if let values = event.outcome?.values {
                            for value in values {
                                print("SLEEP: value \(value)")
                            }
                        }
                    }
                }*/
            }
        }
        
        
        for food in foods {
            let foodScore = Analytics.analyzeZone(glucoseValues: pointValues.reversed(), date: food.date)
            print("ANALYTICS: foodScore \(foodScore)")
        }
        
        // Is this a good place to update metabolic score?
        
        guard let dayScore = Analytics.analyzeDay(glucoseValues: pointValues.reversed()) else {
            return nil
        }
        print("ANALYTICS: score \(dayScore)")
 
        if writeScore, let date = startOfDay {
            print("SYNC: score \(dayScore.score) date \(date)")
            save(v: dayScore.score/100.0, date: date, taskIdentifier: "score")
        }
        
        return .init(title: taskEvents.firstEventTitle,
                     detail: taskEvents.firstEventDetail,
                     instructions: taskEvents.firstTaskInstructions,
                     action: {},
                     values: pointValues,
                     foods: foods,
                     insulins: insulins,
                     average: dayScore.average,
                     variability: dayScore.variability,
                     inRange: dayScore.inRange,
                     score: Int(dayScore.score),
                     glucosePeak: dayScore.peak,
                     glucoseDelta: dayScore.delta,
                     activeEnergy: activeEnergy,
                     timeToBaseline: dayScore.timeToBaseline
        )
    }
    
    
    private enum OCKTaskControllerError: Error, LocalizedError {

        case emptyTaskEvents
        case invalidIndexPath(_ indexPath: IndexPath)
        case noOutcomeValueForEvent(_ event: OCKAnyEvent, _ index: Int)
        case cannotMakeOutcomeFor(_ event: OCKAnyEvent)

        var errorDescription: String? {
            switch self {
            case .emptyTaskEvents: return "Task events is empty"
            case let .noOutcomeValueForEvent(event, index): return "Event has no outcome value at index \(index): \(event)"
            case .invalidIndexPath(let indexPath): return "Invalid index path \(indexPath)"
            case .cannotMakeOutcomeFor(let event): return "Cannot make outcome for event: \(event)"
            }
        }
    }

    internal func makeOutcomeFor(event: OCKAnyEvent, withValues values: [OCKOutcomeValue], comment: String? = nil) throws -> OCKAnyOutcome {
        guard
            let task = event.task as? OCKAnyVersionableTask else { throw OCKTaskControllerError.cannotMakeOutcomeFor(event) }
        let taskID = task.uuid
        var outcome = OCKOutcome(taskUUID: taskID, taskOccurrenceIndex: event.scheduleEvent.occurrence, values: values)
        if let comment = comment {
            print("PENDING: notes attached \(comment)")
            let note = OCKNote(author: "system", title: "title", content: comment)
            outcome.notes = [OCKNote]()
            outcome.notes?.append(note)
        }
        return outcome
    }

    // TODO: Use comments f.i when activeEnergy/bodyTemperature is high or low etc
    
    private func save(v: Double, date: Date, taskIdentifier: String , comment: String? = nil)
    {
        var values = [OCKOutcomeValue]()
        var value = OCKOutcomeValue(v)
        value.createdDate = date
        values.append(value)
        save(outcomeValues: values, date: date, taskIdentifier: taskIdentifier, comment: comment)
    }
    
    public func save(outcomeValues: [OCKOutcomeValue], date: Date, taskIdentifier: String, allowDuplicates: Bool = false, comment: String? = nil){
        let eventQuery = OCKEventQuery(for: date)
        fetchAndUpdateEvents(identifier: taskIdentifier, eventQuery: eventQuery, values: outcomeValues, allowDuplicates: allowDuplicates, comment: comment)
    }
    
    internal func fetchAndUpdateEvents(identifier: String, eventQuery: OCKEventQuery, values: [OCKOutcomeValue], allowDuplicates: Bool , comment: String? = nil) {
        
        print("SYNC: score fetchAndUpdateEvents")
  
        storeManager.store.fetchAnyEvents(taskID: identifier, query: eventQuery, callbackQueue: .global()) { result in
        
            switch result {
            case .failure(let error):
                print("SYNC: taskID \(identifier) \(error)")
            case .success(let events):
                if let event = events.first {
                    if var outcome = event.outcome as? OCKOutcome, let value = values.first {
                        if allowDuplicates ? true: outcome.values.isEmpty {
                            print("SYNC: Adding value \(value)")
                            outcome.values.append(value)
                            print("SYNC: comment \(String(describing: comment)) outcome \(outcome)")
                            if let comment = comment{
                                let note = OCKNote(author: "system", title: "title", content: comment)
                                outcome.notes = [OCKNote]()
                                outcome.notes?.append(note)
                            }
                            print("SYNC: Will update taskID \(identifier) with \(value) on \(eventQuery.dateInterval)")
                            
                            self.storeManager.store.updateAnyOutcome(outcome, callbackQueue: .main) { result in
                                switch result {
                                case .failure(let error):
                                    print("SYNC: score \(error)")
                                default:
                                    print("SYNC: score updateAnyOutcome \(result)")
                                    break
                                }
                            }
                        } else {
                            let date = (event.outcome as? OCKOutcome)?.values.first?.createdDate
                            print("SYNC: score already had outcome values \(String(describing: (event.outcome as? OCKOutcome)?.values)) at \(String(describing: date))")
                        }
                    } else if let value = values.first {
                        do {
                            let outcome = try self.makeOutcomeFor(event: event, withValues: [value], comment: comment)
                            self.storeManager.store.addAnyOutcome(outcome, callbackQueue: .main) { result in
                                switch result {
                                case .failure(let error):
                                    print("SYNC: \(error)")
                                default:
                                    print("SYNC: addAnyOutcome")
                                    break
                                }
                            }
                        } catch let error {
                            print("SYNC: taskID \(identifier) with value \(value) on \(eventQuery.dateInterval) gives \(error)")
                        }
                    }
                }
            }
        }
    }
}
