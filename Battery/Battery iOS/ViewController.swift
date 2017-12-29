//
//  ViewController.swift
//  Battery iOS
//
//  Created by Andrew Finke on 12/20/17.
//  Copyright © 2017 Andrew Finke. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        let label = UILabel()
        label.numberOfLines = 0
        label.frame = view.frame
        view.addSubview(label)

        Model.shared.onUpdate { localDevice, devices in
            DispatchQueue.main.async {
                label.text = ([localDevice] + devices).description
            }
        }
    }

}
