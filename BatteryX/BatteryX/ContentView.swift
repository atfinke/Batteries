//
//  ContentView.swift
//  BatteryX
//
//  Created by Andrew Finke on 9/25/19.
//  Copyright © 2019 Andrew Finke. All rights reserved.
//

import SwiftUI

struct ContentView: View {

    @ObservedObject var model = Model()

    var body: some View {
        let font = Font.system(size: 14, weight: .medium, design: .rounded)

        return NavigationView {
            List {
                Section {
                    DeviceView(device: model.localDevice)
                }

                ForEach(model.cloudDevices, id: \.self) { device in
                    Section(footer: Text("\(device.lastUpdated, formatter: Self.dateFormatter)").font(font)) {
                        DeviceView(device: device)
                    }
                }

            }.listStyle(GroupedListStyle())
                .navigationBarTitle(Text("Batteries"))
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
