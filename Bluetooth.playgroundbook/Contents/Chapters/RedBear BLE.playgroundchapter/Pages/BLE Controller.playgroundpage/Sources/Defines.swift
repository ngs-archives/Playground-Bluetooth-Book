import Foundation

public enum PinMode: UInt8 {
    case input       = 0x00
    case output      = 0x01
    case analog      = 0x02
    case pwm         = 0x03
    case servo       = 0x04
    case unavailable = 0xff

    var bytes: [UInt8] { return [rawValue] }
}

public enum PinType: UInt8 {
    case digital = 0x02
    case analog  = 0x03

    var bytes: [UInt8] { return [rawValue] }
}

public enum PinValue: UInt8 {
    case low  = 0x00
    case high = 0x01

    var bytes: [UInt8] { return [rawValue] }
}

public enum PinError: UInt8 {
    case invalidPin  = 0x01
    case invalidMode = 0x03

    var bytes: [UInt8] { return [rawValue] }
}

public enum PinCapability: UInt8 {
    case none     = 0x00
    case digital  = 0x01
    case analog   = 0x02
    case pwm      = 0x04
    case servo    = 0x08
    case i2c      = 0x10

    var bytes: [UInt8] { return [rawValue] }
}

public enum MessageType: Character {
    case sendCustomData          = "Z"
    case queryProtocolVersion    = "V"
    case queryTotalPinCount      = "C"
    case queryPinCapability      = "P"
    case queryPinMode            = "M"
    case queryPinAll             = "A"
    case setPinMode              = "S"
    case digitalRead             = "G"
    case digitalWrite            = "T"
    case analogWrite             = "N"
    // case analogRead           = "?"
    case servoWrite              = "O"
    // case servoRead            = "?"

    public var bytes: [UInt8] {
        return Array("\(rawValue)".utf8)
    }
}

public struct BLEMessage {
    public var type: MessageType
    public var arguments: [UInt8]

    public var bytes: [UInt8] {
        return type.bytes + arguments
    }

    public var data: Data {
        return Data(bytes: bytes)
    }

    public init(_ type: MessageType, _ arguments: [UInt8] = []) {
        self.type = type
        self.arguments = arguments
    }
}
