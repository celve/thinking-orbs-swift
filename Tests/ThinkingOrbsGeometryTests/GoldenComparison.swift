import Foundation

@testable import ThinkingOrbsGeometry

/// Compares a rendered frame against a golden case.
///
/// The comparison is strict — index by index — and only relaxes where the fixture cannot support
/// strictness. Upstream sorts on full-precision depth and only then rounds to six decimals for the
/// file, so a run of dots recording the same `z` may have had true depths differing by around
/// 1e-16: residues of a cancellation, decided by the last bit of `sin` and `cos`. V8's libm and
/// Darwin's disagree there for roughly one dot in forty, which reorders such a run. Nothing in the
/// file distinguishes one order from the other, so within a run that fails strictly the dots are
/// matched as a set instead, and the run is reported as reordered rather than wrong.
///
/// That fallback is deliberately narrow. `shaping` emits every dot at a literal `z: 0`, so both
/// engines agree exactly and its ordering is checked strictly like any other; only genuine
/// floating-point ambiguity is excused, and `reorderedRuns` is asserted against a known list.
enum GoldenComparison {
    struct Result {
        var mismatches: [String] = []
        /// Equal-depth runs that matched only as a set. Expected to be rare and specific.
        var reorderedRuns: [Range<Int>] = []
    }

    private static func dotFields(_ d: Dot, _ c: GoldenCase, _ i: Int) -> [(String, Double, Double)] {
        [
            ("x", d.x, c.dots[i * 6]),
            ("y", d.y, c.dots[i * 6 + 1]),
            ("z", d.z, c.dots[i * 6 + 2]),
            ("r", d.r, c.dots[i * 6 + 3]),
            ("white", d.white, c.dots[i * 6 + 4]),
            ("a", d.alpha, c.dots[i * 6 + 5]),
        ]
    }

    private static func lineFields(_ l: Line, _ c: GoldenCase, _ i: Int) -> [(String, Double, Double)] {
        [
            ("x1", l.x1, c.lines[i * 7]),
            ("y1", l.y1, c.lines[i * 7 + 1]),
            ("x2", l.x2, c.lines[i * 7 + 2]),
            ("y2", l.y2, c.lines[i * 7 + 3]),
            ("white", l.white, c.lines[i * 7 + 4]),
            ("a", l.alpha, c.lines[i * 7 + 5]),
            ("w", l.width, c.lines[i * 7 + 6]),
        ]
    }

    /// Runs of golden dot indices sharing one recorded depth. Most runs hold a single dot.
    static func depthRuns(_ c: GoldenCase) -> [Range<Int>] {
        guard c.dotCount > 0 else { return [] }
        var runs: [Range<Int>] = []
        var start = 0
        for i in 1...c.dotCount where i == c.dotCount || c.dots[i * 6 + 2] != c.dots[start * 6 + 2] {
            runs.append(start..<i)
            start = i
        }
        return runs
    }

    static func compare(_ frame: OrbFrame, _ c: GoldenCase, tolerance: Double) -> Result {
        var result = Result()

        for run in depthRuns(c) {
            // Strict first: this is the comparison that matters, and for all but one shipped
            // case it is the only one that runs.
            var strict: [String] = []
            for i in run {
                for (name, got, want) in dotFields(frame.dots[i], c, i) where abs(got - want) > tolerance {
                    strict.append("dot[\(i)].\(name) got \(got) want \(want) delta \(got - want)")
                }
            }
            if strict.isEmpty { continue }
            guard run.count > 1 else {
                result.mismatches += strict
                continue
            }

            // The run may simply be permuted. Match each rendered dot to an unclaimed golden one.
            var unclaimed = Set(run)
            var unmatched: [String] = []
            for i in run {
                let dot = frame.dots[i]
                let match = unclaimed.first { j in
                    dotFields(dot, c, j).allSatisfy { abs($0.1 - $0.2) <= tolerance }
                }
                guard let match else {
                    unmatched.append(
                        "dot[\(i)] has no counterpart in the equal-depth run \(run) "
                            + "(x \(dot.x), y \(dot.y), r \(dot.r))")
                    continue
                }
                unclaimed.remove(match)
            }
            if unmatched.isEmpty {
                result.reorderedRuns.append(run)
            } else {
                result.mismatches += unmatched
            }
        }

        for i in 0..<c.lineCount {
            for (name, got, want) in lineFields(frame.lines[i], c, i) where abs(got - want) > tolerance {
                result.mismatches.append("line[\(i)].\(name) got \(got) want \(want)")
            }
        }
        return result
    }
}
