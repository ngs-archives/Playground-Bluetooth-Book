import PlaygroundSupport

PlaygroundPage.current.needsIndefiniteExecution = true

let ble = BLEPlayground()
let pin: UInt8 = 9
ble.set(pin: pin, mode: .output)
ble.digitalWrite(pin: pin, value: .high)
