//
//  Battery.swift
//  BatteryX
//
//  Created by Andrew Finke on 9/25/19.
//  Copyright © 2019 Andrew Finke. All rights reserved.
//

import Foundation
import Combine
import os.log

#if os(iOS)
import UIKit
#elseif os(watchOS)
import WatchKit
#elseif os(macOS)
import IOKit.ps
#endif

class Battery: ObservableObject, Equatable {

    // MARK: - Properties -

    @Published var state: BatteryState
    @Published var level: Double

    #if os(iOS)
    private var batteryStateDidChangeNotificationSubscriber: AnyCancellable?
    private var batteryLevelDidChangeNotificationSubscriber: AnyCancellable?
    #elseif os(macOS)
    private var callbackWorkaroundNotificationSubscriber: AnyCancellable?
    private static let callbackWorkaroundNotification = Notification.Name("callbackWorkaroundNotification")
    #endif

    // MARK: - Initialization -

    init(state: BatteryState = .unknown, level: Double = -1.0) {
        self.state = state
        self.level = level
    }

    // MARK: - Helpers -

    func startLocalMonitoring() {
        os_log("Started local monitoring", log: OSLog.battery, type: .info)

        #if os(iOS)
        UIDevice.current.isBatteryMonitoringEnabled = true
        batteryStateDidChangeNotificationSubscriber = NotificationCenter.default.publisher(for: UIDevice.batteryStateDidChangeNotification).sink { _ in
            os_log("UIDevice.batteryStateDidChangeNotification", log: OSLog.battery, type: .info)
            self.update()
        }
        batteryLevelDidChangeNotificationSubscriber = NotificationCenter.default.publisher(for: UIDevice.batteryLevelDidChangeNotification).sink { _ in
            os_log("UIDevice.batteryLevelDidChangeNotification", log: OSLog.battery, type: .info)
            self.update()
        }
        #elseif os(watchOS)
        WKInterfaceDevice.current().isBatteryMonitoringEnabled = true

        Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { _ in
            os_log("WKInterfaceDevice timer", log: OSLog.battery, type: .info)
            self.update()
        }
        #elseif os(macOS)
        callbackWorkaroundNotificationSubscriber = NotificationCenter.default.publisher(for: Battery.callbackWorkaroundNotification).sink { _ in
            os_log("Battery.callbackWorkaroundNotification", log: OSLog.battery, type: .info)
            self.update()
        }

        func callback(context: UnsafeMutableRawPointer?) {
            os_log("callback", log: OSLog.battery, type: .info)
            NotificationCenter.default.post(name: Battery.callbackWorkaroundNotification, object: nil)
        }

        let opaque = Unmanaged.passRetained(self).toOpaque()
        let context = UnsafeMutableRawPointer(opaque)
        let loop: CFRunLoopSource = IOPSNotificationCreateRunLoopSource(
            callback,
            context
        ).takeRetainedValue() as CFRunLoopSource
        CFRunLoopAddSource(CFRunLoopGetCurrent(), loop, .defaultMode)
        #endif
        update()
    }

    // MARK: - Update -

    @objc
    func update() {
        os_log("Updating info", log: OSLog.battery, type: .info)
        let info = latestBatteryInfo()
        state = info.state
        level = info.level
        os_log("New info, state: %{PUBLIC}@, level: %{PUBLIC}@", log: OSLog.battery, type: .info, state.description, level.description)
        objectWillChange.send()
    }

    // MARK: - Battery Info -

    private func latestBatteryInfo() -> (state: BatteryState, level: Double) {
        os_log("Fetching latest info", log: OSLog.battery, type: .info)
        #if os(iOS) || os(watchOS)
        #if os(iOS)
        let device = UIDevice.current
        #elseif os(watchOS)
        let device = WKInterfaceDevice.current()
        #endif
        guard let state = BatteryState(rawValue: device.batteryState.rawValue) else {
            fatalError("invalid state: \(device.batteryState.rawValue)")
        }
        return (state, Double(device.batteryLevel))
        #elseif os(macOS)
        let powerInfo = IOPSCopyPowerSourcesInfo().takeUnretainedValue()
        guard let powerList = IOPSCopyPowerSourcesList(powerInfo).takeUnretainedValue() as? [[String: Any]], let battery = powerList.first else {
            fatalError()
        }
        guard let currentCapactiy = battery[kIOPSCurrentCapacityKey] as? Double,
            let maxCapactiy = battery[kIOPSMaxCapacityKey] as? Double,
            let isCharging = battery[kIOPSIsChargingKey] as? Bool else {
                fatalError()
        }
        let state: BatteryState
        if currentCapactiy == maxCapactiy && isCharging {
            state = .full
        } else if isCharging {
            state = .charging
        } else {
            state = .unplugged
        }
        return (state, currentCapactiy / maxCapactiy)
        #endif
    }

    // MARK: - Equatable -

    static func == (lhs: Battery, rhs: Battery) -> Bool {
        return lhs.state == rhs.state && lhs.level == rhs.level
    }
    
}
