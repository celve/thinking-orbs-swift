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

extension View {
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
