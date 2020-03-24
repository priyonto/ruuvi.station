//
//  TagChartView.swift
//  station
//
//  Created by Viik.ufa on 21.03.2020.
//  Copyright © 2020 Ruuvi Innovations Oy. BSD-3-Clause.
//

import UIKit
import Charts

class TagChartView: LineChartView {
    var presenter: (TagChartPresenterInput & TagChartModuleInput)!
    private let noChartDataText = "TagCharts.NoChartData.text"

    // MARK: - LifeCycle
    override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    // MARK: - Private
    private func configure() {
        chartDescription?.enabled = false

        dragEnabled = true
        setScaleEnabled(true)
        pinchZoomEnabled = false
        highlightPerDragEnabled = false

        backgroundColor = .clear

        legend.enabled = false

        xAxis.labelPosition = .bottom
        xAxis.labelFont = .systemFont(ofSize: 10, weight: .light)
        xAxis.labelTextColor = UIColor.white
        xAxis.drawAxisLineEnabled = false
        xAxis.drawGridLinesEnabled = true
        xAxis.centerAxisLabelsEnabled = false
        xAxis.granularity = 300
        xAxis.valueFormatter = DateValueFormatter()
        xAxis.granularityEnabled = true

        leftAxis.labelPosition = .outsideChart
        leftAxis.labelFont = .systemFont(ofSize: 10, weight: .light)
        leftAxis.drawGridLinesEnabled = true

        leftAxis.labelTextColor = UIColor.white

        rightAxis.enabled = false
        legend.form = .line

        noDataTextColor = UIColor.white
        noDataText = noChartDataText.localized()

        scaleXEnabled = true
        scaleYEnabled = true
    }
}
// MARK: - TagChartViewInput
extension TagChartView: TagChartViewInput {
    func setChartData(_ chartData: LineChartData) {
        self.data = chartData
    }
    func fitZoomTo(first: TimeInterval, last: TimeInterval) {
        let scaleX = CGFloat((last - first) / (60 * 60 * 24))
        self.zoom(scaleX: 0, scaleY: 0, x: 0, y: 0)
        self.zoom(scaleX: scaleX, scaleY: 0, x: 0, y: 0)
        self.moveViewToX(last - (60 * 60 * 24))
    }
    func updataChart() {
        data?.notifyDataChanged()
        notifyDataSetChanged()
    }
}
