//
//  BatteryMonitor.swift
//  battery
//
//  Created by Andrew Finke on 12/19/17.
//  Copyright © 2017 Andrew Finke. All rights reserved.
//

import Foundation

#if os(iOS)
    import UIKit
#elseif os(watchOS)
    import WatchKit
#elseif os(macOS)
    import IOKit.ps
#endif

class BatteryMonitor: NSObject {

    // MARK: - Properties

    var onChange: ((BatteryInfo) -> ())?

    // MARK: - Initialization

    override init() {
        super.init()

        #if os(iOS)
            UIDevice.current.isBatteryMonitoringEnabled = true

            NotificationCenter.default.addObserver(self,
                                                   selector: #selector(triggerUpdate),
                                                   name: .UIDeviceBatteryStateDidChange,
                                                   object: nil)
            NotificationCenter.default.addObserver(self,
                                                   selector: #selector(triggerUpdate),
                                                   name: .UIDeviceBatteryLevelDidChange,
                                                   object: nil)
        #elseif os(watchOS)
            WKInterfaceDevice.current().isBatteryMonitoringEnabled = true
            // 5 Min
            Timer.scheduledTimer(timeInterval: 300,
                                 target: self,
                                 selector: #selector(triggerUpdate),
                                 userInfo: nil,
                                 repeats: true)
        #elseif os(macOS)
            func callback(context: UnsafeMutableRawPointer?) {
                Model.shared.monitor.triggerUpdate()
            }

            let opaque = Unmanaged.passRetained(self).toOpaque()
            let context = UnsafeMutableRawPointer(opaque)
            let loop: CFRunLoopSource = IOPSNotificationCreateRunLoopSource(
                callback,
                context
                ).takeRetainedValue() as CFRunLoopSource
            CFRunLoopAddSource(CFRunLoopGetCurrent(), loop, .defaultMode)
        #endif
    }

    // MARK: - Update

    private func update() {
        onChange?(current())
    }

    @objc
    func triggerUpdate() {
        print(#function)
        update()
    }

    // MARK: - Battery Info

    func current() -> BatteryInfo {
        #if os(iOS)
            let state = BatteryState(rawValue: UIDevice.current.batteryState.rawValue)!
            return BatteryInfo(level: Double(UIDevice.current.batteryLevel), state: state)
        #elseif os(watchOS)
            let state = BatteryState(rawValue: WKInterfaceDevice.current().batteryState.rawValue)!
            return BatteryInfo(level: Double(WKInterfaceDevice.current().batteryLevel), state: state)
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
            return BatteryInfo(level: currentCapactiy / maxCapactiy, state: state)
        #endif
    }

}
