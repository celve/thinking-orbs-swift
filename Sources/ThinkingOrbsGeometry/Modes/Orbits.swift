// Ported from thinking-orbs' src/engine/orbits.ts (MIT, Jakub Antalik);
// see ThirdPartyLicenses/thinking-orbs.txt.

import Foundation

/// Particles running tilted orbits — the `working` state. The tuned preset is coreless: just the
/// ghost paths and the particles.
func frameOrbits(size: Double, t: Double, opts o: ModeOpts) -> OrbFrame {
    let cx = size / 2
    let cy = size / 2
    let R = (size / 2) * 0.82
    let pt = Projection(yaw: t * 0.12, tilt: 0.3, cx: cx, cy: cy, scale: 1)
    let rs = radiusScale(size, o.rsPow ?? 0.6)

    var dots: [Dot] = []
    let orbitN = Int(o.orbitN ?? 12)
    let ghostN = Int(o.ghostN ?? 40)
    let particles = Int(o.particles ?? 3)

    for orb in 0..<orbitN {
        let h1 = hashD(Double(orb), 1.7)
        let h2 = hashD(Double(orb), 5.2)
        let h3 = hashD(Double(orb), 8.9)
        let ro = R * (0.45 + 0.52 * h1)
        let th = h1 * 2 * Double.pi
        let phi = acos(2 * h2 - 1)
        let nx = sin(phi) * cos(th)
        let ny = cos(phi)
        let nz = sin(phi) * sin(th)
        // The basis is deliberately not orthonormalised: uz stays 0 and v is the cross product
        // written out longhand with that zero still in it. Simplifying changes the geometry.
        var ux = -ny
        var uy = nx
        let uz = 0.0
        let ul = max(1e-6, (ux * ux + uy * uy).squareRoot())
        ux /= ul
        uy /= ul
        let vx = ny * uz - nz * uy
        let vy = nz * ux - nx * uz
        let vz = nx * uy - ny * ux
        let speed = (0.25 + 0.55 * h3) * (h3 > 0.5 ? 1 : -1)

        for k in 0..<ghostN {
            let a = (Double(k) / Double(ghostN)) * 2 * Double.pi
            let p = pt(
                (ux * cos(a) + vx * sin(a)) * ro,
                (uy * cos(a) + vy * sin(a)) * ro,
                (uz * cos(a) + vz * sin(a)) * ro)
            // The projector's scale is 1 and the radius is pre-multiplied, so depth divides by it.
            let depth = (p.z / ro + 1) / 2
            dots.append(
                Dot(
                    x: p.x, y: p.y, z: p.z,
                    r: (o.ghostR ?? 0.9) * rs,
                    white: 0.72,
                    alpha: (o.ghostA ?? 0.5) * (0.4 + 0.6 * depth)))
        }

        for m in 0..<particles {
            let a = t * speed + (Double(m) / Double(particles)) * 2 * Double.pi + h2 * 6
            let p = pt(
                (ux * cos(a) + vx * sin(a)) * ro,
                (uy * cos(a) + vy * sin(a)) * ro,
                (uz * cos(a) + vz * sin(a)) * ro)
            let depth = (p.z / ro + 1) / 2
            dots.append(
                Dot(
                    x: p.x, y: p.y, z: p.z,
                    r: ((o.partR ?? 1.2) + (o.partRDepth ?? 1.6) * depth) * rs,
                    white: 0.3 - 0.22 * depth))
        }
    }
    return finalizeFrame(dots: dots, lines: [], rMin: o.rMin ?? 0.3)
}
