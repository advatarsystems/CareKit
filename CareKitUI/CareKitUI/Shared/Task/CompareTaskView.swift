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
public struct CompareTaskView<Header: View, Chart: View, Footer: View>: View {

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
                VStack {
                    header
                }
                .if(isCardEnabled && isHeaderPadded) { $0.padding([.horizontal, .top]) }

                instructions?
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(nil)
                    .if(isCardEnabled) { $0.padding([.horizontal]) }
            
                VStack {
                    chart
                }
                .if(isCardEnabled ) { $0.padding() }
                
                
                /*
                 ScrollView {
                    _CompareTaskViewList(title: Text("Foods"), detail: Text("Details"), foods: foods ?? [])
                }
                .if(isCardEnabled && isFooterPadded) { $0.padding([.horizontal, .bottom]) }
                 */
     
                // Fixme: Maybe to show average, variablity etc?
                
                VStack {
                    footer
                }
               .if(isCardEnabled && isFooterPadded) { $0.padding([.horizontal, .bottom]) }
                
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

public extension CompareTaskView where Header == _CompareTaskViewHeader, Chart == _CompareTaskViewChart {

    /// Create an instance.
    /// - Parameter title: Title text to display in the header.
    /// - Parameter detail: Detail text to display in the header.
    /// - Parameter instructions: Instructions text to display under the header.
    /// - Parameter footer: View to inject under the instructions. Specified content will be stacked vertically.
    init(title: Text, detail: Text? = nil, instructions: Text? = nil, values: [MyChartPoint]? = nil, foods: [FoodViewModel]? = nil, high: Double? = nil, mmol: Bool = true, startDate: Date? = nil, endDate: Date? = nil, detailDisclosure: Bool = false, @ViewBuilder footer: () -> Footer) {
        self.init(isHeaderPadded: true, isFooterPadded: false, instructions: instructions, header: {
            _CompareTaskViewHeader(title: title, detail: detail, action: {}, detailDisclosure: detailDisclosure)
        }, chart: {
            _CompareTaskViewChart(curve: values ?? [], foods: foods ?? [], high: high, mmol: mmol, startDate: startDate, endDate: endDate)
        }, footer: footer)
    }
}

public extension CompareTaskView where Footer == _CompareTaskViewFooter, Chart == _CompareTaskViewChart  {

    /// Create an instance.
    /// - Parameter instructions: Instructions text to display under the header.
    init(instructions: Text? = nil, values: [MyChartPoint]? = nil, foods: [FoodViewModel]? = nil, high: Double? = nil, mmol: Bool = true, startDate: Date? = nil, endDate: Date? = nil, @ViewBuilder header: () -> Header) {
        self.init(isHeaderPadded: false, isFooterPadded: true, instructions: instructions, header: header, chart: {
            _CompareTaskViewChart(curve: values ?? [], foods: foods ?? [], high: high, mmol: mmol, startDate: startDate,endDate: endDate)
        },footer: {
            _CompareTaskViewFooter(title: Text("title"), detail: Text("detail"))
        })
    }
}

public extension CompareTaskView where Header == _CompareTaskViewHeader, Chart == _CompareTaskViewChart, Footer == _CompareTaskViewFooter {

    /// Create an instance.
    /// - Parameter title: Title text to display in the header.
    /// - Parameter detail: Detail text to display in the header.
    /// - Parameter instructions: Instructions text to display under the header.
    init(title: Text, detail: Text? = nil, instructions: Text? = nil, values: [MyChartPoint]? = nil, foods: [FoodViewModel]? = nil,  high: Double? = nil, mmol: Bool = true, average: Double? = nil, variability: Int? = nil, score: Int? = nil, startDate: Date? = nil, endDate: Date? = nil, detailDisclosure: Bool = false, action: @escaping () -> Void = {}) {
       
        self.init(isHeaderPadded: true, isFooterPadded: true, instructions: instructions, foods: foods, header: {
            _CompareTaskViewHeader(title: title, detail: detail, action: action, detailDisclosure: detailDisclosure)
        }, chart: {
            _CompareTaskViewChart(curve: values ?? [], foods: foods ?? [], high: high, mmol: mmol, startDate: startDate, endDate: endDate)
        }, footer: {
            _CompareTaskViewFooter(title: Text("title"), detail: Text("detail"))
        })
        
       
    }
}

/// The default header used by a `CompareTaskView`.
public struct _CompareTaskViewHeader: View {

    @Environment(\.careKitStyle) private var style

    fileprivate let title: Text
    fileprivate let detail: Text?
    fileprivate let action: () -> Void
    fileprivate let detailDisclosure: Bool

