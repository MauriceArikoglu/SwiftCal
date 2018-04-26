//
//  ICSTimeZoneParser.swift
//  CalendarKit-Swift
//
//  Created by Maurice Arikoglu on 25.04.18.
//  Copyright © 2018 Maurice Arikoglu. All rights reserved.
//

import Foundation

/*
 
BEGIN:VTIMEZONE
TZID:Europe/Berlin
X-LIC-LOCATION:Europe/Berlin
BEGIN:DAYLIGHT
TZOFFSETFROM:+0100
TZOFFSETTO:+0200
TZNAME:CEST
DTSTART:19700329T020000
RRULE:FREQ=YEARLY;BYMONTH=3;BYDAY=-1SU
END:DAYLIGHT
BEGIN:STANDARD
TZOFFSETFROM:+0200
TZOFFSETTO:+0100
TZNAME:CET
DTSTART:19701025T030000
RRULE:FREQ=YEARLY;BYMONTH=10;BYDAY=-1SU
END:STANDARD
END:VTIMEZONE

*/

struct TimeZoneTime {

    var isDaylightSaving: Bool
    var startDate: Date!
    var name: String!
    var rrule: EventRule!

    var offsetFrom: Int
    var offsetTo: Int

    init(daylightSaving: Bool) {
        self.isDaylightSaving = daylightSaving
        self.offsetTo = 0
        self.offsetFrom = 0
    }
}

public enum TimeZoneError: Error {
    case missingTimeZoneInfo
    case missingTimeZoneTimeInfo
    case missingTimeZoneId
    case invalidTimeZoneId
}

extension TimeZone {

    init?(formattedICS: String) throws {
        var timezoneNSString: NSString?
        let timezoneScanner = Scanner(string: formattedICS)
        timezoneScanner.scanUpTo(ICSEventKey.timezoneBegin, into: nil)
        timezoneScanner.scanUpTo(ICSEventKey.timezoneEnd, into: &timezoneNSString)

        guard
            let unwrappedTimezoneString = timezoneNSString
            else {
                throw TimeZoneError.missingTimeZoneInfo
        }

        let timezoneICS = String(unwrappedTimezoneString)

        guard
            let timeZoneId = ICSTimeZoneParser.timeZoneIdentifier(from: timezoneICS)
            else {

                let timeZoneTimes = ICSTimeZoneParser.timeZoneTimes(from: timezoneICS)
                guard
                    let daylightTime = timeZoneTimes?.daylightSavings,
                    let standardTime = timeZoneTimes?.standard
                    else {
                        throw TimeZoneError.missingTimeZoneId
                }

                guard
                    let timezone = TimeZone(daylightTime: daylightTime, standardTime: standardTime)
                    else {
                        throw TimeZoneError.missingTimeZoneTimeInfo
                }

                self = timezone
                return
        }

        guard
            let timezone = TimeZone(identifier: timeZoneId)
            else {
               throw TimeZoneError.invalidTimeZoneId
        }

        self = timezone

    }

