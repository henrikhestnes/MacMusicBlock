import AppKit

let directory = URL(fileURLWithPath: CommandLine.arguments[1]).appendingPathComponent("AppIcon.iconset")
try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
var chunks = Data()
func bigEndian(_ value: Int) -> Data {
    var number = UInt32(value).bigEndian
    return withUnsafeBytes(of: &number) { Data($0) }
}

/// A beamed pair of eighth notes, crossed out by a prohibition sign.
func drawIcon(in context: CGContext) {
    let background = NSBezierPath(roundedRect: NSRect(x: 60, y: 60, width: 904, height: 904), xRadius: 210, yRadius: 210)
    let gradient = NSGradient(starting: NSColor(srgbRed: 0.2, green: 0.16, blue: 0.3, alpha: 1),
                              ending: NSColor(srgbRed: 0.08, green: 0.07, blue: 0.14, alpha: 1))!
    gradient.draw(in: background, angle: -60)

    let note = NSColor(srgbRed: 0.95, green: 0.95, blue: 0.98, alpha: 1).cgColor
    context.setFillColor(note)
    for center in [CGPoint(x: 398, y: 352), CGPoint(x: 638, y: 396)] {
        context.saveGState()
        context.translateBy(x: center.x, y: center.y)
        context.rotate(by: 0.42)
        context.fillEllipse(in: CGRect(x: -78, y: -56, width: 156, height: 112))
        context.restoreGState()
    }
    // Stems on the right side of each head, joined by a slanted beam.
    context.fill(CGRect(x: 446, y: 372, width: 30, height: 334))
    context.fill(CGRect(x: 686, y: 416, width: 30, height: 334))
    context.move(to: CGPoint(x: 446, y: 706))
    context.addLine(to: CGPoint(x: 716, y: 750))
    context.addLine(to: CGPoint(x: 716, y: 666))
    context.addLine(to: CGPoint(x: 446, y: 622))
    context.closePath()
    context.fillPath()

    let red = NSColor(srgbRed: 1, green: 0.32, blue: 0.36, alpha: 1).cgColor
    context.setStrokeColor(red)
    context.setLineWidth(64)
    context.setLineCap(.round)
    context.strokeEllipse(in: CGRect(x: 192, y: 192, width: 640, height: 640))
    context.move(to: CGPoint(x: 286, y: 738))
    context.addLine(to: CGPoint(x: 738, y: 286))
    context.strokePath()
}

let types = [16: ["icp4", "ic11"], 32: ["icp5", "ic12"], 128: ["ic07", "ic13"],
             256: ["ic08", "ic14"], 512: ["ic09", "ic10"]]
for size in [16, 32, 128, 256, 512] {
    for scale in [1, 2] {
        let pixels = size * scale
        let bitmap = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: pixels, pixelsHigh: pixels,
                                      bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
                                      colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)
        let context = NSGraphicsContext.current!.cgContext
        context.scaleBy(x: CGFloat(pixels) / 1024, y: CGFloat(pixels) / 1024)
        drawIcon(in: context)
        NSGraphicsContext.restoreGraphicsState()
        let suffix = scale == 2 ? "@2x" : ""
        let png = bitmap.representation(using: .png, properties: [:])!
        try png.write(to: directory.appendingPathComponent("icon_\(size)x\(size)\(suffix).png"))
        // Modern ICNS entries contain PNG data. Write the container directly so the
        // build also works where iconutil's image conversion service is unavailable.
        chunks.append(Data(types[size]![scale - 1].utf8))
        chunks.append(bigEndian(png.count + 8))
        chunks.append(png)
    }
}
var icon = Data("icns".utf8)
icon.append(bigEndian(chunks.count + 8))
icon.append(chunks)
try icon.write(to: directory.deletingLastPathComponent().appendingPathComponent("AppIcon.icns"))
