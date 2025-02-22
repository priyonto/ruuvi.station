import Foundation

extension Date {
    func ruuviAgo(prefix: String = "") -> String {
        let elapsed = Int(Date().timeIntervalSince(self))
        var output = prefix.isEmpty ? "" : (prefix + " ")
        // show date if the tag has not been seen for 24h
        if elapsed >= 24 * 60 * 60 {
            output += AppDateFormatter.shared.ruuviAgoString(from: self)
        } else {
            let seconds = elapsed % 60
            let minutes = (elapsed / 60) % 60
            let hours   = (elapsed / (60*60)) % 24
            if hours > 0 {
                output += String(hours) + " " + "h".localized() + " "
            }
            if minutes > 0 {
                output += String(minutes) + " " + "min".localized() + " "
            }
            output += String(seconds) + " " + "s".localized() + " " + "ago".localized()
        }
        return output
    }
}

extension Date {
    func numberOfDaysFromNow() -> Int? {
        let numberOfDays = Calendar.autoupdatingCurrent.dateComponents([.day], from: self, to: Date())
        return numberOfDays.day
    }
}

extension Date {
    func isStartOfTheDay() -> Bool {
        let calendar = Calendar.autoupdatingCurrent
        let components = calendar.dateComponents([.hour, .minute, .second], from: self)
        return components.hour == 0 && components.minute == 0 && components.second == 0
    }
}
