//
//  JVSIO.swift
//  chuneesium
//
//  Created by DJ AKASAKA on 2026/01/08.
//

import Foundation
import SwiftSerial
import Combine

private enum JVSCommandType: UInt8 {
    case reset = 0xF0
    case setAddress = 0xF1
    case identify = 0x10
    case readSwitches = 0x20
}

enum JVSCommand {
    case reset
    case setAddress(_ address: UInt8)
    case identify
    case readSwitches(players: UInt8, bytes: UInt8)
}

enum JVSError: Error {
    case badSts
    case unknownReport
    case badChecksum
    case malformed
    case badAddress
}

/// JVS switch state update containing raw switch data bytes
struct JVSSwitchState: Equatable {
    let systemState: UInt8
    let playerBytes: Data
    
    init(systemState: UInt8, playerBytes: Data) {
        self.systemState = systemState
        self.playerBytes = playerBytes
    }
    
    var testButton: Bool {
        systemState & 0x80 != 0
    }
}

extension JVSCommand {
    var argumentArray: [UInt8] {
        switch self {
        case .reset: [0xD9]
        case let .setAddress(addr): [addr]
        case .identify: []
        case let .readSwitches(players, bytes): [players, bytes]
        }
    }
    
    var commandNumber: UInt8 {
        switch self {
        case .reset: JVSCommandType.reset.rawValue
        case .setAddress(_): JVSCommandType.setAddress.rawValue
        case .identify: JVSCommandType.identify.rawValue
        case .readSwitches: JVSCommandType.readSwitches.rawValue
        }
    }
}

final class JVSIO {
    private let serialPort: SerialPort
    private var pollingTask: Task<Void, Never>?
    private var isRunning = false
    
    /// Publisher for JVS switch state updates
    var switchState: some Publisher<JVSSwitchState, Never> {
        _switchState
    }
    
    private let _switchState = PassthroughSubject<JVSSwitchState, Never>()
    
    /// Configuration for polling
    var playerCount: UInt8 = 2
    var bytesPerPlayer: UInt8 = 2
    var pollingInterval: TimeInterval = 0.016 // ~60Hz
    
    init(
        portPath: String
    ) {
        self.serialPort = SerialPort(path: portPath)
    }
    
    func open() throws {
        try serialPort.openPort()
        
        serialPort.setSettings(
            receiveRate: .baud115200,
            transmitRate: .baud115200,
            minimumBytesToRead: 1,
            timeout: 3
        )
    
        // Reset and set address
        sendCommand(to: 0xFF, command: .reset)
        Thread.sleep(forTimeInterval: 0.5)
        sendCommand(to: 0xFF, command: .reset)
        Thread.sleep(forTimeInterval: 0.5)
        sendCommand(to: 0xFF, command: .setAddress(1))
        
        let res = receiveResponse()
        if case .success = res {
            print("JVS did set address")
        } else {
            print("JVS address set failed: \(res)")
        }
        
        print("JVS connected")

        sendCommand(to: 0x01, command: .identify)
        let identifyRes = receiveResponse()
        if case let .success(data) = identifyRes {
            print("JVS did identify: \(String(data: data, encoding: .utf8) ?? "unknown")")
        }
        
        // Start the async polling task
        isRunning = true
        pollingTask = Task { [weak self] in
            await self?.pollingLoop()
        }
    }
    
    func close() {
        isRunning = false
        pollingTask?.cancel()
        pollingTask = nil
        serialPort.closePort()
    }
    
    // MARK: - Async Polling Loop
    
    private func pollingLoop() async {
        var previousState: JVSSwitchState? = nil
        
        while isRunning && !Task.isCancelled {
            sendCommand(to: 0x01, command: .readSwitches(players: playerCount, bytes: bytesPerPlayer))
            let result = receiveResponse()
            
            if case let .success(data) = result {
                // Data format: [system state byte] [player bytes...]
                if data.count >= 1 {
                    let systemState = data[0]
                    let playerBytes = data.count > 1 ? data.subdata(in: 1..<data.count) : Data()
                    let newState = JVSSwitchState(systemState: systemState, playerBytes: playerBytes)
                    
                    // Only publish if state changed
                    if newState != previousState {
                        _switchState.send(newState)
                        previousState = newState
                    }
                }
            }
            
            // Sleep for polling interval
            do {
                try await Task.sleep(nanoseconds: UInt64(pollingInterval * 1_000_000_000))
            } catch {
                // Task cancelled
                break
            }
        }
    }
    
    // MARK: - Protocol Logic
    /// Frames, escapes, and writes a packet to the serial port.
    private func sendPacket(commandId: UInt8, data: [UInt8], dest: UInt8, src: UInt8 = 0x00) {
        let decodedBody = [dest, UInt8(data.count + 2), commandId] + data
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
        let data = Data(packet)
        var written = 0
        do {
            while written < data.count {
                let wrote = try serialPort.writeData(data.suffix(from: written))
                written += wrote
                if written < data.count {
                    print("remain=\(data.count-written)")
                }
            }
        } catch {
            print("JVS: Failed to write to serial port: \(error)")
        }
    }
    
    private func receiveEncodedPacket() -> Data? {
        var pkt = try! serialPort.readData(ofLength: 256)
        guard pkt.count >= 3, pkt[0] == 0xE0 else { return nil }
        
        let estimatedLen = pkt[2] + 3
        while pkt.count < estimatedLen {
            let chunk = try! serialPort.readData(ofLength: 64)
            pkt += chunk
            if pkt.count < estimatedLen {
                print("remaining \(Int(estimatedLen) - pkt.count)")
            }
        }

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

        return rslt
    }
   
    
    private func receiveResponse() -> Result<Data, JVSError> {
        let pkt = receiveEncodedPacket()
        guard  let pkt, pkt.count >= 3, pkt[0] == 0xE0 else {
            print("JVS: bad header or too short")
            return .failure(.malformed)
        }
        if pkt[1] != 0x00 {
            print("JVS: expected addr 0, got \(pkt[1])")
            return .failure(.badAddress)
        }
        guard pkt.count >= pkt[2] + 2 else {
            print("JVS: expected \(pkt[2] + 2) bytes but got \(pkt.count)")
            return .failure(.malformed)
        } // bad len
        guard calculateChecksum(for: pkt.subdata(in: 1..<pkt.count-1)) == pkt[pkt.count - 1] else {
            print("JVS: bad cksum")
            return .failure(.badChecksum)
        }
        
        guard pkt[3] == 1 else {
            print("JVS: bad sts")
            return .failure(.badSts)
        }
        
        guard pkt[4] == 0x1 else {
            print("JVS: unsupported report")
            return .failure(.unknownReport)
        }
        
        return .success(pkt.subdata(in: 5..<pkt.count-1))
    }
    /// Calculates the checksum as defined in the protocol.
    private func calculateChecksum(for bytes: Data) -> UInt8 {
        var sum: Int = 0
        for b in bytes {
            sum += Int(b)
        }
        return UInt8(sum % 0x100)
    }
    
    func sendCommand(to: UInt8, command: JVSCommand) {
        sendPacket(commandId: command.commandNumber, data: command.argumentArray, dest: to)
    }
}
