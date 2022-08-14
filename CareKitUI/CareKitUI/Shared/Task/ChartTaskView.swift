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

public class MyChartPoint {
    let value: Double
    let date: Date
    public init(value: Double, date: Date) {
        self.value = value
        self.date = date
    }
}


extension Double {
    func roundToPlaces(places:Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return (self * divisor).rounded() / divisor
    }
}

struct ChartData {
    /// A data series for the lines.
    struct Series: Identifiable {
        /// The name of the city.
        let name: String
        
        /// Average daily sales for each weekday.
        /// The `weekday` property is a `Date` that represents a weekday.
        let values: [MyChartPoint]
        
        let lineWidth: CGFloat
        
        /// The identifier for the series.
        var id: String { name }
    }
    
    /// Sales by location and weekday for the last 30 days.
    var curve: [Series] = [ ]

}

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
public struct ChartTaskView<Header: View, Chart: View, Footer: View>: View {

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
                    _ChartTaskViewList(title: Text("Foods"), detail: Text("Details"), foods: foods ?? [])
                }
                .if(isCardEnabled && isFooterPadded) { $0.padding([.horizontal, .bottom]) }
                 */
     
                // Fixme: Maybe to show average, variablity etc?
                /*
                VStack {
                    footer
                }*/
               // .if(isCardEnabled && isFooterPadded) { $0.padding([.horizontal, .bottom]) }
                
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

public extension ChartTaskView where Header == _ChartTaskViewHeader, Chart == _ChartTaskViewChart {

    /// Create an instance.
    /// - Parameter title: Title text to display in the header.
    /// - Parameter detail: Detail text to display in the header.
    /// - Parameter instructions: Instructions text to display under the header.
    /// - Parameter footer: View to inject under the instructions. Specified content will be stacked vertically.
    init(title: Text, detail: Text? = nil, instructions: Text? = nil, values: [MyChartPoint]? = nil, foods: [FoodViewModel]? = nil, high: Double? = nil, mmol: Bool = true, startDate: Date? = nil, endDate: Date? = nil, @ViewBuilder footer: () -> Footer) {
        self.init(isHeaderPadded: true, isFooterPadded: false, instructions: instructions, header: {
            _ChartTaskViewHeader(title: title, detail: detail, action: {})
        }, chart: {
            _ChartTaskViewChart(curve: values ?? [], foods: foods ?? [], high: high, mmol: mmol, startDate: startDate, endDate: endDate)
        }, footer: footer)
    }
}

public extension ChartTaskView where Footer == _ChartTaskViewFooter, Chart == _ChartTaskViewChart  {

    /// Create an instance.
    /// - Parameter instructions: Instructions text to display under the header.
    /// - Parameter isComplete: True if the button under the instructions is in the completed.
    /// - Parameter action: Action to perform when the button is tapped.
    /// - Parameter header: Header to inject at the top of the card. Specified content will be stacked vertically.
    init(instructions: Text? = nil, values: [MyChartPoint]? = nil, foods: [FoodViewModel]? = nil, high: Double? = nil, mmol: Bool = true, startDate: Date? = nil, endDate: Date? = nil, isComplete: Bool, action: @escaping () -> Void = {}, @ViewBuilder header: () -> Header) {
        self.init(isHeaderPadded: false, isFooterPadded: true, instructions: instructions, header: header, chart: {
            _ChartTaskViewChart(curve: values ?? [], foods: foods ?? [], high: high, mmol: mmol, startDate: startDate,endDate: endDate)
        },footer: {
            _ChartTaskViewFooter(isComplete: isComplete, action: action, title: Text("title"), detail: Text("detail"), foods: foods ?? [])
        })
    }
}

public extension ChartTaskView where Header == _ChartTaskViewHeader, Chart == _ChartTaskViewChart, Footer == _ChartTaskViewFooter {

