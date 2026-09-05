// The paint contract, ported from thinking-orbs' src/engine/core.ts (MIT, Jakub Antalik);
// see ThirdPartyLicenses/thinking-orbs.txt.

import ThinkingOrbsGeometry

/// Turns a mark's ink value into a grey.
///
/// The eight-bit quantisation is part of the contract, not an artefact: upstream builds an
/// `rgba(g,g,g,a)` string from a rounded byte, and the React Native port rounds identically so the
/// platforms land on the same greys rather than merely close ones.
///
/// Both clamps are load-bearing, and neither is redundant. Across the seventy-two golden cases
/// `white` runs from -0.058 to 0.78 and `alpha` from 0.100 to 1.015 — eleven dots in `solving`
/// carry a negative ink value and four in `weaving` an alpha above one. CSS clamps both silently;
/// SwiftUI does not. The geometry stores them unclamped because that is what the fixture records,
/// so the clamping belongs here.
public struct OrbInk: Sendable, Equatable {
    public var dark: Bool

    public init(dark: Bool) { self.dark = dark }

    /// Grey level in 0...1, already quantised to eight bits, and opacity in 0...1.
    public func components(white: Double, alpha: Double) -> (grey: Double, opacity: Double) {
        let w = min(1, max(0, white))
        let mirrored = dark ? 1 - w : w
        return ((mirrored * 255).rounded() / 255, min(1, max(0, alpha)))
    }
}
