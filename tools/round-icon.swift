// Writes a copy of a square icon with transparent rounded corners, for the browser tab icon
// (a favicon can't be rounded with CSS). The corner radius matches the hero icon: 27/120.
// Usage: swift tools/round-icon.swift <input.png> <output.png>
import AppKit

let args = CommandLine.arguments
guard args.count == 3,
      let source = NSImage(contentsOfFile: args[1])?.cgImage(forProposedRect: nil, context: nil, hints: nil)
else {
    FileHandle.standardError.write("Usage: round-icon.swift <input.png> <output.png>\n".data(using: .utf8)!)
    exit(1)
}

let size = source.width
let rect = CGRect(x: 0, y: 0, width: size, height: size)
let radius = CGFloat(size) * 27 / 120
guard let context = CGContext(
    data: nil, width: size, height: size, bitsPerComponent: 8, bytesPerRow: 0,
    space: CGColorSpace(name: CGColorSpace.sRGB)!,
    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
else { exit(1) }
context.interpolationQuality = .high
context.addPath(CGPath(roundedRect: rect, cornerWidth: radius, cornerHeight: radius, transform: nil))
context.clip()
context.draw(source, in: rect)

let rep = NSBitmapImageRep(cgImage: context.makeImage()!)
guard let png = rep.representation(using: .png, properties: [:]) else { exit(1) }
try png.write(to: URL(fileURLWithPath: args[2]))
