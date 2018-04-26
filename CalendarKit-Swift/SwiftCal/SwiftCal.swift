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

        eventStore.append(event)
        return allEvents.count
    }

    public func events(for date: Date) -> [CalendarEvent] {

        var eventsForDate = [CalendarEvent]()

        for event in eventStore where event.takesPlaceOnDate(date) {
            eventsForDate.append(event)
        }

        eventsForDate = eventsForDate.sorted(by: { (e1, e2) in
            // We compare time only because initial start dates might be different because of recurrence
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
