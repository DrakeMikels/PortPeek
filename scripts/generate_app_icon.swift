#!/usr/bin/env swift

import AppKit
import Foundation

let args = CommandLine.arguments

guard args.count == 2 else {
    FileHandle.standardError.write(Data("Usage: generate_app_icon.swift <output_png_path>\n".utf8))
    exit(1)
}

let outputPath = args[1]
let size = 1024
let canvas = NSSize(width: size, height: size)

guard let bitmap = NSBitmapImageRep(
    bitmapDataPlanes: nil,
    pixelsWide: size,
    pixelsHigh: size,
    bitsPerSample: 8,
    samplesPerPixel: 4,
    hasAlpha: true,
    isPlanar: false,
    colorSpaceName: .deviceRGB,
    bitmapFormat: [],
    bytesPerRow: 0,
    bitsPerPixel: 0
) else {
    FileHandle.standardError.write(Data("Unable to create bitmap context\n".utf8))
    exit(1)
}

guard let context = NSGraphicsContext(bitmapImageRep: bitmap) else {
    FileHandle.standardError.write(Data("Unable to create graphics context\n".utf8))
    exit(1)
}

NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = context

let frame = NSRect(origin: .zero, size: canvas)

// Base gradient.
let background = NSGradient(colors: [
    NSColor(calibratedRed: 0.04, green: 0.08, blue: 0.13, alpha: 1.0),
    NSColor(calibratedRed: 0.08, green: 0.18, blue: 0.30, alpha: 1.0)
])!
background.draw(in: frame, angle: -90)

// Subtle highlight.
let glowRect = NSRect(x: 120, y: 500, width: 784, height: 420)
let glowPath = NSBezierPath(roundedRect: glowRect, xRadius: 180, yRadius: 180)
NSColor(calibratedRed: 0.20, green: 0.50, blue: 0.75, alpha: 0.24).setFill()
glowPath.fill()

let center = NSPoint(x: 512, y: 526)
let ringColor = NSColor(calibratedRed: 0.38, green: 0.86, blue: 0.98, alpha: 0.92)
let radii: [CGFloat] = [170, 255, 340]

for radius in radii {
    let rect = NSRect(
        x: center.x - radius,
        y: center.y - radius,
        width: radius * 2,
        height: radius * 2
    )
    let ring = NSBezierPath(ovalIn: rect)
    ring.lineWidth = 18
    ringColor.withAlphaComponent(0.85 - (radius / 500)).setStroke()
    ring.stroke()
}

// Port body.
let portRect = NSRect(x: 328, y: 322, width: 368, height: 260)
let portBody = NSBezierPath(roundedRect: portRect, xRadius: 78, yRadius: 78)
let portGradient = NSGradient(colors: [
    NSColor(calibratedRed: 0.56, green: 0.94, blue: 0.99, alpha: 1.0),
    NSColor(calibratedRed: 0.33, green: 0.78, blue: 0.95, alpha: 1.0)
])!
portGradient.draw(in: portBody, angle: -90)

// Port opening.
let inset = portRect.insetBy(dx: 44, dy: 56)
let openingRect = NSRect(x: inset.minX, y: inset.minY + 6, width: inset.width, height: inset.height - 40)
let opening = NSBezierPath(roundedRect: openingRect, xRadius: 42, yRadius: 42)
NSColor(calibratedRed: 0.06, green: 0.12, blue: 0.18, alpha: 1.0).setFill()
opening.fill()

// Pins.
let pinSize = NSSize(width: 46, height: 18)
let pinY = openingRect.minY + 22
let leftPin = NSRect(x: openingRect.midX - 72, y: pinY, width: pinSize.width, height: pinSize.height)
let rightPin = NSRect(x: openingRect.midX + 26, y: pinY, width: pinSize.width, height: pinSize.height)
NSColor(calibratedRed: 0.57, green: 0.89, blue: 0.99, alpha: 1.0).setFill()
NSBezierPath(roundedRect: leftPin, xRadius: 6, yRadius: 6).fill()
NSBezierPath(roundedRect: rightPin, xRadius: 6, yRadius: 6).fill()

// Active status dot.
let dotRect = NSRect(x: 716, y: 720, width: 134, height: 134)
let dot = NSBezierPath(ovalIn: dotRect)
NSColor(calibratedRed: 0.36, green: 0.99, blue: 0.64, alpha: 1.0).setFill()
dot.fill()
let dotInnerRect = dotRect.insetBy(dx: 28, dy: 28)
NSColor(calibratedRed: 0.12, green: 0.40, blue: 0.22, alpha: 0.45).setFill()
NSBezierPath(ovalIn: dotInnerRect).fill()

context.flushGraphics()
NSGraphicsContext.restoreGraphicsState()

guard let pngData = bitmap.representation(using: .png, properties: [:]) else {
    FileHandle.standardError.write(Data("Unable to encode PNG\n".utf8))
    exit(1)
}

do {
    try pngData.write(to: URL(fileURLWithPath: outputPath))
    print("Wrote icon: \(outputPath)")
} catch {
    FileHandle.standardError.write(Data("Failed to write PNG: \(error)\n".utf8))
    exit(1)
}
