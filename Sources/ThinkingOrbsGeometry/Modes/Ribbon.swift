// Ported from thinking-orbs' src/engine/ribbon.ts (MIT, Jakub Antalik);
// see ThirdPartyLicenses/thinking-orbs.txt.

import Foundation

/// An undulating sash of parallel strands riding a great circle — the `composing` state — and,
/// with `faceOn` set, the slowly morphing ring of `breathing`.
///
/// The projector is built with a scale of 1 and the radius is multiplied into each point instead,
/// so the returned depth must be divided by `R` to normalise. Note it is divided by `R`, never by
/// the wobbled `rr`.
func frameRibbon(size: Double, t: Double, opts o: ModeOpts) -> OrbFrame {
    let cx = size / 2
    let cy = size / 2
    let R = (size / 2) * 0.78
    // spin scales the 3D tumble; 0 freezes the band, leaving only the traveling undulation.
    let spin = o.spin ?? 1
    let camTilt = 0.3
    let pt = Projection(yaw: t * 0.1 * spin, tilt: camTilt, cx: cx, cy: cy, scale: 1)
    let rs = radiusScale(size, o.rsPow ?? 0.6)
    let faceOn = (o.faceOn ?? 0) != 0

    var dots: [Dot] = []

    let ghostN = Int(o.ghostN ?? 150)
    for i in 0..<ghostN {
        let d = fibDir(i, ghostN)
        let p = pt(d.x * R, d.y * R, d.z * R)
        let depth = (p.z / R + 1) / 2
        dots.append(
            Dot(x: p.x, y: p.y, z: p.z, r: 0.8 * rs, white: 0.78, alpha: 0.1 + 0.22 * depth))
    }

    // The band plane, precessing, frozen when spin is 0. Face-on sets the tilt to cancel the
    // camera's, so the great circle reads as a true circle rather than a tilted ellipse.
    let ya = t * 0.24 * spin
    let ta = faceOn ? -camTilt : 0.55 + 0.3 * sin(t * 0.18) * spin
    let ux = cos(ya)
    let uy = 0.0
    let uz = sin(ya)
    let vx = -uz * sin(ta)
    let vy = cos(ta)
    let vz = ux * sin(ta)
    let nx = uy * vz - uz * vy
    let ny = uz * vx - ux * vz
    let nz = ux * vy - uy * vx

    // Radial lobes swell past R, so the base radius is pulled in by most of the wobble amplitude
    // and the silhouette stays inside the frame however far the deformation is pushed.
    let wobAmp = 0.23 * (o.wobMul ?? 1)
    let baseR = faceOn ? R / (1 + 0.85 * wobAmp) : R

    let baseLanes = o.lanes ?? 5
    let segs = Int(o.segs ?? 88)
    let lanes = Int(max(1, jsRound(baseLanes * (o.bandMul ?? 1))))
    for w in 0..<lanes {
        let laneOff = (Double(w) - Double(lanes - 1) / 2) * 0.075
        // The max(1, ...) means a two-lane band gives both lanes an edge of 0.5, not 1.
        let edge = abs(Double(w) - Double(lanes - 1) / 2) / max(1, Double(lanes - 1) / 2)
        for k in 0..<segs {
            let a = (Double(k) / Double(segs)) * 2 * Double.pi
            let wob =
                (0.16 * sin(a * 3 - t * 1.7 + Double(w) * 0.22) + 0.07 * sin(a * 5 + t * 1.1))
                * (o.wobMul ?? 1)
            // A normal-direction wobble is cancelled by the re-normalisation below, so face-on
            // modulates the in-plane radius instead and the lobes genuinely swell outward.
            let radial = faceOn ? 1 + wob : 1
            let off = faceOn ? laneOff : laneOff + wob
            let x = ux * cos(a) + vx * sin(a) + nx * off
            let y = uy * cos(a) + vy * sin(a) + ny * off
            let z = uz * cos(a) + vz * sin(a) + nz * off
            let l = (x * x + y * y + z * z).squareRoot()
            let rr = baseR * radial
            let p = pt((x / l) * rr, (y / l) * rr, (z / l) * rr)
            let depth = (p.z / R + 1) / 2
            dots.append(
                Dot(
                    x: p.x,
                    y: p.y,
                    z: p.z,
                    r: ((o.rBase ?? 1.1) + (o.rDepth ?? 1.7) * depth) * (1 - 0.25 * edge) * rs,
                    white: 0.52 - 0.44 * depth + 0.18 * edge,
                    alpha: 0.4 + 0.6 * depth))
        }
    }
    return finalizeFrame(dots: dots, lines: [], rMin: o.rMin ?? 0.3)
}
