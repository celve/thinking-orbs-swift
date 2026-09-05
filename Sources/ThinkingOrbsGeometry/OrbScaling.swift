// Ported from thinking-orbs' src/engine/profiles.ts (MIT, Jakub Antalik);
// see ThirdPartyLicenses/thinking-orbs.txt.
//
// Transcribed from the TypeScript, not from orbs-spec.json's prose summary of these rules: the
// prose omits the `done`-set interaction, the two `!== 1` short-circuits in resolvePreset, and
// that `extra` merges after scaling.

import Foundation

/// `Math.round` rounds halves toward +infinity; Swift's `.rounded()` rounds them away from zero.
/// Every value scaled here is positive, so the two agree — but `.rounded(.toNearestOrEven)`, which
/// is what `lrint` and `nearbyint` do by default, does not: it would turn `nodeN` 40.5 into 40 and
/// `lanes` 2.5 into 2, breaking three of the eighteen presets.
@inlinable
func jsRound(_ x: Double) -> Double { (x + 0.5).rounded(.down) }

/// Scale the count-like options. Pairs share a square root so a lattice stays roughly square;
/// flat counts scale linearly.
public func scaleCounts(_ opts: ModeOpts, _ scale: Double) -> ModeOpts {
    var out = opts
    var done = Set<OptKey>()
    let rt = scale.squareRoot()

    for (a, b) in OrbSpec.countPairs {
        guard let va = out[a], let vb = out[b], !done.contains(a), !done.contains(b) else { continue }
        out[a] = max(2, jsRound(va * rt))
        out[b] = max(2, jsRound(vb * rt))
        done.insert(a)
        done.insert(b)
    }

    for k in OrbSpec.countKeys {
        // An explicit 0 means the mode opted out of that layer entirely — `ring` has no ghost
        // sphere — so scaling must not resurrect it as a single stray dot.
        guard let v = out[k], v != 0, !done.contains(k) else { continue }
        out[k] = max(1, jsRound(v * scale))
    }

    for k in OrbSpec.iconDensityKeys {
        guard let v = out[k] else { continue }
        out[k] = max(0.02, v * scale)
    }

    return out
}

/// Scale the radius-like options. Neither rounds nor floors, which is why resolved presets carry
/// values like 1.9549999999999998.
public func scaleRadii(_ opts: ModeOpts, _ scale: Double) -> ModeOpts {
    var out = opts
    for k in OrbSpec.radiusKeys {
        guard let v = out[k] else { continue }
        out[k] = v * scale
    }
    // The one legitimate defaulted read in this file: absent means "no multiplier applied yet".
    out.rSizeMul = (out.rSizeMul ?? 1) * scale
    return out
}
