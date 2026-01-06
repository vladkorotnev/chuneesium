//
//  HardwareSlider.swift
//  chuneesium
//
//  Created by DJ AKASAKA on 2026/01/02.
//

import Foundation
import SwiftSerial

enum SliderCommandType: UInt8 {
    case singleReport = 1
    case led = 2
    case enableReport = 3
    case disableReport = 4
    case pingPong = 5
    case reset = 16
    case exception = 238
    case getInfo = 240
}

enum SliderRequest {
    case singleReport
    case led(brightness: UInt8, colors: [SliderColor])
    case pingPong(brightness: UInt8, colors: [SliderColor])
    case enableReport
    case disableReport
    case reset
    case getInfo
}

extension SliderRequest {
    var argumentArray: [UInt8] {
        switch self {
        case let .led(brightness, colors): [brightness] + colors.flatMap { [$0.b, $0.r, $0.g] }
        case let .pingPong(brightness, colors): [brightness] + colors.flatMap { [$0.b, $0.r, $0.g] }
        default: []
        }
    }
    
    var commandNumber: UInt8 {
        switch self {
        case .singleReport: SliderCommandType.singleReport.rawValue
        case .led(_, _): SliderCommandType.led.rawValue
        case .pingPong(_, _): SliderCommandType.pingPong.rawValue
        case .enableReport: SliderCommandType.enableReport.rawValue
        case .disableReport: SliderCommandType.disableReport.rawValue
        case .reset: SliderCommandType.reset.rawValue
        case .getInfo: SliderCommandType.getInfo.rawValue
        }
    }
}

enum SliderResponse {
    case ready
    case singleReport(values: [UInt8])
    case exception(context: UInt8, error: UInt8)
    case getInfo(model: String, class: UInt, chip: String, fw_ver: UInt)
}

/// A controller for Sega-style rhythm game slider hardware.
public class HardwareSlider {
    private let viewModel: SliderCoordinator?
    private let serialPort: SerialPort
    private let readQueue = DispatchQueue(label: "slider.reader", qos: .userInteractive)
    private var isRunning = false
    
    /// Initializes the slider controller with a specific serial port path.
    /// - Parameter portPath: Path to the device, e.g., "/dev/tty.usbserial" or "/dev/ttyUSB0".
    init(
        portPath: String,
        viewModel: SliderCoordinator? = nil
    ) {
        self.serialPort = SerialPort(path: portPath)
        self.viewModel = viewModel
    }
    
    /// Opens the port and starts monitoring for input on a background thread.
    public func open() throws {
        
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
            print("Ping slider...")
            let res = self.receiveResponse()
            if case .ready = res {
                pinging = false
            }
            sleep(1)
        }
        
        sendRequest(.getInfo)
        let info = receiveResponse()
        if case let .getInfo(mdl, cls, chip, fw_ver) = info {
            print("Found device '\(mdl)' class=\(cls) chip='\(chip)' fw=\(fw_ver)")
        } else if case let .exception(context, error) = info {
            print("Error! \(context) -> \(error)")
        }
        
