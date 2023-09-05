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
    private var peripherals: [CBPeripheral] = []
    @Published var peripheralNames: [String] = []
    
    var arduinoPeripheral: CBPeripheral?
    var cPulse: CBCharacteristic?
    var cOximetry: CBCharacteristic?
    var cCommand: CBCharacteristic?
    
    @Published var pPub: Int! = 0
    @Published var oPub: Int! = 0
    @Published var cPub: Int! = 0
    
    @Published var lastUpdate: String! = ""
    
    override init() {
        super.init()
        self.centralManager = CBCentralManager(delegate: self, queue: .main)
    }
    
    func scanForPeripherals() {
        if centralManager?.state == .poweredOn {
            peripheralNames.removeAll()
            peripherals.removeAll()
            
            self.centralManager?.scanForPeripherals(withServices: nil)
        }
    }
    
    func connectPeripheral(idx: Int) {
        centralManager?.stopScan()
        
        let peripheral = peripherals[idx]
        arduinoPeripheral = peripheral
        
        let defaults = UserDefaults.standard
        defaults.set(peripheral.identifier.uuidString, forKey: "peripheral")
        
        centralManager?.connect(peripheral)
    }
    
    func sendCommand(state: Bool) {
        let val:UInt8 = state ? 0x01 : 0x00
        let bytesToSend:[UInt8] = [val]
        
        if let peripheral = arduinoPeripheral, let characteristic = cCommand {
            peripheral.writeValue(bytesToSend.data, for: characteristic, type: .withResponse)
        }
    }
    
    func reset() {
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: "peripheral")
    }
}

extension BluetoothViewModel: CBCentralManagerDelegate, CBPeripheralDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        let defaults = UserDefaults.standard
        if let _ = defaults.string(forKey: "peripheral") {
            self.centralManager?.scanForPeripherals(withServices: nil)
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        print(peripheral)
        
        if let localName = advertisementData["kCBAdvDataLocalName"] as? String {
            if localName == "CLIKSODA_HOT" || localName == "ESP_SPP_SERVER" {
                arduinoPeripheral = peripheral
                
                centralManager?.stopScan()
                
                centralManager?.connect(peripheral)
                return
            }
        }
        
        // Se riesce a trovare la periferica a cui era connesso si connette automaticamente
        let defaults = UserDefaults.standard
        if let identifier = defaults.string(forKey: "peripheral") {
            if identifier.compare(peripheral.identifier.uuidString, options: .caseInsensitive) == .orderedSame {
                arduinoPeripheral = peripheral
                
                peripheralNames.removeAll()
                peripherals.removeAll()
                
                centralManager?.stopScan()
                
                centralManager?.connect(peripheral)
            }
        }
        
        if advertisementData["kCBAdvDataLocalName"] != nil && !peripherals.contains(peripheral) {
            self.peripherals.append(peripheral)

            if let localName = advertisementData["kCBAdvDataLocalName"] as? String {
                self.peripheralNames.append(localName)
            }
        }
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print(peripheral)
        peripheral.delegate = self
        peripheral.discoverServices(nil)
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let services = peripheral.services {
            for service in services {
                print(service)
                peripheral.discoverCharacteristics(nil, for:service)
            }
            
            return
        }
        
        if let services = peripheral.services, let service = services.first {
            print(service)
            peripheral.discoverCharacteristics(nil, for:service)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
       if let characteristics = service.characteristics {
            for characteristic in characteristics {
                print(characteristic)
                switch (characteristic.uuid.uuidString.lowercased()) {
                case "5ccbbe29-e92d-4a1e-9596-f1a8028091f8":
                    cPulse = characteristic
                    peripheral.setNotifyValue(true, for: characteristic)
                case "14e07ff9-3def-4338-9749-a5bc33a7603f":
                    cOximetry = characteristic
                    peripheral.setNotifyValue(true, for: characteristic)
                case "bf789fb6-f22d-43b5-bf9e-d5a166a86afa":
                    cCommand = characteristic
                    peripheral.setNotifyValue(true, for: characteristic)
                default:
                    break
                }
                
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        print(characteristic)
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if let value = characteristic.value {
            if characteristic == cPulse {
                if value.bytes.count == 2 {
                    pPub = Int(value.bytes[1]) * 256 + Int(value.bytes[0])
                }
            } else  if characteristic == cOximetry {
                if value.bytes.count == 2 {
                    oPub = Int(value.bytes[1]) * 256 + Int(value.bytes[0])
                }
            }  else  if characteristic == cCommand {
                if value.bytes.count == 1 {
                    cPub = Int(value.bytes[0])
                }
            }
            
            let date = Date()
            lastUpdate = DateFormatter.localizedString(from: date, dateStyle: .none, timeStyle: .medium)
        }
    }
}



