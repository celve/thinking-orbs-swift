// Ported from thinking-orbs' src/types.ts and src/presets.ts (MIT, Jakub Antalik);
// see ThirdPartyLicenses/thinking-orbs.txt.

/// The nine shipped states, each a distinct animation.
public enum OrbState: String, CaseIterable, Sendable, Codable {
    case working, searching, solving, listening, connecting, weaving, composing, breathing, shaping

    public var mode: OrbMode {
        switch self {
        case .working: .orbits
        case .searching: .globe
        case .solving: .rubik
        case .listening: .wave
        case .connecting: .web
        case .weaving: .braid
        case .composing: .ribbon
        case .breathing: .ring
        case .shaping: .morph
        }
    }

    /// Upstream's per-state default; `breathing` deliberately reads "Thinking…", not "Breathing…".
    public var accessibilityLabel: String {
        switch self {
        case .working: "Working…"
        case .searching: "Searching…"
        case .solving: "Solving…"
        case .listening: "Listening…"
        case .connecting: "Connecting…"
        case .weaving: "Weaving…"
        case .composing: "Composing…"
        case .breathing: "Thinking…"
        case .shaping: "Shaping…"
        }
    }
}

/// Geometry builders. `ring` shares `ribbon`'s implementation, switched by the `faceOn` option.
public enum OrbMode: String, CaseIterable, Sendable, Codable {
    case orbits, globe, rubik, wave, web, braid, ribbon, ring, morph
}