    init?(daylightTime: TimeZoneTime, standardTime: TimeZoneTime) {

        guard
            let daylightMonthString = daylightTime.rrule.byMonth?.first,
            let standardMonthString = standardTime.rrule.byMonth?.first,
            let daylightMonth = Int(daylightMonthString),
            let standardMonth = Int(standardMonthString),
            let daylightDay = daylightTime.rrule.byDay?.first,
            let standardDay = standardTime.rrule.byDay?.first
            else {
                return nil
        }

        let daylightWeekDayString = String(daylightDay[daylightDay.index(daylightDay.endIndex, offsetBy: -2)...])
        let standardWeekDayString = String(standardDay[standardDay.index(standardDay.endIndex, offsetBy: -2)...])

        let daylightWeekDay = GregorianCalendarWeek.fromICS(ics: daylightWeekDayString)!.rawValue
        let standardWeekDay = GregorianCalendarWeek.fromICS(ics: standardWeekDayString)!.rawValue

        let prefixDaylight = String(daylightDay.dropLast(2))
        let prefixStandard = String(standardDay.dropLast(2))

        var daylightDate: Date!
        var standardDate: Date!

        if prefixDaylight.count > 0 {
            let ordinalDaylight = Int(prefixDaylight)
            daylightDate = Date().set(month: daylightMonth, weekday: daylightWeekDay, ordinal: ordinalDaylight)
        } else {
            daylightDate = Date().set(month: daylightMonth, weekday: daylightWeekDay)
        }

        if prefixStandard.count > 0 {
            let ordinalStandard = Int(prefixStandard)
            standardDate = Date().set(month: standardMonth, weekday: standardWeekDay, ordinal: ordinalStandard)
        } else {
            standardDate = Date().set(month: standardMonth, weekday: standardWeekDay)
        }

        let currentDate = Date()

        if daylightDate < standardDate {
            // Daylight date is earlier in year than standard date
            if (daylightDate...standardDate).contains(currentDate) {
                // Current Date is in daylight saving time
                guard
                    let name = daylightTime.name,
                    let timezone = TimeZone(abbreviation: name)
                    else {
                        // If abbreviation is not correct, last straw is to use offset
                        self.init(secondsFromGMT: daylightTime.offsetTo)
                        return
                }

                self = timezone
                return
            } else {
                guard
                    let name = standardTime.name,
                    let timezone = TimeZone(abbreviation: name)
                    else {
                        // If abbreviation is not correct, last straw is to use offset
                        self.init(secondsFromGMT: standardTime.offsetTo)
                        return
                }

                self = timezone
                return
            }
        } else {
            if (standardDate...daylightDate).contains(currentDate) {
                guard
                    let name = standardTime.name,
                    let timezone = TimeZone(abbreviation: name)
                    else {
                        // If abbreviation is not correct, last straw is to use offset
                        self.init(secondsFromGMT: standardTime.offsetTo)
                        return
                }

                self = timezone
                return
            } else {
                // Current Date is in daylight saving time
                guard
                    let name = daylightTime.name,
                    let timezone = TimeZone(abbreviation: name)
                    else {
                        // If abbreviation is not correct, last straw is to use offset
                        self.init(secondsFromGMT: daylightTime.offsetTo)
                        return
                }

                self = timezone
                return
            }
        }

    }

}

struct ICSTimeZoneParser {

    public static func timeZoneIdentifier(from icsString: String) -> String? {

        var timezoneNSString: NSString?
        var timezoneString: String?

        var eventScanner = Scanner(string: icsString)
        eventScanner.scanUpTo(ICSEventKey.timezoneStartDateAndTimezone, into: nil)
        eventScanner.scanUpTo(":", into: &timezoneNSString)

        // Handle variations of timezone:
        //   - `DTSTART;TZID="(UTC-05:00) Eastern Time (US & Canada)":20180320T133000` (has ":" in tzid)
        //   - `DTSTART;TZID=Arabian Standard Time:20180225T110000`
        eventScanner.scanString(":", into: nil)
        var partialTimezoneString: NSString?
        var tempString: NSString?

        let cachedScanLocation = eventScanner.scanLocation
        eventScanner.scanUpTo("\n", into: &tempString)

        if let tempString = tempString, tempString.contains(":") {
            eventScanner.scanLocation = cachedScanLocation
            eventScanner.scanUpTo(":", into: &partialTimezoneString)
            timezoneNSString = timezoneNSString?.appendingFormat(":%@", partialTimezoneString!)
        }

        timezoneString = timezoneNSString?.replacingOccurrences(of: ICSEventKey.timezoneStartDateAndTimezone, with: "").trimmingCharacters(in: CharacterSet.newlines).fixIllegalICS()

        if timezoneString == nil {

            eventScanner = Scanner(string: icsString)
            eventScanner.scanUpTo(ICSEventKey.timezone, into: nil)
            eventScanner.scanUpTo("\n", into: &timezoneNSString)

            timezoneString = timezoneNSString?.replacingOccurrences(of: ICSEventKey.timezone, with: "").trimmingCharacters(in: CharacterSet.newlines).fixIllegalICS()

        }

        return timezoneString
    }

