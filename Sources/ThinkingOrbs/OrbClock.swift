import Foundation

/// The shared clock. Upstream reads `performance.now()` directly, so two orbs in the same state
/// are in phase however far apart they mounted; the analogue here is one process-wide origin
/// rather than a per-view start time.
///
/// The origin also keeps `t` small. Feeding an absolute reference date in would put `t` near 8e8,
/// a magnitude no golden vector exercises and where the modes' `truncatingRemainder` cycles lose
/// most of their resolution.
public enum OrbClock {
    /// Resolved once, on first use, by the runtime's atomic lazy initialisation.
    public static let epoch = Date()

    public static var now: Double { Date().timeIntervalSince(epoch) }

    /// Upstream renders one static frame at this instant under reduced motion. It is passed as
    /// `t` directly, *not* multiplied by the preset or user speed.
    public static let reducedMotionTime = 0.6
}
