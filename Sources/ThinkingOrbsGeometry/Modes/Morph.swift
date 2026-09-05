// Ported from thinking-orbs' src/engine/morph.ts (MIT, Jakub Antalik);
// see ThirdPartyLicenses/thinking-orbs.txt.

import Foundation

/// A dotted outline morphing circle to triangle to square — the `shaping` state.
///
/// Upstream tuned this behind a blur-and-threshold filter and then dropped the filter, keeping the
/// geometry. Its note is worth carrying over: do not shrink the radius to compensate for the
/// softer antialiased edge, because that makes the mark genuinely smaller than the tuning.
private func smoothE(_ x: Double) -> Double { x * x * (3 - 2 * x) }

/// A closed polygon parameterised by arc length over [0, 1).
private struct PolyPath {
    let verts: [(x: Double, y: Double)]
    let lengths: [Double]
    let total: Double

    init(_ verts: [(x: Double, y: Double)]) {
        self.verts = verts
        var lengths: [Double] = []
        var total = 0.0
        for i in 0..<verts.count {
            let a = verts[i]
            let b = verts[(i + 1) % verts.count]
            let l = hypot(b.x - a.x, b.y - a.y)
            lengths.append(l)
            total += l
        }
        self.lengths = lengths
        self.total = total
    }

    /// The guard order matters: the length test comes before the bound check, so an `f` at or
    /// just past 1 clamps into the last edge rather than wrapping.
    func callAsFunction(_ f: Double) -> (x: Double, y: Double) {
        var target = f * total
        var i = 0
        while target > lengths[i] && i < verts.count - 1 {
            target -= lengths[i]
            i += 1
        }
        let a = verts[i]
        let b = verts[(i + 1) % verts.count]
        let ff = lengths[i] != 0 ? min(1, target / lengths[i]) : 0
        return (a.x + (b.x - a.x) * ff, a.y + (b.y - a.y) * ff)
    }
}

private func circlePath(_ f: Double) -> (x: Double, y: Double) {
    let a = -Double.pi / 2 + f * 2 * Double.pi
    return (cos(a) * 0.24, sin(a) * 0.24)
}

private let triangle = PolyPath([(0.0, -0.26), (0.24, 0.16), (-0.24, 0.16)])
/// Five vertices, so the walk starts at top-centre like the other two shapes.
private let square = PolyPath([(0, -0.2), (0.2, -0.2), (0.2, 0.2), (-0.2, 0.2), (-0.2, -0.2)])

private func shape(_ index: Int, _ f: Double) -> (x: Double, y: Double) {
    switch index {
    case 0: circlePath(f)
    case 1: triangle(f)
    default: square(f)
    }
}

private let hold = 1.4
private let morphDuration = 0.9
private let seg = hold + morphDuration
private let shapeCount = 3

/// A low floor keeps sparse outlines possible without degenerating.
private func morphN(_ d: Double) -> Int { Int(max(6, jsRound(34 * d))) }

func frameMorph(size: Double, t: Double, opts o: ModeOpts) -> OrbFrame {
    let tc = t.truncatingRemainder(dividingBy: seg * Double(shapeCount))
    let k = Int((tc / seg).rounded(.down))
    let local = tc - Double(k) * seg
    let m = local > hold ? smoothE((local - hold) / morphDuration) : 0
    let sprd = o.spread ?? 1

    // The two shape paths are blended as sampled points, not as paths. The circle is therefore a
    // 160-gon and never an analytic circle: sampling a true circle would put every dot slightly
    // inside this outline.
    let M = 160
    var pts: [(x: Double, y: Double)] = []
    pts.reserveCapacity(M)
    for i in 0..<M {
        let f = Double(i) / Double(M)
        let a = shape(k, f)
        let b = shape((k + 1) % shapeCount, f)
        pts.append(((a.x + (b.x - a.x) * m) * sprd, (a.y + (b.y - a.y) * m) * sprd))
    }

    var lengths: [Double] = []
    var total = 0.0
    for i in 0..<M {
        let a = pts[i]
        let b = pts[(i + 1) % M]
        let l = hypot(b.x - a.x, b.y - a.y)
        lengths.append(l)
        total += l
    }

    // The radius depends only on rDot; the count sets the gaps.
    let n = morphN(o.iconD ?? 1)
    let re = (o.rDot ?? 0.021) * 1.35 * sprd
    // Driven by `local`, not `t`, so the pulse resets with each shape.
    let pulse = 1 + 0.02 * sin(local * 3.1)

    var dots: [Dot] = []
    let c2 = size / 2
    // `segIndex` and `acc` are carried across dots, not reset per dot: the walk is monotonic and
    // the `segIndex < M - 1` clamp behaves differently if it restarts.
    var segIndex = 0
    var acc = 0.0
    for k2 in 0..<n {
        let target = (Double(k2) / Double(n)) * total
        while acc + lengths[segIndex] < target && segIndex < M - 1 {
            acc += lengths[segIndex]
            segIndex += 1
        }
        let a = pts[segIndex]
        let b = pts[(segIndex + 1) % M]
        let f = lengths[segIndex] != 0 ? min(1, (target - acc) / lengths[segIndex]) : 0
        let x = (a.x + (b.x - a.x) * f) * pulse
        let y = (a.y + (b.y - a.y) * f) * pulse
        dots.append(
            Dot(
                x: c2 + x * size,
                y: c2 + y * size,
                z: 0,
                r: max(0.35, re * size),
                white: 0.1))
    }
    return finalizeFrame(dots: dots, lines: [], rMin: o.rMin ?? 0.3)
}
