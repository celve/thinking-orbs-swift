// Ported from thinking-orbs' src/engine/core.ts (MIT, Jakub Antalik);
// see ThirdPartyLicenses/thinking-orbs.txt.

import Foundation

@inlinable
public func lerp(_ a: Double, _ b: Double, _ f: Double) -> Double { a + (b - a) * f }

@inlinable
public func frac(_ x: Double) -> Double { x - x.rounded(.down) }

/// Deterministic hash in [0, 1) — the classic sine-based GLSL hash.
@inlinable
public func hashD(_ a: Double, _ b: Double) -> Double {
    let h = sin(a * 12.9898 + b * 78.233) * 43758.5453
    return h - h.rounded(.down)
}

/// Value noise on a 2D lattice. The four-term expansion is kept as written: the algebraically
/// equivalent nested-lerp form differs in the last bits.
@inlinable
public func vnoise(_ x: Double, _ y: Double) -> Double {
    let xi = x.rounded(.down)
    let yi = y.rounded(.down)
    var fx = x - xi
    var fy = y - yi
    fx = fx * fx * (3 - 2 * fx)
    fy = fy * fy * (3 - 2 * fy)
    let a = hashD(xi, yi)
    let b = hashD(xi + 1, yi)
    let c = hashD(xi, yi + 1)
    let d = hashD(xi + 1, yi + 1)
    return a + (b - a) * fx + (c - a) * fy + (a - b - c + d) * fx * fy
}

/// Stable directions on a unit sphere (Fibonacci lattice).
@inlinable
public func fibDir(_ i: Int, _ n: Int) -> (x: Double, y: Double, z: Double) {
    let golden = Double.pi * (3 - 5.0.squareRoot())
    let y = 1 - (2 * (Double(i) + 0.5)) / Double(n)
    let rad = (1 - y * y).squareRoot()
    let a = Double(i) * golden
    return (rad * cos(a), y, rad * sin(a))
}

/// Shortest signed angular distance, wrapped to (-pi, pi].
@inlinable
public func angleDelta(_ a: Double, _ b: Double) -> Double { atan2(sin(a - b), cos(a - b)) }

/// Dot radii were tuned for a 300pt frame; sub-linear scaling keeps small orbs legible.
@inlinable
public func radiusScale(_ size: Double, _ exponent: Double) -> Double {
    Foundation.pow(size / 300, exponent)
}

/// Shared spin, tilt and orthographic projection.
///
/// Two conventions are in play across the modes and they are not interchangeable. Some callers
/// pass `scale: 1` with the radius already multiplied into the point and then divide the returned
/// depth by that radius; others pass the radius as `scale` and use `(z + 1) / 2` directly. The
/// returned z is *never* multiplied by `scale`, so its magnitude differs per mode — the sort only
/// ever compares within one frame, and normalising it would break every golden comparison.
public struct Projection: Sendable {
    @usableFromInline let st: Double
    @usableFromInline let ct: Double
    @usableFromInline let sy: Double
    @usableFromInline let cyw: Double
    @usableFromInline let cx: Double
    @usableFromInline let cy: Double
    @usableFromInline let scale: Double

    public init(yaw: Double, tilt: Double, cx: Double, cy: Double, scale: Double) {
        self.st = sin(tilt)
        self.ct = cos(tilt)
        self.sy = sin(yaw)
        self.cyw = cos(yaw)
        self.cx = cx
        self.cy = cy
        self.scale = scale
    }

    /// Screen x, screen y, and unscaled camera-space depth. y is negated because screen y runs
    /// down, matching both `CanvasRenderingContext2D` and SwiftUI's `GraphicsContext`.
    @inlinable
    public func callAsFunction(_ x: Double, _ y: Double, _ z: Double)
        -> (x: Double, y: Double, z: Double)
    {
        let x1 = x * cyw + z * sy
        let z1 = -x * sy + z * cyw
        let y1 = y * ct - z1 * st
        let z2 = y * st + z1 * ct
        return (cx + x1 * scale, cy - y1 * scale, z2)
    }
}
