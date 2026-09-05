import Testing

@testable import ThinkingOrbsGeometry

/// Which scaling rule owns a key. The four key lists are disjoint, so attribution is unambiguous,
/// and a difference in a pass-through key means the bug is in the generated base table or the
/// `extra` merge — never in the scaling.
enum Rule: String {
    case countPair, countKey, iconDensity, radius, rSizeMul, passThrough

    static func owner(of key: OptKey) -> Rule {
        if key == .rSizeMul { return .rSizeMul }
        if OrbSpec.countPairs.contains(where: { $0.0 == key || $0.1 == key }) { return .countPair }
        if OrbSpec.countKeys.contains(key) { return .countKey }
        if OrbSpec.iconDensityKeys.contains(key) { return .iconDensity }
        if OrbSpec.radiusKeys.contains(key) { return .radius }
        return .passThrough
    }
}

@Suite struct PresetTests {
    /// Compared with `==`, not a tolerance: upstream rounds to six decimals only inside `cases`,
    /// so `resolved` carries full double precision, and every scaling operation is IEEE-exact.
    @Test(arguments: Golden.presets)
    func matchesGoldenResolved(_ preset: GoldenPreset) throws {
        let got = ResolvedPreset.resolved(preset.state, preset.size)
        let want = preset.resolved

        #expect(got.mode == want.mode)
        #expect(got.speed == want.speed, "\(preset.key): speed table drift")

        let mine = Set(got.opts.presentKeys)
        let theirs = Set(want.opts.keys.compactMap { OptKey(rawValue: $0) })
        #expect(
            mine == theirs,
            """
            \(preset.key): key set differs
              fabricated: \(mine.subtracting(theirs).map(\.rawValue).sorted())
              missing:    \(theirs.subtracting(mine).map(\.rawValue).sorted())
              rules:      \(Set(mine.symmetricDifference(theirs).map { Rule.owner(of: $0).rawValue }).sorted())
            """)

        // No early exit, so one run shows the whole shape of a failure.
        for key in OptKey.allCases {
            guard let want = want.opts[key.rawValue], let got = got.opts[key] else { continue }
            #expect(
                got == want,
                "\(preset.key).\(key.rawValue): got \(got) want \(want) [rule: \(Rule.owner(of: key))]")
        }
    }

    /// Fires in both directions: upstream adding a fortieth key, or the generated struct going
    /// stale. Synthesised `Codable` ignores unknown JSON keys, so nothing else would notice.
    @Test func optionKeyUniverseMatchesGolden() {
        let fromGolden = Set(Golden.resolvedKeyNames)
        let fromCode = Set(OptKey.allCases.map(\.rawValue))
        #expect(fromGolden == fromCode, "unknown in golden: \(fromGolden.subtracting(fromCode))")
        #expect(OptKey.allCases.count == 39)
    }

    /// A crossed getter/setter pair, or a case handled in one switch but not the other.
    @Test func subscriptRoundTripsEveryKey() {
        for key in OptKey.allCases {
            var opts = ModeOpts()
            opts[key] = 1
            #expect(opts[key] == 1, "\(key.rawValue) did not read back")
            #expect(opts.presentKeys == [key], "\(key.rawValue) wrote a different field")
        }
    }

    @Test func everyStateResolvesAtEverySize() {
        for state in OrbState.allCases {
            for size in OrbSize.allCases {
                #expect(Presets.preset(state.mode, size) != nil, "\(state)-\(size.rawValue)")
            }
        }
    }
}
