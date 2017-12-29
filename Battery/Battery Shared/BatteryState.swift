//
//  BatteryState.swift
//  Battery
//
//  Created by Andrew Finke on 12/20/17.
//  Copyright © 2017 Andrew Finke. All rights reserved.
//

import Foundation

enum BatteryState: Int {
    case unknown
    case unplugged // on battery, discharging
    case charging // plugged in, less than 100%
    case full

    var description: String {
        switch self {
        case .unknown:
            return "Unknown"
        case .unplugged:
            return "Unplugged"
        case .charging:
            return "Charging"
        case .full:
            return "Full"
        }
    }
}
