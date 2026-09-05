// The 2D binding, ported from thinking-orbs' src/engine/core.ts (MIT, Jakub Antalik);
// see ThirdPartyLicenses/thinking-orbs.txt.

import SwiftUI
import ThinkingOrbsGeometry

extension GraphicsContext {
    /// Draw a finished frame. Lines first, so nodes sit on top of their edges; then dots in the
    /// order the geometry already sorted them.
    ///
    /// Plain source-over fills throughout — no gradients, no blend modes, no blur. Screen y runs
    /// down here exactly as it does on a 2D canvas, and the projection already accounts for that,
    /// so nothing is flipped.
    func draw(_ frame: OrbFrame, ink: OrbInk) {
        for line in frame.lines {
            let (grey, opacity) = ink.components(white: line.white, alpha: line.alpha)
            var path = Path()
            path.move(to: CGPoint(x: line.x1, y: line.y1))
            path.addLine(to: CGPoint(x: line.x2, y: line.y2))
            stroke(
                path,
                with: .color(Color(white: grey, opacity: opacity)),
                lineWidth: line.width)
        }
        for dot in frame.dots {
            let (grey, opacity) = ink.components(white: dot.white, alpha: dot.alpha)
            let box = CGRect(
                x: dot.x - dot.r, y: dot.y - dot.r, width: dot.r * 2, height: dot.r * 2)
            fill(Path(ellipseIn: box), with: .color(Color(white: grey, opacity: opacity)))
        }
    }
}
