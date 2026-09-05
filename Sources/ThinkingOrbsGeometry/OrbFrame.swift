// Ported from thinking-orbs' src/engine/core.ts (MIT, Jakub Antalik);
// see ThirdPartyLicenses/thinking-orbs.txt.

/// One dot. `white` is the ink value on paper — 0 is darkest — mirrored on dark substrates.
/// `z` is unscaled camera-space depth whose magnitude differs per mode; it orders the draw list
/// and means nothing across frames.
public struct Dot: Sendable, Equatable {
    public var x: Double
    public var y: Double
    public var z: Double
    public var r: Double
    public var white: Double
    /// Upstream leaves this optional and reads it as `?? 1` everywhere, so absent and 1 are
    /// indistinguishable. It is *not* clamped here — the goldens carry values slightly over 1.
    public var alpha: Double

    public init(x: Double, y: Double, z: Double, r: Double, white: Double, alpha: Double = 1) {
        self.x = x
        self.y = y
        self.z = z
        self.r = r
        self.white = white
        self.alpha = alpha
    }
}

/// A stroked edge between two projected points — only the `connecting` state emits these.
public struct Line: Sendable, Equatable {
    public var x1: Double
    public var y1: Double
    public var x2: Double
    public var y2: Double
    public var white: Double
    public var alpha: Double
    public var width: Double

    public init(
        x1: Double, y1: Double, x2: Double, y2: Double,
        white: Double, alpha: Double = 1, width: Double
    ) {
        self.x1 = x1
        self.y1 = y1
        self.x2 = x2
        self.y2 = y2
        self.white = white
        self.alpha = alpha
        self.width = width
    }
}

/// One rendered instant: a complete, final set of draw instructions. `dots` is already culled,
/// radius-clamped and z-sorted into draw order; `lines` are drawn first. Nothing here needs
/// further interpretation, which is what makes a frame portable to any 2D renderer.
public struct OrbFrame: Sendable, Equatable {
    public var dots: [Dot]
    public var lines: [Line]

    public init(dots: [Dot] = [], lines: [Line] = []) {
        self.dots = dots
        self.lines = lines
    }
}

extension OrbFrame {
    /// The geometry for a state at a size and an instant. `t` is engine time — already multiplied
    /// by the preset's speed.
    public init(state: OrbState, size: OrbSize, at t: Double) {
        let preset = ResolvedPreset.resolved(state, size)
        self = preset.mode.frame(size: size.points, t: t, opts: preset.opts)
    }
}
