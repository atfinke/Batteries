//
//  Logging.swift
//  BatteryX
//
//  Created by Andrew Finke on 9/26/19.
//  Copyright © 2019 Andrew Finke. All rights reserved.
//

import Foundation
import os.log

extension OSLog {

    // MARK: - Types -

    private enum CustomCategory: String {
        case appLifecycle, model, cloud, device, battery
    }

    private static let subsystem: String = {
        guard let identifier = Bundle.main.bundleIdentifier else { fatalError() }
        return identifier
    }()

    static let appLifecycle = OSLog(subsystem: subsystem, category: CustomCategory.appLifecycle.rawValue)
    static let model = OSLog(subsystem: subsystem, category: CustomCategory.model.rawValue)
    static let cloud = OSLog(subsystem: subsystem, category: CustomCategory.cloud.rawValue)
    static let device = OSLog(subsystem: subsystem, category: CustomCategory.device.rawValue)
    static let battery = OSLog(subsystem: subsystem, category: CustomCategory.battery.rawValue)

}
