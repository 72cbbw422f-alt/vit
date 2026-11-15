import AppKit
import Foundation

// VITAL's production icon: one unmistakable heart/ECG mark on a deep navy field.
// Keep the artwork inside the safe area; iOS applies the rounded mask itself.
let size = 1024
let image = NSImage(size: NSSize(width: size, height: size))
image.lockFocus()
guard let context = NSGraphicsContext.current?.cgContext else { fatalError("No graphics context") }
context.setAllowsAntialiasing(true)
context.setShouldAntialias(true)
let bounds = CGRect(x: 0, y: 0, width: size, height: size)
let background = NSGradient(colors: [
    NSColor(calibratedRed: 0.055, green: 0.095, blue: 0.19, alpha: 1),
    NSColor(calibratedRed: 0.035, green: 0.055, blue: 0.14, alpha: 1)
])!
background.draw(in: NSBezierPath(rect: bounds), angle: -45)

// Soft ambient halo behind the symbol.
context.saveGState()
context.setShadow(offset: .zero, blur: 54, color: NSColor(calibratedRed: 0.12, green: 0.82, blue: 0.78, alpha: 0.22).cgColor)
let halo = NSBezierPath(ovalIn: CGRect(x: 205, y: 205, width: 614, height: 614))
NSColor(calibratedRed: 0.08, green: 0.35, blue: 0.43, alpha: 0.16).setFill()
halo.fill()
context.restoreGState()

// Continuous heart outline, deliberately simple and legible at small sizes.
let heart = NSBezierPath()
heart.move(to: NSPoint(x: 512, y: 260))
heart.curve(to: NSPoint(x: 512, y: 760), controlPoint1: NSPoint(x: 250, y: 470), controlPoint2: NSPoint(x: 300, y: 690))
heart.curve(to: NSPoint(x: 512, y: 260), controlPoint1: NSPoint(x: 724, y: 690), controlPoint2: NSPoint(x: 774, y: 470))
heart.lineWidth = 34
heart.lineJoinStyle = .round
heart.lineCapStyle = .round
let teal = NSColor(calibratedRed: 0.43, green: 0.88, blue: 0.83, alpha: 1)
teal.setStroke()
heart.stroke()

// ECG pulse forms the central identity mark.
let pulse = NSBezierPath()
pulse.move(to: NSPoint(x: 275, y: 505))
pulse.line(to: NSPoint(x: 405, y: 505))
pulse.line(to: NSPoint(x: 458, y: 570))
pulse.line(to: NSPoint(x: 520, y: 405))
pulse.line(to: NSPoint(x: 578, y: 620))
pulse.line(to: NSPoint(x: 625, y: 505))
pulse.line(to: NSPoint(x: 748, y: 505))
pulse.lineWidth = 31
pulse.lineCapStyle = .round
pulse.lineJoinStyle = .round
NSColor(calibratedRed: 0.58, green: 0.96, blue: 0.91, alpha: 1).setStroke()
pulse.stroke()

image.unlockFocus()
guard let tiff = image.tiffRepresentation,
      let bitmap = NSBitmapImageRep(data: tiff),
      let png = bitmap.representation(using: .png, properties: [:]) else {
    fatalError("Could not render app icon")
}
let output = URL(fileURLWithPath: "VITAL/Assets.xcassets/AppIcon.appiconset/AppIcon.png")
try FileManager.default.createDirectory(at: output.deletingLastPathComponent(), withIntermediateDirectories: true)
try png.write(to: output)
print("Generated (output.path)")
