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
import Foundation
import SwiftUI
import Charts

/// A card that displays a header view, multi-line label, and a completion button.
///
/// In CareKit, this view is intended to display a particular event for a task. The state of the button indicates the completion state of the event.
///
/// # Style
/// The card supports styling using `careKitStyle(_:)`.
///
/// ```
///     +-------------------------------------------------------+
///     |                                                       |
///     |  <Title>                                              |
///     |  <Detail>                                             |
///     |                                                       |
///     |  --------------------------------------------------   |
///     |                                                       |
///     |  <Instructions>                                       |
///     |                                                       |
///     |  +-------------------------------------------------+  |
///     |  |               <Completion Button>               |  |
///     |  +-------------------------------------------------+  |
///     |                                                       |
///     +-------------------------------------------------------+
/// ```
public struct EventTaskView<Header: View, List: View, Footer: View>: View {

    // MARK: - Properties

    @Environment(\.careKitStyle) private var style
    @Environment(\.isCardEnabled) private var isCardEnabled

    private let isHeaderPadded: Bool
    private let isFooterPadded: Bool
    private let header: Header
    private let list: List
    private let footer: Footer
    private let instructions: Text?

    public var body: some View {
        
        CardView {
            VStack(alignment: .leading, spacing: style.dimension.directionalInsets1.top) {
                /*
                VStack {
                    header
                }
                .if(isCardEnabled && isHeaderPadded) { $0.padding([.horizontal, .top]) }*/

                instructions?
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(nil)
                    .if(isCardEnabled) { $0.padding([.horizontal]) }
                
                VStack {
                    list
                }
               // .if(isCardEnabled ) { $0.padding() }
                
                /*
                VStack {
                    footer
                }
               .if(isCardEnabled && isFooterPadded) { $0.padding([.horizontal, .bottom]) }
                 */
                
            }
        }
    }

    // MARK: - Init

    /// Create an instance.
    /// - Parameter instructions: Instructions text to display under the header.
    /// - Parameter header: Header to inject at the top of the card. Specified content will be stacked vertically.
    /// - Parameter footer: View to inject under the instructions. Specified content will be stacked vertically.
    public init(instructions: Text? = nil, @ViewBuilder header: () -> Header, @ViewBuilder list: () -> List, @ViewBuilder footer: () -> Footer) {
        self.init(isHeaderPadded: false, isFooterPadded: false, instructions: instructions, header: header, list: list, footer: footer)
    }

    init(isHeaderPadded: Bool, isFooterPadded: Bool, instructions: Text? = nil, foods: [FoodViewModel]? = nil,
         @ViewBuilder header: () -> Header, @ViewBuilder list: () -> List, @ViewBuilder footer: () -> Footer) {
        self.isHeaderPadded = isHeaderPadded
        self.isFooterPadded = isFooterPadded
        self.instructions = instructions
        self.header = header()
        self.list = list()
        self.footer = footer()
    }
}

public extension EventTaskView where Header == _EventTaskViewHeader, List == _EventTaskViewList {

    /// Create an instance.
    /// - Parameter title: Title text to display in the header.
    /// - Parameter detail: Detail text to display in the header.
    /// - Parameter instructions: Instructions text to display under the header.
    /// - Parameter footer: View to inject under the instructions. Specified content will be stacked vertically.
    init(title: Text, detail: Text? = nil, instructions: Text? = nil, foods: [FoodViewModel]? = nil, @ViewBuilder footer: () -> Footer) {

        self.init(isHeaderPadded: true, isFooterPadded: false, instructions: instructions, header: {
            _EventTaskViewHeader(title: title, detail: detail)
        }, list: {
            _EventTaskViewList( foods: foods ?? [])
        }, footer: footer)
    }
}

public extension EventTaskView where Footer == _EventTaskViewFooter, List == _EventTaskViewList  {

