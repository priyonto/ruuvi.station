import Foundation

extension Date {
    var ruuviAgo: String {
        let elapsed = Int(Date().timeIntervalSince(self))
        var output = "Updated".localized() + " "
        // show date if the tag has not been seen for 24h
        if elapsed >= 24 * 60 * 60 {
            let df = DateFormatter()
            df.dateFormat = "E MMM dd yyyy HH:mm:ss"
            output += df.string(from: self)
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
