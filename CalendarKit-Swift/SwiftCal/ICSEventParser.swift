//
//  PUEventParser.swift
//  CalendarKit-Swift
//
//  Created by Maurice Arikoglu on 29.11.17.
//  Copyright © 2017 Maurice Arikoglu. All rights reserved.
//

import UIKit

struct ICSEventParser {

    static func event(from icsString: String, calendarTimezone: TimeZone? = nil) -> CalendarEvent? {

        let timeZone = ICSTimeZoneParser.timeZoneIdentifier(from: icsString)

        let dateFormatter = DateFormatter()

        guard
            let startDateString = startDate(from: icsString, timezone: timeZone),
            let endDateString = endDate(from: icsString, timezone: timeZone),
            let uniqueId = uniqueIdentifier(from: icsString)
            else {
                return nil
        }

        let startDateInfo = dateFormatter.dateFromICSString(icsDate: startDateString,
                                                            calendarTimezone: calendarTimezone)

        guard
            let startDate = startDateInfo.date,
            let endDate = dateFormatter.dateFromICSString(icsDate: endDateString,
                                                          calendarTimezone: calendarTimezone).date
            else {
                return nil
        }

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
            let lastModifiedString = lastModified(from: icsString) {

            event.createdDate = dateFormatter.dateFromICSString(icsDate: createdDateString).date
            event.lastModified = dateFormatter.dateFromICSString(icsDate: lastModifiedString).date
        }

        event.attendees = attendees(from: icsString)

        event.organizerEmail = organizerEmail(from: icsString)

        event.title = summary(from: icsString)
        event.notes = description(from: icsString)

        event.location = location(from: icsString)

        event.exceptionDates = exceptionDates(from: icsString)
            .compactMap { dateFormatter.dateFromICSString(icsDate: $0).date }

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
        eventScanner.scanUpTo(ICSEventKey.exceptionDate, into: nil)

        while !eventScanner.isAtEnd {

            eventScanner.scanUpTo(":", into: nil)

            var exceptionNSString: NSString?

            eventScanner.scanUpTo("\n", into: &exceptionNSString)

            let exceptionString = exceptionNSString?.replacingOccurrences(of: ":", with: "").trimmingCharacters(in: CharacterSet.newlines).fixIllegalICS()

            if exceptionString != nil {

                exceptions.append(exceptionString!)
            }

            eventScanner.scanUpTo(ICSEventKey.exceptionDate, into: nil)
        }

        return exceptions
    }

    public static func recurrenceRule(from icsString: String) -> String? {

        var recurrenceString: NSString?

        let eventScanner = Scanner(string: icsString)
        eventScanner.scanUpTo(ICSEventKey.recurrenceRule, into: nil)
        eventScanner.scanUpTo("\n", into: &recurrenceString)

        return recurrenceString?.replacingOccurrences(of: ICSEventKey.recurrenceRule, with: "").trimmingCharacters(in: CharacterSet.newlines).fixIllegalICS()
    }

    private static func exceptionRule(from icsString: String) -> String? {

        var exceptionString: NSString?

        let eventScanner = Scanner(string: icsString)
        eventScanner.scanUpTo(ICSEventKey.exceptionRule, into: nil)
        eventScanner.scanUpTo("\n", into: &exceptionString)

        return exceptionString?.replacingOccurrences(of: ICSEventKey.exceptionRule, with: "").trimmingCharacters(in: CharacterSet.newlines).fixIllegalICS()
    }

    private static func transparent(from icsString: String) -> String? {

        var transparentString: NSString?

        let eventScanner = Scanner(string: icsString)
        eventScanner.scanUpTo(ICSEventKey.transparent, into: nil)
        eventScanner.scanUpTo("\n", into: &transparentString)

        return transparentString?.replacingOccurrences(of: ICSEventKey.transparent, with: "").trimmingCharacters(in: CharacterSet.newlines).fixIllegalICS()
    }

    private static func summary(from icsString: String) -> String? {

        var summaryString: NSString?

        let eventScanner = Scanner(string: icsString)
        eventScanner.scanUpTo(ICSEventKey.summary, into: nil)
        eventScanner.scanUpTo("\n", into: &summaryString)

        return summaryString?.replacingOccurrences(of: ICSEventKey.summary, with: "").trimmingCharacters(in: CharacterSet.newlines).fixIllegalICS()
    }

    private static func status(from icsString: String) -> String? {

        var statusString: NSString?

        let eventScanner = Scanner(string: icsString)
        eventScanner.scanUpTo(ICSEventKey.status, into: nil)
        eventScanner.scanUpTo("\n", into: &statusString)

        return statusString?.replacingOccurrences(of: ICSEventKey.status, with: "").trimmingCharacters(in: CharacterSet.newlines).fixIllegalICS()
    }

