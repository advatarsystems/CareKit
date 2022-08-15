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

open class OCKMultiChartTaskController: OCKTaskController {

    /// Data used to create a `CareKitUI.ChartTaskView`.
    @Published public private(set) var viewModels: [ChartTaskViewModel]? {
        willSet { objectWillChange.send() }
    }

    private var cancellable: AnyCancellable?

    public required init(storeManager: OCKSynchronizedStoreManager) {
        super.init(storeManager: storeManager)
        cancellable = $taskEvents.sink { taskEvents in
            self.viewModels = self.makeViewModels(from: [taskEvents])
        }
    }
    
    private func makeViewModels(from taskEvents: [OCKTaskEvents]) -> [ChartTaskViewModel]? {
        guard !taskEvents.isEmpty else { return nil }

        let errorHandler: (Error) -> Void = { [weak self] error in
            self?.error = error
        }
        var pointValues = [MyChartPoint]()
        
        for taskEvent in taskEvents {
            for events in taskEvent {
                for event in events {
                    if let _ = event.task as? OCKHealthKitTask {
                        if let outcome = event.outcome {
                            if let outcome = outcome as? OCKHealthKitOutcome, let dates = outcome.dates {
                                let count = outcome.values.count
                                let values = outcome.values
                                for index in 0..<count {
                                    if let doubleValue = values[index].doubleValue {
                                        let newValue = CareKitUI.MyChartPoint(value: doubleValue, date: dates[index])
                                        pointValues.append(newValue)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        guard let firstEvent = taskEvents.first, let lastEvent = taskEvents.last else {
            return nil
        }
        
        let viewModelFirst = ChartTaskViewModel(title: firstEvent.firstEventTitle,
                                            detail: firstEvent.firstEventDetail,
                                            instructions: firstEvent.firstTaskInstructions,
                                            action: toggleActionForFirstEvent(errorHandler: errorHandler),
                                            isComplete: firstEvent.isFirstEventComplete,
                                                values: pointValues, foods: nil, variability: nil, score: nil)
       
        let viewModelLast = ChartTaskViewModel(title: lastEvent.firstEventTitle,
                                            detail: lastEvent.firstEventDetail,
                                            instructions: lastEvent.firstTaskInstructions,
                                            action: toggleActionForFirstEvent(errorHandler: errorHandler),
                                            isComplete: lastEvent.isFirstEventComplete,
                                            values: pointValues, foods: nil, variability: nil, score: nil)

        return [viewModelFirst,viewModelLast ]
        
    }
}
