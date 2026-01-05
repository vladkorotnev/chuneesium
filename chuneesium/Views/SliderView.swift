//
//  ContentView.swift
//  chuneesium
//
//  Created by DJ AKASAKA on 2026/01/01.
//

import SwiftUI

struct SliderView: View {
    @ObservedObject private var viewModel: SliderCoordinator
    
    init(viewModel: SliderCoordinator) {
        self.viewModel = viewModel
    }
    
    var body: some View {
        ZStack {
            HStack(spacing: 0) {
                ForEach(viewModel.columnTouchState.indices, id: \.self) { column in
                    let value = viewModel.columnTouchState[column]
                    Rectangle()
                        .fill(.clear)
                        .frame(minWidth: SLIDER_WIDTH_PX_PER_CELL, maxWidth: SLIDER_WIDTH_PX_PER_CELL)
                        .background(
                            LinearGradient(colors: [.clear, .white], startPoint: .top, endPoint: .bottom)
                        )
                        .opacity(Double(value) / 255.0)
                        .blur(radius: 3)
                }
            }
            VStack {
                Spacer()
                HStack(alignment: .bottom, spacing: 0) {
                    ForEach(viewModel.viewState.indices, id: \.self) { index in
                        let item = viewModel.viewState[index]

                        // If not the first item, check for a gap from previous item
                        if index > 0 || item.location.left > 0 {
                            
                            let gap = {
                                if index > 0 {
                                    let prev =  viewModel.viewState[index - 1]
                                    let prevRight = prev.location.left + prev.location.width
                                    return item.location.left - prevRight
                                } else {
                                    return item.location.left
                                }
                            }()
                            
                            if gap > 0 {
                                Spacer(minLength: CGFloat(gap) * SLIDER_WIDTH_PX_PER_CELL)
                            }
                        }

                        // Render the actual item
                        SliderCell(
                            color: item.labelTint,
                            width: item.location.width
                        ) {
                            Text(item.label)
                        }
                    }
                    Spacer(minLength: CGFloat((16 - (viewModel.items.map { $0.location.left + $0.location.width }.max() ?? 0)))*SLIDER_WIDTH_PX_PER_CELL)
                }
                .simultaneousGesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged({ v in
                            let point = v.location
                            let left = Int(floor(point.x / SLIDER_WIDTH_PX_PER_CELL))
                            viewModel.onInputUpdate(from: .mouse, state: [SliderTouchCoordinates(row: 0, column: left): 255])
                        })
                        .onEnded({ v in
                            viewModel.onInputUpdate(from: .mouse, state: [:])
                        })
                )
            }
            
        }
        .frame(width: 16 * SLIDER_WIDTH_PX_PER_CELL)
        .frame(
            minWidth: 16 * SLIDER_WIDTH_PX_PER_CELL,
            maxWidth: 16 * SLIDER_WIDTH_PX_PER_CELL,
            minHeight: 150,
            maxHeight: .infinity
        )
    }
}


#Preview {
    SliderView(viewModel:  SliderCoordinator(
        items: [
            SliderButton(
                tint: .green,
                label: "BACK",
                location: .init(left: 0, width: 3),
            ),
            SliderButton(
                tint: .green,
                label: "NEXT",
                location: .init(left: 4, width: 3),
            ),
        ]
    )
    )
}
