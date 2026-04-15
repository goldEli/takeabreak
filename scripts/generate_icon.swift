#!/usr/bin/swift

import AppKit
import Foundation

let arguments = CommandLine.arguments

guard arguments.count == 2 else {
    fputs("Usage: generate_icon.swift <output-iconset-dir>\n", stderr)
    exit(1)
}

let outputDirectory = URL(fileURLWithPath: arguments[1], isDirectory: true)
let fileManager = FileManager.default

try? fileManager.removeItem(at: outputDirectory)
try fileManager.createDirectory(at: outputDirectory, withIntermediateDirectories: true)

let iconSpecs: [(size: Int, name: String)] = [
    (16, "icon_16x16.png"),
    (32, "icon_16x16@2x.png"),
    (32, "icon_32x32.png"),
    (64, "icon_32x32@2x.png"),
    (128, "icon_128x128.png"),
    (256, "icon_128x128@2x.png"),
    (256, "icon_256x256.png"),
    (512, "icon_256x256@2x.png"),
    (512, "icon_512x512.png"),
    (1024, "icon_512x512@2x.png"),
]

for spec in iconSpecs {
    let image = NSImage(size: NSSize(width: spec.size, height: spec.size))
    image.lockFocus()

    guard let context = NSGraphicsContext.current?.cgContext else {
        throw NSError(domain: "TakeABreakIcon", code: 1)
    }

    let rect = CGRect(x: 0, y: 0, width: spec.size, height: spec.size)
    let cornerRadius = CGFloat(spec.size) * 0.22

    let backgroundPath = NSBezierPath(roundedRect: rect, xRadius: cornerRadius, yRadius: cornerRadius)
    backgroundPath.addClip()

    let colorSpace = CGColorSpaceCreateDeviceRGB()
    let colors = [
        NSColor(calibratedRed: 0.97, green: 0.63, blue: 0.27, alpha: 1.0).cgColor,
        NSColor(calibratedRed: 0.85, green: 0.32, blue: 0.18, alpha: 1.0).cgColor,
    ] as CFArray

    let gradient = CGGradient(
        colorsSpace: colorSpace,
        colors: colors,
        locations: [0.0, 1.0]
    )!

    context.drawLinearGradient(
        gradient,
        start: CGPoint(x: 0, y: rect.height),
        end: CGPoint(x: rect.width, y: 0),
        options: []
    )

    let inset = CGFloat(spec.size) * 0.085
    let innerRect = rect.insetBy(dx: inset, dy: inset)
    let glowColor = NSColor(calibratedWhite: 1.0, alpha: 0.18)
    context.setFillColor(glowColor.cgColor)
    context.fillEllipse(in: CGRect(
        x: innerRect.minX,
        y: innerRect.midY,
        width: innerRect.width * 0.95,
        height: innerRect.height * 0.62
    ))

    let cupScale = CGFloat(spec.size) / 1024.0
    let cupPath = NSBezierPath()
    cupPath.move(to: CGPoint(x: 252 * cupScale, y: 408 * cupScale))
    cupPath.line(to: CGPoint(x: 252 * cupScale, y: 618 * cupScale))
    cupPath.curve(
        to: CGPoint(x: 644 * cupScale, y: 618 * cupScale),
        controlPoint1: CGPoint(x: 252 * cupScale, y: 638 * cupScale),
        controlPoint2: CGPoint(x: 600 * cupScale, y: 638 * cupScale)
    )
    cupPath.line(to: CGPoint(x: 644 * cupScale, y: 408 * cupScale))
    cupPath.close()

    NSColor.white.setFill()
    cupPath.fill()

    let handlePath = NSBezierPath()
    handlePath.move(to: CGPoint(x: 650 * cupScale, y: 588 * cupScale))
    handlePath.curve(
        to: CGPoint(x: 788 * cupScale, y: 484 * cupScale),
        controlPoint1: CGPoint(x: 748 * cupScale, y: 596 * cupScale),
        controlPoint2: CGPoint(x: 804 * cupScale, y: 548 * cupScale)
    )
    handlePath.curve(
        to: CGPoint(x: 650 * cupScale, y: 440 * cupScale),
        controlPoint1: CGPoint(x: 776 * cupScale, y: 428 * cupScale),
        controlPoint2: CGPoint(x: 706 * cupScale, y: 420 * cupScale)
    )
    handlePath.lineWidth = 56 * cupScale
    handlePath.lineCapStyle = .round
    handlePath.lineJoinStyle = .round
    NSColor.white.setStroke()
    handlePath.stroke()

    let saucerPath = NSBezierPath(roundedRect: CGRect(
        x: 214 * cupScale,
        y: 336 * cupScale,
        width: 596 * cupScale,
        height: 62 * cupScale
    ), xRadius: 28 * cupScale, yRadius: 28 * cupScale)
    saucerPath.fill()

    func drawSteam(at x: CGFloat) {
        let steamPath = NSBezierPath()
        steamPath.move(to: CGPoint(x: x * cupScale, y: 708 * cupScale))
        steamPath.curve(
            to: CGPoint(x: (x + 22) * cupScale, y: 900 * cupScale),
            controlPoint1: CGPoint(x: (x - 26) * cupScale, y: 760 * cupScale),
            controlPoint2: CGPoint(x: (x + 54) * cupScale, y: 832 * cupScale)
        )
        steamPath.lineWidth = 42 * cupScale
        steamPath.lineCapStyle = .round
        NSColor.white.withAlphaComponent(0.92).setStroke()
        steamPath.stroke()
    }

    drawSteam(at: 344)
    drawSteam(at: 468)
    drawSteam(at: 592)

    let badgeRect = CGRect(
        x: 164 * cupScale,
        y: 158 * cupScale,
        width: 250 * cupScale,
        height: 132 * cupScale
    )
    let badgePath = NSBezierPath(roundedRect: badgeRect, xRadius: 58 * cupScale, yRadius: 58 * cupScale)
    NSColor(calibratedWhite: 0.08, alpha: 0.18).setFill()
    badgePath.fill()

    let paragraph = NSMutableParagraphStyle()
    paragraph.alignment = .center
    let attributes: [NSAttributedString.Key: Any] = [
        .font: NSFont.systemFont(ofSize: 92 * cupScale, weight: .bold),
        .foregroundColor: NSColor.white,
        .paragraphStyle: paragraph,
    ]
    let badgeText = NSAttributedString(string: "TB", attributes: attributes)
    let badgeTextRect = CGRect(
        x: badgeRect.minX,
        y: badgeRect.minY + 16 * cupScale,
        width: badgeRect.width,
        height: badgeRect.height
    )
    badgeText.draw(in: badgeTextRect)

    image.unlockFocus()

    guard
        let tiffData = image.tiffRepresentation,
        let bitmap = NSBitmapImageRep(data: tiffData),
        let pngData = bitmap.representation(using: .png, properties: [:])
    else {
        throw NSError(domain: "TakeABreakIcon", code: 2)
    }

    try pngData.write(to: outputDirectory.appendingPathComponent(spec.name))
}
