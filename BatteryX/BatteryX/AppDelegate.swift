//
//  AppDelegate.swift
//  BatteryX
//
//  Created by Andrew Finke on 9/25/19.
//  Copyright © 2019 Andrew Finke. All rights reserved.
//

import UIKit
import os.log
import BackgroundTasks
import Combine

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    private var willEnterForegroundNotificationSubscriber: AnyCancellable?
    private var willResignActiveNotificationSubscriber: AnyCancellable?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        os_log("UIApplication.applicationDidFinishLaunching", log: OSLog.appLifecycle, type: .info)
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
            application.registerForRemoteNotifications()
        })

        willEnterForegroundNotificationSubscriber = NotificationCenter
            .default
            .publisher(for: UIApplication.willEnterForegroundNotification)
            .sink(receiveValue: { _ in
                os_log("UIApplication.willEnterForegroundNotification", log: OSLog.appLifecycle, type: .info)
                NotificationCenter.default.post(name: Model.forceIncremenentNotification, object: nil)
            })

        willResignActiveNotificationSubscriber = NotificationCenter
        .default
        .publisher(for: UIApplication.willResignActiveNotification)
        .sink(receiveValue: { _ in
            os_log("UIApplication.willEnterForegroundNotification", log: OSLog.appLifecycle, type: .info)
            NotificationCenter.default.post(name: Model.forceScheduleRefreshNotification, object: nil)
        })

        return true
    }

    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        os_log("Received remote notification", log: OSLog.appLifecycle, type: .info)
        NotificationCenter.default.post(name: Model.didReceiveRemoteNotification, object: nil, userInfo: userInfo)
        Timer.scheduledTimer(withTimeInterval: 5.0, repeats: false) { _ in
            completionHandler(.newData)
        }
    }

    // MARK: - UISceneSession Lifecycle -

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }


}

