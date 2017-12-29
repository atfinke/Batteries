//
//  WatchConnectivityManager.swift
//  Battery iOS
//
//  Created by Andrew Finke on 12/21/17.
//  Copyright © 2017 Andrew Finke. All rights reserved.
//

import WatchConnectivity

class WatchConnectivityManager: NSObject, WCSessionDelegate {

    func activate() {
        guard WCSession.isSupported() else {
            return
        }
        let session = WCSession.default
        session.delegate = self
        session.activate()
    }

    func triggerUpdate() {
        //https://developer.apple.com/documentation/watchkit/wkextension
        WCSession.default.transferUserInfo(["Date": Date()])
    }

    // MARK: - WCSessionDelegate

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if let error = error {
            print("session activation failed with error: \(error.localizedDescription)")
            return
        }

        triggerUpdate()
        print("session activated with state: \(activationState.rawValue)")
    }

    func sessionDidBecomeInactive(_ session: WCSession) {
        print(#function)
    }

    func sessionDidDeactivate(_ session: WCSession) {
        print(#function)
    }

    func session(_ session: WCSession, didFinish userInfoTransfer: WCSessionUserInfoTransfer, error: Error?) {
        print(#function)
        print(error as Any)
    }

}
