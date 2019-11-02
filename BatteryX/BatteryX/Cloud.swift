//
//  Cloud.swift
//  Battery
//
//  Created by Andrew Finke on 12/20/17.
//  Copyright © 2017 Andrew Finke. All rights reserved.
//

import Foundation
import CloudKit
import Combine
import os.log
import UserNotifications

#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

class Cloud {
    
    // MARK: - Types -
    
    enum Key: String {
        case queue = "com.andrewfinke.battery.update"
        case container = "iCloud.com.andrewfinke.Battery.cloud"
        case device = "Device"
        case updateRequest = "UpdateRequest"
        case number
    }
    
    enum RemoteUpdateType: String {
        case request, device
    }
    
    // MARK: - Properties -

    private var lastLocalDeviceSync = Date.distantPast
    private var isSyncingLocalDevice = false
    private let database = CKContainer(identifier: Key.container.rawValue).privateCloudDatabase
    private var isAuthenticated: Bool {
        return true//FileManager.default.ubiquityIdentityToken != nil
    }

    // MARK: - Subscribe -
    
    func subscribe() {
        os_log("Subscribing: started", log: OSLog.cloud, type: .info)
        guard isAuthenticated else {
            os_log("Subscribing: not authenticated", log: OSLog.cloud, type: .error)
            return
        }

        let notificationInfo = CKSubscription.NotificationInfo()
        notificationInfo.shouldSendContentAvailable = true
        notificationInfo.shouldBadge = true
        let options: CKQuerySubscription.Options = [
            .firesOnRecordCreation,
            .firesOnRecordUpdate,
            .firesOnRecordDeletion
        ]

        let requestSubscription = CKQuerySubscription(recordType: Key.updateRequest.rawValue,
                                                      predicate: NSPredicate(value: true),
                                                      options: options)
        requestSubscription.notificationInfo = notificationInfo

        let deviceSubscription = CKQuerySubscription(recordType: Key.device.rawValue,
                                                     predicate: NSPredicate(value: true),
                                                     options: options)
        deviceSubscription.notificationInfo = notificationInfo

        let operation = CKFetchSubscriptionsOperation.fetchAllSubscriptionsOperation()
        operation.fetchSubscriptionCompletionBlock = { subscriptions, error in
            if let error = error as? CKError {
                os_log("Subscribing: Fetch subscriptions  error: %{PUBLIC}@", log: OSLog.cloud, type: .error, error.localizedDescription)
            } else if let subscriptions = subscriptions {
                let observedRecords = Set(subscriptions.values.compactMap({ $0 as? CKQuerySubscription }).compactMap({ $0.recordType }))
                os_log("Subscribing: Fetched %{PUBLIC}@ subscriptions: %{PUBLIC}@", log: OSLog.cloud, type: .info, subscriptions.count.description, observedRecords.description)

                if !observedRecords.contains(Key.updateRequest.rawValue) {
                    os_log("Subscribing: No request subscription found", log: OSLog.cloud, type: .info)
                    self.database.save(requestSubscription) { _, error in
                        if let error = error as? CKError {
                            os_log("Subscribing: Request subscription save error: %{PUBLIC}@", log: OSLog.cloud, type: .error, error.localizedDescription)
                        } else {
                            os_log("Subscribing: Request subscription save successful", log: OSLog.cloud, type: .info)
                        }
                    }
                } else {
                    os_log("Subscribing: Already has request subscription", log: OSLog.cloud, type: .info)
                }
                if !observedRecords.contains(Key.device.rawValue) {
                    os_log("Subscribing: No device subscription found", log: OSLog.cloud, type: .info)
                    self.database.save(deviceSubscription) { _, error in
                        if let error = error as? CKError {
                            os_log("Subscribing: Device subscription save error: %{PUBLIC}@", log: OSLog.cloud, type: .error, error.localizedDescription)
                        } else {
                            os_log("Subscribing: Device subscription save successful", log: OSLog.cloud, type: .info)
                        }
                    }
                } else {
                    os_log("Subscribing: Already has device subscription", log: OSLog.cloud, type: .info)
                }
                // remove subscripts
            } else {
                fatalError()
            }
        }
        database.add(operation)
    }
    
