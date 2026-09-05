// Ported from thinking-orbs' src/presets.ts (MIT, Jakub Antalik);
// see ThirdPartyLicenses/thinking-orbs.txt.

/// Rendered size in points. Upstream ships two tuned presets — 64 and 20 — which are separate
/// designs rather than a scale factor. This enum is deliberately hand-written rather than
/// generated, so a locally tuned size can be added without editing a generated file.
public enum OrbSize: Int, CaseIterable, Sendable, Codable {
    case size64 = 64
    case size20 = 20

    public var points: Double { Double(rawValue) }
}

/// A mode's tuning at one size: multipliers on the base profile, plus options that bypass scaling.
public struct Preset: Sendable, Equatable {
    public var speed: Double
    public var count: Double
    public var size: Double
    public var extra: ModeOpts?

    public init(speed: Double, count: Double, size: Double, extra: ModeOpts? = nil) {
        self.speed = speed
        self.count = count
        self.size = size
        self.extra = extra
    }
}

/// A state and size resolved to the mode, clock multiplier and options a frame needs.
public struct ResolvedPreset: Sendable, Equatable {
    public var mode: OrbMode
    public var speed: Double
    public var opts: ModeOpts
}

public enum Presets {
    /// Locally tuned sizes, merged over the upstream table. Adding a size means one `OrbSize` case
    /// and one row per mode here; no golden data exists for it, so its values are a judgement call.
    public static let local: [OrbMode: [Int: Preset]] = [:]

    static func preset(_ mode: OrbMode, _ size: OrbSize) -> Preset? {
        local[mode]?[size.rawValue] ?? OrbSpec.upstreamPresets[mode]?[size.rawValue]
    }

    /// Every combination, resolved once. A lazy `static let` is initialised exactly once and is
    /// atomic, so this is the memoisation upstream's `Map` provides without a mutable global.
    static let table: [Key: ResolvedPreset] = {
        var table: [Key: ResolvedPreset] = [:]
        for state in OrbState.allCases {
            for size in OrbSize.allCases {
                guard let preset = preset(state.mode, size) else { continue }
                table[Key(state: state, size: size)] = resolve(mode: state.mode, preset: preset)
            }
        }
        return table
    }()

    struct Key: Hashable, Sendable {
        var state: OrbState
        var size: OrbSize
    }

    /// Pure, so the tests and any custom preset can drive it directly.
    public static func resolve(mode: OrbMode, preset: Preset) -> ResolvedPreset {
        resolve(mode: mode, base: OrbSpec.baseProfiles[mode] ?? ModeOpts(), preset: preset)
    }

    /// The base profile is a parameter so the two `!= 1` short-circuits can be tested. Both are
    /// unobservable on the shipped profiles — skipping the scaling at a multiplier of 1 differs
    /// from running it only where a value sits below one of the floors, and none does.
    public static func resolve(mode: OrbMode, base: ModeOpts, preset: Preset) -> ResolvedPreset {
        var opts = base
        // Guarded, not unconditional: skipping scaleRadii at 1 is why three presets carry no
        // rSizeMul key at all, rather than rSizeMul == 1.
        if preset.count != 1 { opts = scaleCounts(opts, preset.count) }
        if preset.size != 1 { opts = scaleRadii(opts, preset.size) }
        if let extra = preset.extra {
            for k in extra.presentKeys { opts[k] = extra[k] }
        }
        return ResolvedPreset(mode: mode, speed: preset.speed, opts: opts)
    }
}

extension ResolvedPreset {
    /// The resolved tuning for a state at a size.
    public static func resolved(_ state: OrbState, _ size: OrbSize) -> ResolvedPreset {
        Presets.table[Presets.Key(state: state, size: size)]!
    }
}
