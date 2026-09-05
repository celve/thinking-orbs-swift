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
