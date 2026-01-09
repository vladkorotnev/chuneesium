//
//  Swoopbars.swift
//  chuneesium
//
//  Created by DJ AKASAKA on 2026/01/06.
//

final class LEDSwoopbars: LEDEffect {
    private let evenColorMaker: () -> SliderColor
    private let oddColorMaker: () -> SliderColor
    private var evenColor: SliderColor = .init()
    private var oddColor: SliderColor = .init()
    private var vPhase = 0
    private var isDown = false
    
    init(
        evenColor: @escaping @autoclosure () -> SliderColor,
        oddColor: @escaping @autoclosure () -> SliderColor
    ) {
        self.evenColorMaker = evenColor
        self.oddColorMaker = oddColor
        self.evenColor = evenColorMaker()
        self.oddColor = oddColorMaker()
    }
    
    var isFinished: Bool {
        vPhase == -10 && isDown
    }
    
    func draw(on display: LEDDisplay) {
        var oddColumn = Array(repeating: oddColor, count: 10)
        var evenColumn = Array(repeating: evenColor, count: 10)
        
        for i in 0..<10 {
            if !isDown {
                oddColumn[i] = oddColumn[i].multiply(brightness: Double(i + 1) / 10.0)
                evenColumn[i] = evenColumn[i].multiply(brightness: (10.0-Double(i)) / 10.0)
            } else {
                evenColumn[i] = evenColumn[i].multiply(brightness: Double(i + 1) / 10.0)
                oddColumn[i] = oddColumn[i].multiply(brightness: (10.0-Double(i)) / 10.0)
            }
        }
        
        if vPhase < 0 || vPhase > 20 {
            evenColumn = Array(repeating: .init(), count: 10)
            oddColumn = Array(repeating: .init(), count: 10)
        } else if vPhase < 10 {
            evenColumn.insert(contentsOf: Array(repeating: .init(), count: 10 - vPhase), at: 0)
            evenColumn.removeLast(10 - vPhase)
            
            oddColumn.append(contentsOf: Array(repeating: .init(), count: 10 - vPhase))
            oddColumn.removeFirst(10 - vPhase)
        } else {
            evenColumn.append(contentsOf: Array(repeating: .init(), count: vPhase - 10))
            evenColumn.removeFirst(vPhase - 10)
            
            oddColumn.insert(contentsOf: Array(repeating: .init(), count: vPhase - 10), at: 0)
            oddColumn.removeLast(vPhase - 10)
        }
    
        for i in 0..<display.columnCount {
            display.setColumn(x: i, column: (i % 2 == 0) ? evenColumn : oddColumn)
        }
        
        if !isDown {
            vPhase += 1
            if vPhase == 25 {
                isDown = true
            }
        } else {
            vPhase -= 1
            if vPhase == -10 {
                isDown = false
            }
        }
    }
    
    func reset() {
        vPhase = 0
        isDown = false
        evenColor = evenColorMaker()
        oddColor = oddColorMaker()
    }
}
