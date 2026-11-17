import AppKit
import Foundation

// VITAL app icon — Midnight identity: luminous lime ring, heart and ECG pulse.
let size = 1024
let image = NSImage(size: NSSize(width: size, height: size))
image.lockFocus()
guard let context = NSGraphicsContext.current?.cgContext else { fatalError("No graphics context") }
context.setAllowsAntialiasing(true)
context.setShouldAntialias(true)

let bounds = CGRect(x: 0, y: 0, width: size, height: size)
let background = NSGradient(colors: [
    NSColor(calibratedRed: 0.055, green: 0.090, blue: 0.165, alpha: 1),
    NSColor(calibratedRed: 0.025, green: 0.045, blue: 0.095, alpha: 1)
])!
background.draw(in: NSBezierPath(rect: bounds), angle: -45)

// Subtle layered midnight waves along the lower edge.
let waveOne = NSBezierPath()
waveOne.move(to: NSPoint(x: 0, y: 0))
waveOne.line(to: NSPoint(x: 0, y: 190))
waveOne.curve(to: NSPoint(x: 1024, y: 115), controlPoint1: NSPoint(x: 300, y: 95), controlPoint2: NSPoint(x: 700, y: 245))
waveOne.line(to: NSPoint(x: 1024, y: 0))
waveOne.close()
NSColor(calibratedRed: 0.10, green: 0.19, blue: 0.29, alpha: 0.34).setFill()
waveOne.fill()

let lime = NSColor(calibratedRed: 0.70, green: 0.94, blue: 0.28, alpha: 1)
let glow = NSColor(calibratedRed: 0.63, green: 0.96, blue: 0.20, alpha: 0.28)

// Soft halo.
context.saveGState()
context.setShadow(offset: .zero, blur: 70, color: glow.cgColor)
let halo = NSBezierPath(ovalIn: CGRect(x: 205, y: 205, width: 614, height: 614))
NSColor(calibratedRed: 0.25, green: 0.42, blue: 0.12, alpha: 0.12).setFill()
halo.fill()
context.restoreGState()

// Open circular arc around the heart.
let ring = NSBezierPath()
ring.appendArc(withCenter: NSPoint(x: 512, y: 512), radius: 350, startAngle: 42, endAngle: 318, clockwise: false)
ring.lineWidth = 25
ring.lineCapStyle = .round
context.saveGState()
context.setShadow(offset: .zero, blur: 24, color: glow.cgColor)
lime.setStroke()
ring.stroke()
context.restoreGState()

// Heart outline.
let heart = NSBezierPath()
heart.move(to: NSPoint(x: 512, y: 315))
heart.curve(to: NSPoint(x: 512, y: 735), controlPoint1: NSPoint(x: 280, y: 470), controlPoint2: NSPoint(x: 300, y: 655))
heart.curve(to: NSPoint(x: 512, y: 315), controlPoint1: NSPoint(x: 724, y: 655), controlPoint2: NSPoint(x: 744, y: 470))
heart.lineWidth = 29
heart.lineJoinStyle = .round
heart.lineCapStyle = .round
context.saveGState()
context.setShadow(offset: .zero, blur: 22, color: glow.cgColor)
lime.setStroke()
heart.stroke()
context.restoreGState()

// ECG pulse across the center of the heart.
let pulse = NSBezierPath()
pulse.move(to: NSPoint(x: 300, y: 515))
pulse.line(to: NSPoint(x: 415, y: 515))
pulse.line(to: NSPoint(x: 463, y: 575))
pulse.line(to: NSPoint(x: 520, y: 425))
pulse.line(to: NSPoint(x: 575, y: 615))
pulse.line(to: NSPoint(x: 625, y: 515))
pulse.line(to: NSPoint(x: 724, y: 515))
pulse.lineWidth = 27
pulse.lineCapStyle = .round
pulse.lineJoinStyle = .round
context.saveGState()
context.setShadow(offset: .zero, blur: 18, color: glow.cgColor)
NSColor(calibratedRed: 0.83, green: 1.0, blue: 0.54, alpha: 1).setStroke()
pulse.stroke()
context.restoreGState()

image.unlockFocus()
guard let tiff = image.tiffRepresentation,
      let bitmap = NSBitmapImageRep(data: tiff),
      let png = bitmap.representation(using: .png, properties: [:]) else {
    fatalError("Could not render app icon")
}
let output = URL(fileURLWithPath: "VITAL/Assets.xcassets/AppIcon.appiconset/AppIcon.png")
try FileManager.default.createDirectory(at: output.deletingLastPathComponent(), withIntermediateDirectories: true)
try png.write(to: output)
print("Generated \(output.path)")
