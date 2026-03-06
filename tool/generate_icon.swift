import Cocoa

let size = 1024
let bgColor = NSColor(red: 0x2E/255.0, green: 0x1A/255.0, blue: 0x0E/255.0, alpha: 1.0)
let ringColor = NSColor(red: 0xC8/255.0, green: 0x9B/255.0, blue: 0x5E/255.0, alpha: 1.0)
let textColor = NSColor(red: 0xF5/255.0, green: 0xD6/255.0, blue: 0xA8/255.0, alpha: 1.0)

let rep = NSBitmapImageRep(
    bitmapDataPlanes: nil,
    pixelsWide: size, pixelsHigh: size,
    bitsPerSample: 8, samplesPerPixel: 4,
    hasAlpha: true, isPlanar: false,
    colorSpaceName: .deviceRGB,
    bytesPerRow: size * 4,
    bitsPerPixel: 32
)!

NSGraphicsContext.saveGraphicsState()
let ctx = NSGraphicsContext(bitmapImageRep: rep)!
NSGraphicsContext.current = ctx
let g = ctx.cgContext

// Background
g.setFillColor(bgColor.cgColor)
g.fill(CGRect(x: 0, y: 0, width: size, height: size))

// Outer circle (filled)
let cx = CGFloat(size) / 2
let cy = CGFloat(size) / 2
let outerR: CGFloat = CGFloat(size) * 0.42
let innerR: CGFloat = CGFloat(size) * 0.38

g.setFillColor(ringColor.cgColor)
g.fillEllipse(in: CGRect(x: cx - outerR, y: cy - outerR, width: outerR * 2, height: outerR * 2))

// Inner circle (cut out with background)
g.setFillColor(bgColor.cgColor)
g.fillEllipse(in: CGRect(x: cx - innerR, y: cy - innerR, width: innerR * 2, height: innerR * 2))

// Draw "暗棋" text centered
let fontSize: CGFloat = 260
let font = NSFont(name: "PingFangTC-Semibold", size: fontSize)
    ?? NSFont(name: "STHeitiTC-Medium", size: fontSize)
    ?? NSFont.systemFont(ofSize: fontSize, weight: .semibold)

let paragraphStyle = NSMutableParagraphStyle()
paragraphStyle.alignment = .center

let attrs: [NSAttributedString.Key: Any] = [
    .font: font,
    .foregroundColor: textColor,
    .paragraphStyle: paragraphStyle,
]

let text: NSString = "暗棋"
let textSize = text.size(withAttributes: attrs)
let textRect = CGRect(
    x: (CGFloat(size) - textSize.width) / 2,
    y: (CGFloat(size) - textSize.height) / 2,
    width: textSize.width,
    height: textSize.height
)
text.draw(in: textRect, withAttributes: attrs)

NSGraphicsContext.restoreGraphicsState()

// Save PNG
let pngData = rep.representation(using: .png, properties: [:])!
let basePath = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "."

let iconURL = URL(fileURLWithPath: "\(basePath)/assets/icon/app_icon.png")
try! pngData.write(to: iconURL)
print("Generated app_icon.png (\(pngData.count) bytes)")

let fgURL = URL(fileURLWithPath: "\(basePath)/assets/icon/app_icon_foreground.png")
try! pngData.write(to: fgURL)
print("Generated app_icon_foreground.png")
