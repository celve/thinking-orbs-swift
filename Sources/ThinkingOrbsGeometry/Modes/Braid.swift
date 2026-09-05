// Ported from thinking-orbs' src/engine/braid.ts (MIT, Jakub Antalik);
// see ThirdPartyLicenses/thinking-orbs.txt.

import Foundation

/// Three strands plaiting around the sphere — the `weaving` state.
func frameBraid(size: Double, t: Double, opts o: ModeOpts) -> OrbFrame {
    let cx = size / 2
    let cy = size / 2
    let R = (size / 2) * 0.76
    let pt = Projection(yaw: t * 0.4, tilt: 0.3, cx: cx, cy: cy, scale: 1)
    let rs = radiusScale(size, o.rsPow ?? 0.6)

    var dots: [Dot] = []
    let ghostN = Int(o.ghostN ?? 150)
    for i in 0..<ghostN {
        let d = fibDir(i, ghostN)
        let p = pt(d.x * R, d.y * R, d.z * R)
        let depth = (p.z / R + 1) / 2
        dots.append(
            Dot(x: p.x, y: p.y, z: p.z, r: 0.8 * rs, white: 0.78, alpha: 0.1 + 0.22 * depth))
    }

    let strandN = Int(o.strandN ?? 52)
    let turns = o.turns ?? 3
    // The strand count is a literal three, not an option.
    for s in 0..<3 {
        let phase = (Double(s) / 3) * 2 * Double.pi
        for i in 0..<strandN {
            // u walks pole to pole; the frac drift slides the whole strand along.
            let u = (frac(Double(i) / Double(strandN) + t * 0.045) * 2 - 1) * 0.96
            let surf = max(0, 1 - u * u).squareRoot()
            let endFade = min(1, (1 - abs(u)) / 0.1)
            let a = u * Double.pi * turns + phase
            // Radial breathing: strands trade places, giving the over-and-under of a plait.
            let weave = 1 + 0.075 * sin(u * Double.pi * turns * 2 + phase * 2 + t * 0.8)
            let rr = surf * R * weave
            let p = pt(cos(a) * rr, u * R * weave, sin(a) * rr)
            let depth = (p.z / R + 1) / 2
            dots.append(
                Dot(
                    x: p.x, y: p.y, z: p.z,
                    r: ((o.rBase ?? 1.2) + (o.rDepth ?? 1.8) * depth) * rs,
                    white: 0.55 - 0.45 * depth,
                    alpha: endFade * (0.45 + 0.55 * depth)))
        }
    }
    return finalizeFrame(dots: dots, lines: [], rMin: o.rMin ?? 0.3)
}
