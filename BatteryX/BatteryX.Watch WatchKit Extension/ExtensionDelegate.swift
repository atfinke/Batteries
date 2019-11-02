//
//  ExtensionDelegate.swift
//  BatteryX.Watch WatchKit Extension
//
//  Created by Andrew Finke on 9/26/19.
//  Copyright © 2019 Andrew Finke. All rights reserved.
//

import WatchKit
import os.log
import UserNotifications

class ExtensionDelegate: NSObject, WKExtensionDelegate {

    func applicationDidFinishLaunching() {
        os_log("WKExtension.applicationDidFinishLaunching", log: OSLog.appLifecycle, type: .info)
        let _ = Cloud.registerForRemoteNotifications()
            .receive(on: RunLoop.main)
            .sink(receiveCompletion: { completion in
                switch completion {
                case .finished:
                    break
                case .failure(_):
                    break
                }
        }, receiveValue: { success in
            WKExtension.shared().registerForRemoteNotifications()
        })
    }

    func applicationWillEnterForeground() {
        os_log("WKExtension.applicationWillEnterForeground", log: OSLog.appLifecycle, type: .info)
        NotificationCenter.default.post(name: Model.forceIncremenentNotification, object: nil)
    }

    func applicationWillResignActive() {
        os_log("WKExtension.applicationWillResignActive", log: OSLog.appLifecycle, type: .info)
        NotificationCenter.default.post(name: Model.forceScheduleRefreshNotification, object: nil)
    }

    func didReceiveRemoteNotification(_ userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (WKBackgroundFetchResult) -> Void) {
        os_log("Received remote notification", log: OSLog.cloud, type: .info)
        NotificationCenter.default.post(name: Model.didReceiveRemoteNotification, object: nil, userInfo: userInfo)
        Timer.scheduledTimer(withTimeInterval: 5.0, repeats: false) { _ in
            completionHandler(.newData)
        }
    }
//
    func handle(_ backgroundTasks: Set<WKRefreshBackgroundTask>) {
        // Sent when the system needs to launch the application in the background to process tasks. Tasks arrive in a set, so loop through and process each one.
        for task in backgroundTasks {

            // Use a switch statement to check the task type
            switch task {
            case let backgroundTask as WKApplicationRefreshBackgroundTask:
                os_log("WKExtension.handle.WKApplicationRefreshBackgroundTask", log: OSLog.appLifecycle, type: .info)
                NotificationCenter.default.post(name: Model.forceScheduleRefreshNotification, object: nil, userInfo: nil)
                Timer.scheduledTimer(withTimeInterval: 5.0, repeats: false) { _ in
                    backgroundTask.setTaskCompletedWithSnapshot(false)
                }
            case let snapshotTask as WKSnapshotRefreshBackgroundTask:
                os_log("WKExtension.handle.WKSnapshotRefreshBackgroundTask", log: OSLog.appLifecycle, type: .info)
                NotificationCenter.default.post(name: Model.forceScheduleRefreshNotification, object: nil, userInfo: nil)
                Timer.scheduledTimer(withTimeInterval: 5.0, repeats: false) { _ in
                    snapshotTask.setTaskCompleted(restoredDefaultState: true, estimatedSnapshotExpiration: Date(timeIntervalSinceNow: 60 * 15), userInfo: nil)
                }
            case let relevantShortcutTask as WKRelevantShortcutRefreshBackgroundTask:
                // Be sure to complete the relevant-shortcut task once you're done.
                relevantShortcutTask.setTaskCompletedWithSnapshot(false)
            case let intentDidRunTask as WKIntentDidRunRefreshBackgroundTask:
                // Be sure to complete the intent-did-run task once you're done.
                intentDidRunTask.setTaskCompletedWithSnapshot(false)
            default:
                // make sure to complete unhandled task types
                task.setTaskCompletedWithSnapshot(false)
            }
        }
    }

}

