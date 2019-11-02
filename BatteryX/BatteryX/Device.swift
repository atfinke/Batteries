//
//  Device.swift
//  BatteryX
//
//  Created by Andrew Finke on 9/25/19.
//  Copyright © 2019 Andrew Finke. All rights reserved.
//

#if os(iOS)
    import UIKit
#elseif os(watchOS)
    import WatchKit
#elseif os(macOS)
    import Foundation
#endif

import Combine
import CloudKit
import os.log

class Device: ObservableObject, Hashable, CustomStringConvertible {

    // MARK: - Types -

    enum Key: String {
        case id, os, name, level, state
    }

    // MARK: - Properties -

    static private let localDeviceIDKey = "Device.id"
    static private let dateFormatter: RelativeDateTimeFormatter = {
           let formatter = RelativeDateTimeFormatter()
           formatter.dateTimeStyle = .named
           return formatter
       }()


    let id: String
    let os: String
    var name: String
    @Published var battery: Battery

    var lastUpdated: Date {
        didSet {
            updateLastUpdatedString()
        }
    }
    @Published var lastUpdatedString = ""
    private let isLocal: Bool

    private var subscriber: AnyCancellable?

    // MARK: - Initalization -

    init() {
        os_log("Creating new local device", log: OSLog.device, type: .info)

        #if os(iOS)
        os = "iOS"
        name = UIDevice.current.name
        #elseif os(watchOS)
        os = "watchOS"
        name = WKInterfaceDevice.current().name
        #elseif os(macOS)
        os = "macOS"
        name = Host.current().localizedName!
        #endif

        if let deviceIDKey = UserDefaults.standard.string(forKey: Device.localDeviceIDKey) {
            id = deviceIDKey
        } else {
            let deviceIDKey = os + "-" + NSUUID().uuidString
            UserDefaults.standard.set(deviceIDKey, forKey: Device.localDeviceIDKey)
            id = deviceIDKey
        }

        let battery = Battery()
        self.battery = battery
        self.lastUpdated = Date()
        self.isLocal = true

        subscriber = battery.objectWillChange.sink { _ in
            os_log("Received new battery info", log: OSLog.device, type: .info)
            self.lastUpdated = Date()
            self.objectWillChange.send()
        }

        Timer.scheduledTimer(withTimeInterval: 60.0, repeats: true) { _ in
            self.updateLastUpdatedString()
        }

        NotificationCenter.default.addObserver(forName: Model.forceIncremenentNotification, object: nil, queue: nil) { _ in
            self.updateLastUpdatedString()
        }

        battery.startLocalMonitoring()
    }

    init?(record: CKRecord) {
        guard let id = record[Key.id] as? NSString,
            let os = record[Key.os] as? NSString,
            let name = record[Key.name] as? NSString,
            let levelNum = record[Key.level] as? NSNumber,
            let stateNum = record[Key.state] as? NSNumber,
            let state = BatteryState(rawValue: stateNum.intValue),
            let lastUpdated = record.modificationDate else {
                os_log("Failed tp create cloud device from CKRecord", log: OSLog.device, type: .error)
                return nil
        }

        os_log("Creating new cloud device", log: OSLog.device, type: .info)

        self.id = id as String
        self.os = os as String
        self.name = name as String
        self.battery = Battery(state: state, level: levelNum.doubleValue)
        self.lastUpdated = lastUpdated
        self.isLocal = false
    }

    // MARK: - Helpers -

    private func updateLastUpdatedString() {
        lastUpdatedString = Device.dateFormatter.localizedString(for: lastUpdated, relativeTo: Date())
    }

    // MARK: - Hashable -
    
    static func == (lhs: Device, rhs: Device) -> Bool {
        return lhs.id == rhs.id &&
            lhs.os == rhs.os &&
            lhs.name == rhs.name &&
            lhs.battery == rhs.battery &&
            lhs.lastUpdated == rhs.lastUpdated
    }

    func hash(into hasher: inout Hasher) {
        return id.hash(into: &hasher)
    }

    // MARK: - CustomStringConvertible -

    var description: String {
        return "\(name): \(battery.state.description) - \(battery.level)"
    }
}

// https://stackoverflow.com/questions/38774772/subscript-dictionary-with-string-based-enums-in-swift
extension CKRecord {
    subscript(key: Device.Key) -> __CKRecordObjCValue? {
        get {
            return self[key.rawValue]
        }

        set {
            self[key.rawValue] = newValue
        }
    }
}
