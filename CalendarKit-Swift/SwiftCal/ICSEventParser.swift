//
//  PUEventParser.swift
//  CalendarKit-Swift
//
//  Created by Maurice Arikoglu on 29.11.17.
//  Copyright © 2017 Maurice Arikoglu. All rights reserved.
//

import UIKit

class ICSEventParser: NSObject {

    private struct ICS {
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
    }

    static func event(from icsString: String) -> CalendarEvent? {

        let timeZone = timezone(from: icsString)

        let dateFormatter = DateFormatter()

        guard let startDateString = startDate(from: icsString, timezone: timeZone),
            let endDateString = endDate(from: icsString, timezone: timeZone),
            let uniqueId = uniqueIdentifier(from: icsString)
            else { return nil }
        
        let startDateInfo = dateFormatter.dateFromICSString(icsDate: startDateString)
        
        guard let startDate = startDateInfo.date,
            let endDate = dateFormatter.dateFromICSString(icsDate: endDateString).date
            else { return nil }
        
        let event = CalendarEvent(startDate: startDate, endDate: endDate, uniqueId: uniqueId)
        
        event.occurrenceDate = startDate
        event.isAllDay = startDateInfo.allDay
        
        let statusString = status(from: icsString)
        
        if statusString != nil {
            switch statusString! {
                
            case "TENTATIVE":
                event.status = EventStatus.tentative
            case "CONFIRMED":
                event.status = EventStatus.confirmed
            case "CANCELLED":
                event.status = EventStatus.cancelled
            default:
                event.status = EventStatus.tentative
            }
        }
        
        if let createdDateString = createdDate(from: icsString),
            let lastModifiedString = lastModified(from: icsString){
            
            event.createdDate = dateFormatter.dateFromICSString(icsDate: createdDateString).date
            event.lastModified = dateFormatter.dateFromICSString(icsDate: lastModifiedString).date
        }
        
        event.attendees = attendees(from: icsString)

        event.organizerEmail = organizerEmail(from: icsString)

        event.title = summary(from: icsString)
        event.notes = description(from: icsString)
        
        event.location = location(from: icsString)
        
        event.exceptionDates = exceptionDates(from: icsString).map({ (dateString) -> Date in
            // If the date can not be read we return distant Past
            return dateFormatter.dateFromICSString(icsDate: dateString).date ?? Date.distantPast
        })

        if let exceptionRule = exceptionRule(from: icsString) {
            event.exceptionRule = eventRule(from: exceptionRule)
        }
        
        if let recurrenceRule = recurrenceRule(from: icsString) {
            event.recurrenceRuleString = recurrenceRule
            event.recurrenceRule = eventRule(from: recurrenceRule)
        }

        return event
    }
    
    private static func exceptionDates(from icsString: String) -> [String] {
        
        var exceptions = [String]()
        
        let eventScanner = Scanner(string: icsString)
        eventScanner.scanUpTo(ICS.exceptionDate, into: nil)
        
        while !eventScanner.isAtEnd {
            
            eventScanner.scanUpTo(":", into: nil)
            
            var exceptionNSString: NSString?
            
            eventScanner.scanUpTo("\n", into: &exceptionNSString)
            
            let exceptionString = exceptionNSString?.replacingOccurrences(of: ":", with: "").trimmingCharacters(in: CharacterSet.newlines).fixIllegalICS()
            
            if (exceptionString != nil) {
                
                exceptions.append(exceptionString!)
            }
            
            eventScanner.scanUpTo(ICS.exceptionDate, into: nil)
        }
        
        return exceptions
    }
    
    private static func recurrenceRule(from icsString: String) -> String? {
        
        var recurrenceString: NSString?
        
        let eventScanner = Scanner(string: icsString)
        eventScanner.scanUpTo(ICS.recurrenceRule, into: nil)
        eventScanner.scanUpTo("\n", into: &recurrenceString)
        
        return recurrenceString?.replacingOccurrences(of: ICS.recurrenceRule, with: "").trimmingCharacters(in: CharacterSet.newlines).fixIllegalICS()
    }
    
