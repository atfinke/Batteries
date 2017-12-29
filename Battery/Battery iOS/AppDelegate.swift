//
//  AppDelegate.swift
//  Battery iOS
//
//  Created by Andrew Finke on 12/20/17.
//  Copyright © 2017 Andrew Finke. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    let watchManager = WatchConnectivityManager()

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        watchManager.activate()
        return true
    }

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Model.shared.cloud.subscribe()
    }

    // MARK: - Updating
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        update(completion: completionHandler)
    }

    func application(_ application: UIApplication, performFetchWithCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        update(completion: completionHandler)
    }

    func update(completion: @escaping (UIBackgroundFetchResult) -> ()) {
        guard Model.shared.shouldUpdateCloud else {
            completion(.newData)
            return
        }
        
        watchManager.triggerUpdate()
        Model.shared.updateCloud { error in
            if error != nil {
                completion(.failed)
            } else {
                DispatchQueue.main.async {
                    if UIApplication.shared.applicationState == .active {
                        Model.shared.triggerFetch()
                    }
                    completion(.newData)
                }
            }
        }
    }

}