    /// Create an instance.
    /// - Parameter title: Title text to display in the header.
    /// - Parameter detail: Detail text to display in the header.
    /// - Parameter instructions: Instructions text to display under the header.
    /// - Parameter isComplete: True if the button under the instructions is in the completed state.
    /// - Parameter action: Action to perform when the button is tapped.
    init(title: Text, detail: Text? = nil, instructions: Text? = nil, values: [MyChartPoint]? = nil, foods: [FoodViewModel]? = nil,  high: Double? = nil, mmol: Bool = true, startDate: Date? = nil, endDate: Date? = nil, isComplete: Bool, action: @escaping () -> Void = {}) {
       
        self.init(isHeaderPadded: true, isFooterPadded: true, instructions: instructions, foods: foods, header: {
            _ChartTaskViewHeader(title: title, detail: detail, action: action)
        }, chart: {
            _ChartTaskViewChart(curve: values ?? [], foods: foods ?? [], high: high, mmol: mmol, startDate: startDate, endDate: endDate)
        }, footer: {
            _ChartTaskViewFooter(isComplete: isComplete, action: action, title: Text("title"), detail: Text("detail"), foods: foods ?? [])
        })
        
       
    }
}

/// The default header used by a `ChartTaskView`.
public struct _ChartTaskViewHeader: View {

    @Environment(\.careKitStyle) private var style

    fileprivate let title: Text
    fileprivate let detail: Text?
    fileprivate let action: () -> Void

    public var body: some View {
        VStack(alignment: .leading, spacing: style.dimension.directionalInsets1.top) {
            HStack {
                HeaderView(title: title, detail: detail)
                Spacer()
                Image(systemName: "chevron.right")
            }.onTapGesture {
                action()
            }
            Divider()
        }
    }
}

/// The default footer used by an `ChartTaskView`.
public struct _ChartTaskViewFooter: View {

    fileprivate let title: Text
    fileprivate let detail: Text?
    private let foods: [FoodViewModel]

    @Environment(\.sizeCategory) private var sizeCategory
    @Environment(\.careKitStyle) private var style

    @OSValue<CGFloat>(values: [.watchOS: 8], defaultValue: 14) private var padding

    fileprivate let isComplete: Bool
    fileprivate let action: () -> Void

    public init(isComplete: Bool, action: @escaping () -> Void = {}, title: Text, detail: Text,foods: [FoodViewModel]) {
        self.isComplete = isComplete
        self.action = action
        self.title = title
        self.detail = detail
        self.foods = foods
    }
    
    private var content: some View {
        
        VStack {
            ForEach(foods) { food in
                let hour = Calendar.current.component(.hour, from: food.date)
                let minute = Calendar.current.component(.minute, from: food.date)
                let time = "\(hour):\(minute)"
                LabeledValueTaskView(title: Text(food.name),
                                     detail: Text(time),
                                     state: .complete(Text(String(describing: Int(food.score ?? 0))), nil)
                )
            }
        }
    }
    
