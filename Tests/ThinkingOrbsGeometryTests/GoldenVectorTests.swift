import Testing

@testable import ThinkingOrbsGeometry

/// Modes still to be transcribed. Each phase removes entries; `unportedModesProduceNothing`
/// guards the other direction, so a mode cannot half-land and go unnoticed.
private let unported: Set<OrbMode> = [.web, .morph]

private let portedCases = Golden.cases.filter { !unported.contains($0.mode) }

@Suite struct GoldenVectorTests {
    /// Every dot of every ported case against the web engine's own output. See `GoldenComparison`
    /// for the one place ordering is not asserted, and why the fixture cannot assert it.
    @Test(arguments: portedCases)
    func dotsMatchTheWebEngine(_ c: GoldenCase) throws {
        let frame = OrbFrame(state: c.state, size: c.orbSize, at: c.t)

        // Before the field comparison: a count mismatch means a wrong loop bound or a wrong
        // rounding, which is a different bug from wrong arithmetic and would drown in per-index
        // noise if they were reported together.
        try #require(
            frame.dots.count == c.dotCount,
            "\(c.key): got \(frame.dots.count) dots, want \(c.dotCount)")

        let bad = GoldenComparison.mismatches(frame, c, tolerance: Golden.file.tolerance)
        #expect(
            bad.isEmpty,
            "\(c.key): \(bad.count) mismatch(es) — \(bad.prefix(3).joined(separator: "; "))")
    }

    /// A separate test so a failure names which pass broke. A no-op for the sixty-four cases
    /// that emit no lines.
    @Test(arguments: portedCases)
    func lineCountsMatchTheWebEngine(_ c: GoldenCase) throws {
        let frame = OrbFrame(state: c.state, size: c.orbSize, at: c.t)
        #expect(
            frame.lines.count == c.lineCount,
            "\(c.key): got \(frame.lines.count) lines, want \(c.lineCount)")
    }

    /// A mode listed as unported must actually produce nothing, so the filter above can never
    /// quietly hide a half-finished transcription.
    @Test func unportedModesProduceNothing() {
        for c in Golden.cases where unported.contains(c.mode) {
            let frame = OrbFrame(state: c.state, size: c.orbSize, at: c.t)
            #expect(frame.dots.isEmpty && frame.lines.isEmpty, "\(c.key) is no longer empty")
        }
    }

    /// The equal-depth exception must stay narrow. If a future change made whole frames tie, the
    /// comparison would silently stop checking order at all.
    @Test(arguments: portedCases)
    func equalDepthRunsAreTheExceptionNotTheRule(_ c: GoldenCase) {
        let runs = GoldenComparison.depthRuns(c)
        let tied = runs.filter { $0.count > 1 }.reduce(0) { $0 + $1.count }
        #expect(
            tied <= c.dotCount / 2,
            "\(c.key): \(tied) of \(c.dotCount) dots sit in equal-depth runs")
    }
}
