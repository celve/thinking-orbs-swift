import Testing

@testable import ThinkingOrbsGeometry

/// Pins the shape of the vendored fixture. These fail the moment `Spec/` is re-vendored from a
/// different upstream version, which is the signal to re-run the generator and re-read the goldens.
@Suite struct FixtureTests {
    @Test func fixtureIsTheVersionThisPortWasWrittenAgainst() {
        #expect(Golden.file.specVersion == "1.0.0")
        #expect(Golden.file.sourceLibrary.name == "thinking-orbs")
        #expect(Golden.file.sourceLibrary.version == "0.3.1")
    }

    @Test func coversEveryStateAtEverySizeAtEveryTimestamp() {
        #expect(Golden.file.times == [0.6, 1.7, 3.3, 5.1])
        #expect(Golden.cases.count == OrbState.allCases.count * OrbSize.allCases.count * 4)
        #expect(Golden.presets.count == 18)
        for state in OrbState.allCases {
            for size in OrbSize.allCases {
                let matching = Golden.cases.filter { $0.state == state && $0.orbSize == size }
                #expect(matching.count == 4, "\(state)-\(size.rawValue)")
            }
        }
    }

    /// The tolerance belongs to `cases`, whose values upstream rounds to six decimals. The
    /// `resolved` block is emitted unrounded, so preset tests compare exactly instead.
    @Test func toleranceIsTheOneUpstreamChose() {
        #expect(Golden.file.tolerance == 1e-4)
    }

    @Test func flatArraysAreWellFormed() {
        for c in Golden.cases {
            #expect(c.dots.count == c.dotCount * 6, "\(c.key) dots")
            #expect(c.lines.count == c.lineCount * 7, "\(c.key) lines")
            #expect(c.state.mode == c.mode, "\(c.key) mode")
        }
    }

    /// Only `connecting` emits line segments, and only at size 64.
    @Test func linesAppearOnlyWhereExpected() {
        for c in Golden.cases where c.lineCount > 0 {
            #expect(c.state == .connecting && c.orbSize == .size64, "\(c.key)")
        }
    }
}
