// Makes the README's images, which GitHub shows without the site's CSS: the app icon with
// rounded corners, and a strip of iPhone screenshots in the same device frames as the site (assets/site.css).
// Usage (macOS): swift tools/make-readme-images.swift (from anywhere). Reads images/,
// writes .github/readme/. Run it after tools/prepare-images.sh.
import AppKit
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

let site = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
let out = site.appendingPathComponent(".github/readme")
try FileManager.default.createDirectory(at: out, withIntermediateDirectories: true)

func load(_ path: String) -> CGImage {
    let url = site.appendingPathComponent(path)
    guard let src = CGImageSourceCreateWithURL(url as CFURL, nil),
          let image = CGImageSourceCreateImageAtIndex(src, 0, nil) else {
        fatalError("Cannot read \(url.path)")
    }
    return image
}

func canvas(_ width: Int, _ height: Int) -> CGContext {
    let ctx = CGContext(data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: 0,
                        space: CGColorSpace(name: CGColorSpace.sRGB)!,
                        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
    ctx.interpolationQuality = .high
    return ctx
}

func save(_ ctx: CGContext, _ name: String) {
    let url = out.appendingPathComponent(name)
    let dest = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil)!
    CGImageDestinationAddImage(dest, ctx.makeImage()!, nil)
    guard CGImageDestinationFinalize(dest) else { fatalError("Cannot write \(url.path)") }
    print("Wrote \(url.path)")
}

func rounded(_ rect: CGRect, _ radius: CGFloat) -> CGPath {
    CGPath(roundedRect: rect, cornerWidth: radius, cornerHeight: radius, transform: nil)
}

func gray(_ value: CGFloat, _ alpha: CGFloat = 1) -> CGColor {
    CGColor(srgbRed: value, green: value, blue: value, alpha: alpha)
}

// App icon: same corner radius as the site's hero icon (27 / 120).
do {
    let icon = load("images/app-icon.png")
    let size = icon.width
    let ctx = canvas(size, size)
    let rect = CGRect(x: 0, y: 0, width: size, height: size)
    ctx.addPath(rounded(rect, CGFloat(size) * 27 / 120))
    ctx.clip()
    ctx.draw(icon, in: rect)
    save(ctx, "app-icon.png")
}

// Screenshot strip: the .phone frame from assets/site.css (screen radius .125 of the width,
// a black bezel, a light and a dark ring, and a soft shadow), scaled to a 400 px screen.
do {
    let shots = ["01-today", "03-week", "04-tags", "07-dark"].map {
        load("images/full/iphone-18-pro-max-\($0).jpg")
    }
    let screenW: CGFloat = 400
    let screenH = (screenW * CGFloat(shots[0].height) / CGFloat(shots[0].width)).rounded()
    let bezel: CGFloat = 17, ring1: CGFloat = 4, ring2: CGFloat = 3
    let frame = bezel + ring1 + ring2
    let gap: CGFloat = 56, margin: CGFloat = 48
    let deviceW = screenW + 2 * frame, deviceH = screenH + 2 * frame
    let width = Int(margin * 2 + deviceW * CGFloat(shots.count) + gap * CGFloat(shots.count - 1))
    let height = Int(margin * 2 + deviceH)
    let ctx = canvas(width, height)
    let screenR = screenW * 0.125

    for (i, shot) in shots.enumerated() {
        let x = margin + CGFloat(i) * (deviceW + gap)
        let device = CGRect(x: x, y: margin, width: deviceW, height: deviceH)
        // Outer dark ring with the shadow, then the light ring, then the black bezel.
        ctx.saveGState()
        ctx.setShadow(offset: CGSize(width: 0, height: -18), blur: 40, color: gray(0, 0.28))
        ctx.addPath(rounded(device, screenR + frame))
        ctx.setFillColor(CGColor(srgbRed: 0.231, green: 0.239, blue: 0.231, alpha: 1))
        ctx.fillPath()
        ctx.restoreGState()
        let light = device.insetBy(dx: ring2, dy: ring2)
        ctx.addPath(rounded(light, screenR + bezel + ring1))
        ctx.setFillColor(CGColor(srgbRed: 0.553, green: 0.561, blue: 0.549, alpha: 1))
        ctx.fillPath()
        let body = light.insetBy(dx: ring1, dy: ring1)
        ctx.addPath(rounded(body, screenR + bezel))
        ctx.setFillColor(CGColor(srgbRed: 0.043, green: 0.043, blue: 0.047, alpha: 1))
        ctx.fillPath()
        let screen = body.insetBy(dx: bezel, dy: bezel)
        ctx.saveGState()
        ctx.addPath(rounded(screen, screenR))
        ctx.clip()
        ctx.draw(shot, in: screen)
        ctx.restoreGState()
    }
    save(ctx, "iphone-screenshots.png")
}
