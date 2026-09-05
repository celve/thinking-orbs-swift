// What one orb costs per frame. `TimelineView(.animation)` redraws at the display's refresh rate
// and the modes are stateless, so the whole frame is rebuilt every tick — which makes the
// per-frame geometry cost the thing worth knowing.

import AppKit
import Foundation
import SwiftUI
import ThinkingOrbs
import ThinkingOrbsGeometry

enum Benchmark {
    static func time(_ iterations: Int, _ body: () -> Void) -> Double {
        // One warm pass, so first-call costs do not land in the measurement.
        body()
        let start = DispatchTime.now().uptimeNanoseconds
        for _ in 0..<iterations { body() }
        let end = DispatchTime.now().uptimeNanoseconds
        return Double(end - start) / Double(iterations) / 1_000_000  // ms
    }

    @MainActor
    static func run() {
        let iterations = 2000
        print("geometry, one frame, milliseconds\n")
        print("  state        size  dots   ms/frame   % of a core at 60fps")

        var worst = 0.0
        for size in OrbSize.allCases {
            for state in OrbState.allCases {
                let dots = OrbFrame(state: state, size: size, at: 0.6).dots.count
                let ms = time(iterations) {
                    _ = OrbFrame(state: state, size: size, at: 1.7)
                }
                worst = max(worst, ms)
                let load = ms * 60 / 10  // ms/frame * 60 frames / 1000ms, as a percentage
                print(
                    "  \(state.rawValue.padding(toLength: 12, withPad: " ", startingAt: 0))"
                        + " \(size.rawValue == 64 ? "64" : "20")    "
                        + "\(String(dots).padding(toLength: 6, withPad: " ", startingAt: 0))"
                        + " \(String(format: "%8.4f", ms))   \(String(format: "%.2f%%", load))")
            }
        }
        print("\n  worst geometry: \(String(format: "%.4f", worst)) ms/frame")

        // Rasterisation through ImageRenderer is not the live compositing path — it allocates a
        // bitmap each time — so this is an upper bound on painting, not a measurement of it.
        print("\nrasterisation via ImageRenderer, upper bound\n")
        for state in [OrbState.composing, .working, .shaping] {
            let view = ThinkingOrb(state, size: .size64).orbTime(1.7)
            let ms = time(200) {
                let renderer = ImageRenderer(content: view)
                renderer.scale = 2
                _ = renderer.cgImage
            }
            print("  \(state.rawValue): \(String(format: "%.3f", ms)) ms/frame")
        }
    }
}
