//
//  InterfaceController.swift
//  Battery watchOS App Extension
//
//  Created by Andrew Finke on 12/20/17.
//  Copyright © 2017 Andrew Finke. All rights reserved.
//

import WatchKit
import Foundation


class InterfaceController: WKInterfaceController {

    @IBOutlet weak var deviceTable: WKInterfaceTable!

    override func awake(withContext context: Any?) {
        super.awake(withContext: context)

        Model.shared.onUpdate { localDevice, cloudDevices in
            DispatchQueue.main.async {
                let devices = [localDevice] + cloudDevices
                self.deviceTable.setNumberOfRows(devices.count, withRowType: "DeviceRowController")

                for (index, device) in devices.enumerated() {
                    let row = self.deviceTable.rowController(at: index) as? DeviceRowController
                    row?.nameLabel.setText(device.name)
                    row?.batteryLabel.setText(device.batteryInfo.level.description)
                }
            }
        }
    }
    
    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
    }
    
    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }

}
