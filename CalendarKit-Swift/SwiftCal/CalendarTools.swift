//
//  CalendarTools.swift
//  CalendarKit-Swift
//
//  Created by Maurice Arikoglu on 25.04.18.
//  Copyright © 2018 Maurice Arikoglu. All rights reserved.
//

import Foundation

enum GregorianCalendarWeek: Int {
    case sunday = 1
    case monday
    case tuesday
    case wednesday
    case thursday
    case friday
    case saturday

    func icsIdentifier() -> String {
        switch self.rawValue {
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

    static func fromICS(ics: String) -> GregorianCalendarWeek? {
        switch ics {
        case "SU":
            return .sunday
        case "MO":
            return .monday
        case "TU":
            return .tuesday
        case "WE":
            return .wednesday
        case "TH":
            return .thursday
        case "FR":
            return .friday
        case "SA":
            return .saturday
        default:
            return nil
        }
    }
}
