//
//  Cloud.swift
//  Battery
//
//  Created by Andrew Finke on 12/20/17.
//  Copyright © 2017 Andrew Finke. All rights reserved.
//

import Foundation
import CloudKit

#if os(iOS)
    import UIKit
#elseif os(macOS)
    import AppKit
#endif

class Cloud {

    private var isUpdating = false
    private let database = CKContainer(identifier: "iCloud.com.andrewfinke.gallery").privateCloudDatabase

    #if CLOUD_SUBSCRIBER
    func subscribe() {
        let options: CKQuerySubscriptionOptions = [.firesOnRecordCreation, .firesOnRecordUpdate]

        let subscription = CKQuerySubscription(recordType: "Device",
                                               predicate: NSPredicate(value: true),
                                               options: options)

        let notificationInfo = CKNotificationInfo()
        notificationInfo.shouldSendContentAvailable = true
    notificationInfo.shouldBadge = true

        subscription.notificationInfo = notificationInfo

        database.save(subscription) { record, error in
        }
    }

    func registerForRemoteNotifications() {
        UIApplication.shared.registerForRemoteNotifications()
    }
    #endif


    func fetch(localDeviceID: String, completion: @escaping ((_ cloudDevices: [Device]?, Error?) -> ())) {
        // Updated in last week
        let date = Date(timeInterval: -60.0 * 60 * 24 * 7, since: Date())
        let predicate = NSPredicate(format: "modificationDate > %@", date as NSDate)

        let query = CKQuery(recordType: "Device", predicate: predicate)
        database.perform(query, inZoneWith: nil) { records, error in
            if var records = records {
                records = records.filter({ $0["DeviceID"] as? NSString != localDeviceID as NSString})
                let devices = records.flatMap({ Device(record: $0) })
                assert(devices.count == records.count)
                completion(devices, nil)
            } else {
                completion(nil, error)
            }
        }
    }

    func update(_ device: Device, completion: @escaping ((Error?) -> ())) {
        guard !isUpdating else {
            completion(nil)
            return
        }

        isUpdating = true
        let predicate = NSPredicate(format: "DeviceID == %@", device.id)
        let query = CKQuery(recordType: "Device", predicate: predicate)
        database.perform(query, inZoneWith: nil) { records, error in
            let record: CKRecord
            var recordIDsToDelete = [CKRecordID]()

            if let records = records, let existingRecord = records.first {
                record = existingRecord
                if records.count > 1 {
                    recordIDsToDelete = records.suffix(from: 1).map { $0.recordID }
                }
            } else {
                record = CKRecord(recordType: "Device")
            }

            record["Name"] = device.name as NSString
            record["DeviceID"] = device.id as NSString
            record["Level"] = NSNumber(floatLiteral: device.batteryInfo.level)
            record["State"] = NSNumber(integerLiteral: device.batteryInfo.state.rawValue)

            let operation = CKModifyRecordsOperation(recordsToSave: [record], recordIDsToDelete: recordIDsToDelete)
            operation.modifyRecordsCompletionBlock = { _, _, error in
                self.isUpdating = false
                completion(error)
            }
            self.database.add(operation)
        }
    }

}
