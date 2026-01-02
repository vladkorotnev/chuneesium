//
//  SliderCell.swift
//  chuneesium
//
//  Created by DJ AKASAKA on 2026/01/01.
//

import SwiftUI

let SLIDER_WIDTH_PX_PER_CELL: CGFloat = 80

struct SliderCell<Content: View>: View {
   
    let color: Color
    let width: Int
    let content: Content
    
    init(
        color: Color = Color(red: 1, green: 0, blue: 0),
        width: Int = 1,
        content: () -> Content
    ) {
        self.color = color
        self.width = width
        self.content = content()
    }
    
    private var widthInPx: CGFloat {
        CGFloat(width) * SLIDER_WIDTH_PX_PER_CELL
    }
    
    var body: some View {
        content
            .font(.system(size: 24.0, weight: .medium))
            .stroke(color: .black, width: 1)
            .frame(
                minWidth: widthInPx,
                maxHeight: 75.0,
            )
            .frame(width: widthInPx)
            .background(
                LinearGradient(
                    colors: [
                        color.opacity(0),
                        color
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .border(width: 1.0, edges: [.leading, .trailing], color: .init(white: 0, opacity: 0.3))
    }
}

#Preview {
    HStack {
        SliderCell {
            Text("Button")
        }
        SliderCell {
            EmptyView()
        }
        SliderCell {
            Text("Button")
        }
    }.background(.orange)
}
