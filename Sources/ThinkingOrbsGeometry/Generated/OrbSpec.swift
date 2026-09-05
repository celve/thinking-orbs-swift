// Generated from Spec/orbs-spec.json (specVersion 1.0.0,
// thinking-orbs 0.3.1) by Scripts/generate-tables.sh.
// Do not edit — run that script instead.
//
// Upstream is MIT, Jakub Antalik; see ThirdPartyLicenses/thinking-orbs.txt.

/// Every option name the engine knows. Keying `ModeOpts` on this rather than `String` is what
/// makes the subscript below exhaustive: a new key cannot be added without handling it.
public enum OptKey: String, CaseIterable, Sendable, Hashable {
    case bandMul
    case dimBase
    case faceOn
    case ghostA
    case ghostN
    case ghostR
    case iconD
    case inkFar
    case inkSpan
    case lanes
    case latRings
    case lineW
    case lonDensity
    case moveCount
    case nodeN
    case nodeR
    case nodeRDepth
    case orbitN
    case partR
    case partRDepth
    case particles
    case rActive
    case rBase
    case rBoost
    case rDepth
    case rDot
    case rMin
    case rSizeMul
    case rings
    case rsPow
    case scanMul
    case segs
    case signals
    case spin
    case spread
    case strandN
    case thr
    case turns
    case wobMul
}

/// The tuned options a mode reads. Optional throughout because absence is observable —
/// `rSizeMul` is missing entirely from three resolved presets, not present-and-1.
public struct ModeOpts: Sendable, Equatable {
    public var bandMul: Double?
    public var dimBase: Double?
    public var faceOn: Double?
    public var ghostA: Double?
    public var ghostN: Double?
    public var ghostR: Double?
    public var iconD: Double?
    public var inkFar: Double?
    public var inkSpan: Double?
    public var lanes: Double?
    public var latRings: Double?
    public var lineW: Double?
    public var lonDensity: Double?
    public var moveCount: Double?
    public var nodeN: Double?
    public var nodeR: Double?
    public var nodeRDepth: Double?
    public var orbitN: Double?
    public var partR: Double?
    public var partRDepth: Double?
    public var particles: Double?
    public var rActive: Double?
    public var rBase: Double?
    public var rBoost: Double?
    public var rDepth: Double?
    public var rDot: Double?
    public var rMin: Double?
    public var rSizeMul: Double?
    public var rings: Double?
    public var rsPow: Double?
    public var scanMul: Double?
    public var segs: Double?
    public var signals: Double?
    public var spin: Double?
    public var spread: Double?
    public var strandN: Double?
    public var thr: Double?
    public var turns: Double?
    public var wobMul: Double?

    public init(
        bandMul: Double? = nil,
        dimBase: Double? = nil,
        faceOn: Double? = nil,
        ghostA: Double? = nil,
        ghostN: Double? = nil,
        ghostR: Double? = nil,
        iconD: Double? = nil,
        inkFar: Double? = nil,
        inkSpan: Double? = nil,
        lanes: Double? = nil,
        latRings: Double? = nil,
        lineW: Double? = nil,
        lonDensity: Double? = nil,
        moveCount: Double? = nil,
        nodeN: Double? = nil,
        nodeR: Double? = nil,
        nodeRDepth: Double? = nil,
        orbitN: Double? = nil,
        partR: Double? = nil,
        partRDepth: Double? = nil,
        particles: Double? = nil,
        rActive: Double? = nil,
        rBase: Double? = nil,
        rBoost: Double? = nil,
        rDepth: Double? = nil,
        rDot: Double? = nil,
        rMin: Double? = nil,
        rSizeMul: Double? = nil,
        rings: Double? = nil,
        rsPow: Double? = nil,
        scanMul: Double? = nil,
        segs: Double? = nil,
        signals: Double? = nil,
        spin: Double? = nil,
        spread: Double? = nil,
        strandN: Double? = nil,
        thr: Double? = nil,
        turns: Double? = nil,
        wobMul: Double? = nil
    ) {
        self.bandMul = bandMul
        self.dimBase = dimBase
        self.faceOn = faceOn
        self.ghostA = ghostA
        self.ghostN = ghostN
        self.ghostR = ghostR
        self.iconD = iconD
        self.inkFar = inkFar
        self.inkSpan = inkSpan
        self.lanes = lanes
        self.latRings = latRings
        self.lineW = lineW
        self.lonDensity = lonDensity
        self.moveCount = moveCount
        self.nodeN = nodeN
        self.nodeR = nodeR
        self.nodeRDepth = nodeRDepth
        self.orbitN = orbitN
        self.partR = partR
        self.partRDepth = partRDepth
        self.particles = particles
        self.rActive = rActive
        self.rBase = rBase
        self.rBoost = rBoost
        self.rDepth = rDepth
        self.rDot = rDot
        self.rMin = rMin
        self.rSizeMul = rSizeMul
        self.rings = rings
        self.rsPow = rsPow
        self.scanMul = scanMul
        self.segs = segs
        self.signals = signals
        self.spin = spin
        self.spread = spread
        self.strandN = strandN
        self.thr = thr
        self.turns = turns
        self.wobMul = wobMul
    }

