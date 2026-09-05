// Upstream stops every instance when the tab is hidden, and that behaviour has to be ported
// deliberately: `TimelineView(.animation)` keeps redrawing a minimised or fully occluded window.
// Measured on an M4 at 60Hz, nine orbs cost about the same CPU minimised as visible without this.

import Combine
import SwiftUI

#if canImport(AppKit)
import AppKit
#elseif canImport(UIKit)
import UIKit
#endif

/// Whether the host application is on screen at all. Process-wide rather than per-view, because
/// that is the level the platform reports and it is where the whole cost goes.
@MainActor
final class OrbVisibility: ObservableObject {
    static let shared = OrbVisibility()

    @Published private(set) var isVisible = true

    private init() {
        #if canImport(AppKit)
        observe(NSApplication.didChangeOcclusionStateNotification) {
            NSApp?.occlusionState.contains(.visible) ?? true
        }
        #elseif canImport(UIKit)
        observe(UIApplication.didEnterBackgroundNotification) { false }
        observe(UIApplication.willEnterForegroundNotification) { true }
        #endif
    }

    private func observe(_ name: Notification.Name, _ state: @escaping @MainActor () -> Bool) {
        NotificationCenter.default.addObserver(forName: name, object: nil, queue: .main) {
            [weak self] _ in
            MainActor.assumeIsolated { self?.isVisible = state() }
        }
    }
}
