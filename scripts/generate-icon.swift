import AppKit
import Foundation

struct Palette {
    static let inkTop = NSColor(calibratedRed: 0.05, green: 0.12, blue: 0.16, alpha: 1.0)
    static let inkBottom = NSColor(calibratedRed: 0.09, green: 0.22, blue: 0.28, alpha: 1.0)
    static let coral = NSColor(calibratedRed: 1.0, green: 0.45, blue: 0.36, alpha: 1.0)
    static let coralGlow = NSColor(calibratedRed: 1.0, green: 0.61, blue: 0.45, alpha: 0.65)
    static let mint = NSColor(calibratedRed: 0.35, green: 0.92, blue: 0.81, alpha: 1.0)
    static let mintGlow = NSColor(calibratedRed: 0.48, green: 0.97, blue: 0.90, alpha: 0.45)
    static let parchment = NSColor(calibratedRed: 0.97, green: 0.93, blue: 0.84, alpha: 1.0)
    static let textOnCard = NSColor(calibratedRed: 0.10, green: 0.18, blue: 0.20, alpha: 0.88)
    static let frame = NSColor(calibratedRed: 1.0, green: 1.0, blue: 1.0, alpha: 0.10)
}

let outputDirectory = URL(fileURLWithPath: CommandLine.arguments.dropFirst().first ?? "", isDirectory: true)
guard !outputDirectory.path.isEmpty else {
    fputs("Usage: swift generate-icon.swift <iconset-output-dir>\n", stderr)
    exit(1)
}

try? FileManager.default.createDirectory(at: outputDirectory, withIntermediateDirectories: true)

let iconSizes: [(String, Int)] = [
    ("icon_16x16.png", 16),
    ("icon_16x16@2x.png", 32),
    ("icon_32x32.png", 32),
    ("icon_32x32@2x.png", 64),
    ("icon_128x128.png", 128),
    ("icon_128x128@2x.png", 256),
    ("icon_256x256.png", 256),
    ("icon_256x256@2x.png", 512),
    ("icon_512x512.png", 512),
    ("icon_512x512@2x.png", 1024),
]

func roundedCardPath(_ rect: NSRect, radius: CGFloat) -> NSBezierPath {
    NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius)
}

func fillGlow(at center: CGPoint, diameter: CGFloat, color: NSColor) {
    let glowRect = NSRect(
        x: center.x - diameter / 2,
        y: center.y - diameter / 2,
        width: diameter,
        height: diameter
    )
    let gradient = NSGradient(colors: [color, color.withAlphaComponent(0.0)])!
    gradient.draw(in: NSBezierPath(ovalIn: glowRect), relativeCenterPosition: .zero)
}

func drawCaptionBars(in rect: NSRect, alignment: NSTextAlignment, widthScale: CGFloat) {
    let barHeight = max(2, rect.height * 0.13)
    let spacing = barHeight * 0.9
    let y1 = rect.minY + rect.height * 0.56
    let y2 = y1 - spacing - barHeight
    let widths = [rect.width * widthScale, rect.width * (widthScale - 0.18)]

    for (index, width) in widths.enumerated() {
        let x: CGFloat
        switch alignment {
        case .right:
            x = rect.maxX - width
        case .center:
            x = rect.midX - width / 2
        default:
            x = rect.minX
        }

        let barRect = NSRect(
            x: x,
            y: index == 0 ? y1 : y2,
            width: width,
            height: barHeight
        )
        let barPath = roundedCardPath(barRect, radius: barHeight / 2)
        Palette.textOnCard.setFill()
        barPath.fill()
    }
}

func drawArrow(from start: CGPoint, to end: CGPoint, lineWidth: CGFloat) {
    let path = NSBezierPath()
    path.move(to: start)
    path.curve(
        to: end,
        controlPoint1: CGPoint(x: start.x + (end.x - start.x) * 0.55, y: start.y + lineWidth * 2.6),
        controlPoint2: CGPoint(x: start.x + (end.x - start.x) * 0.60, y: end.y - lineWidth * 2.2)
    )
    path.lineWidth = lineWidth
    path.lineCapStyle = .round
    path.lineJoinStyle = .round

    let shadow = NSShadow()
    shadow.shadowColor = Palette.parchment.withAlphaComponent(0.24)
    shadow.shadowBlurRadius = lineWidth * 1.8
    shadow.shadowOffset = NSSize(width: 0, height: 0)
    shadow.set()

    Palette.parchment.setStroke()
    path.stroke()

    let dx = end.x - start.x
    let dy = end.y - start.y
    let angle = atan2(dy, dx)
    let arrowSize = lineWidth * 2.6

    let arrowPath = NSBezierPath()
    arrowPath.move(to: end)
    arrowPath.line(to: CGPoint(
        x: end.x - cos(angle - .pi / 6) * arrowSize,
        y: end.y - sin(angle - .pi / 6) * arrowSize
    ))
    arrowPath.move(to: end)
    arrowPath.line(to: CGPoint(
        x: end.x - cos(angle + .pi / 6) * arrowSize,
        y: end.y - sin(angle + .pi / 6) * arrowSize
    ))
    arrowPath.lineWidth = lineWidth
    arrowPath.lineCapStyle = .round
    arrowPath.stroke()

    NSGraphicsContext.current?.restoreGraphicsState()
}