    public subscript(key: OptKey) -> Double? {
        get {
            switch key {
            case .bandMul: bandMul
            case .dimBase: dimBase
            case .faceOn: faceOn
            case .ghostA: ghostA
            case .ghostN: ghostN
            case .ghostR: ghostR
            case .iconD: iconD
            case .inkFar: inkFar
            case .inkSpan: inkSpan
            case .lanes: lanes
            case .latRings: latRings
            case .lineW: lineW
            case .lonDensity: lonDensity
            case .moveCount: moveCount
            case .nodeN: nodeN
            case .nodeR: nodeR
            case .nodeRDepth: nodeRDepth
            case .orbitN: orbitN
            case .partR: partR
            case .partRDepth: partRDepth
            case .particles: particles
            case .rActive: rActive
            case .rBase: rBase
            case .rBoost: rBoost
            case .rDepth: rDepth
            case .rDot: rDot
            case .rMin: rMin
            case .rSizeMul: rSizeMul
            case .rings: rings
            case .rsPow: rsPow
            case .scanMul: scanMul
            case .segs: segs
            case .signals: signals
            case .spin: spin
            case .spread: spread
            case .strandN: strandN
            case .thr: thr
            case .turns: turns
            case .wobMul: wobMul
            }
        }
        set {
            switch key {
            case .bandMul: bandMul = newValue
            case .dimBase: dimBase = newValue
            case .faceOn: faceOn = newValue
            case .ghostA: ghostA = newValue
            case .ghostN: ghostN = newValue
            case .ghostR: ghostR = newValue
            case .iconD: iconD = newValue
            case .inkFar: inkFar = newValue
            case .inkSpan: inkSpan = newValue
            case .lanes: lanes = newValue
            case .latRings: latRings = newValue
            case .lineW: lineW = newValue
            case .lonDensity: lonDensity = newValue
            case .moveCount: moveCount = newValue
            case .nodeN: nodeN = newValue
            case .nodeR: nodeR = newValue
            case .nodeRDepth: nodeRDepth = newValue
            case .orbitN: orbitN = newValue
            case .partR: partR = newValue
            case .partRDepth: partRDepth = newValue
            case .particles: particles = newValue
            case .rActive: rActive = newValue
            case .rBase: rBase = newValue
            case .rBoost: rBoost = newValue
            case .rDepth: rDepth = newValue
            case .rDot: rDot = newValue
            case .rMin: rMin = newValue
            case .rSizeMul: rSizeMul = newValue
            case .rings: rings = newValue
            case .rsPow: rsPow = newValue
            case .scanMul: scanMul = newValue
            case .segs: segs = newValue
            case .signals: signals = newValue
            case .spin: spin = newValue
            case .spread: spread = newValue
            case .strandN: strandN = newValue
            case .thr: thr = newValue
            case .turns: turns = newValue
            case .wobMul: wobMul = newValue
            }
        }
    }

    /// The keys actually carried, in `OptKey` order. The preset tests compare these as a set,
    /// which is the only signal that catches an option fabricated by a stray `?? 0`.
    public var presentKeys: [OptKey] { OptKey.allCases.filter { self[$0] != nil } }
}

public enum OrbSpec {
    public static let specVersion = "1.0.0"

