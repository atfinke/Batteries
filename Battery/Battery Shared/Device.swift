//
//  Device.swift
//  Battery
//
//  Created by Andrew Finke on 12/20/17.
//  Copyright © 2017 Andrew Finke. All rights reserved.
//

#if os(iOS)
    import UIKit
#elseif os(watchOS)
    import WatchKit
#elseif os(macOS)
    import Foundation
#endif

struct Device {
    let id: String
    let name: String
    let lastUpdated: Date

    var batteryInfo: BatteryInfo

    static func local(batteryInfo: BatteryInfo) -> Device {
        let name: String
        #if os(iOS)
            name = UIDevice.current.name
        #elseif os(watchOS)
            name = WKInterfaceDevice.current().name
        #elseif os(macOS)
            name = Host.current().localizedName!
        #endif

        let id: String
        if let savedID = UserDefaults.standard.string(forKey: "LocalDeviceID") {
            id = savedID
        } else {
            id = NSUUID().uuidString
            UserDefaults.standard.set(id, forKey: "LocalDeviceID")
        }

        return Device(id: id,
                      name: name,
                      lastUpdated: Date(),
                      batteryInfo: batteryInfo)
    }
}
