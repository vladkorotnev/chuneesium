//
//  ScrollString.swift
//  chuneesium
//
//  Created by DJ AKASAKA on 2026/01/05.
//

import SwiftUI
import AppKit

final class LEDScrollString: LEDEffect {
    var text: String = "HELLO" {
        didSet { renderBitmap() }
    }
    private let colorMaker: () -> Color
    private var color: Color = .indigo.opacity(0.6)
    var speedDivisor = 4
    var holdoff = 22
    
    private var position = -1
    private var bitmap: [[SliderColor]]?
    private var skipCount = 0
    
    init(
        text: String,
        color: @escaping @autoclosure () -> Color = .indigo.opacity(0.6),
        speedDivisor: Int = 2,
        holdoff: Int = 11
    ) {
        self.text = text
        self.colorMaker = color
        self.color = colorMaker()
        self.holdoff = holdoff
        self.speedDivisor = speedDivisor
        renderBitmap()
    }
    
    func reset() {
        position = -1
        color = colorMaker()
        renderBitmap()
    }

    func createStretchedTextImageRGBA32(
        text: String,
        fontName: String,
        fontSize: CGFloat,
        color: NSColor,
        stretchFactor: CGFloat
    ) -> NSImage? {
        guard let font = NSFont(name: fontName, size: fontSize) else { return nil }
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: color,
            .kern: stretchFactor,
        ]
        
        let string = text as NSString
        
        // 1. Use boundingRect for a more accurate measurement than .size()
        // .usesLineFragmentOrigin is crucial for accurate vertical placement
        let drawingOptions: NSString.DrawingOptions = [.usesLineFragmentOrigin, .usesFontLeading]
        let baseRect = string.boundingRect(with: NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude),
                                           options: drawingOptions,
                                           attributes: attributes)
    
        let newWidth = Int(ceil(baseRect.width * stretchFactor))
        
        let bitmapRep = NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: newWidth,
            pixelsHigh: Int(baseRect.height),
            bitsPerSample: 8,
            samplesPerPixel: 4,
            hasAlpha: true,
            isPlanar: false,
            colorSpaceName: .deviceRGB,
            bytesPerRow: newWidth * 4,
            bitsPerPixel: 32
        )
        
        guard let bitmapContext = bitmapRep else { return nil }
        
        NSGraphicsContext.saveGraphicsState()
        let graphicsContext = NSGraphicsContext(bitmapImageRep: bitmapContext)
        NSGraphicsContext.current = graphicsContext
        let cgContext = graphicsContext?.cgContext
        
        // Disable smoothing
        cgContext?.setShouldSmoothFonts(false)
        
        // 3. Apply the horizontal stretch
        cgContext?.scaleBy(x: stretchFactor, y: 1.0)
        
        // 4. Draw with a slight Y offset
        // This moves the text down slightly so the top isn't cut off.
        // We use the negative of the bounding rect's Y origin to normalize the baseline.
        let drawOrigin = NSPoint(x: 0, y: 2.0)
        string.draw(at: drawOrigin, withAttributes: attributes)
        
        NSGraphicsContext.restoreGraphicsState()
        
        let finalImage = NSImage(size: NSSize(width: newWidth, height: Int(baseRect.height)))
        finalImage.addRepresentation(bitmapContext)
        
        return finalImage
    }
    
    private func renderBitmap() {
        guard let image = createStretchedTextImageRGBA32(
            text: text,
            fontName: "Terminus (TTF) Bold",
            fontSize: 12.0,
            color: NSColor(cgColor: color.resolve(in: .init()).cgColor) ?? .white,
            stretchFactor: 1.5
        ) else {
            print("Rendering failed")
            return
        }
        
        NSPasteboard.general.clearContents()
        NSPasteboard.general.writeObjects([image])
 
        let pixelData = (image.cgImage(forProposedRect: nil, context: nil, hints: nil)!).dataProvider!.data
        let data: UnsafePointer<UInt8> = CFDataGetBytePtr(pixelData)

        var tmpBmp = Array(repeating: Array(repeating: SliderColor(), count: 10), count: Int(image.size.width))
        for y in 0..<Int(image.size.height) {
            if y > 9 { continue }
            for x in 0..<Int(image.size.width) {
                let pos = CGPoint(x: x, y: y)

                let pixelInfo: Int = ((Int(image.size.width) * Int(pos.y) * 4) + Int(pos.x) * 4)

                let r = data[pixelInfo]
                let g = data[pixelInfo + 1]
                let b = data[pixelInfo + 2]
                
                tmpBmp[x][min(9, y)] = SliderColor(r: r, g: g, b: b)
            }
        }
        
        bitmap = tmpBmp
        position = 0
    }
    
    func draw(on display: LEDDisplay) {
        guard let bitmap else { return }
        
        guard (skipCount - 1) <= 0 else {
            skipCount -= 1
            return
        }
        
        if position >= 0 && position < bitmap.count {
            display.hShift(count: -1, inserting: bitmap[position])
        } else {
            display.hShift(count: -1)
        }
        
        position += 1
        
        if position > bitmap.count + holdoff {
            position = -1
        }
        
        skipCount = speedDivisor
    }
    
    var isFinished: Bool {
        guard let bitmap else { return true }
        return position == bitmap.count + holdoff
    }
}
