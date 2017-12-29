//
//  ExtensionDelegate.swift
//  Battery watchOS App Extension
//
//  Created by Andrew Finke on 12/20/17.
//  Copyright © 2017 Andrew Finke. All rights reserved.
//

import WatchKit

class ExtensionDelegate: NSObject, WKExtensionDelegate {

    func applicationDidBecomeActive() {
        requestUpdate()
    }

    func applicationWillResignActive() {
        requestUpdate()
    }

    func requestUpdate() {
        // Request update 30 min from now
        let date = Date(timeIntervalSinceNow: 60*30)
        WKExtension.shared().scheduleBackgroundRefresh(withPreferredDate: date, userInfo: nil) { _ in

        }
        Model.shared.updateCloud(completion: nil)
    }

    func handle(_ backgroundTasks: Set<WKRefreshBackgroundTask>) {
        Model.shared.updateCloud { error in
            for task in backgroundTasks {
                task.setTaskCompletedWithSnapshot(true)
            }
        }
        requestUpdate()
    }

}
