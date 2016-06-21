import Foundation
import CoreBluetooth

public class BLEPlayground: NSObject {

    private let ble = BLE()
    private var pendingData = [Data]()

    public override init() {
        super.init()
        ble.delegate = self
    }

    public func write(data: Data) {
        if ble.activePeripheral != nil {
            print("write \(data)")
            ble.write(data: data)
        } else {
            print("pending write \(data)")
            pendingData.append(data)
        }
    }

    public func write(message: BLEMessage) {
        write(data: message.data)
    }

    private func processData(_ data: Data) {
        print(data)
    }

    public func queryProtocolVersion() {
        write(message: BLEMessage(.queryProtocolVersion))
    }

    public func queryTotalPinCount() {
        write(message: BLEMessage(.queryTotalPinCount))
    }

    public func query(pinCapability: PinCapability) {
        write(message: BLEMessage(.queryPinCapability, pinCapability.bytes))
    }

    public func query(pinMode: PinMode) {
        write(message: BLEMessage(.queryPinMode, pinMode.bytes))
    }

    public func queryPinAll() {
        write(message: BLEMessage(.queryPinMode))
    }

    public func set(pin: UInt8, mode: PinMode) {
        write(message: BLEMessage(.setPinMode, [pin] + mode.bytes))
    }

    public func send(customData data: Data) {
        var buf = MessageType.sendCustomData.bytes
        buf.append(UInt8(data.count))
        buf.append(contentsOf: Array(UnsafeBufferPointer(
            start: UnsafePointer<UInt8>((data as NSData).bytes),
            count: data.count)))
        write(message: BLEMessage(.sendCustomData, buf))
    }

    public func digitalWrite(pin: UInt8, value: PinValue) {
        write(message: BLEMessage(.digitalWrite, [pin] + value.bytes))
    }

    public func digitalRead(pin: UInt8) {
        write(message: BLEMessage(.digitalRead, [pin]))
    }

    public func analogWrite(pin: UInt8, value: UInt8) {
        write(message: BLEMessage(.analogWrite, [pin, value]))
    }

     public func analogRead(pin: UInt8) {
         // write(message: BLEMessage(.analogRead, [pin]))
        fatalError("Not yet implemented")
     }

    public func servoWrite(pin: UInt8, value: UInt8) {
        write(message: BLEMessage(.servoWrite, [pin, value]))
    }

     public func servoRead(pin: UInt8) {
         // write(message: BLEMessage(.servoRead, [pin]))
        fatalError("Not yet implemented")
     }

}

extension BLEPlayground: BLEDelegate {
    public func bleDidUpdateState(state: CBManagerState) {
        if state == .poweredOn {
            _ = ble.startScanning(timeout: 2000)
        }
    }

    public func bleDidConnectToPeripheral(peripheral: CBPeripheral) {
    }

    public func bleDidDisconenctFromPeripheral(peripheral: CBPeripheral) {

    }

    public func bleDidReceiveData(data: Data?) {
        if let data = data {
            self.processData(data)
        }
    }

    public func bleDidDiscoverCharacteristics() {
        print(pendingData)
        pendingData.forEach { ble.write(data: $0) }
        pendingData.removeAll()
    }
}
