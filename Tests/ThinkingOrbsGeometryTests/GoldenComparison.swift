import Foundation

@testable import ThinkingOrbsGeometry

/// Compares a rendered frame against a golden case.
///
/// Dots are compared index by index, except within a run of dots whose *recorded* depth is
/// identical, where they are compared as an unordered set instead. That exception is not a
/// convenience — it is the strongest comparison the fixture supports.
///
/// Upstream sorts on full-precision depth and only then rounds to six decimals for the file. A
/// face-on band therefore lands in the file as a run of dots all recording `z: 0` whose true
/// depths differ by around 1e-16 — residues of a cancellation, decided by the last bit of `sin`
/// and `cos`. V8's libm and Darwin's disagree there for roughly one dot in forty, which reorders
/// the run. Since the file records those depths as equal, nothing in it distinguishes one order
/// from the other, and no renderer can reconstruct upstream's. Every value is still checked; only
/// the order within an equal-depth run is not, and dots at equal depth do not occlude each other.
enum GoldenComparison {
    struct Field {
        let name: String
        let got: Double
        let want: Double
    }

    static func dotFields(_ d: Dot, _ c: GoldenCase, _ i: Int) -> [Field] {
        [
            Field(name: "x", got: d.x, want: c.dots[i * 6]),
            Field(name: "y", got: d.y, want: c.dots[i * 6 + 1]),
            Field(name: "z", got: d.z, want: c.dots[i * 6 + 2]),
            Field(name: "r", got: d.r, want: c.dots[i * 6 + 3]),
            Field(name: "white", got: d.white, want: c.dots[i * 6 + 4]),
            Field(name: "a", got: d.alpha, want: c.dots[i * 6 + 5]),
        ]
    }

    static func lineFields(_ l: Line, _ c: GoldenCase, _ i: Int) -> [Field] {
        [
            Field(name: "x1", got: l.x1, want: c.lines[i * 7]),
            Field(name: "y1", got: l.y1, want: c.lines[i * 7 + 1]),
            Field(name: "x2", got: l.x2, want: c.lines[i * 7 + 2]),
            Field(name: "y2", got: l.y2, want: c.lines[i * 7 + 3]),
            Field(name: "white", got: l.white, want: c.lines[i * 7 + 4]),
            Field(name: "a", got: l.alpha, want: c.lines[i * 7 + 5]),
            Field(name: "w", got: l.width, want: c.lines[i * 7 + 6]),
        ]
    }

    /// Runs of golden dot indices sharing one recorded depth. Most runs are a single dot.
    static func depthRuns(_ c: GoldenCase) -> [Range<Int>] {
        var runs: [Range<Int>] = []
        var start = 0
        for i in 1...max(c.dotCount, 1) where i == c.dotCount || c.dots[i * 6 + 2] != c.dots[start * 6 + 2] {
            runs.append(start..<i)
            start = i
        }
        return c.dotCount == 0 ? [] : runs
    }

    /// Every mismatch, as readable lines. Empty means the frame matches.
    static func mismatches(_ frame: OrbFrame, _ c: GoldenCase, tolerance: Double) -> [String] {
        var bad: [String] = []

        for run in depthRuns(c) {
            if run.count == 1 {
                let i = run.lowerBound
                for f in dotFields(frame.dots[i], c, i) where abs(f.got - f.want) > tolerance {
                    bad.append("dot[\(i)].\(f.name) got \(f.got) want \(f.want) delta \(f.got - f.want)")
                }
                continue
            }
            // An equal-depth run: match each rendered dot to an unclaimed golden dot.
            var unclaimed = Set(run)
            for i in run {
                let dot = frame.dots[i]
                let match = unclaimed.first { j in
                    dotFields(dot, c, j).allSatisfy { abs($0.got - $0.want) <= tolerance }
                }
                guard let match else {
                    bad.append(
                        "dot[\(i)] has no counterpart in the equal-depth run \(run) "
                            + "(x \(dot.x), y \(dot.y), r \(dot.r))")
                    continue
                }
                unclaimed.remove(match)
            }
        }

        for i in 0..<c.lineCount {
            for f in lineFields(frame.lines[i], c, i) where abs(f.got - f.want) > tolerance {
                bad.append("line[\(i)].\(f.name) got \(f.got) want \(f.want)")
            }
        }
        return bad
    }
}
