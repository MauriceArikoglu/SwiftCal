//
//  PUCalendarEvent.swift
//  CalendarKit-Swift
//
//  Created by Maurice Arikoglu on 29.11.17.
//  Copyright © 2017 Maurice Arikoglu. All rights reserved.
//

import UIKit

public enum EventStatus {
    case tentative
    case confirmed
    case cancelled
}

public struct EventAttendee {

    public enum AttendeeRole {
        case chair
        case required
        case optional
        case non
    }

    var url: String?
    public var name: String?
    public var email: String?
    public var status: String?
    public var role: AttendeeRole?
}

public class EventRule: NSObject {

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

public class CalendarEvent: NSObject {

    // MARK: Public properties
    @objc public var startDate: Date?
    @objc public var endDate: Date?
    var occurrenceDate: Date?
    @objc public var isAllDay: Bool = false

    public var status: EventStatus?

    @objc public var createdDate: Date?
    @objc public var lastModified: Date?
    @objc public var eventIdentifier: String?

    @objc public var title: String?
    @objc public var notes: String?
    public var hasNotes: Bool {
        get {
            return !(notes ?? "").isEmpty
        }
    }

    @objc public var location: String?
    public var hasLocation: Bool {
        get {
            return !(location ?? "").isEmpty
        }
    }

    public var attendees = [EventAttendee]()
    public var hasAttendees: Bool {
        get {
            return !attendees.isEmpty
        }
    }

    public var organizerEmail: String?

    var exceptionDates: [Date]?
    var hasExceptionDates: Bool {
        get {
            return (exceptionDates != nil)
        }
    }

    var exceptionRule: EventRule?
    var hasExceptionRule: Bool {
        get {
            return (exceptionRule != nil)
        }
    }

    var recurrenceRule: EventRule?
    public var recurrenceRuleString: String?
    var hasRecurrenceRule: Bool {
        get {
            return (recurrenceRule != nil)
        }
    }

    public init(startDate: Date, endDate: Date?, uniqueId: String) {
        super.init()
        self.startDate = startDate
        self.endDate = endDate
        self.eventIdentifier = uniqueId
    }

