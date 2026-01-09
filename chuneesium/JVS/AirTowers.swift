//
//  AirTowers.swift
//  chuneesium
//
//  Created by DJ AKASAKA on 2026/01/08.
//

import Combine
import Foundation

final class AirTowers {
    private var _rawState = PassthroughSubject<[Bool], Never>()
    private var _output = PassthroughSubject<Int, Never>()
    
    var output: AnyPublisher<Double, Never> {
        _output
            .map {
                guard $0 != 0 else { return 0.0 }
                guard $0 != 12 else { return 1.0 }
                return Double($0) / 12.0
            }
            .eraseToAnyPublisher()
    }
    
    var rawState: AnyPublisher<[Bool], Never> {
        _rawState.eraseToAnyPublisher()
    }
    
    func feed(state: JVSSwitchState) {
        guard state.playerBytes.count >= 4 else { return }
        let byteLeft = state.playerBytes[1]
        let byteRight = state.playerBytes[3]

        let bottomToTop = [
            byteLeft & 0x20 == 0,
            byteRight & 0x20 == 0,
            byteLeft & 0x10 == 0,
            byteRight & 0x10 == 0,
            byteLeft & 0x08 == 0,
            byteRight & 0x08 == 0,
        ]
        
        _rawState.send(bottomToTop)
        
        let level = calculateLevel(from: bottomToTop)
        _output.send(level)
    }
    
    private func calculateLevel(from state: [Bool]) -> Int {
        // Find the lowest activated sensor index
        guard let lowestIndex = state.firstIndex(of: true) else {
            return 0 // No sensors activated
        }
        
        // Count consecutive activated sensors starting from the lowest
        var consecutiveCount = 0
        for i in lowestIndex..<state.count {
            if state[i] {
                consecutiveCount += 1
            } else {
                break
            }
        }
        
        // Formula: level * 2 + span, capped at 12
        return min(lowestIndex * 2 + consecutiveCount, 12)
    }
}
