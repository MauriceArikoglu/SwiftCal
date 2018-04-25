//
//  SwiftCal.swift
//  CalendarKit-Swift
//
//  Created by Maurice Arikoglu on 30.11.17.
//  Copyright © 2017 Maurice Arikoglu. All rights reserved.
//

import UIKit

public class SwiftCal: NSObject {

    public var events = [CalendarEvent]()
    public var method: String?
    public var timezone: TimeZone?

    @discardableResult public func addEvent(_ event: CalendarEvent) -> Int {

        events.append(event)
        return events.count
    }

    public func events(for date: Date) -> [CalendarEvent] {

        var eventsForDate = [CalendarEvent]()

        for event in events where event.takesPlaceOnDate(date) {
            eventsForDate.append(event)
        }

        eventsForDate = eventsForDate.sorted(by: { (e1, e2) in
            //We compare time only because initial start dates might be different because of recurrence
            let calendar = Calendar.current
            guard
                let sd1 = e1.startDate,
                let sd2 = e2.startDate,
                let compareDate1 = calendar.date(from: calendar.dateComponents([.hour, .minute, .second], from: sd1)),
                let compareDate2 = calendar.date(from: calendar.dateComponents([.hour, .minute, .second], from: sd2))
                else {
                    return false
            }

            return compareDate1 < compareDate2
        })

        return eventsForDate
    }

}

public class Read {

    public static func swiftCal(from icsString: String) -> SwiftCal {

        let formattedICS = icsString.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        var calendarEvents = formattedICS.components(separatedBy: "BEGIN:VEVENT")

        var timezoneString: NSString?
        let timezoneScanner = Scanner(string: icsString)
        timezoneScanner.scanUpTo("BEGIN:VTIMEZONE", into: nil)
        timezoneScanner.scanUpTo("END:VTIMEZONE", into: &timezoneString)

        let calendar = SwiftCal()

        if calendarEvents.count > 0 {

            var methodString: NSString?
            let methodScanner = Scanner(string: icsString)
            methodScanner.scanUpTo("METHOD:", into: nil)
            methodScanner.scanUpTo("\r\n", into: &methodString)
            if let theMethodString = methodString {
                calendar.method = String(theMethodString.substring(from: 7))
            }

            var timezoneId: NSString?
            var timezoneOffset: NSString?

            let headerScanner = Scanner(string: calendarEvents.first!)
            headerScanner.scanUpTo("TZID:", into: nil)
            headerScanner.scanUpTo("\n", into: &timezoneId)
            headerScanner.scanUpTo("BEGIN:STANDARD", into: nil)
            headerScanner.scanUpTo("TZOFFSETTO:", into: nil)
            headerScanner.scanUpTo("\n", into: &timezoneOffset)

            if timezoneId?.replacingOccurrences(of: "TZID:", with: "").trimmingCharacters(in: .newlines) != nil,
                let timezoneOffset = timezoneOffset?.replacingOccurrences(of: "TZOFFSETTO:", with: "").trimmingCharacters(in: .newlines) {
                // timezoneoffset e.g. +0430 indicating 4 hours 30 mins ahead of UTC
                if timezoneOffset.count == 5 {
                    let isAhead = timezoneOffset.first == "+"
                    let hoursString = timezoneOffset.dropFirst().dropLast(2)
                    let minutesString = timezoneOffset.dropFirst(3)
                    if let hours = Int(hoursString), let minutes = Int(minutesString) {
                        let offset = hours * 60 * 60 + minutes * 60
                        let offsetFromUTC = isAhead ? -offset : offset
                        calendar.timezone = TimeZone(secondsFromGMT: Int(offsetFromUTC))
                    }
                }
            }

            calendarEvents.remove(at: 0)
        }

        for event in calendarEvents {

            guard
                let calendarEvent = ICSEventParser.event(from: event, calendarTimezone: calendar.timezone)
                else {
                    continue
            }
            calendar.addEvent(calendarEvent)
        }

        return calendar
    }
}
