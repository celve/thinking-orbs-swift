// Ported from thinking-orbs' src/ThinkingOrb.tsx (MIT, Jakub Antalik);
// see ThirdPartyLicenses/thinking-orbs.txt.

import SwiftUI
import ThinkingOrbsGeometry

/// A dotted thought-orb loading indicator.
///
/// Strictly monochrome, as upstream is: light dots on a dark scheme, dark dots on a light one,
/// taken from the environment. The view is exactly `size` points square and never wants to grow.
public struct ThinkingOrb: View {
    private let state: OrbState
    private let size: OrbSize
    private let speed: Double
    private let paused: Bool

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.orbTime) private var frozenTime
    @Environment(\.orbFrameRate) private var frameRate
    @ObservedObject private var visibility = OrbVisibility.shared

    public init(
        _ state: OrbState = .working,
        size: OrbSize = .size64,
        speed: Double = 1,
        paused: Bool = false
    ) {
        self.state = state
        self.size = size
        self.speed = speed
        self.paused = paused
    }

    /// The preset's baked speed times the caller's multiplier. Resolved once per view rather than
    /// inside the timeline closure, which re-runs every frame.
    private var effectiveSpeed: Double {
        ResolvedPreset.resolved(state, size).speed * speed
    }

    public var body: some View {
        content
            .frame(width: size.points, height: size.points)
            .accessibilityElement()
            .accessibilityAddTraits(.isImage)
            .accessibilityLabel(Text(state.accessibilityLabel))
    }

    @ViewBuilder
    private var content: some View {
        if let frozenTime {
            canvas(at: frozenTime)
        } else if reduceMotion {
            // A single representative frame, at a literal 0.6 — not scaled by the speed.
            canvas(at: OrbClock.reducedMotionTime)
        } else if paused || !visibility.isVisible {
            // Upstream draws one frame and never starts the loop, so unpausing jumps to the
            // current instant rather than resuming where it stopped. This freezes at the clock as
            // of the last evaluation, which is the nearest stateless equivalent — and because the
            // clock is absolute, an orb that stopped while hidden comes back in phase.
            canvas(at: OrbClock.now * effectiveSpeed)
        } else if let frameRate, frameRate > 0 {
            // Anchored to the shared epoch, so a fixed rate keeps instances in phase too.
            TimelineView(.periodic(from: OrbClock.epoch, by: 1 / frameRate)) { timeline in
                canvas(at: timeline.date.timeIntervalSince(OrbClock.epoch) * effectiveSpeed)
            }
        } else {
            TimelineView(.animation) { timeline in
                canvas(at: timeline.date.timeIntervalSince(OrbClock.epoch) * effectiveSpeed)
            }
        }
    }

    private func canvas(at t: Double) -> some View {
        let ink = OrbInk(dark: colorScheme == .dark)
        let frame = OrbFrame(state: state, size: size, at: t)
        // Non-linear, so blending happens in sRGB as it does on a 2D canvas.
        return Canvas(colorMode: .nonLinear, rendersAsynchronously: false) { context, _ in
            context.draw(frame, ink: ink)
        }
    }
}
