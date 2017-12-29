//
//  AppDelegate.swift
//  Battery macOS
//
//  Created by Andrew Finke on 12/20/17.
//  Copyright © 2017 Andrew Finke. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {


    var statusItem: NSStatusItem!

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application

//        return [[NSImage alloc] initWithContentsOfFile:fileName];
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        statusItem.image = NSImage(contentsOf: URL(fileURLWithPath: "/System/Library/PrivateFrameworks/BatteryUIKit.framework/Versions/A/Resources/BatteryCharging.pdf"))!
 statusItem.title = "Battery"
        statusItem.button?.imagePosition = .imageRight

        let formatter = NumberFormatter()
        formatter.maximumFractionDigits = 0
        formatter.numberStyle = .percent

        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .none
        dateFormatter.timeStyle = .short

        Model.shared.onUpdate { localDevice, cloudDevices in
            DispatchQueue.main.async {
                let menu = NSMenu()

                let dict = [
                    NSAttributedStringKey.font: NSFont.menuFont(ofSize: 12)
                ]
                let string = NSAttributedString(string: formatter.string(from: NSNumber(value: localDevice.batteryInfo.level))!, attributes: dict)

                self.statusItem.attributedTitle = string;
                self.statusItem.button?.imagePosition = .imageRight

                let devicesItem = NSMenuItem(title: "Other Devices:",
                                                     action: nil,
                                                     keyEquivalent: "")
                menu.addItem(devicesItem)

                for device in cloudDevices {
                    let string = device.name + " " + formatter.string(from: NSNumber(value: device.batteryInfo.level))! + " (\(device.batteryInfo.state.description)) \(dateFormatter.string(from: device.lastUpdated))"
                    let deviceMenuItem = NSMenuItem(title: string,
                                                    action: #selector(AppDelegate.quit(sender:)),
                                                    keyEquivalent: "")
                    menu.addItem(deviceMenuItem)
                }

                if let lastUpdated = cloudDevices.map({ $0.lastUpdated }).sorted().first {
                    let timeItem = NSMenuItem(title: "Last Updated: \(dateFormatter.string(from: lastUpdated))",
                                              action: nil,
                                              keyEquivalent: "")
                    menu.addItem(timeItem)
                }


                menu.addItem(NSMenuItem.separator())
                let quitMenuItem = NSMenuItem(title: "Quit",
                                                     action: #selector(AppDelegate.quit(sender:)),
                                                     keyEquivalent: "")
                menu.addItem(quitMenuItem)


                self.statusItem.menu = menu
            }

        }

    }

    @objc
    func about(sender : NSMenuItem) {
        print("XXX")
    }

    @objc
    func quit(sender : NSMenuItem) {
        NSApp.terminate(self)
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }

    


}

