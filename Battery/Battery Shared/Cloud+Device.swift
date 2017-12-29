//
//  Cloud+Device.swift
//  Battery
//
//  Created by Andrew Finke on 12/20/17.
//  Copyright © 2017 Andrew Finke. All rights reserved.
//

import CloudKit

extension Device {
    init?(record: CKRecord) {
        guard let name = record["Name"] as? NSString,
            let deviceID = record["DeviceID"] as? NSString,
            let lastUpdated = record.modificationDate,
            let levelNum = record["Level"] as? NSNumber,
            let stateNum = record["State"] as? NSNumber,
            let state = BatteryState(rawValue: stateNum.intValue) else {
                return nil
        }
        self.id = deviceID as String
        self.name = name as String
        self.lastUpdated = lastUpdated
        self.batteryInfo =  BatteryInfo(level: levelNum.doubleValue, state: state)
    }
}
