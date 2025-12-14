//
//  Date+Formatting.swift
//  TravelAbroad
//
//  Created by Tanner Macpherson on 12/13/25.
//

import Foundation

extension Date {
    func timeAgoOrDateString() -> String {
        let now = Date()
        let calendar = Calendar.current
        let components = calendar.dateComponents([.minute, .hour, .day], from: self, to: now)

        // Check if more than 7 days old
        if let days = components.day, days >= 7 {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "MMMM d"

            // Check if from previous year
            let dateYear = calendar.component(.year, from: self)
            let currentYear = calendar.component(.year, from: now)

            if dateYear < currentYear {
                dateFormatter.dateFormat = "MMMM d, yyyy"
            }

            return dateFormatter.string(from: self)
        }

        // Less than 7 days - show time ago
        if let days = components.day, days > 0 {
            return "\(days)d"
        } else if let hours = components.hour, hours > 0 {
            return "\(hours)h"
        } else if let minutes = components.minute, minutes > 0 {
            return "\(minutes)m"
        } else {
            return "Just now"
        }
    }
}