    private static func exceptionRule(from icsString: String) -> String? {
        
        var exceptionString: NSString?
        
        let eventScanner = Scanner(string: icsString)
        eventScanner.scanUpTo(ICS.exceptionRule, into: nil)
        eventScanner.scanUpTo("\n", into: &exceptionString)
        
        return exceptionString?.replacingOccurrences(of: ICS.exceptionRule, with: "").trimmingCharacters(in: CharacterSet.newlines).fixIllegalICS()
    }

    private static func transparent(from icsString: String) -> String? {
        
        var transparentString: NSString?
        
        let eventScanner = Scanner(string: icsString)
        eventScanner.scanUpTo(ICS.transparent, into: nil)
        eventScanner.scanUpTo("\n", into: &transparentString)
        
        return transparentString?.replacingOccurrences(of: ICS.transparent, with: "").trimmingCharacters(in: CharacterSet.newlines).fixIllegalICS()
    }
    
    private static func summary(from icsString: String) -> String? {
        
        var summaryString: NSString?
        
        let eventScanner = Scanner(string: icsString)
        eventScanner.scanUpTo(ICS.summary, into: nil)
        eventScanner.scanUpTo("\n", into: &summaryString)
        
        return summaryString?.replacingOccurrences(of: ICS.summary, with: "").trimmingCharacters(in: CharacterSet.newlines).fixIllegalICS()
    }
    
    private static func status(from icsString: String) -> String? {
        
        var statusString: NSString?
        
        let eventScanner = Scanner(string: icsString)
        eventScanner.scanUpTo(ICS.status, into: nil)
        eventScanner.scanUpTo("\n", into: &statusString)
        
        return statusString?.replacingOccurrences(of: ICS.status, with: "").trimmingCharacters(in: CharacterSet.newlines).fixIllegalICS()
    }

    private static func organizerEmail(from icsString: String) -> String? {

        var organizerEmailString: NSString?

        let eventScanner = Scanner(string: icsString)
        eventScanner.scanUpTo(ICS.organizer, into: nil)
        if eventScanner.isAtEnd {
            eventScanner.scanLocation = 0
            eventScanner.scanUpTo(ICS.organizer2, into: nil)
        }
        eventScanner.scanUpTo("mailto:", into: nil)
        eventScanner.scanUpTo("\n", into: &organizerEmailString)

        if let organizerEmailString = organizerEmailString {
            return organizerEmailString.replacingOccurrences(of: "mailto:", with: "", options: .caseInsensitive, range: NSMakeRange(0, organizerEmailString.length)).trimmingCharacters(in: CharacterSet.newlines).fixIllegalICS()
        }

        return nil
    }

    private static func sequence(from icsString: String) -> String? {
        
        var sequenceString: NSString?
        
        let eventScanner = Scanner(string: icsString)
        eventScanner.scanUpTo(ICS.sequence, into: nil)
        eventScanner.scanUpTo("\n", into: &sequenceString)
        
        return sequenceString?.replacingOccurrences(of: ICS.sequence, with: "").trimmingCharacters(in: CharacterSet.newlines).fixIllegalICS()
    }
    
    private static func location(from icsString: String) -> String? {
        
        var locationString: NSString?
        
        let eventScanner = Scanner(string: icsString)
        eventScanner.scanUpTo(ICS.location, into: nil)
        eventScanner.scanUpTo("\n", into: &locationString)

        return locationString?.replacingOccurrences(of: ICS.location, with: "").replacingOccurrences(of: "\\n", with: "\n").replacingOccurrences(of: "\\", with: "").trimmingCharacters(in: CharacterSet.newlines).fixIllegalICS()
    }
    
    private static func lastModified(from icsString: String) -> String? {
        
        var lastModifiedString: NSString?
        
        let eventScanner = Scanner(string: icsString)
        eventScanner.scanUpTo(ICS.lastModified, into: nil)
        eventScanner.scanUpTo("\n", into: &lastModifiedString)
        
        return lastModifiedString?.replacingOccurrences(of: ICS.lastModified, with: "").trimmingCharacters(in: CharacterSet.newlines).fixIllegalICS()
    }
    
