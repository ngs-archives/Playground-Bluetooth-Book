/*
 Copyright (C) 2016 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information.
 
 This is an example playground page.
*/

import UIKit
import CoreBluetooth
import PlaygroundSupport

class DataSource: NSObject, UITableViewDataSource {

    var peripherals = [(CBPeripheral, Int)]()

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return peripherals
            .count
    }

    func addPeripheral(peripheral: CBPeripheral
        , RSSI: Int) {
        var peripherals = self.peripherals
        if let idx = peripherals
            .map({ $0.0.identifier })
            .index(of: peripheral.identifier) {
            peripherals.remove(at: idx)
            peripherals.insert((peripheral, RSSI), at: idx)
        } else {
            peripherals.append((peripheral, RSSI))
        }
        self.peripherals = peripherals
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellIdentifier = "cell"
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier
            ) ?? UITableViewCell(style: .subtitle, reuseIdentifier: cellIdentifier)
        let (peripheral, RSSI) = self.peripherals[indexPath.row]
        cell.textLabel?.text = peripheral.identifier.debugDescription
        cell.detailTextLabel?.text = "\(RSSI) \(peripheral.name ?? "")"
        return cell
    }
}

class BTDelegate: NSObject, CBCentralManagerDelegate {
    let tableView = UITableView()
    let dataSource = DataSource()

    override init() {
        tableView.dataSource = dataSource
    }

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            print("on")
            central.scanForPeripherals(withServices: nil, options: nil)
        default:
            print(central.state.rawValue)
            break
        }
    }

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : AnyObject], rssi RSSI: NSNumber) {
        print(peripheral.description)
        dataSource.addPeripheral(peripheral: peripheral, RSSI: RSSI.intValue)
        tableView.reloadData()
        PlaygroundPage.current.liveView
    }
}

let liveView = UIView()
let delegate = BTDelegate()

liveView.addSubview(delegate.tableView)

PlaygroundPage.current.liveView = delegate.tableView
PlaygroundPage.current.needsIndefiniteExecution = true

let mgr = CBCentralManager(delegate: delegate, queue: nil)
