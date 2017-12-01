//
//  PUCalendarEvent.swift
//  CalendarKit-Swift
//
//  Created by Maurice Arikoglu on 29.11.17.
//  Copyright © 2017 Maurice Arikoglu. All rights reserved.
//

import UIKit

enum EventStatus {
    case tentative
    case confirmed
    case cancelled
}

struct EventAttendee {
    
    enum AttendeeRole {
        case chair
        case required
        case optional
        case non
    }
    
    var url: String?
    var name: String?
    
    var role: AttendeeRole?
}

class EventRule: NSObject {
    
    var frequency: String?
    var count: Int?
    var interval: Int = 0
    
    var weekstart: String?
    var untilDate: Date?
    
    var bySecond: [String]?
    var byMinute: [String]?
    var byHour: [String]?
    var byDay: [String]?
    var byDayOfMonth: [String]?
    var byDayOfYear: [String]?
    var byWeekOfYear: [String]?
    var byMonth: [String]?
    var bySetPosition: [String]?
    

}

class CalendarEvent: NSObject {

    // MARK: Public properties
    var startDate: Date?
    var endDate: Date?
    var occurrenceDate: Date?
    var isAllDay: Bool = false
    
    var status: EventStatus?

    var createdDate: Date?
    var lastModified: Date?
    var eventIdentifier: String?
    
    var title: String?
    var notes: String?
    var hasNotes: Bool {
        get {
            return !(notes ?? "").isEmpty
        }
    }
    
    var location: String?
    var hasLocation: Bool {
        get {
            return !(location ?? "").isEmpty
        }
    }
    
    var attendees = [EventAttendee]()
    var hasAttendees: Bool {
        get {
            return !attendees.isEmpty
        }
    }
    
    var exceptionDates: [Date]?
    var exceptionRule: EventRule?
    var hasExceptionRule: Bool {
        get {
            return (exceptionRule != nil)
        }
    }

    var recurrenceRule: EventRule?
    var hasRecurrenceRule: Bool {
        get {
            return (recurrenceRule != nil)
        }
    }

    init(startDate: Date, endDate: Date?, uniqueId: String) {
        super.init()
        self.startDate = startDate
        self.endDate = endDate
        self.eventIdentifier = uniqueId
    }
    
    func repeatsOnDate(_ checkDate: Date) -> Bool {
        // Check if start Date exists and if start Date is in future compared to now
        guard let startDate = startDate,
        startDate < Date() else {
            return false
        }
        
        let calendar = Calendar.current
        // Check if the date to check is the start Date (even startDate might have an exception)
        if calendar.isDate(startDate, inSameDayAs: checkDate) { return !exceptionOnDate(checkDate) }

        if exceptionDates != nil {
            for date in exceptionDates! {
                // Check whether checkDate is contained in exception Dates
                if calendar.isDate(date, inSameDayAs: checkDate) { return false }
            }
        }
        // Check if the event is recurring
        guard let recurrence = recurrenceRule,
        let frequency = recurrence.frequency else {
            // If not recurring it obviously cant be on any other date than startDate (here already validated!)
            return false
        }
        
        func gregorianDayOfWeekString(from day: Int) -> String {
            switch day {
            case 1:
                return "SU"
            case 2:
                return "MO"
            case 3:
                return "TU"
            case 4:
                return "WE"
            case 5:
                return "TH"
            case 6:
                return "FR"
            case 7:
                return "SA"
            default:
                return ""
            }
        }
        
        let checkDateComponents = calendar.dateComponents([.day, .month, .year, .weekOfYear, .weekday], from: checkDate)
        let dayOfYear = calendar.ordinality(of: Calendar.Component.day, in: Calendar.Component.year, for: checkDate)
        let weekday: String = gregorianDayOfWeekString(from: checkDateComponents.weekday!)
        
        if recurrence.byDay != nil &&
            !recurrence.byDay!.contains(weekday) &&
            !recurrence.byDay!.contains("1" + weekday) &&
            !recurrence.byDay!.contains("2" + weekday) &&
            !recurrence.byDay!.contains("3" + weekday) {
            return false
        }
        
        if (recurrence.byDayOfMonth != nil &&
            (recurrence.byDayOfMonth?.contains(String(checkDateComponents.day!))) ?? false) ||
            (recurrence.byDayOfYear != nil &&
            (recurrence.byDayOfYear?.contains(String(dayOfYear!))) ?? false) ||
            (recurrence.byWeekOfYear != nil &&
            (recurrence.byWeekOfYear?.contains(String(checkDateComponents.weekOfYear!))) ?? false) ||
            (recurrence.byMonth != nil &&
            (recurrence.byMonth?.contains(String(checkDateComponents.month!))) ?? false) {
            return false
        }

        // If there's no repetition interval provided, it means the interval equals 1.
        recurrence.interval = recurrence.interval == 0 ? 1 : recurrence.interval
        
        switch frequency {
        case "WEEKLY":
            if let count = recurrence.count {
                let finalComponents = DateComponents()
                finalComponents.day = count * recurrence.interval
                
            } else if let untilDate = recurrence.untilDate {
                
            } else {
                
            }
            
        case "MONTHLY":
            print("to")
        case "YEARLY":
            print("to")

        default:
            return false
        }
        
        return false
    }
    
    private func exceptionOnDate(_ checkDate: Date) -> Bool {
        
        return false
    }
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
}
