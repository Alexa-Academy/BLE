//
//  ContentView.swift
//  ArduinoBLE
//
//  Created by Paolo Godino on 25/06/23.
//

import SwiftUI

struct ContentView: View {
    @State private var pCurrent = 0.0
    
    @State private var oCurrent = 0.0
    
    @State private var selectedPeripheralIndex = 0
    
    @ObservedObject private var bluetoothViewModel = BluetoothViewModel()
    
    @State private var lastUpdate = ""
    
    @State private var isMeasuring = false
    
    @State private var isPulse = false
    
    var body: some View {
        VStack {
            HStack {
                Picker("Scegli la periferica", selection: $selectedPeripheralIndex) {
                    ForEach(0 ..< self.bluetoothViewModel.peripheralNames.count, id: \.self) { index in
                        Text(self.bluetoothViewModel.peripheralNames[index]).tag(index)
                    }
                }
                .frame(width: 200)
                
                Button("Scan") {
                    self.bluetoothViewModel.scanForPeripherals()
                }
                .padding(EdgeInsets(top: 0, leading: 10, bottom: 0, trailing: 0))
                
                Button("Associa") {
                    self.bluetoothViewModel.connectPeripheral(idx: selectedPeripheralIndex)
                }
                .padding(EdgeInsets(top: 0, leading: 10, bottom: 0, trailing: 0))
                
                Button("Reset") {
                    self.bluetoothViewModel.reset()
                }
                .padding(EdgeInsets(top: 0, leading: 10, bottom: 0, trailing: 0))
                
                Button(isMeasuring ? "Ferma" : "Avvia") {
                    isMeasuring = !isMeasuring
                    self.bluetoothViewModel.sendCommand(state: isMeasuring)
                }
                .padding(EdgeInsets(top: 0, leading: 40, bottom: 0, trailing: 0))
                
                if isPulse {
                    Image(systemName: "heart.fill")
                        .padding(EdgeInsets(top: 0, leading: 50, bottom: 0, trailing: 0))
                } else {
                    Image(systemName: "heart")
                        .padding(EdgeInsets(top: 0, leading: 50, bottom: 0, trailing: 0))
                }
            }
            .padding(EdgeInsets(top: 30, leading: 0, bottom: 40, trailing: 0))
            
     
            HStack {
                VStack(spacing: 40) {
                    Text("Pulsazioni")
                        .font(.largeTitle)
                    
                    Gauge(value: pCurrent, in: 0...200) {
                        Image(systemName: "heart.circle")
                            .font(.caption)
                    } currentValueLabel: {
                        Text("\(Int(pCurrent))")
                    }
                    .gaugeStyle(.accessoryCircular)
                    .tint(.orange)
                    .scaleEffect(1.8)
                }
                .padding()
                
                VStack(spacing: 40) {
                    Text("Ossigeno %")
                        .font(.largeTitle)
                    
                    Gauge(value: oCurrent, in: 0...100) {
                        Image(systemName: "gauge.medium")
                            .font(.caption)
                    } currentValueLabel: {
                        Text("\(Int(oCurrent))")
                    }
                    .gaugeStyle(.accessoryCircular)
                    .tint(.orange)
                    .scaleEffect(1.8)
                }
                .padding()
            }
            
            Text("Ultimo aggiornamento: \(lastUpdate)")
                .padding(EdgeInsets(top: 30, leading: 0, bottom: 0, trailing: 0))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .onReceive(bluetoothViewModel.$pPub) { pulse in
            if let p = pulse {
                pCurrent = Double(p)
                lastUpdate = bluetoothViewModel.lastUpdate
            }
        }
        .onReceive(bluetoothViewModel.$oPub) { oximetry in
            if let o = oximetry {
                oCurrent = Double(o)
                lastUpdate = bluetoothViewModel.lastUpdate
            }
        }
        .onReceive(bluetoothViewModel.$cPub) { command in
            if let c = command {
                isPulse = c == 1
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
