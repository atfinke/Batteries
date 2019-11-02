//
//  BatteryState.swift
//  BatteryX
//
//  Created by Andrew Finke on 9/25/19.
//  Copyright © 2019 Andrew Finke. All rights reserved.
//

import Foundation

enum BatteryState: Int, Equatable {
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
