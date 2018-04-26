//
//  ViewController.swift
//  CalendarKit-Swift
//
//  Created by Maurice Arikoglu on 29.11.17.
//  Copyright © 2017 Maurice Arikoglu. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.

        do {
            let file = try String(contentsOfFile: Bundle.main.path(forResource: "university-formatted", ofType: "ics") ?? "")
            let swiftCal = try SwiftCal(icsFileContent: file)
//            let eventsForToday = swiftCal.events(for: Date().addingTimeInterval(86400 * 1))

            for event in swiftCal.allEvents {
                
                guard
                    let title = event.title,
                    let start = event.startDate
                    else {
                        print("Insufficient event info")
                        continue
                }
                print(title)
                print(start)
            }
        } catch {
            fatalError("Something went wrong, check your ics file.")
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}
