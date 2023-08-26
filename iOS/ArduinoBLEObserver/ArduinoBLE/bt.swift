//
//  bt.swift
//  ClikTester
//
//  Created by Paolo Godino on 28/01/23.
//

import Foundation
import CoreBluetooth

extension Data {
    var bytes: [UInt8] {
        return [UInt8](self)
    }
}

extension Array where Element == UInt8 {
    var data: Data {
        return Data(self)
    }
}

class BluetoothViewModel: NSObject, ObservableObject {
    private var centralManager: CBCentralManager?
    //private var peripherals: [CBPeripheral] = []
    @Published var peripheralNames: [String] = []
    
    var arduinoPeripheral: CBPeripheral?
    var cTemp: CBCharacteristic?
    var cHum: CBCharacteristic?
    var cLed: CBCharacteristic?
    
    @Published var tPub: Double! = 0.0
    @Published var hPub: Double! = 0.0
    
    @Published var lastUpdate: String! = ""
    
    override init() {
        super.init()
        self.centralManager = CBCentralManager(delegate: self, queue: .main)
    }
}

extension BluetoothViewModel: CBCentralManagerDelegate, CBPeripheralDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn {
            self.centralManager?.scanForPeripherals(withServices: nil)
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        if let peripheralLocalName = advertisementData["kCBAdvDataLocalName"] as? String {
            if peripheralLocalName == "AlexaAcademy Sensor" {
                //print(advertisementData)
                
                if let data = advertisementData["kCBAdvDataServiceData"] as? NSDictionary {
                    if let temp = data[CBUUID(string: "2A6E")] as? Data {
                        tPub = ((Double(temp.bytes[1]) * 256.0 + Double(temp.bytes[0])) / 100.0).rounded(.toNearestOrAwayFromZero)
                    }
                    
                    if let hum = data[CBUUID(string: "2A6F")] as? Data {
                        hPub = ((Double(hum.bytes[1]) * 256.0 + Double(hum.bytes[0])) / 100.0).rounded(.toNearestOrAwayFromZero)
                    }

                    if let timestamp = advertisementData["kCBAdvDataTimestamp"] as? TimeInterval {
                        let date = Date.init(timeIntervalSinceReferenceDate: timestamp)
                        lastUpdate = DateFormatter.localizedString(from: date, dateStyle: .none, timeStyle: .medium)
                    }
                }
                
                arduinoPeripheral = peripheral
                
                //central.stopScan()
            }
        }
    }
}
