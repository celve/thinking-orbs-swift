// Ported from thinking-orbs' src/engine/core.ts (MIT, Jakub Antalik);
// see ThirdPartyLicenses/thinking-orbs.txt.

/// Turn raw mode output into a finished frame: drop invisible marks, clamp radii to the mode's
/// floor, and z-sort far to near into draw order.
///
/// This runs in the geometry step, not the painter, so a frame is a complete set of draw
/// instructions: every value is final and the array order is the order to draw in.
///
/// The comparator carries the original index because upstream's order depends on sort stability
/// and Swift's does not promise it. `Array.prototype.sort` has been stable since ES2019, so
/// upstream's `a.z - b.z` keeps equal-depth dots in emission order. Swift's `sort(by:)` happens to
/// be a stable merge sort today, but the standard library documents the opposite — the order of
/// equal elements is explicitly unspecified — so relying on it would be relying on an
/// implementation detail. Every `shaping` frame emits all its dots at z = 0, so a future change
/// there would scramble an entire state's draw list.
///
/// This does not make the port's order match upstream's everywhere: where a cancellation leaves
/// depths differing by around 1e-16, the last bit of `sin` decides the order and V8's libm and
/// Darwin's disagree. `GoldenComparison` explains why the fixture cannot pin those runs either.
public func finalizeFrame(dots: [Dot], lines: [Line], rMin: Double = 0.3) -> OrbFrame {
    var visible: [(index: Int, dot: Dot)] = []
    visible.reserveCapacity(dots.count)
    for dot in dots where dot.alpha >= 0.02 {
        var dot = dot
        dot.r = max(rMin, dot.r)
        visible.append((visible.count, dot))
    }
    visible.sort { a, b in
        a.dot.z == b.dot.z ? a.index < b.index : a.dot.z < b.dot.z
    }
    return OrbFrame(dots: visible.map(\.dot), lines: lines.filter { $0.alpha >= 0.02 })
}
