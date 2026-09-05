// Ported from thinking-orbs' src/engine/lattice.ts (MIT, Jakub Antalik);
// see ThirdPartyLicenses/thinking-orbs.txt.

import Foundation

/// Globe: a lat/long dot field with a scan meridian sweeping across it — the `searching` state.
///
/// The projector carries the radius as its scale, so points are unit-length and the returned depth
/// is already in [-1, 1]. Compare with `frameRibbon`, which passes a scale of 1 and divides.
func frameGlobe(size: Double, t: Double, opts o: ModeOpts) -> OrbFrame {
    let spin = 0.5
    let cx = size / 2
    let cy = size / 2
    let radius = (size / 2) * 0.82
    let tilt = 0.4 + 0.06 * sin(t * 0.35)
    let pt = Projection(yaw: t * spin, tilt: tilt, cx: cx, cy: cy, scale: radius)
    // The scan sweeps relative to the spin; scanMul scales that relative rate.
    let scan = t * (spin + (1.7 - spin) * (o.scanMul ?? 1))
    let rs = radiusScale(size, o.rsPow ?? 0.6)
    let dimBase = o.dimBase ?? 1

    let latRings = Int(o.latRings ?? 17)
    let lonDensity = o.lonDensity ?? 44
    var dots: [Dot] = []

    // Inclusive of latRings, so both poles get a ring.
    for li in 0...latRings {
        let lat = -Double.pi / 2 + (Double(li) / Double(latRings)) * Double.pi
        let cosLat = cos(lat)
        let sinLat = sin(lat)
        let lonCount = Int(max(1, jsRound(abs(cosLat) * lonDensity)))
        for lj in 0..<lonCount {
            let lon = (Double(lj) / Double(lonCount)) * 2 * Double.pi
            let p = pt(cosLat * cos(lon), sinLat, cosLat * sin(lon))
            let depth = (p.z + 1) / 2
            // The scan reads as a size ripple, not a shine.
            let d = angleDelta(lon + t * spin, scan)
            let boost = exp(-(d * d) / 0.18) * max(0, p.z)
            dots.append(
                Dot(
                    x: p.x,
                    y: p.y,
                    z: p.z,
                    r: ((o.rBase ?? 0.6) + (o.rDepth ?? 1.7) * depth + (o.rBoost ?? 1) * boost) * rs,
                    white: (o.inkFar ?? 0.62) - (o.inkSpan ?? 0.54) * depth,
                    alpha: dimBase + (1 - dimBase) * min(1, boost)))
        }
    }
    return finalizeFrame(dots: dots, lines: [], rMin: o.rMin ?? 0.3)
}

// MARK: - The solver heartbeat, shared by rubik

/// A quarter-turn of one half-open band `[lo, hi)` about one axis.
struct Move {
    var axis: Int
    var lo: Double
    var hi: Double
    var ang: Double
}

/// Rapid eased moves scramble, then replay in reverse so everything clicks back to solved, rests,
/// and repeats. `amount` is per-move progress in [0, 1]; `active` is the move currently turning.
func solveCycle(time: Double, count: Int, slotDur: Double, rest: Double)
    -> (amount: [Double], active: Int)
{
    let cyc = 2 * Double(count) * slotDur + rest
    let tc = time.truncatingRemainder(dividingBy: cyc)
    var amount = [Double](repeating: 0, count: count)
    var active = -1
    if tc < 2 * Double(count) * slotDur {
        let slot = Int((tc / slotDur).rounded(.down))
        let p = (tc - Double(slot) * slotDur) / slotDur
        let cl = min(1, p / 0.7)
        let ep = 1 - pow(1 - cl, 3)  // machine ease-out
        if slot < count {
            for i in 0..<slot { amount[i] = 1 }
            amount[slot] = ep
            active = slot
        } else {
            // The move list is never reversed; only the amounts run backwards.
            let u = 2 * count - 1 - slot
            for i in 0..<u { amount[i] = 1 }
            amount[u] = 1 - ep
            active = u
        }
    }
    return (amount, active)
}

/// Compose the moves in sequence. Each move's band test reads the *currently rotated* coordinate,
/// so the turns compose as real cube moves; testing membership once against the original point
/// would produce a plausible-looking but entirely different animation.
func applyMoves(
    _ pt3: (x: Double, y: Double, z: Double),
    _ moves: [Move],
    _ sc: (amount: [Double], active: Int)
) -> (x: Double, y: Double, z: Double, inActive: Bool) {
    var (x, y, z) = pt3
    var inActive = false
    for i in 0..<moves.count {
        if sc.amount[i] <= 0 { continue }
        let mv = moves[i]
        let coord = mv.axis == 0 ? x : mv.axis == 1 ? y : z
        // Half-open, so a coordinate of exactly 1 is in no band.
        if coord < mv.lo || coord >= mv.hi { continue }
        if i == sc.active { inActive = true }
        let a = mv.ang * sc.amount[i]
        let ca = cos(a)
        let sa = sin(a)
        if mv.axis == 0 {
            let y2 = y * ca - z * sa
            z = y * sa + z * ca
            y = y2
        } else if mv.axis == 1 {
            let x2 = x * ca + z * sa
            z = -x * sa + z * ca
            x = x2
        } else {
            let x2 = x * ca - y * sa
            y = x * sa + y * ca
            x = x2
        }
    }
    return (x, y, z, inActive)
}