    func received(recordID: CKRecord.ID) -> Future<RemoteUpdateType, Error> {
        os_log("Received notification record: id: %{PUBLIC}@", log: OSLog.cloud, type: .info, recordID.description)
        return Future<RemoteUpdateType, Error> { promise in
            self.database.fetch(withRecordID: recordID) { record, error in
                if let error = error as? CKError {
                    os_log("Received notification record: error: %{PUBLIC}@", log: OSLog.cloud, type: .error, error.localizedDescription)
                }

                guard let record = record else { fatalError() }

                if record.recordType == Key.updateRequest.rawValue {
                    os_log("Received notification record: request type", log: OSLog.cloud, type: .info)
                    promise(.success(.request))
                } else if record.recordType == Key.device.rawValue {
                    os_log("Received notification record: device type w/ id: %{PUBLIC}@", log: OSLog.cloud, type: .info, record.recordID)
                    promise(.success(.device))
                } else {
                    fatalError("invalid record type: \(record.recordType)")
                }
            }
        }
    }
    
    // MARK: - Request -
    
    func incrementUpdateRequest() {
        os_log("Incrementing update request: started", log: OSLog.cloud, type: .info)
        guard isAuthenticated else {
            os_log("Incrementing update request: not authenticated", log: OSLog.cloud, type: .error)
            return
        }

        let query = CKQuery(recordType: Key.updateRequest.rawValue, predicate: NSPredicate(value: true))
        database.perform(query, inZoneWith: nil) { records, error in
            if let error = error as? CKError {
                fatalError(error.localizedDescription)
            }
            // error handling??
            
            let record: CKRecord
            var recordIDsToDelete = [CKRecord.ID]()
            
            if let records = records, let existingRecord = records.first {
                record = existingRecord
                if records.count > 1 {
                    recordIDsToDelete = records.suffix(from: 1).map { $0.recordID }
                }
                os_log("Incrementing update request: Found %{PUBLIC}@ request records", log: OSLog.cloud, type: .info, records.count.description)
            } else {
                record = CKRecord(recordType: Key.updateRequest.rawValue)
                os_log("Incrementing update request: No request record found", log: OSLog.cloud, type: .info)
            }

            if let date = record.modificationDate, -date.timeIntervalSinceNow < 60 * 10 {
                let timeAgo = -date.timeIntervalSinceNow
                os_log("Incrementing update request: last update too recent: %{PUBLIC}@", log: OSLog.cloud, type: .info, timeAgo.description)
                return
            }

            let number = record[Key.number.rawValue] as? Int ?? 0
            record[Key.number.rawValue] = number + 1
            os_log("Incrementing update request: number %{PUBLIC}@", log: OSLog.cloud, type: .info, number.description)
            
            let operation = CKModifyRecordsOperation(recordsToSave: [record],
                                                     recordIDsToDelete: recordIDsToDelete)
            operation.modifyRecordsCompletionBlock = { _, _, error in
                if let error = error as? CKError {
                    os_log("Incrementing update request: save error: %{PUBLIC}@", log: OSLog.cloud, type: .error, error.localizedDescription)
                } else {
                    os_log("Incrementing update request: save successful", log: OSLog.cloud, type: .info)
                }
            }
            self.database.add(operation)
        }
    }
    
    func fetchDevices(excluding localDevice: Device) -> Future<[Device], CKError> {
        os_log("Fetching devices: started", log: OSLog.cloud, type: .info)

        return Future<[Device], CKError> { promise in
            guard self.isAuthenticated else {
                os_log("Fetching devices: not authenticated", log: OSLog.cloud, type: .error)
                promise(.failure(CKError(.notAuthenticated)))
                return
            }

            // Updated in last week
            let date = Date(timeInterval: -60.0 * 60 * 24 * 7, since: Date())
            let predicate = NSPredicate(format: "modificationDate > %@ && id != %@", date as NSDate, localDevice.id)
            let query = CKQuery(recordType: Key.device.rawValue, predicate: predicate)
            self.database.perform(query, inZoneWith: nil) { records, error in
                if let error = error as? CKError {
                    os_log("Fetching devices: error: %{PUBLIC}@", log: OSLog.cloud, type: .error, error.localizedDescription)
                    promise(.failure(error))
                } else if let records = records {
                    let devices = records.compactMap { Device(record: $0) }
                    os_log("Fetching devices: Found records: %{PUBLIC}@, Devices Created: %{PUBLIC}@: %{PUBLIC}@", log: OSLog.cloud, type: .info, records.count.description, devices.count.description, devices.description)
                    assert(devices.count == records.count)
                    promise(.success(devices))
                }
            }
        }
    }
    
