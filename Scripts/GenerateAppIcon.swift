import AppKit
import Foundation

let size = 1024
let canvas = NSImage(size: NSSize(width: size, height: size))
canvas.lockFocus()
guard let context = NSGraphicsContext.current?.cgContext else { fatalError("No graphics context") }
context.setAllowsAntialiasing(true)
context.setShouldAntialias(true)

let bounds = CGRect(x: 0, y: 0, width: size, height: size)
let background = NSBezierPath(roundedRect: bounds.insetBy(dx: 8, dy: 8), xRadius: 220, yRadius: 220)
let bg = NSGradient(colors: [NSColor(calibratedRed: 0.025, green: 0.10, blue: 0.22, alpha: 1), NSColor(calibratedRed: 0.015, green: 0.035, blue: 0.12, alpha: 1), NSColor(calibratedRed: 0.08, green: 0.04, blue: 0.20, alpha: 1)])!
bg.draw(in: background, angle: -45)

let ringRect = CGRect(x: 205, y: 310, width: 614, height: 614)
let ring = NSBezierPath()
ring.appendArc(withCenter: NSPoint(x: 512, y: 617), radius: 292, startAngle: 205, endAngle: 510)
ring.lineWidth = 24
ring.lineCapStyle = .round
let ringGradient = NSGradient(colors: [NSColor(calibratedRed: 0.12, green: 0.94, blue: 0.83, alpha: 1), NSColor(calibratedRed: 0.16, green: 0.55, blue: 1, alpha: 1), NSColor(calibratedRed: 0.62, green: 0.28, blue: 0.98, alpha: 1)])!
ringGradient.draw(in: ring, angle: 0)

let heart = NSBezierPath()
heart.move(to: NSPoint(x: 512, y: 405))
heart.curve(to: NSPoint(x: 512, y: 790), controlPoint1: NSPoint(x: 420, y: 480), controlPoint2: NSPoint(x: 270, y: 625))
heart.curve(to: NSPoint(x: 512, y: 405), controlPoint1: NSPoint(x: 755, y: 625), controlPoint2: NSPoint(x: 604, y: 480))
heart.close()
heart.lineWidth = 24
heart.lineJoinStyle = .round
NSColor(calibratedRed: 0.25, green: 0.96, blue: 0.88, alpha: 1).setStroke()
heart.stroke()

let pulse = NSBezierPath()
pulse.move(to: NSPoint(x: 280, y: 590))
pulse.line(to: NSPoint(x: 405, y: 590))
pulse.line(to: NSPoint(x: 455, y: 650))
pulse.line(to: NSPoint(x: 510, y: 485))
pulse.line(to: NSPoint(x: 565, y: 700))
pulse.line(to: NSPoint(x: 615, y: 590))
pulse.line(to: NSPoint(x: 745, y: 590))
pulse.lineWidth = 20
pulse.lineCapStyle = .round
pulse.lineJoinStyle = .round
NSColor.white.setStroke()
pulse.stroke()

let word = "VITAL" as NSString
let attrs: [NSAttributedString.Key: Any] = [
    .font: NSFont.systemFont(ofSize: 112, weight: .heavy),
    .foregroundColor: NSColor.white,
    .kern: 18
]
let textSize = word.size(withAttributes: attrs)
word.draw(at: NSPoint(x: (CGFloat(size) - textSize.width) / 2, y: 145), withAttributes: attrs)

let underline = NSBezierPath(roundedRect: CGRect(x: 300, y: 105, width: 424, height: 9), xRadius: 5, yRadius: 5)
NSGradient(colors: [NSColor(calibratedRed: 0.10, green: 0.88, blue: 0.82, alpha: 1), NSColor(calibratedRed: 0.36, green: 0.46, blue: 1, alpha: 1), NSColor(calibratedRed: 0.65, green: 0.28, blue: 0.95, alpha: 1)])!.draw(in: underline, angle: 0)

canvas.unlockFocus()
guard let tiff = canvas.tiffRepresentation,
      let bitmap = NSBitmapImageRep(data: tiff),
      let png = bitmap.representation(using: .png, properties: [:]) else {
    fatalError("Could not render app icon")
}
let output = URL(fileURLWithPath: "VITAL/Assets.xcassets/AppIcon.appiconset/AppIcon.png")
try FileManager.default.createDirectory(at: output.deletingLastPathComponent(), withIntermediateDirectories: true)
try png.write(to: output)
print("Generated \(output.path)")
