// Ported from thinking-orbs' src/engine/registry.ts (MIT, Jakub Antalik);
// see ThirdPartyLicenses/thinking-orbs.txt.

extension OrbMode {
    /// The geometry for one instant. `t` is engine time, already multiplied by the preset speed.
    public func frame(size: Double, t: Double, opts o: ModeOpts) -> OrbFrame {
        switch self {
        case .globe: frameGlobe(size: size, t: t, opts: o)
        case .rubik: frameRubik(size: size, t: t, opts: o)
        case .wave: frameWave(size: size, t: t, opts: o)
        case .orbits: frameOrbits(size: size, t: t, opts: o)
        case .braid: frameBraid(size: size, t: t, opts: o)
        // `ring` is `ribbon` with the `faceOn` flag set, which the preset supplies.
        case .ribbon, .ring: frameRibbon(size: size, t: t, opts: o)
        case .web, .morph: OrbFrame()
        }
    }
}
