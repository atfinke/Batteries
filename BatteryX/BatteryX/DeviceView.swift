//
//  DeviceView.swift
//  BatteryX
//
//  Created by Andrew Finke on 11/2/19.
//  Copyright © 2019 Andrew Finke. All rights reserved.
//

import Foundation

struct DeviceView: View {

    static let levelFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .percent
        return formatter
    }()

    @ObservedObject var device: Device

    var body: some View {
        let color: Color
        switch device.battery.state {

        case .unknown:
            color = .black
        case .unplugged:
            color = .green
        case .charging:
            color = .yellow
        case .full:
            color = .yellow
        }

        return VStack {
            HStack {
                Text(device.name)
                    .font(Font.system(size: 16, weight: .semibold, design: .rounded))
                Spacer()
                Text("\(NSNumber(value: device.battery.level), formatter: Self.levelFormatter)")
                    .font(Font.system(size: 16, weight: .medium, design: .monospaced))
                    .foregroundColor(Color.secondary)
                RoundedRectangle(cornerRadius: 15)
                    .frame(width: 40, height: 20)
                    .foregroundColor(color)
            }
        }
    }
}