    private static func description(from icsString: String) -> String? {
        
        var descriptionString: NSString?
        
        let eventScanner = Scanner(string: icsString)
        eventScanner.scanUpTo(ICS.description, into: nil)
        eventScanner.scanUpTo("\n", into: &descriptionString)

        // description could have newline characters in them (ideally newlines within the description should be represented by \\n as per ICS protocol)
        // we know these newlines are characters within the description and not delimiters, since they start with a space or tab
        var isMultiLineDescription = true;

        while isMultiLineDescription {
            var nextLine: NSString?
            eventScanner.scanUpTo("\n", into: &nextLine)
            if let nextLine = nextLine, nextLine.hasPrefix(" ") {
                descriptionString = descriptionString?.appending(nextLine.trimmingCharacters(in: .whitespacesAndNewlines)) as! NSString
            } else {
                isMultiLineDescription = false;
            }
        }

        return descriptionString?.replacingOccurrences(of: ICS.description, with: "").replacingOccurrences(of: "\\n", with: "\n").replacingOccurrences(of: "\\", with: "").trimmingCharacters(in: CharacterSet.newlines)
    }

    private static func characterSetWithNewLineSkip() -> CharacterSet {
        var skipCharacterSet = CharacterSet()
        skipCharacterSet.insert(charactersIn: "\n")
        skipCharacterSet.insert(charactersIn: "\r\n")
        return skipCharacterSet
    }
    
    private static func createdDate(from icsString: String) -> String? {
        
        var createdString: NSString?
        
        let eventScanner = Scanner(string: icsString)
        eventScanner.scanUpTo(ICS.created, into: nil)
        eventScanner.scanUpTo("\n", into: &createdString)
        
        return createdString?.replacingOccurrences(of: ICS.created, with: "").trimmingCharacters(in: CharacterSet.newlines).fixIllegalICS()
    }
    
    private static func recurrence(from icsString: String, with timezoneString: String) -> String? {
        
        var recurrenceString: NSString?
        
        let eventScanner = Scanner(string: icsString)
        let mergedSearchString = String.init(format: ICS.recurrenceId, timezoneString)
        
        eventScanner.scanUpTo(mergedSearchString, into: nil)
        eventScanner.scanUpTo("\n", into: &recurrenceString)
        
        return recurrenceString?.replacingOccurrences(of: mergedSearchString, with: "").trimmingCharacters(in: CharacterSet.newlines).fixIllegalICS()
    }
    
    private static func attendees(from icsString: String) -> [EventAttendee] {
        
        var attendees = [EventAttendee]()
        
        let eventScanner = Scanner(string: icsString)
        eventScanner.charactersToBeSkipped = characterSetWithNewLineSkip()
        
        var scanStatus = false;
        
        repeat {
        
            var attendeeNSString: NSString?

            if eventScanner.scanString(ICS.attendee, into: nil) ||
                (eventScanner.scanUpTo(ICS.attendee, into: nil) && !eventScanner.isAtEnd) {

                scanStatus = eventScanner.scanUpTo("\n", into: &attendeeNSString)
                
                if scanStatus {

                    var isMultiLineDescription = true;

                    while isMultiLineDescription {
                        var nextLine: NSString?
                        let originalScanLocation = eventScanner.scanLocation
                        eventScanner.scanUpTo("\n", into: &nextLine)
                        if let nextLine = nextLine, nextLine.hasPrefix(" ") {
                            attendeeNSString = attendeeNSString?.appending(nextLine.trimmingCharacters(in: .whitespacesAndNewlines)) as NSString?
                        } else {
                            eventScanner.scanLocation = originalScanLocation
                            isMultiLineDescription = false;
                        }
                    }
                    
                    let attendeeString = attendeeNSString?.replacingOccurrences(of: ICS.attendee, with: "").trimmingCharacters(in: CharacterSet.newlines).fixIllegalICS()
                    
                    // Create attendee from String
                    if (attendeeString != nil) {
                     
                        let attendee = self.attendee(from: attendeeString!)
                        
                        if (attendee != nil) {
                            
                            attendees.append(attendee!)
                        }
                    }
                }
            } else {
                
                scanStatus = false
            }
            
        } while scanStatus
        
        return attendees
    }
    
