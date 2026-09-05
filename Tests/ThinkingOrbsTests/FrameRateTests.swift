#if canImport(AppKit)

import AppKit
import SwiftUI
import Testing

@testable import ThinkingOrbs
@testable import ThinkingOrbsGeometry

@Suite(.serialized)
@MainActor
struct FrameRateTests {
    init() { _ = NSApplication.shared }

    private func png(_ view: some View) -> Data? {
        let renderer = ImageRenderer(content: view)
        renderer.scale = 2
        guard let image = renderer.cgImage else { return nil }
        return NSBitmapImageRep(cgImage: image).representation(using: .png, properties: [:])
    }

    @Test func aFixedRateStillDraws() throws {
        let view = ThinkingOrb(.searching, size: .size64).orbFrameRate(30).orbTime(0.6)
        #expect(try #require(png(view)).isEmpty == false)
    }

    /// A frozen instant wins over any schedule, so a snapshot is deterministic whatever the host
    /// has set globally.
    @Test func frozenTimeIgnoresTheRate() throws {
        let free = try #require(png(ThinkingOrb(.working, size: .size64).orbTime(1.7)))
        let paced = try #require(
            png(ThinkingOrb(.working, size: .size64).orbFrameRate(15).orbTime(1.7)))
        #expect(free == paced)
    }

    /// Zero or negative would mean an infinite interval; the view falls back to the display.
    @Test(arguments: [0.0, -1.0])
    func nonPositiveRatesFallBackToTheDisplay(_ rate: Double) throws {
        let view = ThinkingOrb(.breathing, size: .size20).orbFrameRate(rate).orbTime(0.6)
        #expect(try #require(png(view)).isEmpty == false)
    }
}

#endif