func drawIcon(size: CGFloat) -> NSImage {
    let image = NSImage(size: NSSize(width: size, height: size))
    image.lockFocus()
    defer { image.unlockFocus() }

    guard let context = NSGraphicsContext.current?.cgContext else { return image }
    context.setAllowsAntialiasing(true)
    context.setShouldAntialias(true)

    let inset = size * 0.03
    let canvas = NSRect(x: inset, y: inset, width: size - inset * 2, height: size - inset * 2)
    let clipPath = roundedCardPath(canvas, radius: size * 0.225)
    clipPath.addClip()

    let background = NSGradient(colors: [Palette.inkTop, Palette.inkBottom])!
    background.draw(in: clipPath, angle: -52)

    fillGlow(at: CGPoint(x: size * 0.28, y: size * 0.78), diameter: size * 0.60, color: Palette.coralGlow)
    fillGlow(at: CGPoint(x: size * 0.78, y: size * 0.24), diameter: size * 0.58, color: Palette.mintGlow)

    let backShadow = NSShadow()
    backShadow.shadowColor = NSColor.black.withAlphaComponent(0.22)
    backShadow.shadowBlurRadius = size * 0.05
    backShadow.shadowOffset = NSSize(width: 0, height: -size * 0.018)

    let upperCard = NSRect(x: size * 0.34, y: size * 0.53, width: size * 0.43, height: size * 0.20)
    let lowerCard = NSRect(x: size * 0.18, y: size * 0.27, width: size * 0.47, height: size * 0.22)

    NSGraphicsContext.saveGraphicsState()
    backShadow.set()
    let upperPath = roundedCardPath(upperCard, radius: size * 0.075)
    Palette.mint.setFill()
    upperPath.fill()
    NSGraphicsContext.restoreGraphicsState()

    NSGraphicsContext.saveGraphicsState()
    backShadow.set()
    let lowerPath = roundedCardPath(lowerCard, radius: size * 0.08)
    Palette.coral.setFill()
    lowerPath.fill()
    NSGraphicsContext.restoreGraphicsState()

    drawCaptionBars(
        in: upperCard.insetBy(dx: size * 0.055, dy: size * 0.038),
        alignment: .right,
        widthScale: 0.70
    )
    drawCaptionBars(
        in: lowerCard.insetBy(dx: size * 0.055, dy: size * 0.042),
        alignment: .left,
        widthScale: 0.74
    )

    let lineWidth = max(2, size * 0.038)
    NSGraphicsContext.saveGraphicsState()
    drawArrow(
        from: CGPoint(x: lowerCard.maxX - size * 0.015, y: lowerCard.maxY - size * 0.010),
        to: CGPoint(x: upperCard.minX + size * 0.03, y: upperCard.minY + size * 0.045),
        lineWidth: lineWidth
    )

    let sparkRect = NSRect(x: size * 0.47, y: size * 0.45, width: size * 0.09, height: size * 0.09)
    Palette.parchment.withAlphaComponent(0.95).setFill()
    NSBezierPath(ovalIn: sparkRect).fill()

    let framePath = roundedCardPath(canvas.insetBy(dx: size * 0.004, dy: size * 0.004), radius: size * 0.215)
    framePath.lineWidth = max(1, size * 0.006)
    Palette.frame.setStroke()
    framePath.stroke()

    return image
}

func pngData(for image: NSImage) -> Data? {
    guard let tiffData = image.tiffRepresentation,
          let bitmap = NSBitmapImageRep(data: tiffData) else {
        return nil
    }
    return bitmap.representation(using: .png, properties: [:])
}

for (filename, size) in iconSizes {
    let image = drawIcon(size: CGFloat(size))
    guard let data = pngData(for: image) else {
        fputs("Failed to render \(filename)\n", stderr)
        exit(1)
    }
    let url = outputDirectory.appendingPathComponent(filename)
    try data.write(to: url)
}

print("Generated iconset at \(outputDirectory.path)")