    private static func attendee(from icsString: String) -> EventAttendee? {
        
        var eventScanner = Scanner(string: icsString)
        var url, attributesNS: NSString?
        
        eventScanner.scanUpTo(":", into: &attributesNS)
        eventScanner.scanUpTo("\n", into: &url)
        
        var attendee = EventAttendee()
        
        if url != nil {
            attendee.url = url!.length > 1 ? String(url!.substring(from: 1)) : nil
        }
        
        guard let attributes = attributesNS as String? else {
            return nil
        }
        
        eventScanner = Scanner(string: attributes)
        var roleString: NSString?

        eventScanner.scanUpTo("ROLE=", into: nil)
        eventScanner.scanUpTo(";", into: &roleString)

        if let roleString = roleString {
            let role = roleString.replacingOccurrences(of: "ROLE=", with: "", options: .caseInsensitive, range: NSMakeRange(0, roleString.length))

            switch role {
            case "CHAIR":
                attendee.role = EventAttendee.AttendeeRole.chair
            case "REQ-PARTICIPANT":
                attendee.role = EventAttendee.AttendeeRole.required
            case "OPT-PARTICIPANT":
                attendee.role = EventAttendee.AttendeeRole.optional
            case "NON-PARTICIPANT":
                attendee.role = EventAttendee.AttendeeRole.non
            default:
                attendee.role = nil
            }
        }

        var status: NSString?
        let statusScanner = Scanner(string: icsString)
        statusScanner.scanUpTo("PARTSTAT=", into: nil)
        statusScanner.scanUpTo(";", into: &status)
        if let status = status {
            attendee.status = status.replacingOccurrences(of: "PARTSTAT=", with: "", options: .caseInsensitive, range: NSMakeRange(0, status.length))
        }

        var commonName: NSString?
        let commonNameScanner = Scanner(string: attributes)
        commonNameScanner.scanUpTo("CN=", into: nil)
        commonNameScanner.scanUpTo(";", into: &commonName)
        if let commonName = commonName {
            attendee.name = commonName.replacingOccurrences(of: "CN=", with: "", options: .caseInsensitive, range: NSMakeRange(0, commonName.length))
        }

        var email: NSString?
        let emailScanner = Scanner(string: icsString)
        emailScanner.scanUpTo("mailto:", into: nil)
        emailScanner.scanUpTo(";", into: &email)
        if let email = email {
            attendee.email = email.replacingOccurrences(of: "mailto:", with: "", options: .caseInsensitive, range: NSMakeRange(0, email.length))
        }

        return attendee
    }
    
    private static func uniqueIdentifier(from icsString: String) -> String? {
        
        var uniqueIdString: NSString?
        
        let eventScanner = Scanner(string: icsString)
        eventScanner.scanUpTo(ICS.uniqueId, into: nil)
        eventScanner.scanUpTo("\n", into: &uniqueIdString)
        
        return uniqueIdString?.replacingOccurrences(of: ICS.uniqueId, with: "").trimmingCharacters(in: CharacterSet.newlines).fixIllegalICS()
    }
    
    private static func timestamp(from icsString: String) -> String? {
        
        var timestampString: NSString?
        
        let eventScanner = Scanner(string: icsString)
        eventScanner.scanUpTo(ICS.timestamp, into: nil)
        eventScanner.scanUpTo("\n", into: &timestampString)
        
        return timestampString?.replacingOccurrences(of: ICS.timestamp, with: "").trimmingCharacters(in: CharacterSet.newlines).fixIllegalICS()
    }

