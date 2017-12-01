//
//  SwiftCal.swift
//  CalendarKit-Swift
//
//  Created by Maurice Arikoglu on 30.11.17.
//  Copyright © 2017 Maurice Arikoglu. All rights reserved.
//

import UIKit

class SwiftCal: NSObject {

    var events = [CalendarEvent]()
    var timezone: NSTimeZone?
    
    @discardableResult func addEvent(_ event: CalendarEvent) -> Int {
        
        events.append(event)
        return events.count
    }
    
}

class Read {
    
    static func swiftCal(from icsString: String) -> SwiftCal {
        
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
