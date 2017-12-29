//
//  TodayViewController.swift
//  Today
//
//  Created by Andrew Finke on 12/21/17.
//  Copyright © 2017 Andrew Finke. All rights reserved.
//

import UIKit
import NotificationCenter
import WatchKit

class TodayViewController: UIViewController, NCWidgetProviding {

    let watchManager = WatchConnectivityManager()

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view from its nib.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        update(completion: nil)
    }
    
    func widgetPerformUpdate(completionHandler: (@escaping (NCUpdateResult) -> Void)) {
        update(completion: completionHandler)
    }

    func update(completion: ((NCUpdateResult) -> ())?) {
        guard Model.shared.shouldUpdateCloud else {
            completion?(.newData)
            return
        }

        watchManager.triggerUpdate()
        Model.shared.updateCloud { error in
            if error != nil {
                completion?(.failed)
            } else {
                DispatchQueue.main.async {
                    if completion == nil {
                        Model.shared.triggerFetch()
                    }
                    completion?(.newData)
                }
            }
        }
    }
    
}
