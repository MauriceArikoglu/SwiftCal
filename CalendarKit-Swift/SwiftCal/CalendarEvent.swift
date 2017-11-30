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
    var interval: Int?
    
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
    
    var exceptionRule: EventRule?
    var recurrenceRule: EventRule?
    
    init(startDate: Date, endDate: Date?, uniqueId: String) {
        super.init()
        self.startDate = startDate
        self.endDate = endDate
        self.eventIdentifier = uniqueId
    }
    
}
