import AppKit
import CoreGraphics

// Renders Tallhagen's original app icon: full-bleed teal, soft decorative circles,
// and a white card with seven countable dots (3 teal + 3 orange + 1 purple).
// Not part of any Xcode target. Regenerate the icon on a Mac with:
//   swiftc -O Tools/MakeIcon.swift -o /tmp/makeicon
//   /tmp/makeicon Tallhagen/Assets.xcassets/AppIcon.appiconset/AppIcon.png
let size = 1024
let colorSpace = CGColorSpace(name: CGColorSpace.sRGB)!
let context = CGContext(
    data: nil, width: size, height: size, bitsPerComponent: 8, bytesPerRow: 0,
    space: colorSpace, bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
)!

func rgb(_ r: CGFloat, _ g: CGFloat, _ b: CGFloat) -> CGColor {
    CGColor(colorSpace: colorSpace, components: [r, g, b, 1])!
}
let teal = rgb(0.0, 0.48, 0.44)
let tealLight = rgb(0.56, 0.78, 0.76)
let orange = rgb(0.80, 0.36, 0.14)
let orangeSoft = rgb(0.93, 0.52, 0.34)
let purple = rgb(0.47, 0.34, 0.74)
let yellow = rgb(0.98, 0.77, 0.32)
let paper = rgb(0.985, 0.98, 0.955)
let white = rgb(1, 1, 1)

// Background.
context.setFillColor(teal)
context.fill(CGRect(x: 0, y: 0, width: size, height: size))

// Decorative circles, partly off the edges (masked by iOS, so nothing important sits in corners).
func circle(_ cx: CGFloat, _ cy: CGFloat, _ r: CGFloat, _ color: CGColor) {
    context.setFillColor(color)
    context.fillEllipse(in: CGRect(x: cx - r, y: cy - r, width: 2 * r, height: 2 * r))
}
circle(180, 820, 150, yellow)
circle(850, 870, 120, tealLight)
circle(830, 190, 160, orangeSoft)

// White card.
let card = CGRect(x: 192, y: 232, width: 640, height: 560)
let cardPath = CGPath(roundedRect: card, cornerWidth: 96, cornerHeight: 96, transform: nil)
context.addPath(cardPath)
context.setFillColor(paper)
context.fillPath()

// Seven dots in rows of three, centred: 3 teal, 3 orange, 1 purple.
let dotRadius: CGFloat = 52
let spacing: CGFloat = 150
let centerX: CGFloat = 512
let rows: [(count: Int, color: CGColor, y: CGFloat)] = [
    (3, teal, 648), (3, orange, 512), (1, purple, 376),
]
for row in rows {
    let totalWidth = CGFloat(row.count - 1) * spacing
    for index in 0..<row.count {
        let x = centerX - totalWidth / 2 + CGFloat(index) * spacing
        circle(x, row.y, dotRadius, row.color)
        // Small highlight so the dots read as beads.
        context.setStrokeColor(white)
        context.setLineWidth(9)
        context.setLineCap(.round)
        let highlight = CGMutablePath()
        highlight.addArc(center: CGPoint(x: x, y: row.y), radius: dotRadius - 20,
                         startAngle: .pi * 0.62, endAngle: .pi * 0.38, clockwise: true)
        context.addPath(highlight)
        context.strokePath()
    }
}

let image = context.makeImage()!
let rep = NSBitmapImageRep(cgImage: image)
let data = rep.representation(using: .png, properties: [:])!
let output = URL(fileURLWithPath: CommandLine.arguments[1])
try! data.write(to: output)
print("wrote \(output.path)")
