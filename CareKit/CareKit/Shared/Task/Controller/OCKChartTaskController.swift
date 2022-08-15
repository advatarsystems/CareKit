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

        let errorHandler: (Error) -> Void = { [weak self] error in
            self?.error = error
        }
        var glucoseValues = [Double]()
        var pointValues = [MyChartPoint]()
        var foods = [FoodViewModel]()
        
        for events in taskEvents {
            
            for event in events {
                if let task = event.task as? OCKHealthKitTask {
                    if task.healthKitLinkage.quantityIdentifier == HKQuantityTypeIdentifier.bloodGlucose {
                        if let outcome = event.outcome {
                            if let outcome = outcome as? OCKHealthKitOutcome, let dates = outcome.dates {
                                let count = outcome.values.count
                                let values = outcome.values
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
                        if let outcome = event.outcome {
                            if let outcome = outcome as? OCKHealthKitOutcome, let dates = outcome.dates {
                                let count = outcome.values.count
                                for index in 0..<count {
                                     if let metadata = outcome.metadata {
                                        let item = metadata[index]
                                        if let name = item["HKFoodType"] {
                                            let food = FoodViewModel(name: name, date: dates[index], score: 0, startGlucose: nil, index: index)
                                            foods.append(food)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        
        var variability: Double?
        var score: Double?
        
        if let average = Sigma.average(glucoseValues), let sd = Sigma.standardDeviationSample(glucoseValues) {
            let isMol = average < 30 // Is it possible to have less than 1.6 mmol/L ?
            let dev = isMol ? 100*(average-6.1)/(6.1-3.9): 100*(average-110)/(110-70)
            let cv = sd/average*100.0
            let devf = (100 + dev)/100.0 // < 1 if below upper limit and then the score is lower
            print("STATISTICS: average \(average) std \(sd) cv \(cv) dev \(dev) devf \(devf) score \((100.0 - devf*cv))")
            variability = cv
            score = 100.0 - devf*cv
        } else {
            print("STATISTICS: Could not compute \(String(describing: Sigma.average(glucoseValues))) \(String(describing: Sigma.standardDeviationSample(glucoseValues)))")
        }
        
        return .init(title: taskEvents.firstEventTitle,
                     detail: taskEvents.firstEventDetail,
                     instructions: taskEvents.firstTaskInstructions,
                     action: toggleActionForFirstEvent(errorHandler: errorHandler),
                     isComplete: taskEvents.isFirstEventComplete,
                     values: pointValues,
                     foods: foods,
                     variability: variability,
                     score: score)
    }
}
