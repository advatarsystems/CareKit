//
//  File 2.swift
//  
//
//  Created by Johan Sellström on 2022-10-18.
//

import Foundation
import SwiftUI
import Charts

public struct ChartViewData {
    
    public var title: String
    public var dailyPoints: [MyChartPoint]
    public var dailyAverage: Double
    
    public var yearlyPoints: [MyChartPoint]
    public var yearlyAverage: Double
    
    public init(title: String, dailyPoints: [MyChartPoint], dailyAverage: Double, yearlyPoints: [MyChartPoint], yearlyAverage: Double) {
        self.title = title
        self.dailyPoints = dailyPoints
        self.dailyAverage = dailyAverage
        self.yearlyPoints = yearlyPoints
        self.yearlyAverage = yearlyAverage
    }
}

extension MyChartPoint: Equatable {
    public static func == (lhs: MyChartPoint, rhs: MyChartPoint) -> Bool {
        return lhs.value == rhs.value && lhs.date == rhs.date
    }
}

extension ChartViewData: Equatable {
    public static func == (lhs: ChartViewData, rhs: ChartViewData) -> Bool {
        return lhs.dailyPoints == rhs.dailyPoints
    }
}

public typealias DataAction = (ChartViewData?, Error?) -> Void

public struct ChartView: View {
    
    enum TimeRange {
        case last30Days
        case last12Months
    }
    
    struct TimeRangePicker: View {
        @Binding var value: TimeRange

        var body: some View {
            Picker("Time Range", selection: $value.animation(.easeInOut)) {
                Text("30 Days").tag(TimeRange.last30Days)
                Text("12 Months").tag(TimeRange.last12Months)
            }
            .pickerStyle(.segmented)
        }
    }
    
    struct DailyChartView: View {
        let showAverageLine: Bool
        let showLimitLine: Bool
        let dailyPoints: [MyChartPoint]
        let dailyAverage: Double
        let limit: Double
        let lineWidth: CGFloat = 2

        var body: some View {
            Chart {
                ForEach(dailyPoints, id: \.date) {
                    BarMark(
                        x: .value("Day", $0.date, unit: .day),
                        y: .value("Score", $0.value)
                    )
                }
                .foregroundStyle((showAverageLine || showLimitLine) ? .gray.opacity(0.3) : .blue)

                if showAverageLine {
                    RuleMark(
                        y: .value("Average", dailyAverage.rounded(toPlaces: 0))
                    )
                    .lineStyle(StrokeStyle(lineWidth: lineWidth))
                    .annotation(position: .top, alignment: .leading) {
                        Text("Average: \(dailyAverage.rounded(toPlaces: 0), format: .number)")
                            .font(.body.bold())
                            .foregroundStyle(.blue)
                    }
                }
                
                if showLimitLine {
                    RuleMark(
                        y: .value("Limit", limit.rounded(toPlaces: 0))
                    )
                    .lineStyle(StrokeStyle(lineWidth: lineWidth))
                    .foregroundStyle(.green)
                    .annotation(position: .top, alignment: .trailing) {
                        Text("Limit: \(limit.rounded(toPlaces: 0), format: .number)")
                            .font(.body.bold())
                            .foregroundStyle(.green)
                    }
                }
            }
        }
    }
    
    struct MonthlyChartView: View {
        let showAverageLine: Bool
        let showLimitLine: Bool
        let yearlyPoints: [MyChartPoint]
        let yearlyAverage: Double
        let limit: Double
        let lineWidth: CGFloat = 2

        var body: some View {
            Chart {
                ForEach(yearlyPoints, id: \.date) {
                    BarMark(
                        x: .value("Month", $0.date, unit: .month),
                        y: .value("Score", $0.value)
                    )
                }.foregroundStyle((showAverageLine || showLimitLine) ? .gray.opacity(0.3) : .blue)
                
                if showAverageLine {
                    RuleMark(
                        y: .value("Average", yearlyAverage.rounded(toPlaces: 0))
                    )
                    .lineStyle(StrokeStyle(lineWidth: lineWidth))
                    .annotation(position: .top, alignment: .leading) {
                        Text("Average: \(yearlyAverage.rounded(toPlaces: 0), format: .number)")
                            .font(.body.bold())
                            .foregroundStyle(.blue)
                    }
                }
                if showLimitLine {
                    RuleMark(
                        y: .value("Limit", limit.rounded(toPlaces: 0))
                    )
                    .lineStyle(StrokeStyle(lineWidth: lineWidth))
                    .foregroundStyle(.green)
                    .annotation(position: .top, alignment: .trailing) {
                        Text("Limit: \(limit.rounded(toPlaces: 0), format: .number)")
                            .font(.body.bold())
                            .foregroundStyle(.green)
                    }
                }
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .month)) { _ in
                    AxisGridLine()
                    AxisTick()
                    AxisValueLabel(format: .dateTime.month(.narrow), centered: true)
                }
            }
        }
    }

    @State private var timeRange: TimeRange = .last30Days
    @State private var showAverageLine: Bool = false
    @State private var showLimitLine: Bool = false
    @Binding var chartViewData: ChartViewData
    
    @Binding var isEmpty: Bool
    
    public init(chartViewData: Binding <ChartViewData>, isEmpty: Binding<Bool>) {
        _chartViewData = chartViewData
        _isEmpty = isEmpty
    }
    
    public var body: some View {
        CardView {
            List {
                VStack(alignment: .leading) {
                    
                    Text(chartViewData.title).font(.headline)
                    
                    if !isEmpty {
                        TimeRangePicker(value: $timeRange)
                        .padding(.bottom)
                    
                    Text(loc("Average"))
                        .font(.callout)
                        .foregroundStyle(.secondary)
                    }
                    switch timeRange {
                    case .last30Days:
                        if isEmpty {
                            Spacer()
                            VStack {
                                Spacer()
                                HStack {
                                    Spacer()
                                    Text("No Data")
                                    Spacer()
                                }
                                Spacer()
                            }
                        } else {
                            Text("\(chartViewData.dailyAverage.rounded(toPlaces: 0), format: .number)")
                                .font(.title2.bold())
                                .foregroundColor(.primary)
                            DailyChartView(showAverageLine: showAverageLine, showLimitLine: showLimitLine, dailyPoints: chartViewData.dailyPoints, dailyAverage: chartViewData.dailyAverage, limit: 6.1)
                                .frame(height: 240)
                        }
                    case .last12Months:
                        if isEmpty {
                            Spacer()
                            VStack {
                                Spacer()
                                HStack {
                                    Spacer()
                                    Text("No Data")
                                    Spacer()
                                }
                                Spacer()
                            }
                        } else {
                            Text("\(chartViewData.yearlyAverage.rounded(toPlaces: 0), format: .number)")
                                .font(.title2.bold())
                                .foregroundColor(.primary)
                            MonthlyChartView(showAverageLine: showAverageLine, showLimitLine: showLimitLine, yearlyPoints: chartViewData.yearlyPoints, yearlyAverage: chartViewData.yearlyAverage, limit: 6.1)
                                .frame(height: 240)
                        }
                    }
                }.listRowSeparator(.hidden)
                if !isEmpty {
                    Section("Options") {
                        Toggle("Show Limit", isOn: $showLimitLine)
                        if timeRange == .last30Days {
                            Toggle("Show Daily Average", isOn: $showAverageLine)
                        } else {
                            Toggle("Show Monthly Average", isOn: $showAverageLine)
                        }
                    }
                }
            }
            .listStyle(.plain)
            .disabled(isEmpty)
        }
    }
}
