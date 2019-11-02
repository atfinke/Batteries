//
//  Model.swift
//  Battery
//
//  Created by Andrew Finke on 12/20/17.
//  Copyright © 2017 Andrew Finke. All rights reserved.
//

import Combine
import CloudKit
import os.log

#if os(iOS)
import UIKit
#elseif os(watchOS)
import WatchKit
#endif

class Model: ObservableObject {
    
    // MARK: - Properties -
    
    static let didReceiveRemoteNotification = NSNotification.Name("didReceiveRemoteNotification")
    static let forceIncremenentNotification = NSNotification.Name("forceIncremenentNotification")
    static let forceScheduleRefreshNotification = NSNotification.Name("forceScheduleRefreshNotification")
    
    let cloud = Cloud()
    @Published var cloudDevices = [Device]()
    @Published var localDevice = Device()

    var deviceSubscriber: AnyCancellable?
    var forceIncremenentNotificationSubscriber: AnyCancellable?
    var forceScheduleRefreshNotificationSubscriber: AnyCancellable?
    var didReceiveRemoteNotificationSubscriber: AnyCancellable?
    var recordTypeSubscriber: AnyCancellable?
    var fetchSubscriber: AnyCancellable?
    
    // MARK: - Initalization -
    
    init() {
        os_log("Init", log: OSLog.model, type: .info)
        cloud.incrementUpdateRequest()
        cloud.subscribe()

        setupSubscribers()
        setupBackgroundScheduler()

        syncLocalDevice()
        fetchDevices()
    }

    func fetchDevices() {
        os_log("Fetching devices: started", log: OSLog.model, type: .info)
        fetchSubscriber = cloud.fetchDevices(excluding: localDevice)
            .receive(on: RunLoop.main)
            .sink(receiveCompletion: { completion in
                switch completion {
                case .finished:
                    break
                case .failure(let error):
                    os_log("Fetching devices: error %{PUBLIC}@", log: OSLog.model, type: .info, error.localizedDescription)
                }
            }, receiveValue: { devices in
                os_log("Fetching devices: Got devices %{PUBLIC}@", log: OSLog.model, type: .info, devices.count.description)
                self.cloudDevices = devices.sorted(by: { $0.name.lowercased() < $1.name.lowercased() })
                self.objectWillChange.send()
            })
    }
    
    func syncLocalDevice() {
        os_log("Sync device: started", log: OSLog.model, type: .info)
        let _ = cloud.update(localDevice)
            .sink(receiveCompletion: { completion in
                switch completion {
                case .finished:
                    break
                case .failure(let error):
                    os_log("Sync device: error %{PUBLIC}@", log: OSLog.model, type: .info, error.localizedDescription)
                }
            }, receiveValue: { success in
                os_log("Sync device: success %{PUBLIC}@", log: OSLog.model, type: .info, success.description)
            })
    }
    
}
