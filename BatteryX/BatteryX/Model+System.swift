//
//  Model+System.swift
//  BatteryX
//
//  Created by Andrew Finke on 9/27/19.
//  Copyright © 2019 Andrew Finke. All rights reserved.
//

import CloudKit
import Foundation
import os.log

#if os(iOS)
import BackgroundTasks
import UIKit
#elseif os(watchOS)
import WatchKit
#endif

extension Model {

    func setupSubscribers() {
        deviceSubscriber = localDevice.objectWillChange.sink { _ in
            os_log("Received new device info", log: OSLog.model, type: .info)
            self.syncLocalDevice()
        }

        forceIncremenentNotificationSubscriber = NotificationCenter
            .default
            .publisher(for: Model.forceIncremenentNotification)
            .sink { _ in
                os_log("forceIncremenentNotification", log: OSLog.model, type: .info)
                self.cloud.incrementUpdateRequest()
                self.syncLocalDevice()
        }

        forceScheduleRefreshNotificationSubscriber = NotificationCenter
            .default
            .publisher(for: Model.forceScheduleRefreshNotification)
            .sink { _ in
                os_log("forceScheduleRefreshNotification", log: OSLog.model, type: .info)
                self.scheduleAppRefresh()
                self.syncLocalDevice()
        }

        didReceiveRemoteNotificationSubscriber = NotificationCenter
            .default
            .publisher(for: Model.didReceiveRemoteNotification)
            .eraseToAnyPublisher()
            .compactMap { $0.userInfo }
            .compactMap { CKQueryNotification(fromRemoteNotificationDictionary: $0) }
            .filter { $0.notificationType == .query }
            .compactMap { $0.recordID }
            .sink { recordID in
                os_log("UIApplication.didReceiveRemoteNotification recordID: %{PUBLIC}@", log: OSLog.model, type: .info, recordID)
                self.recordTypeSubscriber = self.cloud
                    .received(recordID: recordID)
                    .sink(receiveCompletion: { completion in
                        switch completion {
                        case .finished:
                            break
                        case .failure(_):
                            break
                        }
                    }, receiveValue: { updateType in
                        switch updateType {
                        case .request:
                            self.syncLocalDevice()
                        case .device:
                            self.fetchDevices()
                        }
                    })
        }
    }

    func setupBackgroundScheduler() {
        #if os(iOS)
        BGTaskScheduler.shared.register(forTaskWithIdentifier: "com.andrewfinke.battery.update", using: nil) { task in
               os_log("Handle app refresh", log: OSLog.appLifecycle, type: .info)
                UserDefaults.standard.set(UserDefaults.standard.integer(forKey: "bg") + 1, forKey: "bg")
               NotificationCenter.default.post(name: Model.forceScheduleRefreshNotification, object: nil, userInfo: nil)
               Timer.scheduledTimer(withTimeInterval: 5.0, repeats: false) { _ in
                   task.setTaskCompleted(success: true)
               }
               self.scheduleAppRefresh()
           }
        #endif
    }

    private func scheduleAppRefresh() {
        #if os(iOS)
        do {
            let request = BGAppRefreshTaskRequest(identifier: "com.andrewfinke.battery.update")
            request.earliestBeginDate = Date(timeIntervalSinceNow: 60 * 15)
            try BGTaskScheduler.shared.submit(request)
        } catch {
            print(error)
        }
        #elseif os(watchOS)
        WKExtension.shared().scheduleBackgroundRefresh(withPreferredDate: Date(timeIntervalSinceNow: 60 * 15), userInfo: nil) { error in
//            self.scheduleAppRefresh()
        }
        #endif
    }
}
