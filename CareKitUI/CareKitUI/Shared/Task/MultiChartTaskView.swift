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
public struct MultiChartTaskView<Header: View, Chart: View, Footer: View>: View {

    // MARK: - Properties

    @Environment(\.careKitStyle) private var style
    @Environment(\.isCardEnabled) private var isCardEnabled

    private let isHeaderPadded: Bool
    private let isFooterPadded: Bool
    private let header: Header
    private let chart: Chart
    private let footer: Footer
    private let instructions: Text?
    private let foods: [FoodViewModel]?
    private let high: Double?
    private let mmol: Bool
    private let startDate: Date?
    private let endDate: Date?

    public var body: some View {
        CardView {
            VStack(alignment: .leading, spacing: style.dimension.directionalInsets1.top) {
                VStack { header }
                    .if(isCardEnabled && isHeaderPadded) { $0.padding([.horizontal, .top]) }

                instructions?
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(nil)
                    .if(isCardEnabled) { $0.padding([.horizontal]) }
                
                VStack { chart }
                    .if(isCardEnabled ) { $0.padding() }
                
                // Fixme: Maybe to show average?
                /*
                VStack { footer }
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
    public init(instructions: Text? = nil, @ViewBuilder header: () -> Header, @ViewBuilder chart: () -> Chart, @ViewBuilder footer: () -> Footer) {
        self.init(isHeaderPadded: false, isFooterPadded: false, instructions: instructions, header: header, chart: chart, footer: footer)
    }

    init(isHeaderPadded: Bool, isFooterPadded: Bool, instructions: Text? = nil, foods: [FoodViewModel]? = nil, high: Double? = nil, mmol: Bool = true, startDate: Date? = nil, endDate: Date? = nil,
         @ViewBuilder header: () -> Header, @ViewBuilder chart: () -> Chart, @ViewBuilder footer: () -> Footer) {
        self.isHeaderPadded = isHeaderPadded
        self.isFooterPadded = isFooterPadded
        self.instructions = instructions
        self.header = header()
        self.chart = chart()
        self.footer = footer()
        self.foods = foods
        self.high = high
        self.mmol = mmol
        self.startDate = startDate
        self.endDate = endDate
    }
}

public extension MultiChartTaskView where Header == _MultiChartTaskViewHeader, Chart == _MultiChartTaskViewChart {

    /// Create an instance.
    /// - Parameter title: Title text to display in the header.
    /// - Parameter detail: Detail text to display in the header.
    /// - Parameter instructions: Instructions text to display under the header.
    /// - Parameter footer: View to inject under the instructions. Specified content will be stacked vertically.
    init(title: Text, detail: Text? = nil, instructions: Text? = nil, values: [MyChartPoint]? = nil, foods: [FoodViewModel]? = nil, high: Double? = nil, mmol: Bool = true, startDate: Date? = nil, endDate: Date? = nil, @ViewBuilder footer: () -> Footer) {
        self.init(isHeaderPadded: true, isFooterPadded: false, instructions: instructions, header: {
            _MultiChartTaskViewHeader(title: title, detail: detail)
        }, chart: {
            _MultiChartTaskViewChart(curve: values ?? [], foods: foods ?? [], high: high, mmol: mmol, startDate: startDate, endDate: endDate)
        }, footer: footer)
    }
}

public extension MultiChartTaskView where Footer == _MultiChartTaskViewFooter, Chart == _MultiChartTaskViewChart  {

    /// Create an instance.
    /// - Parameter instructions: Instructions text to display under the header.
    /// - Parameter isComplete: True if the button under the instructions is in the completed.
    /// - Parameter action: Action to perform when the button is tapped.
    /// - Parameter header: Header to inject at the top of the card. Specified content will be stacked vertically.
    init(instructions: Text? = nil, values: [MyChartPoint]? = nil, foods: [FoodViewModel]? = nil, high: Double? = nil, mmol: Bool = true, startDate: Date? = nil, endDate: Date? = nil, isComplete: Bool, action: @escaping () -> Void = {}, @ViewBuilder header: () -> Header) {
        self.init(isHeaderPadded: false, isFooterPadded: true, instructions: instructions, header: header, chart: {
            _MultiChartTaskViewChart(curve: values ?? [], foods: foods ?? [], high: high, mmol: mmol, startDate: startDate,endDate: endDate)
        },footer: {
            _MultiChartTaskViewFooter(isComplete: isComplete, action: action)
        })
    }
}

public extension MultiChartTaskView where Header == _MultiChartTaskViewHeader, Chart == _MultiChartTaskViewChart, Footer == _MultiChartTaskViewFooter {

    /// Create an instance.
    /// - Parameter title: Title text to display in the header.
    /// - Parameter detail: Detail text to display in the header.
    /// - Parameter instructions: Instructions text to display under the header.
    /// - Parameter isComplete: True if the button under the instructions is in the completed state.
    /// - Parameter action: Action to perform when the button is tapped.
    init(title: Text, detail: Text? = nil, instructions: Text? = nil, values: [MyChartPoint]? = nil, foods: [FoodViewModel]? = nil,  high: Double? = nil, mmol: Bool = true, startDate: Date? = nil, endDate: Date? = nil, isComplete: Bool, action: @escaping () -> Void = {}) {
        self.init(isHeaderPadded: true, isFooterPadded: true, instructions: instructions, foods: foods, header: {
            _MultiChartTaskViewHeader(title: title, detail: detail)
        }, chart: {
            _MultiChartTaskViewChart(curve: values ?? [], foods: foods ?? [], high: high, mmol: mmol, startDate: startDate, endDate: endDate)
        }, footer: {
            _MultiChartTaskViewFooter(isComplete: isComplete, action: action)
        })
    }
}

/// The default header used by a `MultiChartTaskView`.
public struct _MultiChartTaskViewHeader: View {

    @Environment(\.careKitStyle) private var style

    fileprivate let title: Text
    fileprivate let detail: Text?

    public var body: some View {
        VStack(alignment: .leading, spacing: style.dimension.directionalInsets1.top) {
            HeaderView(title: title, detail: detail, image: nil)
            Divider()
        }
    }
}

/// The default footer used by an `ChartTaskView`.
public struct _MultiChartTaskViewFooter: View {

    @Environment(\.sizeCategory) private var sizeCategory

    @OSValue<CGFloat>(values: [.watchOS: 8], defaultValue: 14) private var padding

    private var content: some View {
        Group {
            if isComplete {
                HStack {
                    Text(loc("COMPLETED"))
                    Image(systemName: "checkmark")
                }
            } else {
                Text(loc("MARK_COMPLETE"))
            }
        }
        .multilineTextAlignment(.center)
    }

    fileprivate let isComplete: Bool
    fileprivate let action: () -> Void

    public var body: some View {
        Button(action: action) {
            RectangularCompletionView(isComplete: isComplete) {
                HStack {
                    Spacer()
                    content
                    Spacer()
                }.padding(padding.scaled())
            }
        }.buttonStyle(NoHighlightStyle())
    }
}

func findMultiElement(location: CGPoint,
                 proxy: ChartProxy,
                 curve: [MyChartPoint],
                 geometry: GeometryProxy) -> MyChartPoint? {
  // Figure out the X position by offseting gesture location with chart frame
  let relativeXPosition = location.x - geometry[proxy.plotAreaFrame].origin.x
  // Use value(atX:) to find plotted value for the given X axis position.
  // Since FoodIntake chart plots `date` on the X axis, we'll get a Date back.
  if let date = proxy.value(atX: relativeXPosition) as Date? {
    // Find the closest date element.
    var minDistance: TimeInterval = .infinity
    var index: Int? = nil
    for dataIndex in curve.indices {
      let nthDataDistance = curve[dataIndex].date.distance(to: date)
      if abs(nthDataDistance) < minDistance {
        minDistance = abs(nthDataDistance)
        index = dataIndex
      }
    }
    if let index {
      return curve[index]
    }
  }
  return nil
}

        
public struct _MultiChartTaskViewChart: View {
    
    let symbolSize: CGFloat = 100
    let lineWidth: CGFloat = 3
    private let curve: [MyChartPoint]
    private let foods: [FoodViewModel]
    private let high: Double?
    @State var selectedElement: MyChartPoint?
    private let mmol: Bool
    private let startDate: Date?
    private let endDate: Date?

    var data = ChartData()
    
    init(curve: [MyChartPoint], foods: [FoodViewModel], high: Double?, mmol: Bool, startDate: Date? = nil, endDate: Date? = nil) {
        if let start = startDate, let end = endDate {
            self.curve = curve.filter{ $0.date >= start && $0.date <= end
                
            }
        } else {
            self.curve = curve
        }
        self.foods = foods
        self.high = high
        self.mmol = mmol
        self.startDate = startDate
        self.endDate = endDate
        
        if let thisDay = self.curve.first?.date {
            var startOfDay = Calendar.current.startOfDay(for: thisDay)
            let oneday: TimeInterval = 24*60*60
            var endOfDay = startOfDay.addingTimeInterval(oneday)
            
            if let start = startDate, let end = endDate {
                startOfDay = start
                endOfDay = end
            }
            
            var value = 3.9
            if !mmol {
                value *= 18.0
            }
            let low = [MyChartPoint(value: value, date: startOfDay), MyChartPoint(value:value, date: endOfDay)]
            
            value = 10.0
            if !mmol {
                value *= 18.0
            }
            let high = [MyChartPoint(value: value, date: startOfDay), MyChartPoint(value: value, date: endOfDay)]
            let curveSeries = ChartData.Series(name: "curve", values: self.curve, lineWidth: 3.0)
            let lowSeries = ChartData.Series(name: "low", values: low, lineWidth: 1.0)
            let highSeries = ChartData.Series(name: "high", values: high, lineWidth: 1.0)
            if let high = self.high {
                value = high
                if !mmol {
                    value *= 18.0
                }
                let ideal = [MyChartPoint(value: value, date: startOfDay), MyChartPoint(value:value, date: endOfDay)]
                let idealSeries = ChartData.Series(name: "ideal", values: ideal, lineWidth: 1.0)
                data.curve = [curveSeries,lowSeries,highSeries,idealSeries]
            } else {
                data.curve = [curveSeries,lowSeries,highSeries]
            }
        }
    
    }
    
    public var body: some View {
        
        Chart {
            ForEach(data.curve) { series in
                ForEach(series.values, id: \.date) { element in
                    LineMark(
                        x: .value("Day", element.date),
                        y: .value("Sales", element.value)
                    )
                }
                .foregroundStyle(by: .value("Name", series.name))
                .interpolationMethod(.catmullRom)
                .lineStyle(StrokeStyle(lineWidth: series.lineWidth))
                .symbolSize(symbolSize)
            }
            /*
            ForEach(curve, id: \.date) { element in
                LineMark(
                    x: .value("Day", element.date),
                    y: .value("Sales", element.value)
                )
            }
            //.foregroundStyle(by: .value("City", "x"))
            //.symbol(by: .value("City", series.city))
            .interpolationMethod(.catmullRom)
            .lineStyle(StrokeStyle(lineWidth: lineWidth))
            .symbolSize(symbolSize)
            */
        
            
            if selectedElement != nil {
                PointMark(
                    x: .value("Day", selectedElement!.date),
                    y: .value("Sales", selectedElement!.value)
                )
                .foregroundStyle(.red)
                .symbolSize(symbolSize)
            }
        }
        .chartOverlay { proxy in
            GeometryReader { geo in
                Rectangle()
                    .fill(.clear)
                    .contentShape(Rectangle())
                    .gesture(
                        SpatialTapGesture()
                            .onEnded { value in
                                let element = findElement(location: value.location,
                                                          proxy: proxy,
                                                          curve: curve,
                                                          geometry: geo)
                                if selectedElement?.date == element?.date {
                                    // If tapping the same element, clear the selection.
                                    selectedElement = nil
                                } else {
                                    selectedElement = element
                                }
                            }
                            .exclusively(before: DragGesture()
                                .onChanged { value in
                                    selectedElement = findElement(location: value.location,
                                                                  proxy: proxy, curve: curve,
                                                                  geometry: geo)
                                })
                    )
            }
        }
        .chartBackground { proxy in
            ZStack(alignment: .topLeading) {
                GeometryReader { geo in
                    if let selectedElement {
                        // Find date span for the selected interval
                        let dateInterval = Calendar.current.dateInterval(of: .minute, for: selectedElement.date)!
                        // Map date to chart X position
                        let startPositionX = proxy.position(forX: dateInterval.start) ?? 0
                        // Offset the chart X position by chart frame
                        let midStartPositionX = startPositionX + geo[proxy.plotAreaFrame].origin.x
                        let lineHeight = geo[proxy.plotAreaFrame].maxY
                        let boxWidth: CGFloat = 50
                        let boxOffset = max(0, min(geo.size.width - boxWidth, midStartPositionX - boxWidth / 2))
                        
                        // Draw the scan line
                        Rectangle()
                            .fill(.quaternary)
                            .frame(width: 2, height: lineHeight)
                            .position(x: midStartPositionX, y: lineHeight / 2)
                        
                        // Draw the data info box
                        VStack(alignment: .leading) {
                            Text("\(selectedElement.date, format: .dateTime.hour().minute())")
                                .font(.callout)
                                .foregroundStyle(.secondary)
                            Text("\(selectedElement.value.roundToPlaces(places: 1), format: .number) ")
                                .font(.title2.bold())
                                .foregroundColor(.primary)
                        }
                        .frame(width: boxWidth, alignment: .leading)
                        .background { // some styling
                            ZStack {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(.background)
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(.quaternary.opacity(0.7))
                            }
                            .padding([.leading, .trailing], -8)
                            .padding([.top, .bottom], -4)
                        }
                        .offset(x: boxOffset)
                    }
                }
            }
        }
        /*.chartForegroundStyleScale([
         "x": .purple
         ])
         .chartSymbolScale([
         "x": Circle().strokeBorder(lineWidth: lineWidth)
         ])*/
        .chartXAxis {
            AxisMarks(values: .stride(by: .hour)) { _ in
                AxisValueLabel(format: .dateTime.hour(.defaultDigits(amPM:.abbreviated)), centered: true, collisionResolution: AxisValueLabelCollisionResolution.greedy)
            }
        }
        .chartYScale(range: .plotDimension(endPadding: 8))
        .chartLegend(.hidden)
        .frame(height: 200)
    }

    
}


#if DEBUG
struct MultiChartTaskView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            MultiChartTaskView(title: Text("Title"), detail: Text("Detail"), instructions: Text("Instructions"), isComplete: false)
            MultiChartTaskView(title: Text("Title"), detail: Text("Detail"), instructions: Text("Instructions"), isComplete: true)
        }.padding()
    }
}
#endif
