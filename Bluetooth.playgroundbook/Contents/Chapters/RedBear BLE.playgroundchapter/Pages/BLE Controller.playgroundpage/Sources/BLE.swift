/*
 Copyright (c) 2015 Fernando Reynoso
 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

import Foundation
import CoreBluetooth

public protocol BLEDelegate {
    func bleDidUpdateState(state: CBManagerState)
    func bleDidConnectToPeripheral(peripheral: CBPeripheral)
    func bleDidDisconenctFromPeripheral(peripheral: CBPeripheral)
    func bleDidDiscoverCharacteristics()
    func bleDidReceiveData(data: Data?)
}

public class BLE: NSObject {

    let RBL_SERVICE_UUID = "713D0000-503E-4C75-BA94-3148F18D941E"
    let RBL_CHAR_TX_UUID = "713D0002-503E-4C75-BA94-3148F18D941E"
    let RBL_CHAR_RX_UUID = "713D0003-503E-4C75-BA94-3148F18D941E"

    public var delegate: BLEDelegate?

    private      var centralManager:   CBCentralManager!
    private      var characteristics = [String : CBCharacteristic]()
    private      var data:             NSMutableData?
    private      var RSSICompletionHandler: ((NSNumber?, NSError?) -> ())?

    public       var activePeripheral: CBPeripheral?
    public private(set) var peripherals = [CBPeripheral]()

    public override init() {
        super.init()

        self.centralManager = CBCentralManager(delegate: self, queue: nil)
        self.data = NSMutableData()
    }

    @objc private func scanTimeout() {

        print("[DEBUG] Scanning stopped")
        self.centralManager.stopScan()
    }

    // MARK: Public methods
    public func startScanning(timeout: Double) -> Bool {

        if self.centralManager.state != .poweredOn {

            print("[ERROR] Couldn´t start scanning")
            return false
        }

        print("[DEBUG] Scanning started")

        // CBCentralManagerScanOptionAllowDuplicatesKey

        Timer.scheduledTimer(timeInterval: timeout, target: self, selector: #selector(BLE.scanTimeout), userInfo: nil, repeats: false)

        let services:[CBUUID] = [CBUUID(string: RBL_SERVICE_UUID)]
        self.centralManager.scanForPeripherals(withServices: services, options: nil)

        return true
    }

    public func connectToPeripheral(peripheral: CBPeripheral) -> Bool {

        if self.centralManager.state != .poweredOn {

            print("[ERROR] Couldn´t connect to peripheral")
            return false
        }

        print("[DEBUG] Connecting to peripheral: \(peripheral.identifier.uuidString)")

        self.centralManager.connect(peripheral, options: [CBConnectPeripheralOptionNotifyOnDisconnectionKey : NSNumber(value: true)])

        return true
    }

    public func disconnectFromPeripheral(peripheral: CBPeripheral) -> Bool {

        if self.centralManager.state != .poweredOn {

            print("[ERROR] Couldn´t disconnect from peripheral")
            return false
        }

        self.centralManager.cancelPeripheralConnection(peripheral)

        return true
    }

    public func read() {

        guard let char = self.characteristics[RBL_CHAR_TX_UUID] else { return }

        self.activePeripheral?.readValue(for: char)
    }

    public func write(data: Data) {

        print(data)

        guard let char = self.characteristics[RBL_CHAR_RX_UUID] else { return }

        self.activePeripheral?.writeValue(data, for: char, type: .withoutResponse)
    }

    public func enableNotifications(enable: Bool) {

        guard let char = self.characteristics[RBL_CHAR_TX_UUID] else { return }

        self.activePeripheral?.setNotifyValue(enable, for: char)
    }

    public func readRSSI(completion: (RSSI: NSNumber?, error: NSError?) -> ()) {

        self.RSSICompletionHandler = completion
        self.activePeripheral?.readRSSI()
    }
}

extension BLE: CBCentralManagerDelegate {
    public func centralManagerDidUpdateState(_ central: CBCentralManager) {

        switch central.state {
        case .unknown:
            print("[DEBUG] Central manager state: Unknown")
            break

        case .resetting:
            print("[DEBUG] Central manager state: Resseting")
            break

        case .unsupported:
            print("[DEBUG] Central manager state: Unsopported")
            break

        case .unauthorized:
            print("[DEBUG] Central manager state: Unauthorized")
            break

        case .poweredOff:
            print("[DEBUG] Central manager state: Powered off")
            break

        case .poweredOn:
            print("[DEBUG] Central manager state: Powered on")
            break
        }

        self.delegate?.bleDidUpdateState(state: central.state)
    }

    public func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : AnyObject],rssi RSSI: NSNumber) {
        print("[DEBUG] Find peripheral: \(peripheral.identifier.uuidString) RSSI: \(RSSI)")

        let index = peripherals.index(where: { $0.identifier.uuidString == peripheral.identifier.uuidString })

        if let index = index {
            peripherals[index] = peripheral
        } else {
            peripherals.append(peripheral)
        }
        if self.connectToPeripheral(peripheral: peripheral) {
            self.centralManager.stopScan()
        }
    }

    public func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: NSError?) {
        print("[ERROR] Could not connecto to peripheral \(peripheral.identifier.uuidString) error: \(error!.description)")
    }

    public func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {

        print("[DEBUG] Connected to peripheral \(peripheral.identifier.uuidString)")

        self.activePeripheral = peripheral

        self.activePeripheral?.delegate = self
        self.activePeripheral?.discoverServices([CBUUID(string: RBL_SERVICE_UUID)])

        self.delegate?.bleDidConnectToPeripheral(peripheral: peripheral)
    }

    public func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: NSError?) {

        var text = "[DEBUG] Disconnected from peripheral: \(peripheral.identifier.uuidString)"

        if error != nil {
            text += ". Error: \(error!.description)"
        }

        print(text)

        self.activePeripheral?.delegate = nil
        self.activePeripheral = nil
        self.characteristics.removeAll(keepingCapacity: false)

        self.delegate?.bleDidDisconenctFromPeripheral(peripheral: peripheral)
    }
}

extension BLE: CBPeripheralDelegate {
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: NSError?) {

        if error != nil {
            print("[ERROR] Error discovering services. \(error!.description)")
            return
        }

        print("[DEBUG] Found services for peripheral: \(peripheral.identifier.uuidString)")


        for service in peripheral.services! {
            let theCharacteristics = [CBUUID(string: RBL_CHAR_RX_UUID), CBUUID(string: RBL_CHAR_TX_UUID)]

            peripheral.discoverCharacteristics(theCharacteristics, for: service)
        }
    }

    public func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: NSError?) {

        if error != nil {
            print("[ERROR] Error discovering characteristics. \(error!.description)")
            return
        }

        print("[DEBUG] Found characteristics for peripheral: \(peripheral.identifier.uuidString)")

        for characteristic in service.characteristics! {
            self.characteristics[characteristic.uuid.uuidString] = characteristic
        }

        enableNotifications(enable: true)
        self.delegate?.bleDidDiscoverCharacteristics()
    }

    public func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: NSError?) {
        
        if error != nil {
            
            print("[ERROR] Error updating value. \(error!.description)")
            return
        }
        
        if characteristic.uuid.uuidString == RBL_CHAR_TX_UUID {
            
            self.delegate?.bleDidReceiveData(data: characteristic.value)
        }
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didReadRSSI RSSI: NSNumber, error: NSError?) {
        self.RSSICompletionHandler?(RSSI, error)
        self.RSSICompletionHandler = nil
    }
}
