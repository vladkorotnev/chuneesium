//
//  RepeatArray.swift
//  chuneesium
//
//  Created by DJ AKASAKA on 2026/01/03.
//

extension Array {
    func pattern(length: Int) -> [Element] {
        guard !self.isEmpty else { fatalError("Empty array cannot be repeated") }
        guard length > 0 else { return [] }

        var result = [] + self
        while result.count < length {
            result += self
        }
        return Array(result[...(length-1)])
    }
}
