import Foundation
import Charts
import RuuviOntology

public class XAxisValueFormatter: NSObject, AxisValueFormatter {

    public func stringForValue(_ value: Double, axis: AxisBase?) -> String {
        let date = Date(timeIntervalSince1970: value)

        if date.isStartOfTheDay() {
            return AppDateFormatter.shared.graphXAxisDateString(from: date)
        } else {
            return AppDateFormatter.shared.graphXAxisTimeString(from: date)
        }
    }
}
