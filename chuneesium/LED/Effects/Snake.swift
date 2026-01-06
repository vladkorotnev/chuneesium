//
//  Snake.swift
//  chuneesium
//
//  Created by DJ AKASAKA on 2026/01/06.
//

import Foundation

/// An automatic "Snake" game simulation rendered on the LED matrix.
/// - The snake moves continuously and always steers toward the food.
/// - The snake never dies; movement wraps at edges and length is capped.
/// - `isFinished` is always `false` so this effect can run indefinitely.
final class LEDSnake: LEDEffect {
    private struct Point: Equatable {
        var x: Int
        var y: Int
    }
    
    private enum Direction: CaseIterable {
        case up, down, left, right
        
        var delta: (dx: Int, dy: Int) {
            switch self {
            case .up: return (0, 1)
            case .down: return (0, -1)
            case .left: return (-1, 0)
            case .right: return (1, 0)
            }
        }
        
        func isOpposite(of other: Direction) -> Bool {
            switch (self, other) {
            case (.up, .down), (.down, .up),
                 (.left, .right), (.right, .left):
                return true
            default:
                return false
            }
        }
    }
    
    // Game state
    private var snake: [Point] = []
    private var direction: Direction = .right
    private var food: Point?
    private var isInitialized = false
    
    /// Maximum length of the snake.
    var maxLength: Int = 6
    
    // Timing
    private var frameCounter = 0
    /// Number of draw calls between snake moves. Lower = faster.
    var framesPerStep: Int = 3
    
    // Colors
    var headColor = SliderColor(r: 0, g: 255, b: 64)
    var bodyColor = SliderColor(r: 0, g: 160, b: 32)
    var foodColor = SliderColor(r: 255, g: 32, b: 32)
    
    // Effect never really "finishes".
    var isFinished: Bool { false }
    
    func reset() {
        snake.removeAll()
        direction = .right
        food = nil
        isInitialized = false
        frameCounter = 0
    }
    
    func draw(on display: LEDDisplay) {
        if !isInitialized {
            startNewGame(on: display)
            isInitialized = true
        }
        
        frameCounter += 1
        if frameCounter < framesPerStep {
            render(on: display)
            return
        }
        frameCounter = 0
        
        stepGame(on: display)
        render(on: display)
    }
    
    func react(to event: ControlEvent) {
        guard let beatSpeed = LightBinding.controlChange(channel: 3, control: 127).extractRawValue(event) else { return }
        // beatSpeed: 0.0 ≈ 100bpm (slow), 1.0 ≈ 200bpm (fast)
        // Map this into an integer frame delay: higher bpm → smaller framesPerStep.
        let clamped = max(0.0, min(1.0, beatSpeed))
        // framesPerStep in [1, 6]; 1 is fastest, 6 is slowest.
        let mapped = Int((1.0 - clamped) * 5.0) + 1
        framesPerStep = max(1, min(6, mapped))
    }
    
    // MARK: - Game Logic
    
    private func startNewGame(on display: LEDDisplay) {
        let width = display.columnCount
        let height = 10
        
        guard width >= 2 && height >= 2 else {
            snake = []
            food = nil
            return
        }
        
        let startX = Int.random(in: 0..<width)
        let startY = Int.random(in: 0..<height)
        
        direction = [.left, .right].randomElement() ?? .right
        
        // Start at 3 pixels long.
        let delta = direction.delta
        snake = [
            Point(x: startX, y: startY),
            Point(x: (startX - delta.dx + width) % width, y: (startY - delta.dy + height) % height),
            Point(x: (startX - 2 * delta.dx + width * 2) % width, y: (startY - 2 * delta.dy + height * 2) % height)
        ]
        
        placeFood(on: display)
    }
    
    private func stepGame(on display: LEDDisplay) {
        guard !snake.isEmpty else {
            startNewGame(on: display)
            return
        }
        
        maybeTurn(on: display)
        
        let width = display.columnCount
        let height = 10
        
        let head = snake[0]
        let delta = direction.delta
        
        // Move without wrapping – rely on `maybeTurn` to keep us in-bounds.
        let newX = head.x + delta.dx
        let newY = head.y + delta.dy
        
        // Clamp to playfield as a fallback safeguard.
        let clampedX = max(0, min(width - 1, newX))
        let clampedY = max(0, min(height - 1, newY))
        
        let newHead = Point(x: clampedX, y: clampedY)
        
        snake.insert(newHead, at: 0)
        
        if let food, food == newHead {
            placeFood(on: display)
        } else {
            snake.removeLast()
        }
        
        // Enforce maximum length cap.
        if snake.count > maxLength {
            snake = Array(snake.prefix(maxLength))
        }
    }
    
    private func maybeTurn(on display: LEDDisplay) {
        let width = display.columnCount
        let height = 10
        
        guard let head = snake.first else { return }
        
        // If there's no food, just keep going straight.
        guard let food = food else { return }
        
        // Helper to compute regular Manhattan distance within playfield.
        func manhattanDistance(from p: Point, to q: Point) -> Int {
            let dx = abs(p.x - q.x)
            let dy = abs(p.y - q.y)
            return dx + dy
        }
        
        let currentBodyWithoutTail = Array(snake.dropLast())
        
        // Evaluate all possible directions and pick the one that
        // (1) reduces distance to the food
        // (2) avoids collisions with own body if possible.
        let candidateDirections = Direction.allCases
        
        var bestDirection: Direction = direction
        var bestDistance = Int.max
        var bestIsSafe = false
        
        for dir in candidateDirections {
            let d = dir.delta
            var nx = head.x + d.dx
            var ny = head.y + d.dy
            
            // Disallow moves that would go through walls.
            if nx < 0 || nx >= width || ny < 0 || ny >= height {
                continue
            }
            
            let nextPoint = Point(x: nx, y: ny)
            let dist = manhattanDistance(from: nextPoint, to: food)
            let isSafe = !currentBodyWithoutTail.contains(nextPoint)
            
            if isSafe {
                if !bestIsSafe || dist < bestDistance {
                    bestIsSafe = true
                    bestDistance = dist
                    bestDirection = dir
                }
            } else if !bestIsSafe && dist < bestDistance {
                // Only consider unsafe options if we have no safe candidate yet.
                bestDistance = dist
                bestDirection = dir
            }
        }
        
        direction = bestDirection
    }
    
    private func placeFood(on display: LEDDisplay) {
        let width = display.columnCount
        let height = 10
        
        let maxCells = width * height
        
        var attempts = 0
        var newFood: Point?
        
        repeat {
            let x = Int.random(in: 0..<width)
            let y = Int.random(in: 0..<height)
            let candidate = Point(x: x, y: y)
            
            if !snake.contains(candidate) {
                newFood = candidate
                break
            }
            
            attempts += 1
        } while attempts < maxCells * 2
        
        if let newFood {
            food = newFood
        } else {
            // If we somehow couldn't place food, just clear it;
            // the snake will continue moving without eating.
            food = nil
        }
    }
    
    // MARK: - Rendering
    
    private func render(on display: LEDDisplay) {
        let width = display.columnCount
        let height = 10
        
        // Clear board
        for x in 0..<width {
            for y in 0..<height {
                display.setPixel(x: x, y: y, color: SliderColor())
            }
        }
        
        // Draw food
        if let food {
            display.setPixel(x: food.x, y: food.y, color: foodColor)
        }
        
        // Draw snake: head + body
        guard !snake.isEmpty else { return }
        
        for (index, segment) in snake.enumerated() {
            let color = (index == 0) ? headColor : bodyColor
            display.setPixel(x: segment.x, y: segment.y, color: color)
        }
    }
}

