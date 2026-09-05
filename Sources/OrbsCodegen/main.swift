// Emits Sources/ThinkingOrbsGeometry/Generated/OrbSpec.swift on stdout from Spec/orbs-spec.json.
//
// This tool deliberately does not import ThinkingOrbsGeometry: a broken generated file would
// otherwise break the tool that regenerates it. Agreement with the geometry types is enforced
// by the tests instead, which is a stronger guard than sharing them would be.

import Foundation

// MARK: - Input

struct Spec: Decodable {
    struct Enums: Decodable {
        let states: [String]
        let sizes: [Int]
        let modes: [String]
    }
    struct Preset: Decodable {
        let speed: Double
        let count: Double
        let size: Double
        let extra: [String: Double]?
    }
    struct Scaling: Decodable {
        let countPairs: [[String]]
        let countKeys: [String]
        let iconDensityKeys: [String]
        let radiusKeys: [String]
    }

    let specVersion: String
    let sourceLibrary: [String: String]
    let enums: Enums
    let baseProfiles: [String: [String: Double]]
    let presets: [String: [String: Preset]]
    let scaling: Scaling
}

func die(_ message: String) -> Never {
    FileHandle.standardError.write(Data("orbs-codegen: \(message)\n".utf8))
    exit(1)
}

let root = URL(fileURLWithPath: #filePath)
    .deletingLastPathComponent()
    .deletingLastPathComponent()
    .deletingLastPathComponent()
let specURL = root.appendingPathComponent("Spec/orbs-spec.json")

guard let data = try? Data(contentsOf: specURL) else { die("could not read \(specURL.path)") }
guard let spec = try? JSONDecoder().decode(Spec.self, from: data) else {
    die("could not decode \(specURL.path)")
}

// MARK: - The option-key universe

// `rSizeMul` is written by scaleRadii but appears nowhere in the spec's data — it occurs once in
// the whole file, inside the English prose of scaling.rules.radius. It is nonetheless the 39th key
// of golden.resolved, so the generator injects it and pins the count either side of the injection.
let injected = "rSizeMul"
var derived = Set<String>()
for profile in spec.baseProfiles.values { derived.formUnion(profile.keys) }
for byMode in spec.presets.values {
    for preset in byMode.values {
        if let extra = preset.extra { derived.formUnion(extra.keys) }
    }
}
guard derived.count == 38 else {
    die("expected 38 option keys in the spec's data, found \(derived.count) — upstream changed shape")
}
guard !derived.contains(injected) else { die("\(injected) is now in the spec; drop the injection") }
let optKeys = derived.union([injected]).sorted()

// Every name the scaling rules reference must be a real key, or a rule would silently never fire.
let scalingNames =
    spec.scaling.countPairs.flatMap { $0 } + spec.scaling.countKeys
    + spec.scaling.iconDensityKeys + spec.scaling.radiusKeys
for name in scalingNames where !optKeys.contains(name) {
    die("scaling references unknown option key '\(name)'")
}
for pair in spec.scaling.countPairs where pair.count != 2 {
    die("countPairs entry is not a pair: \(pair)")
}

// Every mode must have a base profile and a preset at every shipped size.
for mode in spec.enums.modes {
    guard spec.baseProfiles[mode] != nil else { die("no base profile for mode '\(mode)'") }
    for size in spec.enums.sizes where spec.presets[mode]?[String(size)] == nil {
        die("no preset for \(mode) at size \(size)")
    }
}

// MARK: - Emission

/// Shortest round-trip representation, verified to re-parse to the identical bit pattern — the
/// preset tests compare against golden.resolved with `==`, so a lossy literal here would fail them.
func lit(_ value: Double) -> String {
    let text = "\(value)"
    guard let back = Double(text), back.bitPattern == value.bitPattern else {
        die("literal \(text) does not round-trip")
    }
    return text
}

@MainActor
func opts(_ values: [String: Double]) -> String {
    let set = optKeys.filter { values[$0] != nil }.map { "\($0): \(lit(values[$0]!))" }
    return "ModeOpts(\(set.joined(separator: ", ")))"
}

var out = ""
@MainActor
func line(_ text: String = "") { out += text + "\n" }

line("// Generated from Spec/orbs-spec.json (specVersion \(spec.specVersion),")
line("// thinking-orbs \(spec.sourceLibrary["version"] ?? "?")) by Scripts/generate-tables.sh.")
line("// Do not edit — run that script instead.")
line("//")
line("// Upstream is MIT, Jakub Antalik; see ThirdPartyLicenses/thinking-orbs.txt.")
line()

// OptKey
line("/// Every option name the engine knows. Keying `ModeOpts` on this rather than `String` is what")
line("/// makes the subscript below exhaustive: a new key cannot be added without handling it.")
line("public enum OptKey: String, CaseIterable, Sendable, Hashable {")
for key in optKeys { line("    case \(key)") }
line("}")
line()

// ModeOpts
line("/// The tuned options a mode reads. Optional throughout because absence is observable —")
line("/// `rSizeMul` is missing entirely from three resolved presets, not present-and-1.")
line("public struct ModeOpts: Sendable, Equatable {")
for key in optKeys { line("    public var \(key): Double?") }
line()
line("    public init(")
line(optKeys.map { "        \($0): Double? = nil" }.joined(separator: ",\n"))
line("    ) {")
for key in optKeys { line("        self.\(key) = \(key)") }
line("    }")
line()
line("    public subscript(key: OptKey) -> Double? {")
line("        get {")
line("            switch key {")
for key in optKeys { line("            case .\(key): \(key)") }
line("            }")
line("        }")
line("        set {")
line("            switch key {")
for key in optKeys { line("            case .\(key): \(key) = newValue") }
line("            }")
line("        }")
line("    }")
line()
line("    /// The keys actually carried, in `OptKey` order. The preset tests compare these as a set,")
line("    /// which is the only signal that catches an option fabricated by a stray `?? 0`.")
line("    public var presentKeys: [OptKey] { OptKey.allCases.filter { self[$0] != nil } }")
line("}")
line()

// The upstream tables
line("public enum OrbSpec {")
line("    public static let specVersion = \"\(spec.specVersion)\"")
line()
line("    /// Unscaled per-mode options, before any preset multiplier is applied.")
line("    public static let baseProfiles: [OrbMode: ModeOpts] = [")
for mode in spec.enums.modes {
    line("        .\(mode): \(opts(spec.baseProfiles[mode]!)),")
}
line("    ]")
line()
line("    /// Keyed by pixel size rather than `OrbSize`, so adding a locally tuned size never")
line("    /// requires editing this generated file. See `Presets.local`.")
line("    public static let upstreamPresets: [OrbMode: [Int: Preset]] = [")
for mode in spec.enums.modes {
    line("        .\(mode): [")
    for size in spec.enums.sizes {
        let p = spec.presets[mode]![String(size)]!
        let extra = p.extra.map { ", extra: \(opts($0))" } ?? ""
        line(
            "            \(size): Preset(speed: \(lit(p.speed)), count: \(lit(p.count)), "
                + "size: \(lit(p.size))\(extra)),")
    }
    line("        ],")
}
line("    ]")
line()
line("    /// Scaled together by the square root of the count multiplier; a key joins at most one")
line("    /// pair, which is what the `done` set in `scaleCounts` enforces.")
line("    public static let countPairs: [(OptKey, OptKey)] = [")
for pair in spec.scaling.countPairs { line("        (.\(pair[0]), .\(pair[1])),") }
line("    ]")
line()
for (name, keys) in [
    ("countKeys", spec.scaling.countKeys),
    ("iconDensityKeys", spec.scaling.iconDensityKeys),
    ("radiusKeys", spec.scaling.radiusKeys),
] {
    line("    public static let \(name): [OptKey] = [\(keys.map { ".\($0)" }.joined(separator: ", "))]")
}
line("}")

FileHandle.standardOutput.write(Data(out.utf8))