    private var xcontent: some View {
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


    public var body: some View {
        
        content
        
        /*
        HStack {
            Spacer()
            content
            Spacer()
        }.padding(padding.scaled())
        */
        
        /*Button(action: action) {
            RectangularCompletionView(isComplete: isComplete) {
                HStack {
                    Spacer()
                    content
                    Spacer()
                }.padding(padding.scaled())
            }
        }.buttonStyle(NoHighlightStyle())
         */
    }
}

func findElement(location: CGPoint,
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

/// The default header used by a `ChartTaskView`.
public struct _ChartTaskViewList: View {

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

public struct _ChartTaskViewChart: View {
    
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
                let newFood = FoodViewModel(name: food.name, date: food.date, score: food.score, startGlucose: 0, index: 0)
                newFoods.append(newFood)
            } else {
                var prev: MyChartPoint = curve.first!
                for (index,point) in curve.enumerated().reversed() {
                    
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
                    .symbolSize(symbolSize*2)
                    .symbol {
                        Image(systemName: "\(food.index).circle.fill").opacity(1.0).zIndex(10)
                    }.foregroundStyle(.green)
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
struct ChartTaskView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            ChartTaskView(title: Text("Title"), detail: Text("Detail"), instructions: Text("Instructions"), isComplete: false)
            ChartTaskView(title: Text("Title"), detail: Text("Detail"), instructions: Text("Instructions"), isComplete: true)
        }.padding()
    }
}
#endif

/*
func date(year: Int, month: Int, day: Int = 1) -> Date {
    Calendar.current.date(from: DateComponents(year: year, month: month, day: day)) ?? Date()
}

func date(year: Int, month: Int, day: Int , hour: Int, minute: Int ) -> Date {
    Calendar.current.date(from: DateComponents(year: year, month: month, day: day, hour: hour, minute: minute)) ?? Date()
}

/// Data for the top style charts.
struct TopStyleData {
    /// Sales by pancake style for the last 30 days, sorted by amount.
    static let last30Days = [
        (name: "Cachapa", sales: 916),
        (name: "Injera", sales: 850),
        (name: "Crêpe", sales: 802),
        (name: "Jian Bing", sales: 753),
        (name: "Dosa", sales: 654),
        (name: "American", sales: 618)
    ]

    /// Sales by pancake style for the last 12 months, sorted by amount.
    static let last12Months = [
        (name: "Cachapa", sales: 9631),
        (name: "Crêpe", sales: 7959),
        (name: "Injera", sales: 7891),
        (name: "Jian Bing", sales: 7506),
        (name: "American", sales: 6777),
        (name: "Dosa", sales: 6325)
    ]
}

/// Data for the daily and monthly sales charts.
struct SalesData {
    /// Sales by day for the last 30 days.
    static let last30Days = [
        (day: date(year: 2022, month: 5, day: 8), sales: 168),
        (day: date(year: 2022, month: 5, day: 9), sales: 117),
        (day: date(year: 2022, month: 5, day: 10), sales: 106),
        (day: date(year: 2022, month: 5, day: 11), sales: 119),
        (day: date(year: 2022, month: 5, day: 12), sales: 109),
        (day: date(year: 2022, month: 5, day: 13), sales: 104),
        (day: date(year: 2022, month: 5, day: 14), sales: 196),
        (day: date(year: 2022, month: 5, day: 15), sales: 172),
        (day: date(year: 2022, month: 5, day: 16), sales: 122),
        (day: date(year: 2022, month: 5, day: 17), sales: 115),
        (day: date(year: 2022, month: 5, day: 18), sales: 138),
        (day: date(year: 2022, month: 5, day: 19), sales: 110),
        (day: date(year: 2022, month: 5, day: 20), sales: 106),
        (day: date(year: 2022, month: 5, day: 21), sales: 187),
        (day: date(year: 2022, month: 5, day: 22), sales: 187),
        (day: date(year: 2022, month: 5, day: 23), sales: 119),
        (day: date(year: 2022, month: 5, day: 24), sales: 160),
        (day: date(year: 2022, month: 5, day: 25), sales: 144),
        (day: date(year: 2022, month: 5, day: 26), sales: 152),
        (day: date(year: 2022, month: 5, day: 27), sales: 148),
        (day: date(year: 2022, month: 5, day: 28), sales: 240),
        (day: date(year: 2022, month: 5, day: 29), sales: 242),
        (day: date(year: 2022, month: 5, day: 30), sales: 173),
        (day: date(year: 2022, month: 5, day: 31), sales: 143),
        (day: date(year: 2022, month: 6, day: 1), sales: 137),
        (day: date(year: 2022, month: 6, day: 2), sales: 123),
        (day: date(year: 2022, month: 6, day: 3), sales: 146),
        (day: date(year: 2022, month: 6, day: 4), sales: 214),
        (day: date(year: 2022, month: 6, day: 5), sales: 250),
        (day: date(year: 2022, month: 6, day: 6), sales: 146)
    ]

    /// Total sales for the last 30 days.
    static var last30DaysTotal: Int {
        last30Days.map { $0.sales }.reduce(0, +)
    }

    static var last30DaysAverage: Double {
        Double(last30DaysTotal / last30Days.count)
    }

    /// Sales by month for the last 12 months.
    static let last12Months = [
        (month: date(year: 2021, month: 7), sales: 3952, dailyAverage: 127, dailyMin: 95, dailyMax: 194),
        (month: date(year: 2021, month: 8), sales: 4044, dailyAverage: 130, dailyMin: 96, dailyMax: 189),
        (month: date(year: 2021, month: 9), sales: 3930, dailyAverage: 131, dailyMin: 101, dailyMax: 184),
        (month: date(year: 2021, month: 10), sales: 4217, dailyAverage: 136, dailyMin: 96, dailyMax: 193),
        (month: date(year: 2021, month: 11), sales: 4006, dailyAverage: 134, dailyMin: 104, dailyMax: 202),
        (month: date(year: 2021, month: 12), sales: 3994, dailyAverage: 129, dailyMin: 96, dailyMax: 190),
        (month: date(year: 2022, month: 1), sales: 4202, dailyAverage: 136, dailyMin: 96, dailyMax: 203),
        (month: date(year: 2022, month: 2), sales: 3749, dailyAverage: 134, dailyMin: 98, dailyMax: 200),
        (month: date(year: 2022, month: 3), sales: 4329, dailyAverage: 140, dailyMin: 104, dailyMax: 218),
        (month: date(year: 2022, month: 4), sales: 4084, dailyAverage: 136, dailyMin: 93, dailyMax: 221),
        (month: date(year: 2022, month: 5), sales: 4559, dailyAverage: 147, dailyMin: 104, dailyMax: 242),
        (month: date(year: 2022, month: 6), sales: 1023, dailyAverage: 170, dailyMin: 120, dailyMax: 250)
    ]

    /// Total sales for the last 12 months.
    static var last12MonthsTotal: Int {
        last12Months.map { $0.sales }.reduce(0, +)
    }

    static var last12MonthsDailyAverage: Int {
        last12Months.map { $0.dailyAverage }.reduce(0, +) / last12Months.count
    }
}

/// Data for the sales by location and weekday charts.
struct LocationData {
    /// A data series for the lines.
    struct Series: Identifiable {
        /// The name of the city.
        let city: String

        /// Average daily sales for each weekday.
        /// The `weekday` property is a `Date` that represents a weekday.
        let sales: [(weekday: Date, sales: Int)]

        /// The identifier for the series.
        var id: String { city }
    }

    /// Sales by location and weekday for the last 30 days.
    static let last30Days: [Series] = [
        .init(city: "100%", sales: [
            (weekday: date(year: 2022, month: 5, day: 2), sales: 54),
            (weekday: date(year: 2022, month: 5, day: 3), sales: 42),
            (weekday: date(year: 2022, month: 5, day: 4), sales: 88),
            (weekday: date(year: 2022, month: 5, day: 5), sales: 49),
            (weekday: date(year: 2022, month: 5, day: 6), sales: 42),
            (weekday: date(year: 2022, month: 5, day: 7), sales: 125),
            (weekday: date(year: 2022, month: 5, day: 8), sales: 67)

        ]),
        .init(city: "95%", sales: [
            (weekday: date(year: 2022, month: 5, day: 2), sales: 81),
            (weekday: date(year: 2022, month: 5, day: 3), sales: 90),
            (weekday: date(year: 2022, month: 5, day: 4), sales: 52),
            (weekday: date(year: 2022, month: 5, day: 5), sales: 72),
            (weekday: date(year: 2022, month: 5, day: 6), sales: 84),
            (weekday: date(year: 2022, month: 5, day: 7), sales: 84),
            (weekday: date(year: 2022, month: 5, day: 8), sales: 137)
        ])
    ]

    /// The best weekday and location for the last 30 days.
    static let last30DaysBest = (
        city: "95%",
        weekday: date(year: 2022, month: 5, day: 8),
        sales: 137
    )

    /// The best weekday and location for the last 12 months.
    static let last12MonthsBest = (
        city: "95%",
        weekday: date(year: 2022, month: 5, day: 8),
        sales: 113
    )

    /// Sales by location and weekday for the last 12 months.
    static let last12Months: [Series] = [
        .init(city: "100%", sales: [
            (weekday: date(year: 2022, month: 5, day: 2), sales: 64),
            (weekday: date(year: 2022, month: 5, day: 3), sales: 60),
            (weekday: date(year: 2022, month: 5, day: 4), sales: 47),
            (weekday: date(year: 2022, month: 5, day: 5), sales: 55),
            (weekday: date(year: 2022, month: 5, day: 6), sales: 55),
            (weekday: date(year: 2022, month: 5, day: 7), sales: 105),
            (weekday: date(year: 2022, month: 5, day: 8), sales: 67)
        ]),
        .init(city: "95%", sales: [
            (weekday: date(year: 2022, month: 5, day: 2), sales: 57),
            (weekday: date(year: 2022, month: 5, day: 3), sales: 56),
            (weekday: date(year: 2022, month: 5, day: 4), sales: 66),
            (weekday: date(year: 2022, month: 5, day: 5), sales: 61),
            (weekday: date(year: 2022, month: 5, day: 6), sales: 60),
            (weekday: date(year: 2022, month: 5, day: 7), sales: 77),
            (weekday: date(year: 2022, month: 5, day: 8), sales: 113)
        ])
    ]
}

enum EventType {
    case food
    case drink
    case medicine
    case excercise
    case insulin
}
/// Data for the sales by location and weekday charts.
struct GlucoseData {
    /// A data series for the lines.
    struct Series: Identifiable {
        /// The name of the city.
        let city: String

        /// Average daily sales for each weekday.
        /// The `weekday` property is a `Date` that represents a weekday.
        let sales: [(weekday: Date, sales: Int)]
        let events:  [(hour: Date, type: EventType, description: String, value: Int)]
        let glucose: [(hour: Date, sales: Int)]
 
        let lineWidth: CGFloat
        /// The identifier for the series.
        var id: String { city }
    }

    /// Sales by location and weekday for the last 30 days.
    static let last30Days: [Series] = [
        .init(city: "100%", sales: [
            (weekday: date(year: 2022, month: 5, day: 2), sales: 54),
            (weekday: date(year: 2022, month: 5, day: 3), sales: 42),
            (weekday: date(year: 2022, month: 5, day: 4), sales: 88),
            (weekday: date(year: 2022, month: 5, day: 5), sales: 49),
            (weekday: date(year: 2022, month: 5, day: 6), sales: 42),
            (weekday: date(year: 2022, month: 5, day: 7), sales: 125),
            (weekday: date(year: 2022, month: 5, day: 8), sales: 67)

        ], events: [], glucose: [], lineWidth: 1),
        .init(city: "95%", sales: [
            (weekday: date(year: 2022, month: 5, day: 2), sales: 81),
            (weekday: date(year: 2022, month: 5, day: 3), sales: 90),
            (weekday: date(year: 2022, month: 5, day: 4), sales: 52),
            (weekday: date(year: 2022, month: 5, day: 5), sales: 72),
            (weekday: date(year: 2022, month: 5, day: 6), sales: 84),
            (weekday: date(year: 2022, month: 5, day: 7), sales: 84),
            (weekday: date(year: 2022, month: 5, day: 8), sales: 137)
        ], events: [], glucose: [], lineWidth: 1)
    ]
    
    /// Sales by location and weekday for the last 30 days.
    static let today: [Series] = [
        .init(city: "95%", sales: [
            (weekday: date(year: 2022, month: 5, day: 2), sales: 81),
            (weekday: date(year: 2022, month: 5, day: 3), sales: 90),
            (weekday: date(year: 2022, month: 5, day: 4), sales: 52),
            (weekday: date(year: 2022, month: 5, day: 5), sales: 72),
            (weekday: date(year: 2022, month: 5, day: 6), sales: 84),
            (weekday: date(year: 2022, month: 5, day: 7), sales: 84),
            (weekday: date(year: 2022, month: 5, day: 8), sales: 137)
        ], events: [
            (hour: date(year: 2022, month: 5, day: 8, hour: 5, minute: 10), type: .food,description: "", value: 78),
            (hour: date(year: 2022, month: 5, day: 8, hour: 12, minute: 10), type: .food,description: "", value: 85)
        ], glucose: [
            (hour: date(year: 2022, month: 5, day: 8, hour: 5, minute: 10), sales: 78),
            (hour: date(year: 2022, month: 5, day: 8, hour: 11, minute: 10), sales: 81),
            (hour: date(year: 2022, month: 5, day: 8, hour: 12, minute: 10), sales: 85),
            (hour: date(year: 2022, month: 5, day: 8, hour: 13, minute: 10), sales: 91),
            (hour: date(year: 2022, month: 5, day: 8, hour: 14, minute: 10), sales: 101),
            (hour: date(year: 2022, month: 5, day: 8, hour: 24, minute: 10), sales: 61)

        ], lineWidth: 3),
        .init(city: "Low", sales: [
           ], events: [], glucose: [
            (hour: date(year: 2022, month: 5, day: 8, hour: 0, minute: 0), sales: 70),
            (hour: date(year: 2022, month: 5, day: 8, hour: 24, minute: 0), sales: 70)
           ], lineWidth: 0.4),
        .init(city: "High", sales: [
           ], events: [], glucose: [
            (hour: date(year: 2022, month: 5, day: 8, hour: 0, minute: 0), sales: 180),
            (hour: date(year: 2022, month: 5, day: 8, hour: 24, minute: 0), sales: 180)
           ], lineWidth: 0.4)
    ]

    
    /// The best weekday and location for the last 30 days.
    static let last30DaysBest = (
        city: "95%",
        weekday: date(year: 2022, month: 5, day: 8),
        sales: 137
    )

    /// The best weekday and location for the last 12 months.
    static let last12MonthsBest = (
        city: "95%",
        weekday: date(year: 2022, month: 5, day: 8),
        sales: 113
    )

    /// Sales by location and weekday for the last 12 months.
    static let last12Months: [Series] = [
        .init(city: "100%", sales: [
            (weekday: date(year: 2022, month: 5, day: 2), sales: 64),
            (weekday: date(year: 2022, month: 5, day: 3), sales: 60),
            (weekday: date(year: 2022, month: 5, day: 4), sales: 47),
            (weekday: date(year: 2022, month: 5, day: 5), sales: 55),
            (weekday: date(year: 2022, month: 5, day: 6), sales: 55),
            (weekday: date(year: 2022, month: 5, day: 7), sales: 105),
            (weekday: date(year: 2022, month: 5, day: 8), sales: 67)
        ], events: [], glucose: [], lineWidth: 1),
        .init(city: "95%", sales: [
            (weekday: date(year: 2022, month: 5, day: 2), sales: 57),
            (weekday: date(year: 2022, month: 5, day: 3), sales: 56),
            (weekday: date(year: 2022, month: 5, day: 4), sales: 66),
            (weekday: date(year: 2022, month: 5, day: 5), sales: 61),
            (weekday: date(year: 2022, month: 5, day: 6), sales: 60),
            (weekday: date(year: 2022, month: 5, day: 7), sales: 77),
            (weekday: date(year: 2022, month: 5, day: 8), sales: 113)
        ], events: [], glucose: [], lineWidth: 1)
    ]
}
*/
