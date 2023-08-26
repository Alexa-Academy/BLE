//
//  ContentView.swift
//  ArduinoBLE
//
//  Created by Paolo Godino on 25/06/23.
//

import SwiftUI

struct ContentView: View {
    @State private var tCurrent = 27.0
    @State private var tMin = -10.0
    @State private var tMax = 40.0
    
    @State private var hCurrent = 27.0
    @State private var hMin = 0.0
    @State private var hMax = 100.0
    
    @State private var lastUpdate = ""
    
    @ObservedObject private var bluetoothViewModel = BluetoothViewModel()
    
    var body: some View {
        VStack {
            HStack {
                VStack(spacing: 40) {
                    Text("Temperatura")
                        .font(.largeTitle)
                    
                    Gauge(value: tCurrent, in: tMin...tMax) {
                        Image(systemName: "thermometer")
                            .font(.caption)
                    } currentValueLabel: {
                        Text("\(Int(tCurrent))")
                    } minimumValueLabel: {
                        Text("\(Int(tMin))")
                    } maximumValueLabel: {
                        Text("\(Int(tMax))")
                    }
                    .gaugeStyle(.accessoryCircular)
                    .tint(Gradient(colors: [.blue, .blue, .green, .green, .red, .red]))
                    .scaleEffect(1.8)
                }
                .padding()
                
                VStack(spacing: 40) {
                    Text("Umidità")
                        .font(.largeTitle)
                    
                    Gauge(value: hCurrent, in: hMin...hMax) {
                        Image(systemName: "thermometer")
                            .font(.caption)
                    } currentValueLabel: {
                        Text("\(Int(hCurrent))")
                    } minimumValueLabel: {
                        Text("\(Int(hMin))")
                    } maximumValueLabel: {
                        Text("\(Int(hMax))")
                    }
                    .gaugeStyle(.accessoryCircular)
                    .tint(Gradient(colors: [.green, .green, .yellow, .yellow, .red, .red]))
                    .scaleEffect(1.8)
                }
                .padding()
            }
            .onReceive(bluetoothViewModel.$tPub) { temp in
                if let t = temp {
                    tCurrent = t
                    lastUpdate = bluetoothViewModel.lastUpdate
                }
            }
            .onReceive(bluetoothViewModel.$hPub) { hum in
                if let h = hum {
                    hCurrent = h
                    lastUpdate = bluetoothViewModel.lastUpdate
                }
            }
            
            Text("Ultimo aggiornamento: \(lastUpdate)")
                .padding(EdgeInsets(top: 30, leading: 0, bottom: 0, trailing: 0))
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