    func update(_ device: Device) -> Future<Bool, CKError> {
        os_log("Updating device: started", log: OSLog.cloud, type: .info)
        return Future<Bool, CKError> { promise in
            guard self.isAuthenticated else {
                os_log("Updating device: not authenticated", log: OSLog.cloud, type: .error)
                promise(.failure(CKError(.notAuthenticated)))
                return
            }
            guard !self.isSyncingLocalDevice else {
                os_log("Updating device: already updating", log: OSLog.cloud, type: .error)
                promise(.success(false))
                return
            }

            let timeAgo = -self.lastLocalDeviceSync.timeIntervalSinceNow
            guard timeAgo > 10 else {
                os_log("Updating device: last update too recent: %{PUBLIC}@", log: OSLog.cloud, type: .info, timeAgo.description)
                promise(.success(false))
                return
            }

            self.isSyncingLocalDevice = true

            let predicate = NSPredicate(format: "id == %@", device.id)
            let query = CKQuery(recordType: "Device", predicate: predicate)

            self.database.perform(query, inZoneWith: nil) { records, error in
                if let error = error as? CKError { fatalError(error.localizedDescription) }
                // todo: error handling

                let record: CKRecord
                var recordIDsToDelete = [CKRecord.ID]()

                if let records = records, let existingRecord = records.first {
                    record = existingRecord
                    if records.count > 1 {
                        recordIDsToDelete = records.suffix(from: 1).map { $0.recordID }
                    }
                    os_log("Updating device: Found %{PUBLIC}@ device records", log: OSLog.cloud, type: .info, records.count.description)
                } else {
                    record = CKRecord(recordType: Key.device.rawValue)
                    os_log("Updating device: No device record found", log: OSLog.cloud, type: .info)
                }

                record[Device.Key.id] = device.id as NSString
                record[Device.Key.os] = device.os as NSString
                record[Device.Key.name] = device.name as NSString
                record[Device.Key.level] = NSNumber(floatLiteral: device.battery.level)
                record[Device.Key.state] = NSNumber(integerLiteral: device.battery.state.rawValue)

                let operation = CKModifyRecordsOperation(recordsToSave: [record],
                                                         recordIDsToDelete: recordIDsToDelete)

                operation.modifyRecordsCompletionBlock = { _, _, error in
                    if let error = error as? CKError {
                        os_log("Updating device: save error: %{PUBLIC}@", log: OSLog.cloud, type: .error, error.localizedDescription)
                        promise(.failure(error))
                    } else {
                        os_log("Updating device: save successful", log: OSLog.cloud, type: .info)
                        self.lastLocalDeviceSync = Date()
                        promise(.success(true))
                    }
                    self.isSyncingLocalDevice = false
                }
                self.database.add(operation)
            }
        }
    }

    static func registerForRemoteNotifications() -> Future<Bool, Error> {
        os_log("Notification authorization: starting", log: OSLog.appLifecycle, type: .info)
        return Future<Bool, Error> { promise in
            UNUserNotificationCenter.current().requestAuthorization(options: [.badge]) { success, error in
                if let error = error {
                    os_log("Notification authorization: error: %{PUBLIC}@", log: OSLog.appLifecycle, type: .error, error.localizedDescription)
                    promise(.failure(error))
                } else {
                    os_log("Notification authorization: success: %{PUBLIC}@", log: OSLog.appLifecycle, type: .info, success.description)
                    promise(.success(true))
                }
            }
        }
    }
    
}
