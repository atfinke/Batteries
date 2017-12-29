//
//  Model.swift
//  Battery
//
//  Created by Andrew Finke on 12/20/17.
//  Copyright © 2017 Andrew Finke. All rights reserved.
//

import Foundation

class Model: NSObject {

    static let shared = Model()

    let cloud = Cloud()
    private var cloudDevices = [Device]()

    let monitor = BatteryMonitor()
    private var localDevice: Device!

    private var lastUpdate: Date?
    private var onUpdate: ((_ local: Device, _ cloud: [Device]) -> ())?

    override init() {
        super.init()

        let battery = monitor.current()
        localDevice = Device.local(batteryInfo: battery)

        #if CLOUD_SUBSCRIBER
            cloud.registerForRemoteNotifications()
        #endif
    }

    var shouldUpdateCloud: Bool {
        if let date = lastUpdate, date.timeIntervalSinceNow > -60 * 15 {
            return false
        }
        return true
    }

    // MARK: - Battery + Cloud Monitoring

    func onUpdate(onUpdate: @escaping ((_ local: Device, _ cloud: [Device]) -> ())) {
        self.onUpdate = onUpdate
        onUpdate(localDevice, [])

        monitor.onChange = { batteryInfo in
            self.updateCloud(completion: { error in

            })
            self.triggerFetch()
        }

        monitor.triggerUpdate()
    }

    func triggerFetch() {
        cloud.fetch(localDeviceID: localDevice.id) { newCloudDevices, error in
            self.cloudDevices = newCloudDevices ?? []
            self.onUpdate?(self.localDevice, self.cloudDevices)
        }
    }

    // MARK: - Update Cloud

    func updateCloud(completion: ((Error?) -> ())?) {
        if !shouldUpdateCloud {
            completion?(nil)
            return
        }

        localDevice.batteryInfo = monitor.current()
        cloud.update(localDevice) { error in
            if error != nil {
                self.lastUpdate = Date()
            }
            completion?(error)
        }
    }
}