    private static func endDate(from icsString: String, timezone: String?) -> String? {

        var endDateNSString: NSString?
        var endDateString: String?
        
        var eventScanner = Scanner(string: icsString)
        if let timezone = timezone {
            let mergedSearchString = String.init(format: ICS.endDateAndTimezone, timezone)

            eventScanner.scanUpTo(mergedSearchString, into: nil)
            eventScanner.scanUpTo("\n", into: &endDateNSString)

            endDateString = endDateNSString?.replacingOccurrences(of: mergedSearchString, with: "").trimmingCharacters(in: CharacterSet.newlines).fixIllegalICS()
        }

        if (endDateString == nil) {
            
            eventScanner = Scanner(string: icsString)
            eventScanner.scanUpTo(ICS.endDate, into: nil)
            eventScanner.scanUpTo("\n", into: &endDateNSString)
            
            endDateString = endDateNSString?.replacingOccurrences(of: ICS.endDate, with: "").trimmingCharacters(in: CharacterSet.newlines).fixIllegalICS()
            
            if (endDateString == nil) {
                
                eventScanner = Scanner(string: icsString)
                eventScanner.scanUpTo(ICS.endDateValueDate, into: nil)
                eventScanner.scanUpTo("\n", into: &endDateNSString)
                
                endDateString = endDateNSString?.replacingOccurrences(of: ICS.endDateValueDate, with: "").trimmingCharacters(in: CharacterSet.newlines).fixIllegalICS()
            }
        }

        return endDateString
    }

    private static func startDate(from icsString: String, timezone: String?) -> String? {

        var startDateNSString: NSString?
        var startDateString: String?

        var eventScanner = Scanner(string: icsString)
        if let timezone = timezone {
            let mergedSearchString = String.init(format: ICS.startDateAndTimezone, timezone)

            eventScanner.scanUpTo(mergedSearchString, into: nil)
            eventScanner.scanUpTo("\n", into: &startDateNSString)

            startDateString = startDateNSString?.replacingOccurrences(of: mergedSearchString, with: "").trimmingCharacters(in: CharacterSet.newlines).fixIllegalICS()
        }

        if (startDateString == nil) {
            
            eventScanner = Scanner(string: icsString)
            eventScanner.scanUpTo(ICS.startDate, into: nil)
            eventScanner.scanUpTo("\n", into: &startDateNSString)
            
            startDateString = startDateNSString?.replacingOccurrences(of: ICS.startDate, with: "").trimmingCharacters(in: CharacterSet.newlines).fixIllegalICS()

            if (startDateString == nil) {
                
                eventScanner = Scanner(string: icsString)
                eventScanner.scanUpTo(ICS.startDateValueDate, into: nil)
                eventScanner.scanUpTo("\n", into: &startDateNSString)
                
                startDateString = startDateNSString?.replacingOccurrences(of: ICS.startDateValueDate, with: "").trimmingCharacters(in: CharacterSet.newlines).fixIllegalICS()

            }
        }

        return startDateString
    }
    
    private static func timezone(from icsString: String) -> String? {
        
        var timezoneNSString: NSString?
        var timezoneString: String?

        var eventScanner = Scanner(string: icsString)
        eventScanner.scanUpTo(ICS.timezoneStartDateAndTimezone, into: nil)
        eventScanner.scanUpTo(":", into: &timezoneNSString)
        
        timezoneString = timezoneNSString?.replacingOccurrences(of: ICS.timezoneStartDateAndTimezone, with: "").trimmingCharacters(in: CharacterSet.newlines).fixIllegalICS()

        if timezoneString == nil {
            
            eventScanner = Scanner(string: icsString)
            eventScanner.scanUpTo(ICS.timezone, into: nil)
            eventScanner.scanUpTo("\n", into: &timezoneNSString)
            
            timezoneString = timezoneNSString?.replacingOccurrences(of: ICS.timezone, with: "").trimmingCharacters(in: CharacterSet.newlines).fixIllegalICS()

        }

        return timezoneString
    }
    