    private static func organizerEmail(from icsString: String) -> String? {

        var organizerEmailString: NSString?

        let eventScanner = Scanner(string: icsString)
        eventScanner.scanUpTo(ICSEventKey.organizer, into: nil)
        if eventScanner.isAtEnd {
            eventScanner.scanLocation = 0
            eventScanner.scanUpTo(ICSEventKey.organizer2, into: nil)
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
        eventScanner.scanUpTo(ICSEventKey.sequence, into: nil)
        eventScanner.scanUpTo("\n", into: &sequenceString)

        return sequenceString?.replacingOccurrences(of: ICSEventKey.sequence, with: "").trimmingCharacters(in: CharacterSet.newlines).fixIllegalICS()
    }

    private static func location(from icsString: String) -> String? {

        var locationString: NSString?

        let eventScanner = Scanner(string: icsString)
        eventScanner.charactersToBeSkipped = newlineCharacterSet()
        eventScanner.scanUpTo(ICSEventKey.location, into: nil)
        eventScanner.scanUpTo("\n", into: &locationString)

        var isMultiLineDescription = true

        while isMultiLineDescription {
            var nextLine: NSString?
            eventScanner.scanUpTo("\n", into: &nextLine)
            if let nextLine = nextLine, nextLine.hasPrefix(" ") {
                locationString = locationString?.appending(nextLine.trimmingCharacters(in: .whitespacesAndNewlines)) as NSString?
            } else {
                isMultiLineDescription = false
            }
        }

        return locationString?.replacingOccurrences(of: ICSEventKey.location, with: "").replacingOccurrences(of: "\\n", with: "\n").replacingOccurrences(of: "\\", with: "").trimmingCharacters(in: CharacterSet.newlines).fixIllegalICS()
    }

    private static func lastModified(from icsString: String) -> String? {

        var lastModifiedString: NSString?

        let eventScanner = Scanner(string: icsString)
        eventScanner.scanUpTo(ICSEventKey.lastModified, into: nil)
        eventScanner.scanUpTo("\n", into: &lastModifiedString)

        return lastModifiedString?.replacingOccurrences(of: ICSEventKey.lastModified, with: "").trimmingCharacters(in: CharacterSet.newlines).fixIllegalICS()
    }

    private static func description(from icsString: String) -> String? {

        var descriptionString: NSString?

        var eventScanner = Scanner(string: icsString)
        eventScanner.charactersToBeSkipped = newlineCharacterSet()
        eventScanner.scanUpTo(ICSEventKey.description, into: nil)
        eventScanner.scanUpTo("\n", into: &descriptionString)

        // Handle description that has the language tag e.g.
        // `DESCRIPTION;LANGUAGE=en-US:Dear Gary, Attached is the ...`
        if descriptionString == nil {
            eventScanner = Scanner(string: icsString)
            eventScanner.charactersToBeSkipped = newlineCharacterSet()
            eventScanner.scanUpTo(ICSEventKey.description2, into: nil)
            eventScanner.scanUpTo(":", into: nil)
            eventScanner.scanString(":", into: nil)
            eventScanner.scanUpTo("\n", into: &descriptionString)
        }

        // a multi-line description can have newline characters
        // as per ICS protocol, the newline characters within a field should be represented by \\n
        // however, some ICS files don't follow this rule and use the actual newline character (\n) instead
        // the way to differentiate between this \n and the \n that acts as a delimiter between different fields in the ICS file is that
        // the newline that starts after this \n has an empty string prefix
        // are characters within the description and not delimiters, since they start with a space or tab
        var isMultiLineDescription = true

        while isMultiLineDescription {
            var nextLine: NSString?
            eventScanner.scanUpTo("\n", into: &nextLine)
            if let nextLine = nextLine, nextLine.hasPrefix(" ") {
                descriptionString = descriptionString?.appending(nextLine.trimmingCharacters(in: .whitespacesAndNewlines)) as NSString?
            } else {
                isMultiLineDescription = false
            }
        }

        return descriptionString?.replacingOccurrences(of: ICSEventKey.description, with: "").replacingOccurrences(of: "\\n", with: "\n").replacingOccurrences(of: "\\", with: "").trimmingCharacters(in: CharacterSet.newlines)
    }

    private static func newlineCharacterSet() -> CharacterSet {
        var skipCharacterSet = CharacterSet()
        skipCharacterSet.insert(charactersIn: "\n")
        skipCharacterSet.insert(charactersIn: "\r\n")
        return skipCharacterSet
    }

    private static func createdDate(from icsString: String) -> String? {

        var createdString: NSString?

        let eventScanner = Scanner(string: icsString)
        eventScanner.scanUpTo(ICSEventKey.created, into: nil)
        eventScanner.scanUpTo("\n", into: &createdString)

        return createdString?.replacingOccurrences(of: ICSEventKey.created, with: "").trimmingCharacters(in: CharacterSet.newlines).fixIllegalICS()
    }

    private static func recurrence(from icsString: String, with timezoneString: String) -> String? {

        var recurrenceString: NSString?

        let eventScanner = Scanner(string: icsString)
        let mergedSearchString = String.init(format: ICSEventKey.recurrenceId, timezoneString)

        eventScanner.scanUpTo(mergedSearchString, into: nil)
        eventScanner.scanUpTo("\n", into: &recurrenceString)

        return recurrenceString?.replacingOccurrences(of: mergedSearchString, with: "").trimmingCharacters(in: CharacterSet.newlines).fixIllegalICS()
    }

    private static func attendees(from icsString: String) -> [EventAttendee] {

        var attendees = [EventAttendee]()

        let eventScanner = Scanner(string: icsString)
        eventScanner.charactersToBeSkipped = newlineCharacterSet()

        var scanStatus = false

        repeat {

            var attendeeNSString: NSString?

            if eventScanner.scanString(ICSEventKey.attendee, into: nil) ||
                (eventScanner.scanUpTo(ICSEventKey.attendee, into: nil) && !eventScanner.isAtEnd) {

                scanStatus = eventScanner.scanUpTo("\n", into: &attendeeNSString)

                if scanStatus {

                    var isMultiLineDescription = true

                    while isMultiLineDescription {
                        var nextLine: NSString?
                        let originalScanLocation = eventScanner.scanLocation
                        eventScanner.scanUpTo("\n", into: &nextLine)
                        if let nextLine = nextLine,
                            nextLine.hasPrefix(" ") {
                            attendeeNSString = attendeeNSString?.appending(nextLine.trimmingCharacters(in: .whitespacesAndNewlines)) as NSString?
                        } else {
                            eventScanner.scanLocation = originalScanLocation
                            isMultiLineDescription = false
                        }
                    }

                    // Create attendee from String
                    guard
                        let attendeeString = attendeeNSString?.replacingOccurrences(of: ICSEventKey.attendee, with: "").trimmingCharacters(in: CharacterSet.newlines).fixIllegalICS(),
                        let attendee = self.attendee(from: attendeeString)
                        else {
                            continue
                    }
                    attendees.append(attendee)
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

        guard
            let attributes = attributesNS as String?
            else {
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
            attendee.status = status.replacingOccurrences(of: "PARTSTAT=",
                                                          with: "",
                                                          options: .caseInsensitive,
                                                          range: NSMakeRange(0, status.length))
        }

        var commonName: NSString?
        let commonNameScanner = Scanner(string: attributes)
        commonNameScanner.scanUpTo("CN=", into: nil)
        commonNameScanner.scanUpTo(";", into: &commonName)
        if let commonName = commonName {
            attendee.name = commonName.replacingOccurrences(of: "CN=",
                                                            with: "",
                                                            options: .caseInsensitive,
                                                            range: NSMakeRange(0, commonName.length))
        }

        var email: NSString?
        let emailScanner = Scanner(string: icsString)
        emailScanner.scanUpTo("mailto:", into: nil)
        emailScanner.scanUpTo(";", into: &email)
        if let email = email {
            attendee.email = email.replacingOccurrences(of: "mailto:",
                                                        with: "",
                                                        options: .caseInsensitive,
                                                        range: NSMakeRange(0, email.length))
        }

        return attendee
    }

    private static func uniqueIdentifier(from icsString: String) -> String? {

        var uniqueIdString: NSString?

        let eventScanner = Scanner(string: icsString)
        eventScanner.scanUpTo(ICSEventKey.uniqueId, into: nil)
        eventScanner.scanUpTo("\n", into: &uniqueIdString)

        return uniqueIdString?.replacingOccurrences(of: ICSEventKey.uniqueId, with: "").trimmingCharacters(in: CharacterSet.newlines).fixIllegalICS()
    }

    private static func timestamp(from icsString: String) -> String? {

        var timestampString: NSString?

        let eventScanner = Scanner(string: icsString)
        eventScanner.scanUpTo(ICSEventKey.timestamp, into: nil)
        eventScanner.scanUpTo("\n", into: &timestampString)

        return timestampString?.replacingOccurrences(of: ICSEventKey.timestamp, with: "").trimmingCharacters(in: CharacterSet.newlines).fixIllegalICS()
    }

    private static func endDate(from icsString: String, timezone: String?) -> String? {

        var endDateNSString: NSString?
        var endDateString: String?

        var eventScanner = Scanner(string: icsString)
        if let timezone = timezone {
            let mergedSearchString = String.init(format: ICSEventKey.endDateAndTimezone, timezone)

            eventScanner.scanUpTo(mergedSearchString, into: nil)
            eventScanner.scanUpTo("\n", into: &endDateNSString)

            endDateString = endDateNSString?.replacingOccurrences(of: mergedSearchString, with: "").trimmingCharacters(in: CharacterSet.newlines).fixIllegalICS()
        }

        if endDateString == nil {

            eventScanner = Scanner(string: icsString)
            eventScanner.scanUpTo(ICSEventKey.endDate, into: nil)
            eventScanner.scanUpTo("\n", into: &endDateNSString)

            endDateString = endDateNSString?.replacingOccurrences(of: ICSEventKey.endDate, with: "").trimmingCharacters(in: CharacterSet.newlines).fixIllegalICS()

            if endDateString == nil {

                eventScanner = Scanner(string: icsString)
                eventScanner.scanUpTo(ICSEventKey.endDateValueDate, into: nil)
                eventScanner.scanUpTo("\n", into: &endDateNSString)

                endDateString = endDateNSString?.replacingOccurrences(of: ICSEventKey.endDateValueDate, with: "").trimmingCharacters(in: CharacterSet.newlines).fixIllegalICS()
            }
        }

        return endDateString
    }

    public static func startDate(from icsString: String, timezone: String?) -> String? {

        var startDateNSString: NSString?
        var startDateString: String?

        var eventScanner = Scanner(string: icsString)
        if let timezone = timezone {
            let mergedSearchString = String.init(format: ICSEventKey.startDateAndTimezone, timezone)

            eventScanner.scanUpTo(mergedSearchString, into: nil)
            eventScanner.scanUpTo("\n", into: &startDateNSString)

            startDateString = startDateNSString?.replacingOccurrences(of: mergedSearchString, with: "").trimmingCharacters(in: CharacterSet.newlines).fixIllegalICS()
        }

        if startDateString == nil {

            eventScanner = Scanner(string: icsString)
            eventScanner.scanUpTo(ICSEventKey.startDate, into: nil)
            eventScanner.scanUpTo("\n", into: &startDateNSString)

            startDateString = startDateNSString?.replacingOccurrences(of: ICSEventKey.startDate, with: "").trimmingCharacters(in: CharacterSet.newlines).fixIllegalICS()

            if startDateString == nil {

                eventScanner = Scanner(string: icsString)
                eventScanner.scanUpTo(ICSEventKey.startDateValueDate, into: nil)
                eventScanner.scanUpTo("\n", into: &startDateNSString)

                startDateString = startDateNSString?.replacingOccurrences(of: ICSEventKey.startDateValueDate, with: "").trimmingCharacters(in: CharacterSet.newlines).fixIllegalICS()

            }
        }

        return startDateString
    }

    // MARK: Frequency and Exception Rules
    public static func eventRule(from icsString: String) -> EventRule {

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

            guard
                let parsedRule = parseRule(from: rule!)
                else {
                    continue
            }

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
    func dateFromICSString(icsDate: String, calendarTimezone: TimeZone? = nil) -> (date: Date?, allDay: Bool) {

        self.dateFormat = ICSFormat.standard

        let formattedString = icsDate.replacingOccurrences(of: "T", with: " ")

        let containsTimezone: Bool = formattedString.lowercased().range(of: "z") != nil

        var date = self.date(from: formattedString)

        if containsTimezone {
            self.dateFormat = ICSFormat.withZone
            date = self.date(from: formattedString)
        } else if let calendarTimezone = calendarTimezone {
            timeZone = TimeZone(secondsFromGMT: 0)
            date = self.date(from: formattedString)
            date?.addTimeInterval(TimeInterval(calendarTimezone.secondsFromGMT()))
            if let givenDate = date {
                date?.addTimeInterval(-TimeZone.current.daylightSavingTimeOffset(for: givenDate))
            }
        }

        if date == nil {

            self.dateFormat = containsTimezone ? ICSFormat.dateOnlyWithZone : ICSFormat.dateOnly

            date = self.date(from: formattedString)

            return (date, true)
        } else {
            // Time in the date -> not all day
            return (date, false)
        }
    }
    
}