    /// Create an instance.
    /// - Parameter instructions: Instructions text to display under the header.
    /// - Parameter isComplete: True if the button under the instructions is in the completed.
    /// - Parameter action: Action to perform when the button is tapped.
    /// - Parameter header: Header to inject at the top of the card. Specified content will be stacked vertically.
    init(instructions: Text? = nil, foods: [FoodViewModel]? = nil, isComplete: Bool, action: @escaping () -> Void = {}, @ViewBuilder header: () -> Header) {
        
        self.init(isHeaderPadded: false, isFooterPadded: true, instructions: instructions, header: header, list: {
            _EventTaskViewList(foods: foods ?? [])
        },footer: {
            _EventTaskViewFooter(isComplete: isComplete, action: action)
        })
    }
}

public extension EventTaskView where Header == _EventTaskViewHeader, List == _EventTaskViewList, Footer == _EventTaskViewFooter {

    /// Create an instance.
    /// - Parameter title: Title text to display in the header.
    /// - Parameter detail: Detail text to display in the header.
    /// - Parameter instructions: Instructions text to display under the header.
    /// - Parameter isComplete: True if the button under the instructions is in the completed state.
    /// - Parameter action: Action to perform when the button is tapped.
    init(title: Text, detail: Text? = nil, instructions: Text? = nil, foods: [FoodViewModel]? = nil,   isComplete: Bool, action: @escaping () -> Void = {}) {
       
        self.init(isHeaderPadded: true, isFooterPadded: true, instructions: instructions, foods: foods, header: {
            _EventTaskViewHeader(title: title, detail: detail)
        }, list: {
            _EventTaskViewList(foods: foods ?? [])
        }, footer: {
            _EventTaskViewFooter(isComplete: isComplete, action: action)
        })
       
    }
}

/// The default header used by a `EventTaskView`.
public struct _EventTaskViewHeader: View {

    @Environment(\.careKitStyle) private var style

    fileprivate let title: Text
    fileprivate let detail: Text?

    public var body: some View {
        VStack(alignment: .leading, spacing: style.dimension.directionalInsets1.top) {
            HeaderView(title: title, detail: detail)
            Divider()
        }
    }
}


/// The default footer used by an `InstructionsTaskView`.
public struct _EventTaskViewFooter: View {

    @Environment(\.sizeCategory) private var sizeCategory

    @OSValue<CGFloat>(values: [.watchOS: 8], defaultValue: 14) private var padding

    private var content: some View {
        Group {
           Text("")
        }
        .multilineTextAlignment(.center)
    }

    fileprivate let isComplete: Bool
    fileprivate let action: () -> Void

    public var body: some View {
        HStack {
            Spacer()
            content
            Spacer()
        }.padding(padding.scaled())
    }
}

/// The default header used by a `EventTaskView`.
public struct _EventTaskViewList: View {

    @Environment(\.careKitStyle) private var style

    private let foods: [FoodViewModel]

    public init(foods: [FoodViewModel]) {
        self.foods = foods
    }
    
    public var isEmpty: Bool {
        return foods.isEmpty
    }
    
    public var body: some View {
        
        if foods.isEmpty {
            EmptyView()
            /*VStack {
                Text("NO FOOD LOGGED")
            }.frame(height: Double(100.0))*/
        } else {
            ScrollView {
                ForEach(foods) { food in
                    let hour = Calendar.current.component(.hour, from: food.date)
                    let minute = Calendar.current.component(.minute, from: food.date)
                    let time = "\(hour < 10 ? "0":"")\(hour):\(minute < 10 ? "0":"")\(minute)"
                    LabeledValueTaskView(title: Text(food.name),
                                         detail: Text(time),
                                         state: .complete(Text(String(describing: Int(food.score ?? 0))), nil)
                    )//.frame(height: 50)
                    Divider()
                }
            }.padding().frame(height: Double(foods.count)*100.0)
        }
    }
}

#if DEBUG
struct EventTaskView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            EventTaskView(title: Text("Title"), detail: Text("Detail"), instructions: Text("Instructions"), isComplete: false)
            EventTaskView(title: Text("Title"), detail: Text("Detail"), instructions: Text("Instructions"), isComplete: true)
        }.padding()
    }
}
#endif
