//
//  SwiftCal.swift
//  CalendarKit-Swift
//
//  Created by Maurice Arikoglu on 30.11.17.
//  Copyright © 2017 Maurice Arikoglu. All rights reserved.
//

import UIKit

public class SwiftCal: NSObject {

    var events = [CalendarEvent]()
    public var timezone: NSTimeZone?
    
    @discardableResult public func addEvent(_ event: CalendarEvent) -> Int {
        
        events.append(event)
        return events.count
    }
    
    public func events(for date: Date) -> [CalendarEvent] {
        
        var eventsForDate = [CalendarEvent]()
        
        for event in events {
            if event.takesPlaceOnDate(date) { eventsForDate.append(event) }
        }
        
        eventsForDate = eventsForDate.sorted(by: { (e1, e2) in
            //We compare time only because initial start dates might be different because of recurrence
            let calendar = Calendar.current
            guard let sd1 = e1.startDate,
                let sd2 = e2.startDate,
            let compareDate1 = calendar.date(from: calendar.dateComponents([.hour, .minute, .second], from: sd1)),
            let compareDate2 = calendar.date(from: calendar.dateComponents([.hour, .minute, .second], from: sd2))
                else { return false }
            
            return compareDate1 < compareDate2
        })
        
        return eventsForDate
    }
    
}

public class Read {
    
    public static func swiftCal(from icsString: String) -> SwiftCal {
        
        let formattedICS = icsString.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        var calendarEvents = formattedICS.components(separatedBy: "BEGIN:VEVENT")
        
        let calendar = SwiftCal()
        
        if calendarEvents.count > 0 {
            
            var calendarIdNSString: NSString?
            
            let headerScanner = Scanner(string: calendarEvents.first!)
            headerScanner.scanUpTo("TZID:", into: nil)
            headerScanner.scanUpTo("\n", into: &calendarIdNSString)
            
            if let timezone = calendarIdNSString?.replacingOccurrences(of: "TZID:", with: "").trimmingCharacters(in: CharacterSet.newlines) {

                print("Calendar Timezone: \(timezone)")
                
                calendar.timezone = NSTimeZone(name: timezone)

            }
            
            calendarEvents.remove(at: 0)
        }
        
        for event in calendarEvents {
            
            guard let calendarEvent = ICSEventParser.event(from: event) else { continue }
            calendar.addEvent(calendarEvent)
        }
        
        return calendar
    }
}
