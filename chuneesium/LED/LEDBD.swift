//
//  LEDBD.swift
//  chuneesium
//
//  Created by DJ AKASAKA on 2026/01/05.
//

import Foundation
import SwiftSerial

private enum LedCommandType: UInt8 {
    case reset = 16
    case getInfo = 0xF0
    case setTimeout = 0x11
    case getStatus = 0xF1
    case setResponse = 0x14
    case setPixelData = 0x82
    case setPixelCount = 0x86
}

enum LedCommand {
    case reset
    case getInfo
    case setTimeout(ms: UInt16)
    case setResponse(enabled: Bool)
    case setPixelData(_ data: [SliderColor])
    case setPixelCount(count: UInt16)
}

extension LedCommand {
    var argumentArray: [UInt8] {
        switch self {
        case .reset: [0xD9]
        case let .setPixelData(data): data.flatMap { [$0.r, $0.g, $0.b] }
        case let .setTimeout(ms): [UInt8((ms >> 8) & 0xFF), UInt8(ms & 0xFF)]
        case let .setResponse(enabled): [UInt8(enabled ? 1 : 0)]
        case let .setPixelCount(count): [UInt8(truncatingIfNeeded: count)]
        default: []
        }
    }
    
    var commandNumber: UInt8 {
        switch self {
        case .reset: LedCommandType.reset.rawValue
        case .getInfo: LedCommandType.getInfo.rawValue
        case .setTimeout(_): LedCommandType.setTimeout.rawValue
        case .setResponse(_): LedCommandType.setResponse.rawValue
        case .setPixelData(_): LedCommandType.setPixelData.rawValue
        case .setPixelCount(_): LedCommandType.setPixelCount.rawValue
        }
    }
}

enum LedResponse {
    case ready
    case exception(packet: Data)
    case getInfo(model: String, class: UInt, chip: String, fw_ver: UInt)
    case setTimeout(timeout: UInt16)
    case setResponse(enable: Bool)
    case setPixelData
    case setPixelCount(count: UInt16)
}

protocol LEDPort {
    var ledCount: Int { get }
    func writePixels(data: [SliderColor])
}

final class LEDBD: LEDPort {
    private let serialPort: SerialPort
    let ledCount: Int
    
    init(
        portPath: String,
        ledCount: Int
    ) {
        self.serialPort = SerialPort(path: portPath)
        self.ledCount = ledCount
    }
    
    func open() throws {
        try serialPort.openPort()
        
        // Protocol specification: 115200 bps, 8N1
        try serialPort.setSettings(
            baudRateSetting: .symmetrical(.baud115200),
            minimumBytesToRead: 1,
            timeout: 3
        )
    
        
        var pinging = true
        while pinging {
            self.sendRequest(.reset)
            print("Ping LEDBD...")
            let res = self.receiveResponse()
            if case .ready = res {
                pinging = false
            } else {
                print("Unexpected response: \(String(describing: res))")
            }
            sleep(1)
        }
        print("LEDBD connected")
        
//        sendRequest(.getInfo)
//        let info = receiveResponse()
//        if case let .getInfo(mdl, cls, chip, fw_ver) = info {
//            print("Found device '\(mdl)' class=\(cls) chip='\(chip)' fw=\(fw_ver)")
//        } else if case let .exception(pkt) = info {
//            print("Error response! \(pkt)")
//        }
//        
        sendRequest(.setResponse(enabled: false))
        let _ = receiveResponse()
        sendRequest(.setPixelCount(count: UInt16(ledCount)))
        print("LEDBD ready")
    }
    
    func close() {
        sendRequest(.setPixelData(Array(repeating: .init(), count: ledCount)))
        serialPort.closePort()
    }
    
    // MARK: - Protocol Logic
    /// Frames, escapes, and writes a packet to the serial port.
    private func sendPacket(commandId: UInt8, data: [UInt8], dest: UInt8 = 0x02, src: UInt8 = 0x01) {
        let decodedBody = [dest, src, UInt8(data.count + 1), commandId] + data
        let checksum = calculateChecksum(for: Data(decodedBody))
        
        var packet: [UInt8] = [0xE0] // SYNC byte is not escaped
        for byte in decodedBody {
            if byte == 0xE0 || byte == 0xD0 {
                packet.append(0xD0) // ESC
                packet.append(byte - 0x01)
            } else {
                packet.append(byte)
            }
        }
        packet.append(checksum)
        
        do {
            _ = try serialPort.writeData(Data(packet))
        } catch {
            print("Slider: Failed to write to serial port: \(error)")
        }
    }
    
    private func receiveEncodedPacket() -> Data? {
        let pkt = try! serialPort.readData(ofLength: 256)
        guard pkt.count > 0, pkt[0] == 0xE0 else { return nil }

        var rslt = Data()
        rslt.append(pkt[0])
        var esc = false
        for byte in pkt.subdata(in: 1..<pkt.count) {
            if byte == 0xD0 {
                esc = true
                continue
            }
            
            rslt.append(byte + (esc ? 1 : 0))
            esc = false
        }
        
        // Return decoded (unescaped) data so downstream parsing and checksums
        // operate on the logical on-wire fields, not the escaped representation.
        return rslt
    }
    
    /// Calculates the checksum as defined in the protocol.
    private func calculateChecksum(for bytes: Data) -> UInt8 {
        var sum: Int = 0
        for b in bytes {
            sum += Int(b)
        }
        return UInt8(sum % 0x100)
    }
    
    private func sendRequest(_ command: LedCommand) {
        sendPacket(commandId: command.commandNumber, data: command.argumentArray)
    }
    
    private func receiveResponse(src: UInt8 = 0x02, dst: UInt8 = 0x01) -> LedResponse? {
        guard let pkt = receiveEncodedPacket(), pkt.count >= 6 else { return nil }
        
        let cksum = calculateChecksum(for: pkt.subdata(in: 1..<(pkt.count-1)))
        if pkt.count > 0, cksum != pkt.last {
            print("LED Checksum expected \(cksum), got \(pkt.last!)")
        }
        
        if pkt[1] != dst {
            print("LED expected dst=\(dst) got=\(pkt[1])")
        }
        if pkt[2] != src {
            print("LED expected src=\(src) got=\(pkt[2])")
        }
        guard pkt[4] == 1 else { return .exception(packet: pkt)}
        
        switch pkt[5] {
        case LedCommandType.reset.rawValue: return LedResponse.ready
        case LedCommandType.getInfo.rawValue:
            let headless = pkt.subdata(in: 7..<(pkt.count-1))
            return LedResponse.getInfo(
                model: String(data: headless.subdata(in: 0..<8), encoding: .utf8) ?? "ERROR",
                class: UInt(headless[8]),
                chip: String(data: headless.subdata(in: 9..<14), encoding: .utf8) ?? "ERROR",
                fw_ver: UInt(headless[14])
            )
        case LedCommandType.setResponse.rawValue: return nil
        default:
            print("?? LED pkt = \(pkt[5])")
            return nil
        }
    }
    
    func writePixels(data: [SliderColor]) {
        sendRequest(.setPixelData(data))
    }
}