    /// Unscaled per-mode options, before any preset multiplier is applied.
    public static let baseProfiles: [OrbMode: ModeOpts] = [
        .orbits: ModeOpts(ghostA: 0.5, ghostN: 40.0, ghostR: 0.9, orbitN: 12.0, partR: 1.2, partRDepth: 1.6, particles: 3.0, rMin: 0.3, rsPow: 0.6),
        .globe: ModeOpts(inkFar: 0.62, inkSpan: 0.54, latRings: 17.0, lonDensity: 44.0, rBase: 0.6, rBoost: 1.0, rDepth: 1.7, rMin: 0.3, rsPow: 0.6),
        .rubik: ModeOpts(inkFar: 0.62, inkSpan: 0.54, latRings: 15.0, lonDensity: 40.0, moveCount: 14.0, rActive: 0.3, rBase: 0.6, rDepth: 1.7, rMin: 0.3, rsPow: 0.6),
        .wave: ModeOpts(lonDensity: 40.0, rBase: 0.6, rDepth: 1.7, rMin: 0.3, rings: 15.0, rsPow: 0.6),
        .web: ModeOpts(lineW: 0.8, nodeN: 30.0, nodeR: 1.4, nodeRDepth: 1.8, rMin: 0.3, rsPow: 0.6, signals: 5.0, thr: 0.72),
        .braid: ModeOpts(ghostN: 150.0, rBase: 1.2, rDepth: 1.8, rMin: 0.3, rsPow: 0.6, strandN: 52.0, turns: 3.0),
        .ribbon: ModeOpts(ghostN: 150.0, lanes: 5.0, rBase: 1.1, rDepth: 1.7, rMin: 0.3, rsPow: 0.6, segs: 88.0),
        .ring: ModeOpts(faceOn: 1.0, ghostN: 0.0, lanes: 5.0, rBase: 1.1, rDepth: 1.7, rMin: 0.3, rsPow: 0.6, segs: 88.0),
        .morph: ModeOpts(iconD: 1.0, rDot: 0.021, rMin: 0.25),
    ]

    /// Keyed by pixel size rather than `OrbSize`, so adding a locally tuned size never
    /// requires editing this generated file. See `Presets.local`.
    public static let upstreamPresets: [OrbMode: [Int: Preset]] = [
        .orbits: [
            64: Preset(speed: 1.885, count: 1.0, size: 1.0),
            20: Preset(speed: 3.9, count: 0.238, size: 2.4),
        ],
        .globe: [
            64: Preset(speed: 2.015, count: 0.42, size: 1.15, extra: ModeOpts(dimBase: 0.45, scanMul: 4.08)),
            20: Preset(speed: 2.665, count: 0.105, size: 1.75, extra: ModeOpts(dimBase: 0.45, scanMul: 4.335)),
        ],
        .rubik: [
            64: Preset(speed: 1.82, count: 0.35, size: 1.05),
            20: Preset(speed: 1.95, count: 0.088, size: 1.9),
        ],
        .wave: [
            64: Preset(speed: 4.388, count: 0.341, size: 1.0),
            20: Preset(speed: 3.998, count: 0.105, size: 1.6),
        ],
        .web: [
            64: Preset(speed: 3.315, count: 1.35, size: 0.95),
            20: Preset(speed: 6.63, count: 0.25, size: 1.52),
        ],
        .braid: [
            64: Preset(speed: 1.625, count: 0.5, size: 1.0),
            20: Preset(speed: 2.75, count: 0.1125, size: 1.36),
        ],
        .ribbon: [
            64: Preset(speed: 2.34, count: 0.25, size: 0.85, extra: ModeOpts(bandMul: 3.9, spin: 0.0, wobMul: 1.0)),
            20: Preset(speed: 3.12, count: 0.051, size: 1.073, extra: ModeOpts(bandMul: 4.94, spin: 0.0, wobMul: 1.0)),
        ],
        .ring: [
            64: Preset(speed: 3.24, count: 0.25, size: 0.956, extra: ModeOpts(bandMul: 3.627, spin: 0.0, wobMul: 0.368)),
            20: Preset(speed: 3.78, count: 0.028, size: 1.622, extra: ModeOpts(bandMul: 3.968, spin: 0.0, wobMul: 0.565)),
        ],
        .morph: [
            64: Preset(speed: 2.405, count: 0.702, size: 0.395, extra: ModeOpts(spread: 1.45)),
            20: Preset(speed: 2.08, count: 0.53, size: 1.011, extra: ModeOpts(spread: 1.45)),
        ],
    ]

    /// Scaled together by the square root of the count multiplier; a key joins at most one
    /// pair, which is what the `done` set in `scaleCounts` enforces.
    public static let countPairs: [(OptKey, OptKey)] = [
        (.latRings, .lonDensity),
        (.rings, .lonDensity),
        (.lanes, .segs),
    ]

    public static let countKeys: [OptKey] = [.orbitN, .ghostN, .nodeN, .strandN, .signals]
    public static let iconDensityKeys: [OptKey] = [.iconD]
    public static let radiusKeys: [OptKey] = [.rBase, .rDepth, .rActive, .rDot, .ghostR, .partR, .partRDepth, .nodeR, .nodeRDepth]
}