    public static func timeZoneTimes(from icsString: String) -> (daylightSavings: TimeZoneTime, standard: TimeZoneTime)? {

        var daylightNSString: NSString?
        /*
         BEGIN:DAYLIGHT
         TZOFFSETFROM:+0100
         TZOFFSETTO:+0200
         TZNAME:CEST
         DTSTART:19700329T020000
         RRULE:FREQ=YEARLY;BYMONTH=3;BYDAY=-1SU
         END:DAYLIGHT
         */
        let daylightScanner = Scanner(string: icsString)
        daylightScanner.scanUpTo(ICSEventKey.daylightBegin, into: nil)
        daylightScanner.scanUpTo(ICSEventKey.daylightEnd, into: &daylightNSString)

        var standardNSString: NSString?
        /*
         BEGIN:STANDARD
         TZOFFSETFROM:+0200
         TZOFFSETTO:+0100
         TZNAME:CET
         DTSTART:19701025T030000
         RRULE:FREQ=YEARLY;BYMONTH=10;BYDAY=-1SU
         END:STANDARD
         */
        let standardScanner = Scanner(string: icsString)
        standardScanner.scanUpTo(ICSEventKey.standardBegin, into: nil)
        standardScanner.scanUpTo(ICSEventKey.standardEnd, into: &standardNSString)

        guard
            let daylightInfo = daylightNSString,
            let standardInfo = standardNSString
            else {
                return nil
        }

        guard
            let daylightTime = timeZoneTime(from: String(daylightInfo), daylightSaving: true),
            let standardTime = timeZoneTime(from: String(standardInfo), daylightSaving: false)
            else {
                return nil
        }

        return (daylightTime, standardTime)
    }

    private static func timeZoneTime(from icsString: String, daylightSaving: Bool) -> TimeZoneTime? {

        var timezone = TimeZoneTime(daylightSaving: daylightSaving)

        guard
            let offsetFromString = timeZoneOffsetFrom(from: icsString),
            let offsetToString = timeZoneOffsetTo(from: icsString),
            offsetFromString.count == 5 && offsetToString.count == 5,
            let timezoneName = timeZoneName(from: icsString),
            let startDateString = ICSEventParser.startDate(from: icsString, timezone: nil),
            let rrule = ICSEventParser.recurrenceRule(from: icsString),
            let firstCharacterFrom = offsetFromString.first,
            let firstCharacterTo = offsetToString.first,
            firstCharacterFrom == "+" || firstCharacterFrom == "-",
            firstCharacterTo == "+" || firstCharacterTo == "-",
            let startDate = DateFormatter().dateFromICSString(icsDate: startDateString).date
            else {
                return nil
        }

        guard
            let hoursFrom = Int(offsetFromString.dropFirst().dropLast(2)),
            let minutesFrom = Int(offsetFromString.dropFirst(3)),
            let hoursTo = Int(offsetToString.dropFirst().dropLast(2)),
            let minutesTo = Int(offsetToString.dropFirst(3))
            else {
                return nil
        }

        let isToAhead = offsetToString.first == "+"
        let isFromAhead = offsetFromString.first == "-"

        timezone.name = timezoneName
        timezone.startDate = startDate
        timezone.offsetFrom = (hoursFrom * 60 * 60) + (minutesFrom * 60) * (isFromAhead ? 1 : -1)
        timezone.offsetTo = (hoursTo * 60 * 60) + (minutesTo * 60) * (isToAhead ? 1 : -1)
        timezone.rrule = ICSEventParser.eventRule(from: rrule)

        return timezone
    }

    private static func timeZoneOffsetFrom(from icsString: String) -> String? {

        var offsetString: NSString?

        let eventScanner = Scanner(string: icsString)
        eventScanner.scanUpTo(ICSEventKey.timezoneOffsetFrom, into: nil)
        eventScanner.scanUpTo("\n", into: &offsetString)

        return offsetString?.replacingOccurrences(of: ICSEventKey.timezoneOffsetFrom, with: "").trimmingCharacters(in: CharacterSet.newlines).fixIllegalICS()
    }

    private static func timeZoneOffsetTo(from icsString: String) -> String? {

        var offsetString: NSString?

        let eventScanner = Scanner(string: icsString)
        eventScanner.scanUpTo(ICSEventKey.timezoneOffsetTo, into: nil)
        eventScanner.scanUpTo("\n", into: &offsetString)

        return offsetString?.replacingOccurrences(of: ICSEventKey.timezoneOffsetTo, with: "").trimmingCharacters(in: CharacterSet.newlines).fixIllegalICS()
    }

    private static func timeZoneName(from icsString: String) -> String? {

        var nameString: NSString?

        let eventScanner = Scanner(string: icsString)
        eventScanner.scanUpTo(ICSEventKey.timezoneName, into: nil)
        eventScanner.scanUpTo("\n", into: &nameString)

        return nameString?.replacingOccurrences(of: ICSEventKey.timezoneName, with: "").trimmingCharacters(in: CharacterSet.newlines).fixIllegalICS()
    }

}