/// Depends only on `count`, so the table is built once. The three hash-driven choices are
/// discrete, but every decision sits at least 0.0197 from a bucket boundary — far outside the
/// ~1e-11 a last-bit difference in `sin` could move them.
func makeMoves(_ count: Int) -> [Move] {
    var moves: [Move] = []
    for i in 0..<count {
        let axis = Int(min(2, (hashD(Double(i), 2.3) * 3).rounded(.down)))
        let lo = -1.0 + 0.5 * min(3, (hashD(Double(i), 5.9) * 4).rounded(.down))
        let dir: Double = hashD(Double(i), 7.7) < 0.5 ? 1 : -1
        moves.append(Move(axis: axis, lo: lo, hi: lo + 0.5, ang: dir * Double.pi / 2))
    }
    return moves
}

// MARK: - Rubik: bands twist in quarter turns, scramble then solve — solving

func frameRubik(size: Double, t: Double, opts o: ModeOpts) -> OrbFrame {
    let cx = size / 2
    let cy = size / 2
    let R = (size / 2) * 0.82
    let pt = Projection(yaw: t * 0.55, tilt: 0.35 + 0.1 * sin(t * 0.9), cx: cx, cy: cy, scale: R)
    let rs = radiusScale(size, o.rsPow ?? 0.6)
    let moveCount = Int(o.moveCount ?? 14)
    let moves = makeMoves(moveCount)
    let sc = solveCycle(time: t, count: moveCount, slotDur: 0.42, rest: 1.2)

    var dots: [Dot] = []
    let latRings = Int(o.latRings ?? 15)
    let lonDensity = o.lonDensity ?? 40
    for li in 0...latRings {
        let lat = -Double.pi / 2 + (Double(li) / Double(latRings)) * Double.pi
        let cosLat = cos(lat)
        let sinLat = sin(lat)
        let lonCount = Int(max(1, jsRound(abs(cosLat) * lonDensity)))
        for lj in 0..<lonCount {
            let lon = (Double(lj) / Double(lonCount)) * 2 * Double.pi
            let m = applyMoves((cosLat * cos(lon), sinLat, cosLat * sin(lon)), moves, sc)
            let p = pt(m.x, m.y, m.z)
            let depth = (p.z + 1) / 2
            // The band being turned inks a touch darker — the "hand".
            dots.append(
                Dot(
                    x: p.x,
                    y: p.y,
                    z: p.z,
                    r: ((o.rBase ?? 0.6) + (o.rDepth ?? 1.7) * depth
                        + (m.inActive ? (o.rActive ?? 0.3) : 0)) * rs,
                    white: (o.inkFar ?? 0.62) - (o.inkSpan ?? 0.54) * depth
                        - (m.inActive ? 0.14 : 0)))
        }
    }
    return finalizeFrame(dots: dots, lines: [], rMin: o.rMin ?? 0.3)
}

// MARK: - Wave: a waveform rolls through the rings — listening

func frameWave(size: Double, t: Double, opts o: ModeOpts) -> OrbFrame {
    let cx = size / 2
    let cy = size / 2
    // The undulation pulls the sphere inward, so the base radius is scaled up to match the other
    // lattice modes.
    let R = (size / 2) * 0.874
    let pt = Projection(yaw: t * 0.18, tilt: 0.38, cx: cx, cy: cy, scale: 1)
    let rs = radiusScale(size, o.rsPow ?? 0.6)

    var dots: [Dot] = []
    let rings = Int(o.rings ?? 15)
    let lonDensity = o.lonDensity ?? 40
    for ri in 0...rings {
        let lat = -Double.pi / 2 + (Double(ri) / Double(rings)) * Double.pi
        let cosLat = cos(lat)
        let sinLat = sin(lat)
        // Two waves at different tempi, so the motion never quite repeats.
        let w = 0.62 * sin(t * 2.1 - Double(ri) * 0.52) + 0.38 * sin(t * 1.27 + Double(ri) * 0.83)
        let rr = R * (0.88 + 0.105 * w)
        let lonCount = Int(max(1, jsRound(abs(cosLat) * lonDensity)))
        for lj in 0..<lonCount {
            let lon = (Double(lj) / Double(lonCount)) * 2 * Double.pi
            let p = pt(cosLat * cos(lon) * rr, sinLat * rr, cosLat * sin(lon) * rr)
            // Divided by the base radius, never by the wobbled one.
            let depth = (p.z / R + 1) / 2
            let crest = max(0, w)
            dots.append(
                Dot(
                    x: p.x,
                    y: p.y,
                    z: p.z,
                    r: ((o.rBase ?? 0.6) + (o.rDepth ?? 1.7) * depth) * (1 + 0.4 * crest) * rs,
                    white: 0.66 - 0.56 * depth - 0.1 * crest))
        }
    }
    return finalizeFrame(dots: dots, lines: [], rMin: o.rMin ?? 0.3)
}
