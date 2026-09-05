// Renders every state, size and scheme at a frozen instant, for eyeballing against the web demo
// at https://orbs.jakubantalik.com and for the smoke check.
//
// Filenames follow upstream's demo/parity.ts convention, `<state>-<size>-<d|l>-<t>.png`, so a
// directory of these can be diffed against web captures with upstream's own diff-png.mjs.

import AppKit
import SwiftUI
import ThinkingOrbs
import ThinkingOrbsGeometry

let frozen = 0.6
// Matches upstream's device-pixel-ratio cap, the only place that cap still has meaning.
let scale: CGFloat = 2

let arguments = CommandLine.arguments
let animate = arguments.contains("--animate")
let positional = arguments.dropFirst().filter { !$0.hasPrefix("--") }
guard positional.count == 1 else {
    FileHandle.standardError.write(
        Data("usage: orbs-snapshot <output-directory> [--animate]\n".utf8))
    exit(2)
}
let directory = URL(fileURLWithPath: positional[positional.startIndex])
try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

// ImageRenderer wants an application to exist before it will rasterise.
_ = NSApplication.shared

func opaquePixels(_ image: CGImage) -> Int {
    let width = image.width
    let height = image.height
    var pixels = [UInt8](repeating: 0, count: width * height * 4)
    guard
        let context = CGContext(
            data: &pixels, width: width, height: height, bitsPerComponent: 8,
            bytesPerRow: width * 4, space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
    else { return 0 }
    context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
    return stride(from: 3, to: pixels.count, by: 4).count { pixels[$0] > 0 }
}

if animate {
    // One loop per state, plus a sheet of all nine running together.
    for size in OrbSize.allCases {
        for state in OrbState.allCases {
            let seconds = Animation.loopSeconds(state, size)
            let count = Int((seconds * Animation.fps).rounded())
            var frames: [CGImage] = []
            for i in 0..<count {
                let real = Double(i) * seconds / Double(count)
                let cell = OrbCell(state: state, size: size, realSeconds: real)
                guard let image = Animation.render(cell, scale: scale) else {
                    FileHandle.standardError.write(Data("could not render \(state.rawValue)\n".utf8))
                    exit(1)
                }
                frames.append(image)
            }
            let url = directory.appendingPathComponent("\(state.rawValue)-\(size.rawValue).gif")
            try Animation.writeGIF(frames, to: url, delay: seconds / Double(count))
            print("wrote \(url.lastPathComponent) (\(frames.count) frames, \(String(format: "%.1f", seconds))s)")
        }
    }

    let sheetSeconds = 4.0
    let sheetCount = Int(sheetSeconds * Animation.fps)
    var sheetFrames: [CGImage] = []
    for i in 0..<sheetCount {
        let real = Double(i) * sheetSeconds / Double(sheetCount)
        guard let image = Animation.render(OrbSheet(realSeconds: real, size: .size64), scale: scale)
        else {
            FileHandle.standardError.write(Data("could not render the sheet\n".utf8))
            exit(1)
        }
        sheetFrames.append(image)
    }
    let sheetURL = directory.appendingPathComponent("nine-states.gif")
    try Animation.writeGIF(sheetFrames, to: sheetURL, delay: sheetSeconds / Double(sheetCount))
    print("wrote \(sheetURL.lastPathComponent) (\(sheetFrames.count) frames)")
    exit(0)
}

var written = 0
for state in OrbState.allCases {
    for size in OrbSize.allCases {
        for dark in [true, false] {
            let view = ThinkingOrb(state, size: size)
                .orbTime(frozen)
                .environment(\.colorScheme, dark ? .dark : .light)
            let renderer = ImageRenderer(content: view)
            renderer.scale = scale
            guard let image = renderer.cgImage,
                let png = NSBitmapImageRep(cgImage: image).representation(using: .png, properties: [:])
            else {
                FileHandle.standardError.write(
                    Data("could not render \(state.rawValue) at \(size.rawValue)\n".utf8))
                exit(1)
            }
            // A frame whose clock never advanced renders as a valid, entirely blank PNG, so the
            // ink is counted here rather than inferred from the file size — connecting at 20
            // draws only nine dots and compresses smaller than an empty frame of a larger size.
            let ink = opaquePixels(image)
            guard ink > 0 else {
                FileHandle.standardError.write(
                    Data("blank frame: \(state.rawValue) \(size.rawValue) \(dark ? "dark" : "light")\n".utf8))
                exit(1)
            }
            let name = "\(state.rawValue)-\(size.rawValue)-\(dark ? "d" : "l")-\(frozen).png"
            let url = directory.appendingPathComponent(name)
            try png.write(to: url)
            print("wrote \(url.lastPathComponent) (\(ink) inked pixels)")
            written += 1
        }
    }
}
print("\(written) frames")
