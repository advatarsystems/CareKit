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
        var activeEnergy: Double = 0.0
        var startOfDay: Date?
        
        let today = Calendar.current.startOfDay(for: Date())
        var writeScore = false
        for events in taskEvents {
            for event in events {
                if let task = event.task as? OCKHealthKitTask {
                    if task.healthKitLinkage.quantityIdentifier == HKQuantityTypeIdentifier.bloodGlucose {
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
                                print("METABOLIC: count \(count) date \(String(describing: dates.first)) \(dates.last)")
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
        
        var average: Double?
        var variability: Int?
        var score: Int?
        var inRange: Int?
        var glucosePeak: Double = 0.0
        var glucoseDelta: Double = 0.0
        var timeToBaseline: Double = 0.0
        
        if let firstValue = pointValues.first, let lastValue = pointValues.last, let avg = Sigma.average(glucoseValues), let sd = Sigma.standardDeviationSample(glucoseValues) {
            
            // FIXME: Maybe heuristic a bit too fragile? But an average less than 30 mg/dl is severly hypoglycemic. On the other hand some people might be using mmol and average above 30 mmol/l (540 mg/dl). The Libre app does not show values above 21 mmol/l
            /*
             
             Variability can be 0-100
             Average can be whatever. It is good if below 6.1 but above 4.0.
             
             Say it is an x2 function where 4.0 is 100 and 6.1 is 90
             f(x)=ax2+bx+c
             f(4) = 100
             f(6.1) = 90
             
             a16+4b+c=100
             37.1a+6.1b+c=90
             
             In Range is easy
             
             How do we weigh them together?
             
             Just an average of the three?
             
             */
            let ismmol = avg < 30 // Is it possible to have less than 1.6 mmol/L ?
            let dev = ismmol ? 100*(avg-6.1)/(6.1-4.0): 100*(avg-110)/(110-72)
            let cv = sd/avg*100.0
            let devf = (100 + dev)/100.0 // < 1 if below upper limit and then the score is lower
            print("STATISTICS: average \(avg) std \(sd) cv \(cv) dev \(dev) devf \(devf) score \((100.0 - devf*cv))")
            variability = Int(cv)
            average = avg
            
            var avgmmol = avg
            if !ismmol {
                avgmmol = avg/18.0
            }
            
            var avgscore = 0.0
            if avgmmol >= 4.0 && avgmmol <= 6.1 {
                avgscore = 120.0 - 6.56 * avgmmol // 6.1 should be 80 so 80 = 120-k*6.1 k = 40/6.1
            } else if avgmmol > 6.1 {
                avgscore = 0.9*(90.0/16.0*avgmmol*avgmmol-450.0/4.0*avgmmol+1125.0/2.0)
            } else if avgmmol < 4.0 {
                avgscore = 100.0/16.0*avgmmol*avgmmol
            }
            
            var above = 0
            var below = 0
            print("STATISTICS: ismmol \(ismmol)")
            if ismmol {
                for value in glucoseValues {
                    print("STATISTICS: value \(value) glucosePeak \(glucosePeak)")
                    if value > glucosePeak {
                        glucosePeak = value
                    }
                    if value > 6.1 {
                        above += 1
                    } else if value < 4.0 {
                        below += 1
                    }
                }
            } else {
                for value in glucoseValues {
                    if value > glucosePeak {
                        glucosePeak = value
                    }
                    if value > 110 {
                        above += 1
                    } else if value < 72 {
                        below += 1
                    }
                }
            }
            
            let ir = 100.0*Double(glucoseValues.count-above-below)/Double(glucoseValues.count)
            inRange = Int(ir)
            
            score = Int((avgscore + (100.0-cv) + ir)/3.0)
            
            print("STATISTICS: average \(avg) std \(sd) cv \(cv) \(100-cv) avgscore \(avgscore)  inRange \(ir) score \(score)")
            
            // Find when back to baseline
            
            print("STATISTICS: baseline start \(firstValue.value)@\(firstValue.date) ")
            glucoseDelta = lastValue.value - firstValue.value
            print("STATISTICS: glucosePeak \(glucosePeak) glucoseDelta \(glucoseDelta)")

        } else {
            print("STATISTICS: Could not compute \(String(describing: Sigma.average(glucoseValues))) \(String(describing: Sigma.standardDeviationSample(glucoseValues)))")
        }
        
        // Is this a good place to update metabolic score?
        
        if writeScore, let s = score, let date = startOfDay {
            print("SYNC: score \(s) date \(date)")
            save(v: Double(s)/100.0, date: date, taskIdentifier: "score")
        }
        
        return .init(title: taskEvents.firstEventTitle,
                     detail: taskEvents.firstEventDetail,
                     instructions: taskEvents.firstTaskInstructions,
                     action: {},
                     values: pointValues,
                     foods: foods,
                     average: average,
                     variability: variability,
                     inRange: inRange,
                     score: score,
                     glucosePeak: glucosePeak,
                     glucoseDelta: glucoseDelta,
                     activeEnergy: activeEnergy,
                     timeToBaseline: timeToBaseline
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
                            print("SYNC: score already had outcome values \((event.outcome as? OCKOutcome)?.values) at \(date)")
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
