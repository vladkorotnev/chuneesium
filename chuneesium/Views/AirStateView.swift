//
//  AirStateView.swift
//  chuneesium
//
//  Created by DJ AKASAKA on 2026/01/08.
//

import SwiftUI

struct AirStateView: View {
    var status: [Bool]
    var body: some View {
        HStack {
            ForEach(status.indices, id: \.self) { i in
                let sts = status[i]
                
                Circle()
                    .fill(sts ? .green : .gray)
                    .frame(width: 15, height: 15)
            }
        }
    }
}

#Preview {
    AirStateView(status:[
        false,
        false,
        true,
        false,
        false
    ])
}
