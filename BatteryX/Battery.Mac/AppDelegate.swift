//
//  AppDelegate.swift
//  Battery.Mac
//
//  Created by Andrew Finke on 9/27/19.
//  Copyright © 2019 Andrew Finke. All rights reserved.
//

import Cocoa
import SwiftUI
import Combine
import os.log

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    var window: NSWindow!
    private var willBecomeActiveNotificationSubscriber: AnyCancellable?
       private var willResignActiveNotificationSubscriber: AnyCancellable?

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        os_log("NSApplication.applicationDidFinishLaunching", log: OSLog.appLifecycle, type: .info)
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
                NSApplication.shared.registerForRemoteNotifications()
            })

        willBecomeActiveNotificationSubscriber = NotificationCenter
            .default
            .publisher(for: NSApplication.willBecomeActiveNotification)
            .sink(receiveValue: { _ in
                os_log("NSApplication.willBecomeActiveNotification", log: OSLog.appLifecycle, type: .info)
//                NotificationCenter.default.post(name: Model.forceIncremenentNotification, object: nil)
            })

        willResignActiveNotificationSubscriber = NotificationCenter
            .default
            .publisher(for: NSApplication.willResignActiveNotification)
            .sink(receiveValue: { _ in
                os_log("NSApplication.willResignActiveNotification", log: OSLog.appLifecycle, type: .info)
//                NotificationCenter.default.post(name: Model.forceScheduleRefreshNotification, object: nil)
            })

        let contentView = ContentView()

        // Create the window and set the content view. 
        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 480, height: 300),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered, defer: false)
        window.center()
        window.setFrameAutosaveName("Main Window")
        window.contentView = NSHostingView(rootView: contentView)
        window.makeKeyAndOrderFront(nil)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }

    func application(_ application: NSApplication, didReceiveRemoteNotification userInfo: [String : Any]) {
        os_log("Received remote notification", log: OSLog.appLifecycle, type: .info)
        NotificationCenter.default.post(name: Model.didReceiveRemoteNotification, object: nil, userInfo: userInfo)
    }

}

