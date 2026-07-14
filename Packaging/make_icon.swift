// Generates Packaging/AppIcon.icns without Xcode asset tooling.
// Run from the repo root:  swift Packaging/make_icon.swift
// Renders the icon procedurally at every size Apple requires, writes an
// .iconset, and compiles it with iconutil (ships with macOS).

import AppKit
import Foundation

// Deterministic RNG (splitmix64) so the grain is identical on every run.
struct SeededRandom {
    var state: UInt64
    mutating func next() -> Double {
        state &+= 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        z ^= z >> 31
        return Double(z >> 11) * (1.0 / 9007199254740992.0)
    }
}

func rgb(_ r: CGFloat, _ g: CGFloat, _ b: CGFloat, _ a: CGFloat = 1) -> CGColor {
    CGColor(srgbRed: r, green: g, blue: b, alpha: a)
}

func drawIcon(in ctx: CGContext, size s: CGFloat) {
    // 1. Squircle background, warm brown gradient.
    let margin = s * 0.09
    let bg = CGRect(x: margin, y: margin, width: s - 2 * margin, height: s - 2 * margin)
    let bgPath = CGPath(roundedRect: bg, cornerWidth: bg.width * 0.225,
                        cornerHeight: bg.width * 0.225, transform: nil)
    ctx.saveGState()
    ctx.addPath(bgPath)
    ctx.clip()
    let bgColors = [rgb(0.58, 0.46, 0.32), rgb(0.42, 0.32, 0.21)] as CFArray
    let space = CGColorSpace(name: CGColorSpace.sRGB)!
    let bgGradient = CGGradient(colorsSpace: space, colors: bgColors, locations: [0, 1])!
    ctx.drawLinearGradient(bgGradient,
                           start: CGPoint(x: bg.midX, y: bg.maxY),
                           end: CGPoint(x: bg.midX, y: bg.minY),
                           options: [])
    ctx.restoreGState()

    // 2. Paper sheet with a folded top-right corner, soft drop shadow.
    let sheetW = s * 0.50
    let sheetH = s * 0.60
    let sheet = CGRect(x: (s - sheetW) / 2, y: (s - sheetH) / 2, width: sheetW, height: sheetH)
    let fold = sheetW * 0.26

    let page = CGMutablePath()
    page.move(to: CGPoint(x: sheet.minX, y: sheet.minY))
    page.addLine(to: CGPoint(x: sheet.maxX, y: sheet.minY))
    page.addLine(to: CGPoint(x: sheet.maxX, y: sheet.maxY - fold))
    page.addLine(to: CGPoint(x: sheet.maxX - fold, y: sheet.maxY))
    page.addLine(to: CGPoint(x: sheet.minX, y: sheet.maxY))
    page.closeSubpath()

    ctx.saveGState()
    ctx.setShadow(offset: CGSize(width: 0, height: -s * 0.012),
                  blur: s * 0.03, color: rgb(0, 0, 0, 0.35))
    ctx.addPath(page)
    ctx.setFillColor(rgb(0.965, 0.945, 0.90))
    ctx.fillPath()
    ctx.restoreGState()

    // 3. Grain speckle, clipped to the sheet.
    ctx.saveGState()
    ctx.addPath(page)
    ctx.clip()
    var rng = SeededRandom(state: 42)
    let dotBase = max(1.0, s / 512)
    let count = Int((sheetW * sheetH) / (dotBase * dotBase * 22))
    for _ in 0..<count {
        let x = sheet.minX + CGFloat(rng.next()) * sheetW
        let y = sheet.minY + CGFloat(rng.next()) * sheetH
        let shade = CGFloat(0.30 + rng.next() * 0.25)
        let alpha = CGFloat(0.05 + rng.next() * 0.10)
        let d = dotBase * CGFloat(0.6 + rng.next() * 1.3)
        ctx.setFillColor(rgb(shade * 1.05, shade * 0.92, shade * 0.72, alpha))
        ctx.fillEllipse(in: CGRect(x: x, y: y, width: d, height: d))
    }
    ctx.restoreGState()

    // 4. Folded flap (darker triangle pointing inward).
    let flap = CGMutablePath()
    flap.move(to: CGPoint(x: sheet.maxX - fold, y: sheet.maxY))
    flap.addLine(to: CGPoint(x: sheet.maxX, y: sheet.maxY - fold))
    flap.addLine(to: CGPoint(x: sheet.maxX - fold, y: sheet.maxY - fold))
    flap.closeSubpath()
    ctx.saveGState()
    ctx.setShadow(offset: CGSize(width: 0, height: -s * 0.006),
                  blur: s * 0.015, color: rgb(0, 0, 0, 0.3))
    ctx.addPath(flap)
    ctx.setFillColor(rgb(0.88, 0.845, 0.77))
    ctx.fillPath()
    ctx.restoreGState()

    // 5. Faint text lines.
    ctx.setFillColor(rgb(0.78, 0.71, 0.58))
    let lineH = sheetH * 0.045
    let lineX = sheet.minX + sheetW * 0.14
    let widths: [CGFloat] = [0.58, 0.72, 0.66, 0.44]
    for (i, w) in widths.enumerated() {
        let y = sheet.maxY - fold - sheetH * 0.14 - CGFloat(i) * sheetH * 0.13
        let line = CGRect(x: lineX, y: y, width: sheetW * w, height: lineH)
        ctx.addPath(CGPath(roundedRect: line, cornerWidth: lineH / 2,
                           cornerHeight: lineH / 2, transform: nil))
        ctx.fillPath()
    }
}

func renderPNG(pixels: Int, to url: URL) {
    let space = CGColorSpace(name: CGColorSpace.sRGB)!
    let ctx = CGContext(data: nil, width: pixels, height: pixels,
                        bitsPerComponent: 8, bytesPerRow: 0, space: space,
                        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
    drawIcon(in: ctx, size: CGFloat(pixels))
    let image = ctx.makeImage()!
    let rep = NSBitmapImageRep(cgImage: image)
    try! rep.representation(using: .png, properties: [:])!.write(to: url)
}

let fm = FileManager.default
let packagingDir = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
let iconset = packagingDir.appendingPathComponent("AppIcon.iconset")
try? fm.removeItem(at: iconset)
try! fm.createDirectory(at: iconset, withIntermediateDirectories: true)

for base in [16, 32, 128, 256, 512] {
    renderPNG(pixels: base, to: iconset.appendingPathComponent("icon_\(base)x\(base).png"))
    renderPNG(pixels: base * 2, to: iconset.appendingPathComponent("icon_\(base)x\(base)@2x.png"))
}

let icns = packagingDir.appendingPathComponent("AppIcon.icns")
let task = Process()
task.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
task.arguments = ["-c", "icns", iconset.path, "-o", icns.path]
try! task.run()
task.waitUntilExit()
guard task.terminationStatus == 0 else {
    fatalError("iconutil failed with status \(task.terminationStatus)")
}
try? fm.removeItem(at: iconset)
print("Wrote \(icns.path)")
