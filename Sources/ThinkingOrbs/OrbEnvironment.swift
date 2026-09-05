import SwiftUI

private struct OrbTimeKey: EnvironmentKey {
    static let defaultValue: Double? = nil
}

extension EnvironmentValues {
    /// Freezes every orb below this view at one engine time, or `nil` for the live clock.
    public var orbTime: Double? {
        get { self[OrbTimeKey.self] }
        set { self[OrbTimeKey.self] = newValue }
    }
}

private struct OrbFrameRateKey: EnvironmentKey {
    static let defaultValue: Double? = nil
}

extension EnvironmentValues {
    /// Redraws per second, or `nil` to follow the display's refresh rate.
    public var orbFrameRate: Double? {
        get { self[OrbFrameRateKey.self] }
        set { self[OrbFrameRateKey.self] = newValue }
    }
}

extension View {
    /// Redraw at a fixed rate instead of following the display.
    ///
    /// The whole cost of an animating orb is the per-frame redraw, so this is the one knob that
    /// changes it: halving the rate roughly halves the CPU. These are slow, smooth animations and
    /// they hold up well below the display's rate — 30 is close to indistinguishable, 20 is
    /// visibly stepped on the faster states.
    ///
    /// Instances stay in phase because the schedule is anchored to the same shared epoch.
    public func orbFrameRate(_ framesPerSecond: Double?) -> some View {
        environment(\.orbFrameRate, framesPerSecond)
    }

    /// Freeze every orb in this subtree at engine time `t`.
    ///
    /// Required rather than merely convenient: `ImageRenderer` never fires `onAppear` and never
    /// advances a `TimelineView`, so an orb rendered offscreen would otherwise paint whatever its
    /// first evaluation produced. The package's own snapshot tool sets this, and any host
    /// rendering an orb into a still image must too.
    public func orbTime(_ t: Double?) -> some View {
        environment(\.orbTime, t)
    }
}
