import Foundation

@testable import ThinkingOrbsGeometry

/// `Spec/orbs-golden.json`, decoded once. Upstream generates it with `scripts/extract-golden.ts`;
/// dots are flat at stride 6 and lines at stride 7, both already in draw order.
struct GoldenFile: Decodable, Sendable {
    struct Source: Decodable, Sendable {
        let name: String
        let version: String
    }
    struct Resolved: Decodable, Sendable {
        let mode: OrbMode
        let speed: Double
        let opts: [String: Double]
    }

    let specVersion: String
    let sourceLibrary: Source
    let tolerance: Double
    let times: [Double]
    let resolved: [String: Resolved]
    let cases: [GoldenCase]
}

struct GoldenCase: Decodable, Sendable {
    let key: String
    let state: OrbState
    let size: Int
    let mode: OrbMode
    let t: Double
    let dotCount: Int
    let lineCount: Int
    let dots: [Double]
    let lines: [Double]

    var orbSize: OrbSize { OrbSize(rawValue: size)! }
}

/// One resolved preset, lifted out of the dictionary so it can be a test argument.
struct GoldenPreset: Sendable {
    let key: String
    let state: OrbState
    let size: OrbSize
    let resolved: GoldenFile.Resolved
}

enum Golden {
    /// The fixture is a development file read from the repo, not a bundled resource — it costs a
    /// consumer nothing. Tests live three directories below the root.
    static let file: GoldenFile = {
        let root = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let url = root.appendingPathComponent("Spec/orbs-golden.json")
        do {
            return try JSONDecoder().decode(GoldenFile.self, from: Data(contentsOf: url))
        } catch {
            fatalError("could not load \(url.path): \(error)")
        }
    }()

    static let cases: [GoldenCase] = file.cases

    static let presets: [GoldenPreset] = file.resolved
        .map { key, resolved in
            let parts = key.split(separator: "-")
            return GoldenPreset(
                key: key,
                state: OrbState(rawValue: String(parts[0]))!,
                size: OrbSize(rawValue: Int(parts[1])!)!,
                resolved: resolved)
        }
        .sorted { $0.key < $1.key }

    /// Every option name appearing anywhere in the resolved block.
    static let resolvedKeyNames: Set<String> = Set(file.resolved.values.flatMap(\.opts.keys))
}

extension GoldenCase: CustomStringConvertible {
    var description: String { key }
}

extension GoldenPreset: CustomStringConvertible {
    var description: String { key }
}
