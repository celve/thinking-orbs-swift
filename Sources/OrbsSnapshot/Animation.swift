// Animated snapshots. A frozen frame proves the geometry; only motion shows whether a state
// reads as the verb it is named after, which is what the web demo is for and what this
// substitutes for offline.

import AppKit
import ImageIO
import SwiftUI
import ThinkingOrbs
import ThinkingOrbsGeometry
import UniformTypeIdentifiers

enum Animation {
    static let fps = 20.0

    /// How long one loop runs, in real seconds. Two states have an exact cycle and are given it
    /// so the loop is seamless; the rest are quasi-periodic and just get a few seconds.
    ///
    /// `orbTime` is engine time, which upstream defines as elapsed seconds times the preset's
    /// baked speed — so a real-time duration has to be divided by that speed, and every orb in a
    /// grid needs its own value rather than one shared environment setting.
    static func loopSeconds(_ state: OrbState, _ size: OrbSize) -> Double {
        let speed = ResolvedPreset.resolved(state, size).speed
        switch state {
        case .shaping: return (1.4 + 0.9) * 3 / speed  // hold and morph, across three shapes
        case .solving: return (2 * 14 * 0.42 + 1.2) / speed  // scramble, unwind, rest
        default: return 4
        }
    }

    static func engineTime(_ state: OrbState, _ size: OrbSize, realSeconds: Double) -> Double {
        realSeconds * ResolvedPreset.resolved(state, size).speed
    }

    @MainActor
    static func render(_ view: some View, scale: CGFloat) -> CGImage? {
        let renderer = ImageRenderer(content: view)
        renderer.scale = scale
        return renderer.cgImage
    }

    /// GIF rather than a video container: it plays inline anywhere a still does, and the palette
    /// costs nothing here because every frame is greyscale on one flat ground.
    static func writeGIF(_ frames: [CGImage], to url: URL, delay: Double) throws {
        guard
            let destination = CGImageDestinationCreateWithURL(
                url as CFURL, UTType.gif.identifier as CFString, frames.count, nil)
        else {
            throw Failure("could not create \(url.lastPathComponent)")
        }
        CGImageDestinationSetProperties(
            destination,
            [kCGImagePropertyGIFDictionary: [kCGImagePropertyGIFLoopCount: 0]] as CFDictionary)
        for frame in frames {
            CGImageDestinationAddImage(
                destination, frame,
                [kCGImagePropertyGIFDictionary: [kCGImagePropertyGIFUnclampedDelayTime: delay]]
                    as CFDictionary)
        }
        guard CGImageDestinationFinalize(destination) else {
            throw Failure("could not finalise \(url.lastPathComponent)")
        }
    }

    struct Failure: Error, CustomStringConvertible {
        let description: String
        init(_ description: String) { self.description = description }
    }
}

/// One orb on an opaque ground. GIF carries only single-bit transparency, so the substrate is
/// painted rather than left clear.
struct OrbCell: View {
    let state: OrbState
    let size: OrbSize
    let realSeconds: Double
    var labelled = false

    var body: some View {
        VStack(spacing: 6) {
            ThinkingOrb(state, size: size)
                .orbTime(Animation.engineTime(state, size, realSeconds: realSeconds))
            if labelled {
                Text(state.rawValue)
                    .font(.system(size: 9, weight: .medium, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.55))
            }
        }
        .padding(10)
        .environment(\.colorScheme, .dark)
    }
}

/// All nine states at once, each advanced by its own baked speed.
struct OrbSheet: View {
    let realSeconds: Double
    let size: OrbSize

    private let rows: [[OrbState]] = [
        [.working, .searching, .solving],
        [.listening, .connecting, .weaving],
        [.composing, .breathing, .shaping],
    ]

    var body: some View {
        VStack(spacing: 0) {
            ForEach(rows, id: \.self) { row in
                HStack(spacing: 0) {
                    ForEach(row, id: \.self) { state in
                        OrbCell(state: state, size: size, realSeconds: realSeconds, labelled: true)
                    }
                }
            }
        }
        .padding(8)
        .background(Color.black)
    }
}