    public func takesPlaceOnDate(_ checkDate: Date) -> Bool {
        // Check if start Date exists and if start Date is in future compared to now
        guard
            let startDate = startDate,
            startDate < Date()
            else {
                return false
        }

        let calendar = Calendar.current
        // Check if the date to check is the start Date (even startDate might have an exception)
        if calendar.isDate(startDate, inSameDayAs: checkDate) {
            return !exceptionOnDate(checkDate)
        }

        if hasExceptionDates {
            for date in exceptionDates! {
                // Check whether checkDate is contained in exception Dates
                if calendar.isDate(date, inSameDayAs: checkDate) {
                    return false
                }
            }
        }
        // Check if the event is recurring
        guard
            let recurrence = recurrenceRule,
            let frequency = recurrence.frequency
            else {
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

        func checkRule(by component: Calendar.Component) -> Bool {

            if let count = recurrence.count {
                var finalComponents = DateComponents()
                finalComponents.setValue(count * recurrence.interval, for: component)
                // Calculate the last occurrence date based on the start date
                guard
                    let lastDate = calendar.date(byAdding: finalComponents, to: startDate)
                    else {
                        return false
                }
                // Check if checkDate is lastDate
                if calendar.isDate(checkDate, inSameDayAs: lastDate) {
                    return !exceptionOnDate(checkDate)
                }
                // Else check if day is of repeat rule pattern
                if lastDate > checkDate {
                    // Check if the days between lastDate and checkDate fit the recurrence pattern
                    guard
                        let difference = calendar.dateComponents([component], from: lastDate, to: checkDate).value(for: component),
                        difference % recurrence.interval == 0
                        else {
                            // Non zero means no matching day, return false
                            return false
                    }
                    // If 0 remains, the recurrence interval pattern matches our day
                    return !exceptionOnDate(checkDate)
                } else {
                    // Return false if last Date is in past compared to checkDate
                    return false
                }
            } else if let untilDate = recurrence.untilDate {
                // Check if the untilDate is in future
                if untilDate > checkDate {
                    // Check if the days between untilDate and checkDate fit the recurrence pattern
                    guard
                        let difference = calendar.dateComponents([component], from: untilDate, to: checkDate).value(for: component),
                        difference % recurrence.interval == 0
                        else {
                            // Non zero means no matching day, return false
                            return false
                    }
                    // If 0 remains, the recurrence interval pattern matches our day
                    return !exceptionOnDate(checkDate)
                } else {
                    // We return false if the untilDate is in past or on the same day as checkDate
                    return false
                }
            } else {
                // If we dont have a recurrence limit,
                // Check if the days between startDate and checkDate fit the recurrence pattern
                guard
                    let difference = calendar.dateComponents([component],
                                                             from: startDate,
                                                             to: checkDate).value(for: component),
                    difference % recurrence.interval == 0
                    else {
                        // Non zero means no matching day, return false
                        return false
                }
                // If 0 remains, the recurrence interval pattern matches our day
                return !exceptionOnDate(checkDate)
            }
        }

        switch frequency {
        case "WEEKLY":
            return checkRule(by: Calendar.Component.day)
        case "MONTHLY":
            return checkRule(by: Calendar.Component.month)
        case "YEARLY":
            return checkRule(by: Calendar.Component.year)

        default:
            return false
        }
    }

    private func exceptionOnDate(_ checkDate: Date) -> Bool {
        // Check if start Date exists and if start Date is in future compared to now
        guard
            let startDate = startDate,
            startDate < Date()
            else {
                return false
        }

        let calendar = Calendar.current
        // Check if the date to check is the start Date (even startDate might have an exception)
        if calendar.isDate(startDate, inSameDayAs: checkDate) {
            return true
        }

        if hasExceptionDates {
            for date in exceptionDates! {
                // Check whether checkDate is contained in exception Dates
                if calendar.isDate(date, inSameDayAs: checkDate) {
                    return true
                }
            }
        }
        // Check if the event has recurring exception
        guard
            let exception = exceptionRule,
            let frequency = exception.frequency
            else {
                // If not recurring it obviously has no exception
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

        if exception.byDay != nil &&
            !exception.byDay!.contains(weekday) &&
            !exception.byDay!.contains("1" + weekday) &&
            !exception.byDay!.contains("2" + weekday) &&
            !exception.byDay!.contains("3" + weekday) {
            return false
        }

        if (exception.byDayOfMonth != nil &&
            (exception.byDayOfMonth?.contains(String(checkDateComponents.day!))) ?? false) ||
            (exception.byDayOfYear != nil &&
                (exception.byDayOfYear?.contains(String(dayOfYear!))) ?? false) ||
            (exception.byWeekOfYear != nil &&
                (exception.byWeekOfYear?.contains(String(checkDateComponents.weekOfYear!))) ?? false) ||
            (exception.byMonth != nil &&
                (exception.byMonth?.contains(String(checkDateComponents.month!))) ?? false) {
            return false
        }

        // If there's no exception interval provided, it means the interval equals 1.
        exception.interval = exception.interval == 0 ? 1 : exception.interval

        func checkRule(by component: Calendar.Component) -> Bool {
            if let count = exception.count {
                var finalComponents = DateComponents()
                finalComponents.setValue(count * exception.interval, for: component)
                // Calculate the last occurrence date based on the start date
                guard
                    let lastDate = calendar.date(byAdding: finalComponents, to: startDate)
                    else {
                        return false
                }
                // Check if checkDate is lastDate
                if calendar.isDate(checkDate, inSameDayAs: lastDate) {
                    return !exceptionOnDate(checkDate)
                }
                // Else check if day is of repeat rule pattern
                if lastDate > checkDate {
                    // Check if the days between lastDate and checkDate fit the recurrence pattern
                    guard
                        let difference = calendar.dateComponents([component],
                                                                 from: lastDate,
                                                                 to: checkDate).value(for: component),
                        difference % exception.interval == 0
                        else {
                            // Non zero means no matching day, return false
                            return false
                    }
                    // If 0 remains, the recurrence interval pattern matches our day
                    return true

                } else {
                    // Return false if last Date is in past compared to checkDate
                    return false
                }
            } else if let untilDate = exception.untilDate {
                // Check if the untilDate is in future
                if untilDate > checkDate {
                    // Check if the days between untilDate and checkDate fit the recurrence pattern
                    guard
                        let difference = calendar.dateComponents([component],
                                                                 from: untilDate,
                                                                 to: checkDate).value(for: component),
                        difference % exception.interval == 0
                        else {
                            // Non zero means no matching day, return false
                            return false
                    }
                    // If 0 remains, the recurrence interval pattern matches our day
                    return true
                } else {
                    return false
                }
                // We return false if the untilDate is in past or on the same day as checkDate
            } else {
                // If we dont have a recurrence limit,
                // Check if the days between startDate and checkDate fit the recurrence pattern
                guard
                    let difference = calendar.dateComponents([component],
                                                             from: startDate,
                                                             to: checkDate).value(for: component),
                    difference % exception.interval == 0
                    else {
                        // Non zero means no matching day, return false
                        return false
                }
                // If 0 remains, the recurrence interval pattern matches our day
                return true
            }
        }

        switch frequency {
        case "WEEKLY":
            return checkRule(by: Calendar.Component.day)
        case "MONTHLY":
            return checkRule(by: Calendar.Component.month)
        case "YEARLY":
            return checkRule(by: Calendar.Component.year)

        default:
            return false
        }
    }

}
