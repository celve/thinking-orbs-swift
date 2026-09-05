import Testing

@testable import ThinkingOrbsGeometry

/// The only cases where a run of equal recorded depths comes out permuted relative to upstream:
/// the face-on band of `breathing` at 64, where the projection cancels to a residue of about
/// 1e-16 and the last bit of `sin` decides the order. See `GoldenComparison`.
private let knownReordered: Set<String> = [
    "breathing-64-1.7", "breathing-64-3.3", "breathing-64-5.1",
]

@Suite struct GoldenVectorTests {
    /// Every dot and line of every case against the web engine's own output.
    @Test(arguments: Golden.cases)
    func matchesTheWebEngine(_ c: GoldenCase) throws {
        let frame = OrbFrame(state: c.state, size: c.orbSize, at: c.t)

        // Before the field comparison: a count mismatch means a wrong loop bound or a wrong
        // rounding, which is a different bug from wrong arithmetic and would drown in per-index
        // noise if they were reported together.
        try #require(
            frame.dots.count == c.dotCount,
            "\(c.key): got \(frame.dots.count) dots, want \(c.dotCount)")

        let result = GoldenComparison.compare(frame, c, tolerance: Golden.file.tolerance)
        #expect(
            result.mismatches.isEmpty,
            "\(c.key): \(result.mismatches.count) mismatch(es) — \(result.mismatches.prefix(3).joined(separator: "; "))")
    }

    /// Separate from the field comparison so a wrong edge count reads as its own failure rather
    /// than as a wall of shifted line values. A no-op for the sixty-four cases with no edges.
    @Test(arguments: Golden.cases)
    func lineCountsMatchTheWebEngine(_ c: GoldenCase) throws {
        let frame = OrbFrame(state: c.state, size: c.orbSize, at: c.t)
        #expect(
            frame.lines.count == c.lineCount,
            "\(c.key): got \(frame.lines.count) lines, want \(c.lineCount)")
    }

    /// Pins how much of the oracle runs unordered. Everything else is compared strictly, so a new
    /// entry here would mean a transcription had started drifting, not that libm had.
    @Test(arguments: Golden.cases)
    func onlyTheKnownRunsAreComparedAsSets(_ c: GoldenCase) {
        let frame = OrbFrame(state: c.state, size: c.orbSize, at: c.t)
        let result = GoldenComparison.compare(frame, c, tolerance: Golden.file.tolerance)
        if knownReordered.contains(c.key) {
            #expect(result.reorderedRuns.count == 1, "\(c.key) should need exactly one set match")
        } else {
            #expect(
                result.reorderedRuns.isEmpty,
                "\(c.key) is newly order-ambiguous at \(result.reorderedRuns)")
        }
    }

    @Test func everyGoldenCaseIsExercised() {
        #expect(Golden.cases.count == 72)
    }
}