    public var body: some View {
        VStack(alignment: .leading, spacing: style.dimension.directionalInsets1.top) {
            HStack {
                HeaderView(title: title, detail: detail, image: nil)
                Spacer()
                if detailDisclosure{ HStack {
                        Text("84").font(.title).fontWeight(.bold).foregroundColor(Color(UIColor.lightGray))
                        Image(systemName: "chevron.right")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(Color(UIColor.lightGray))
                    }
                }
            }.onTapGesture {
                action()
            }
            Divider()
        }
    }
}

/// The default footer used by an `CompareTaskView`.
public struct _CompareTaskViewFooter: View {

    fileprivate let title: Text
    fileprivate let detail: Text?
 
    @Environment(\.sizeCategory) private var sizeCategory
    @Environment(\.careKitStyle) private var style

    @OSValue<CGFloat>(values: [.watchOS: 8], defaultValue: 14) private var padding

    fileprivate let average: Double
    fileprivate let variability: Int
    fileprivate let inRange: Int
    fileprivate let score: Int

    public init(title: Text, detail: Text, average: Double = 5.0, variability: Int = 12, inRange: Int = 98, score: Int = 50) {
        self.title = title
        self.detail = detail
        self.average = average
        self.variability = variability
        self.inRange = inRange
        self.score = score
    }
    
    public var body: some View {
        if average != 0 {
            VStack {
                HStack {
                    Text("Average: ")
                    Text(String(average)+"%").fontWeight(.bold)
                    Spacer()
                    Text("Variability: ")
                    Text(String(variability)+"%").fontWeight(.bold)
                }
                HStack {
                    Text("In Range: ")
                    Text(String(inRange)+"%").fontWeight(.bold)
                    Spacer()
                    Text("Score: ")
                    Text(String(score)).fontWeight(.bold)
                }
            }.font(.caption)
        } else {
            EmptyView()
        }
    }
}

func findElementOnCurve(location: CGPoint,
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

/// The default header used by a `ComparTaskView`.
public struct _CompareTaskViewList: View {

    @Environment(\.careKitStyle) private var style

    fileprivate let title: Text
    fileprivate let detail: Text?
    private let foods: [FoodViewModel]

    public init(title: Text, detail: Text,foods: [FoodViewModel]) {
        self.title = title
        self.detail = detail
        self.foods = foods
    }
    
    public var body: some View {
        
        ForEach(foods) { food in
            let hour = Calendar.current.component(.hour, from: food.date)
            let minute = Calendar.current.component(.minute, from: food.date)
            let time = "\(hour):\(minute)"
            LabeledValueTaskView(title: Text(food.name),
                                detail: Text(time),
                                state: .complete(Text(String(describing: Int(food.score ?? 0))), nil)
            ).padding()
            Divider()
        }
        
    }
}

public struct _CompareTaskViewChart: View {
    
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
        
        var newFoods = [FoodViewModel]()
        for (findex,food) in foods.enumerated().reversed() {
            if curve.isEmpty {
                let newFood = FoodViewModel(name: food.name, date: food.date, score: food.score, startGlucose: 0, index: 1)
                newFoods.append(newFood)
            } else {
                var prev: MyChartPoint = curve.first!
                for (_,point) in curve.enumerated().reversed() {
                   // let match = point.date != prev.date && food.date >= prev.date  && food.date <= point.date
                    if point.date != prev.date, food.date >= prev.date, food.date <= point.date {
                        let newFood = FoodViewModel(name: food.name, date: food.date, score: food.score, startGlucose: point.value, index: findex+1)
                        newFoods.append(newFood)
                    }
                    prev = point
                }
            }
        }
        self.foods = newFoods
    }
    
    public var body: some View {
        
        if data.curve.isEmpty {
            VStack {
                Text("NO DATA")
            }.frame(height: 200)
        } else {
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
                ForEach(foods) { food in
                    PointMark(
                        x: .value("Day", food.date),
                        y: .value("Sales", food.startGlucose)
                    )
                    .symbolSize(symbolSize*3)
                    .symbol {
                        Image(systemName: "\(foods.count-food.index+1).circle.fill").opacity(1.0).zIndex(10).background(
                            Color(UIColor.systemBackground).mask(Circle())
                          )
                    }.foregroundStyle(.red)
                    .opacity(1.0)
                }
                
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
                                    let element = findElementOnCurve(location: value.location,
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
                                        selectedElement = findElementOnCurve(location: value.location,
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
                            let boxWidth: CGFloat = 70
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
}

#if DEBUG
struct CompareTaskView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            CompareTaskView(title: Text("Title"), detail: Text("Detail"), instructions: Text("Instructions"))
            CompareTaskView(title: Text("Title"), detail: Text("Detail"), instructions: Text("Instructions"))
        }.padding()
    }
}
#endif