    // MARK: Frequency and Exception Rules
    private static func eventRule(from icsString: String) -> EventRule {
        
        struct Rule {
            static let frequency = "FREQ"
            static let count = "COUNT"
            static let until = "UNTIL"
            static let interval = "INTERVAL"
            static let day = "BYDAY"
            static let dayOfMonth = "BYMONTHDAY"
            static let dayOfYear = "BYYEARDAY"
            static let weekOfYear = "BYWEEKNO"
            static let month = "BYMONTH"
            static let weekstart = "WKST"
        }
        
        let ruleset = EventRule()
        let rules: [String?] = icsString.components(separatedBy: ";")
        
        for rule in rules {
            
            guard let parsedRule = parseRule(from: rule!) else { continue }
            
            switch rule {
                
            case let rule where (rule?.range(of: Rule.frequency) != nil):
                ruleset.frequency = parsedRule
            case let rule where (rule?.range(of: Rule.count) != nil):
                ruleset.count = Int(parsedRule)
                
            case let rule where (rule?.range(of: Rule.until) != nil):
                let dateFormatter = DateFormatter()
                ruleset.untilDate = dateFormatter.dateFromICSString(icsDate: parsedRule).date
                
            case let rule where (rule?.range(of: Rule.interval) != nil):
                ruleset.interval = Int(parsedRule) ?? 0
                
            case let rule where (rule?.range(of: Rule.day) != nil):
                ruleset.byDay = parsedRule.components(separatedBy: ",")
            case let rule where (rule?.range(of: Rule.dayOfMonth) != nil):
                ruleset.byDayOfMonth = parsedRule.components(separatedBy: ",")
            case let rule where (rule?.range(of: Rule.dayOfYear) != nil):
                ruleset.byDayOfYear = parsedRule.components(separatedBy: ",")
            case let rule where (rule?.range(of: Rule.weekOfYear) != nil):
                ruleset.byWeekOfYear = parsedRule.components(separatedBy: ",")
            case let rule where (rule?.range(of: Rule.month) != nil):
                ruleset.byMonth = parsedRule.components(separatedBy: ",")
            
            case let rule where (rule?.range(of: Rule.weekstart) != nil):
                ruleset.weekstart = parsedRule

            default:
                continue
            }
        }
        
        return ruleset
    }
    
    private static func parseRule(from icsRule: String) -> String? {
        
        var ruleString: NSString?
        let ruleScanner = Scanner(string: icsRule)
        ruleScanner.scanUpTo("=", into: nil)
        ruleScanner.scanUpTo(";", into: &ruleString)
        
        return ruleString?.replacingOccurrences(of: "=", with: "")
    }
}

extension String {
    
    func fixIllegalICS() -> String {
        
        // Sometimes an ICS file can be formatted illegaly
        // Usually there is one property per line
        // If the format is wrong, the parsed property has trailing content that isnt supposed to be there
        // If there is, there will be a whitespace. Any legal property wont have whitespace after them
        // Therefore we remove any content after whitespace
        // If there is no whitespace, we do not change anything
        // This does not work for Fields that are allowed to take whitespaces (description, for instance)
        // " ([A-Z-]){2,}(;|:|=){1}[^ ]"
        var string = self
        
        do {
            let regex = try NSRegularExpression.init(pattern: " ([A-Z-]){2,}(;|:){1}[^ ]", options: [])
            if let rangeToRemove = Range(regex.rangeOfFirstMatch(in: string, options: [], range: NSRange(location: 0, length: string.utf16.count))) {

                string = String(string[..<string.index(string.startIndex, offsetBy: rangeToRemove.lowerBound)])
            }
        } catch {
            
        }
        
        return string
    }
    
}

extension DateFormatter {
    
    struct ICSFormat {
        static let standard = "yyyyMMdd HHmmss"
        static let withZone = "yyyyMMdd HHmmssz"
        static let dateOnly = "yyyyMMdd"
        static let dateOnlyWithZone = "yyyyMMddz"
    }
    // Returns date and isAllDay boolean
    func dateFromICSString(icsDate: String) -> (date: Date?, allDay: Bool) {
        
        self.dateFormat = ICSFormat.standard
        
        let formattedString = icsDate.replacingOccurrences(of: "T", with: " ")
        
        let containsZone: Bool = (formattedString.lowercased().range(of: "z") != nil)
        
        if containsZone {
            self.dateFormat = ICSFormat.withZone
        }
        
        var date = self.date(from: formattedString)
        
        if (date == nil) {
            
            self.dateFormat = containsZone ? ICSFormat.dateOnlyWithZone : ICSFormat.dateOnly
            
            date = self.date(from: formattedString)
            
            return (date, true)
        } else {
            // Time in the date -> not all day
            return (date, false)
        }
    }
}

