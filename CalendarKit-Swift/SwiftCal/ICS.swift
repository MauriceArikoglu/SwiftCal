//
//  iCalendar.swift
//  CalendarKit-Swift
//
//  Created by Maurice Arikoglu on 25.04.18.
//  Copyright © 2018 Maurice Arikoglu. All rights reserved.
//

import Foundation

internal struct ICSEventKey {

    static let exceptionDate = "EXDATE;"
    static let exceptionRule = "EXRULE:"
    static let recurrenceRule = "RRULE:"
    static let transparent = "TRANSP:"
    static let summary = "SUMMARY:"
    static let status = "STATUS:"
    static let organizer = "ORGANIZER;"
    static let organizer2 = "ORGANIZER:"
    static let sequence = "SEQUENCE:"
    static let location = "LOCATION:"
    static let lastModified = "LAST-MODIFIED:"
    static let description = "DESCRIPTION:"
    static let description2 = "DESCRIPTION;"
    static let created = "CREATED:"
    static let recurrenceId = "RECURRENCE-ID;TZID=%@"
    static let attendee = "ATTENDEE;"
    static let uniqueId = "UID:"
    static let timestamp = "DTSTAMP:"
    static let endDate = "DTEND:"
    static let endDateValueDate = "DTEND;VALUE=DATE:"
    static let endDateAndTimezone = "DTEND;TZID=%@:"
    static let startDate = "DTSTART:"
    static let startDateValueDate = "DTSTART;VALUE=DATE:"
    static let startDateAndTimezone = "DTSTART;TZID=%@:"
    static let timezone = "TZID:"
    static let timezoneStartDateAndTimezone = "DTSTART;TZID="
    static let timezoneBegin = "BEGIN:VTIMEZONE"
    static let timezoneEnd = "END:VTIMEZONE"
    static let eventBegin = "BEGIN:VEVENT"
    static let eventEnd = "END:VEVENT"
    static let daylightBegin = "BEGIN:DAYLIGHT"
    static let daylightEnd = "END:DAYLIGHT"
    static let standardBegin = "BEGIN:STANDARD"
    static let standardEnd = "END:STANDARD"
    static let timezoneOffsetTo = "TZOFFSETTO:"
    static let timezoneOffsetFrom = "TZOFFSETFROM:"
    static let timezoneName = "TZNAME:"
}

extension Date {

    public func set(month: Int, weekday: Int, ordinal: Int? = nil) -> Date {

        let currentYear = Calendar.current.component(.year, from: self)

        var components = DateComponents()
        components.year = currentYear
        components.month = month
        components.weekday = weekday
        components.weekdayOrdinal = ordinal

        guard
            let date = Calendar.current.date(from: components)
            else {
                print("Could not modify date")
                return self
        }
        return date
    }

}