        isRunning = true
        readQueue.async { [weak self] in
            self?.monitoringLoop()
        }
    }
    
    /// Stops monitoring and closes the serial connection.
    public func close() {
        isRunning = false
        serialPort.closePort()
    }
    
    
    // MARK: - Protocol Logic
    /// Frames, escapes, and writes a packet to the serial port.
    private func sendPacket(commandId: UInt8, data: [UInt8]) {
        // [Length (after decode)] [Command] [Data...]
        let decodedBody = [commandId, UInt8(data.count)] + data
        let checksum = calculateChecksum(for: Data([0xFF] + decodedBody))
        
        let messageToEncode = decodedBody + [checksum]
        
        // Escape sequence construction
        var packet: [UInt8] = [0xFF] // SYNC byte is not escaped
        for byte in messageToEncode {
            if byte == 0xFF || byte == 0xFD {
                packet.append(0xFD) // ESC
                packet.append(byte - 0x01)
            } else {
                packet.append(byte)
            }
        }
        
        do {
            _ = try serialPort.writeData(Data(packet))
        } catch {
            print("Slider: Failed to write to serial port: \(error)")
        }
    }
    
    /// Reads and decodes a single protocol packet from the serial stream.
    /// - Returns: A fully decoded packet in the form
    ///   [0xFF, cmd, argc, args..., checksum]
    private func receiveEncodedPacket() -> Data? {
        do {
            let encoded = try serialPort.readData(ofLength: 256)
            guard !encoded.isEmpty else { return nil }
            
            // Find SYNC byte (0xFF)
            guard let syncIndex = encoded.firstIndex(of: 0xFF) else {
                return nil
            }
            
            var decoded = Data()
            decoded.append(0xFF)
            
            var esc = false
            var expectedLength: Int? = nil
            
            // Decode bytes after SYNC, handling ESC (0xFD)
            for byte in encoded[(syncIndex + 1)..<encoded.count] {
                if byte == 0xFD {
                    esc = true
                    continue
                }
                
                let decodedByte = byte &+ (esc ? 1 : 0)
                decoded.append(decodedByte)
                esc = false
                
                // Once we have SYNC, cmd, argc we can determine the full length:
                // 1 (sync) + 1 (cmd) + 1 (argc) + argc (args) + 1 (checksum)
                if decoded.count == 3 {
                    let argc = Int(decoded[2])
                    expectedLength = 1 + 1 + 1 + argc + 1
                }
                
                if let expectedLength, decoded.count >= expectedLength {
                    break
                }
            }
            
            guard let expectedLength = expectedLength,
                  decoded.count >= expectedLength else {
                return nil
            }
            
            // Trim to the first full packet in case there are extra bytes.
            return decoded.subdata(in: 0..<expectedLength)
        } catch {
            print("Slider: Failed to read from serial port: \(error)")
            return nil
        }
    }
    
    /// Calculates the checksum as defined in the protocol.
    private func calculateChecksum(for bytes: Data) -> UInt8 {
        var sum: Int = 0
        for b in bytes {
            sum += Int(b & 0xFF)
        }
        return UInt8((256 - (sum & 0xFF)) & 0xFF)
    }
    
    private func sendRequest(_ command: SliderRequest) {
        sendPacket(commandId: command.commandNumber, data: command.argumentArray)
    }
    
    
    private func receiveResponse() -> SliderResponse? {
        guard let pkt = receiveEncodedPacket() else { return nil }
        guard pkt.count >= 4 else { return nil } // SYNC, cmd, argc, checksum
        
        let checksumIndex = pkt.count - 1
        let packetWithoutChecksum = pkt.subdata(in: 0..<checksumIndex)
        let expectedChecksum = calculateChecksum(for: packetWithoutChecksum)
        let receivedChecksum = pkt[checksumIndex]
        
        if expectedChecksum != receivedChecksum {
            print("Slider Checksum expected \(expectedChecksum), got \(receivedChecksum)")
        }
        
        let cmd = pkt[1]
        let argc = Int(pkt[2])
        let argsStart = 3
        let argsEnd = argsStart + argc
        
        guard pkt.count == 1 + 1 + 1 + argc + 1 else {
            print("Slider: Packet length/argc mismatch (cmd=\(cmd), argc=\(argc), count=\(pkt.count))")
            return nil
        }
        
        let args = pkt.subdata(in: argsStart..<argsEnd)
        
        switch cmd {
        case SliderCommandType.singleReport.rawValue:
            return SliderResponse.singleReport(values: Array(args))
            
        case SliderCommandType.exception.rawValue:
            guard args.count >= 2 else { return nil }
            return SliderResponse.exception(context: args[0], error: args[1])
            
        case SliderCommandType.reset.rawValue:
            return SliderResponse.ready
            
        case SliderCommandType.getInfo.rawValue:
            guard args.count >= 0x12 else { return nil }
            return SliderResponse.getInfo(
                model: String(data: args.subdata(in: 0..<8), encoding: .utf8) ?? "ERROR",
                class: UInt(args[8]),
                chip: String(data: args.subdata(in: 9..<14), encoding: .utf8) ?? "ERROR",
                fw_ver: UInt(args[14])
            )
            
        default:
            print("Slider: Unknown packet cmd=\(cmd)")
            return nil
        }
    }
    
    /// Continuous background loop that decodes incoming escaped serial data.
    private func monitoringLoop() {
        self.sendRequest(.enableReport)
        var oldOutputs: [SliderTouchCoordinates: Int] = [:]
        while isRunning {
            do {
                var colors = Array(repeating: SliderColor(r: 0, g: 0, b: 0), count: 31)
                if let viewState = viewModel?.viewState {
                    viewState.forEach { state in
                        for i in 0..<state.location.width*2-1 {
                            let sliderIndex = colors.count - 1 - i - state.location.left*2
                            let itemIndex = i
                            
                            if sliderIndex < colors.count && sliderIndex >= 0 {
                                colors[sliderIndex] = SliderColor(color: state.colors[itemIndex])
                            }
                        }
                    }
                }
                
                self.sendRequest(.pingPong(brightness: 0xFE, colors: colors))
                let res = self.receiveResponse()
                
                if let viewModel, let res, case let .singleReport(values) = res {
                    // convert the layout to left-to-right
                    var outputs: [SliderTouchCoordinates: Int] = [:]
                    stride(from: 0, to: values.count - 1, by: 2).forEach { col in
                        outputs[SliderTouchCoordinates(row: 0, column: 15-col/2)] = Int(values[col])
                        outputs[SliderTouchCoordinates(row: 1, column: 15-col/2)] = Int(values[col+1])
                    }
                    if oldOutputs != outputs {
                        DispatchQueue.main.async {
                            viewModel.onInputUpdate(from: .hardwareSlider, state: outputs)
                        }
                        oldOutputs = outputs
                    }
                }
            } catch {
                // Briefly yield if no data is available or error occurred
                Thread.sleep(forTimeInterval: 0.1)
            }
        }
    }
    

}
