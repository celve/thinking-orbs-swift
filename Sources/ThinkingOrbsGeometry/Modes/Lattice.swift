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
