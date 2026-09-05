#if canImport(AppKit)

import AppKit
import Testing

@testable import ThinkingOrbs

/// The visibility gate must fail open. It starts animating and only stops on an observed
/// transition, so a host where the platform never reports occlusion behaves exactly as it did
/// before the gate existed — an orb that silently refused to animate would be a worse bug than
/// one that animates while hidden.
@Suite(.serialized)
@MainActor
struct VisibilityTests {
    @Test func defaultsToVisibleSoOrbsAnimateUntilToldOtherwise() {
        #expect(OrbVisibility.shared.isVisible)
    }
}

#endif
