import Testing

@testable import ThinkingOrbsGeometry

/// The eighteen resolved presets pin most of the scaling, but seven rules are invisible to them —
/// no shipped profile exercises the branch. These drive `scaleCounts`/`scaleRadii` directly on
/// hand-built options instead. They matter more than their coverage suggests: a locally tuned
/// small size is exactly what would reach the two floors for the first time.
@Suite struct ScalingTests {
    // MARK: - Rules the golden data cannot reach

    /// No shipped profile carries both `latRings` and `rings`, so only a synthetic input pins the
    /// order of `countPairs` and the `done` set that stops a key joining two pairs.
    @Test func pairOrderClaimsLonDensityOnceAndLeavesTheLoserUnscaled() {
        let scaled = scaleCounts(ModeOpts(latRings: 10, lonDensity: 10, rings: 10), 0.25)
        #expect(scaled.latRings == 5)
        #expect(scaled.lonDensity == 5)
        #expect(scaled.rings == 10, "the second pair must be blocked, not scaled again")
    }

    /// Never fires at the shipped counts; a small locally tuned size would be the first to reach it.
    @Test func countKeysFloorAtOne() {
        #expect(scaleCounts(ModeOpts(orbitN: 4), 0.01).orbitN == 1)
    }

    @Test func iconDensityFloorsAtPointZeroTwo() {
        #expect(scaleCounts(ModeOpts(iconD: 1), 0.001).iconD == 0.02)
    }

    /// Pairs floor at 2, not 1, and have no zero exception.
    @Test func pairsFloorAtTwo() {
        let scaled = scaleCounts(ModeOpts(lanes: 3, segs: 3), 0.01)
        #expect(scaled.lanes == 2)
        #expect(scaled.segs == 2)
    }

    /// `extra` merges after both scaling passes and overwrites, so an extra key is never scaled.
    @Test func extraMergesAfterScalingAndWins() {
        let resolved = Presets.resolve(
            mode: .globe,
            preset: Preset(speed: 1, count: 1, size: 2, extra: ModeOpts(rBase: 0.5)))
        #expect(resolved.opts.rBase == 0.5, "extra must overwrite the scaled 0.6 * 2")
    }

    /// Skipping `scaleCounts` at a multiplier of 1 is not the same as running it: the pair floor
    /// would raise a count below 2 even when nothing is being scaled. No shipped profile sits
    /// under a floor, so this needs an injected base to be observable at all.
    @Test func countShortCircuitAtOneIsNotANoOp() {
        let base = ModeOpts(lanes: 1, segs: 1)
        #expect(scaleCounts(base, 1).lanes == 2, "running it would floor to 2")
        let resolved = Presets.resolve(
            mode: .ribbon, base: base, preset: Preset(speed: 1, count: 1, size: 1))
        #expect(resolved.opts.lanes == 1, "the short-circuit must leave it alone")
    }

    /// The same, for radii: at a multiplier of 1 the values would be unchanged, but the key set
    /// would not — `rSizeMul` would appear.
    @Test func sizeShortCircuitAtOneLeavesNoSizeMultiplier() {
        let resolved = Presets.resolve(
            mode: .ribbon, base: ModeOpts(rBase: 1.1), preset: Preset(speed: 1, count: 1, size: 1))
        #expect(resolved.opts.rSizeMul == nil)
    }

    /// The stages commute only because their key sets are disjoint. If that ever stops holding,
    /// the order in `resolve` becomes load-bearing and this test is the warning.
    @Test func countAndRadiusKeySetsAreDisjoint() {
        var counts = Set(OrbSpec.countKeys)
        for (a, b) in OrbSpec.countPairs { counts.formUnion([a, b]) }
        counts.formUnion(OrbSpec.iconDensityKeys)
        #expect(counts.isDisjoint(with: Set(OrbSpec.radiusKeys)))
    }

    // MARK: - Rules the golden data does reach, named so a failure reads plainly

    /// `ring` has no ghost sphere; scaling must not resurrect it as a single stray dot.
    @Test func explicitZeroSurvivesScaling() {
        #expect(scaleCounts(ModeOpts(ghostN: 0), 0.25).ghostN == 0)
    }

    /// `30 * 1.35` is exactly 40.5. Half-up gives 41; banker's rounding would give 40 and break
    /// this preset along with `composing-64` and `breathing-64`.
    @Test func exactHalvesRoundUpNotToEven() {
        #expect(jsRound(40.5) == 41)
        #expect(jsRound(2.5) == 3)
        #expect(ResolvedPreset.resolved(.connecting, .size64).opts.nodeN == 41)
        #expect(ResolvedPreset.resolved(.composing, .size64).opts.lanes == 3)
    }

    /// Radii are multiplied with no rounding and no floor, which is where the resolved presets'
    /// long decimals come from.
    @Test func radiiAreNeitherRoundedNorFloored() {
        let scaled = scaleRadii(ModeOpts(rBase: 0.6, rDepth: 1.7), 1.15)
        #expect(scaled.rBase == 0.6 * 1.15)
        #expect(scaled.rDepth == 1.9549999999999998)
        #expect(scaled.rSizeMul == 1.15)
    }

    /// Written but never read by any mode — it exists only so a resolved preset matches upstream.
    @Test func rSizeMulAppearsOnlyWhenRadiiAreScaled() {
        for state in [OrbState.working, .listening, .weaving] {
            #expect(
                ResolvedPreset.resolved(state, .size64).opts.rSizeMul == nil,
                "\(state)-64 has a size multiplier of 1, so the key must be absent entirely")
        }
        #expect(ResolvedPreset.resolved(.searching, .size64).opts.rSizeMul == 1.15)
    }

    /// Nothing the scaling touches may leak into the shared base table.
    @Test func resolvingDoesNotMutateTheBaseProfiles() {
        let before = OrbSpec.baseProfiles
        for state in OrbState.allCases {
            for size in OrbSize.allCases { _ = ResolvedPreset.resolved(state, size) }
        }
        #expect(OrbSpec.baseProfiles == before)
    }
}
