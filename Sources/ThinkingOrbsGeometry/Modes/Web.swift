// Ported from thinking-orbs' src/engine/web.ts (MIT, Jakub Antalik);
// see ThirdPartyLicenses/thinking-orbs.txt.

import Foundation

/// A constellation wiring itself — the `connecting` state, and the only mode that emits lines.
/// Nodes drift on the sphere under slow value noise; any pair closer than `thr` grows an edge,
/// and bright packets run along randomly re-picked node pairs.
func frameWeb(size: Double, t: Double, opts o: ModeOpts) -> OrbFrame {
    let cx = size / 2
    let cy = size / 2
    let R = (size / 2) * 0.8 * (o.spread ?? 1)
    // The projector carries the radius as its scale, so node vectors stay unit length and the
    // distances below are in unit-sphere space.
    let pt = Projection(yaw: t * 0.12, tilt: 0.32, cx: cx, cy: cy, scale: R)
    let rs = radiusScale(size, o.rsPow ?? 0.6)

    let nodeN = Int(o.nodeN ?? 30)
    let thr = o.thr ?? 0.72
    let nodeR = o.nodeR ?? 1.4
    let nodeRDepth = o.nodeRDepth ?? 1.8

    // Fibonacci lattice plus slow noise wander, renormalised back onto the surface.
    var nodes: [(x: Double, y: Double, z: Double)] = []
    for i in 0..<nodeN {
        let d = fibDir(i, nodeN)
        let x = d.x + 0.3 * (vnoise(Double(i) * 0.31 + 9, t * 0.24) - 0.5) * 2
        let y = d.y + 0.3 * (vnoise(Double(i) * 0.53 + 27, t * 0.21) - 0.5) * 2
        let z = d.z + 0.3 * (vnoise(Double(i) * 0.77 + 55, t * 0.27) - 0.5) * 2
        let l = (x * x + y * y + z * z).squareRoot()
        nodes.append((x / l, y / l, z / l))
    }

    var lines: [Line] = []
    var dots: [Dot] = []

    // Edges between close neighbours, alpha by proximity and depth.
    for i in 0..<nodeN {
        for j in (i + 1)..<nodeN {
            let dx = nodes[i].x - nodes[j].x
            let dy = nodes[i].y - nodes[j].y
            let dz = nodes[i].z - nodes[j].z
            let dist = (dx * dx + dy * dy + dz * dz).squareRoot()
            if dist >= thr { continue }
            let p1 = pt(nodes[i].x, nodes[i].y, nodes[i].z)
            let p2 = pt(nodes[j].x, nodes[j].y, nodes[j].z)
            let depth = ((p1.z + p2.z) / 2 + 1) / 2
            lines.append(
                Line(
                    x1: p1.x, y1: p1.y, x2: p2.x, y2: p2.y,
                    white: 0.42,
                    alpha: (1 - dist / thr) * (0.3 + 0.55 * depth),
                    width: max(0.6, (o.lineW ?? 0.8) * rs)))
        }
    }

    for i in 0..<nodeN {
        let p = pt(nodes[i].x, nodes[i].y, nodes[i].z)
        let depth = (p.z + 1) / 2
        let pulse = 1 + 0.25 * sin(t * 1.4 + Double(i) * 2.7)
        dots.append(
            Dot(
                x: p.x, y: p.y, z: p.z,
                r: (nodeR + nodeRDepth * depth) * pulse * rs,
                white: 0.55 - 0.45 * depth))
    }

    // Signals: bright packets running between paired nodes. A pair that hashes to the same node
    // is skipped, so the dot count varies with `t`.
    let signals = Int(o.signals ?? 5)
    for s in 0..<signals {
        let seg = (t * 0.55 + Double(s) * 7.31).rounded(.down)
        let a = Int((hashD(seg, Double(s) * 3.1 + 1.7) * Double(nodeN)).rounded(.down))
        let b = Int((hashD(seg, Double(s) * 5.7 + 4.2) * Double(nodeN)).rounded(.down))
        if a == b { continue }
        let f = frac(t * 0.55 + Double(s) * 7.31)
        let x = lerp(nodes[a].x, nodes[b].x, f)
        let y = lerp(nodes[a].y, nodes[b].y, f)
        let z = lerp(nodes[a].z, nodes[b].z, f)
        let l = max(1e-6, (x * x + y * y + z * z).squareRoot())
        let p = pt(x / l, y / l, z / l)
        let depth = (p.z + 1) / 2
        dots.append(
            Dot(
                x: p.x, y: p.y, z: p.z,
                r: (nodeR * 1.5 + nodeRDepth * depth) * rs,
                white: 0.05,
                alpha: 0.5 + 0.5 * depth))
    }

    return finalizeFrame(dots: dots, lines: lines, rMin: o.rMin ?? 0.3)
}
