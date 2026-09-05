#if canImport(AppKit)

import AppKit
import SwiftUI
import Testing

@testable import ThinkingOrbs
@testable import ThinkingOrbsGeometry

/// `ImageRenderer` is the failure mode `orbTime` exists to prevent: it never fires `onAppear` and
/// never advances a `TimelineView`, so an orb rendered into a still image has no clock unless one
/// is supplied. These are serialised and main-actor bound because `ImageRenderer` is.
@Suite(.serialized)
@MainActor
struct RenderTests {
    init() { _ = NSApplication.shared }

    private func png(_ view: some View, scale: CGFloat = 2) -> Data? {
        let renderer = ImageRenderer(content: view)
        renderer.scale = scale
        guard let image = renderer.cgImage else { return nil }
        return NSBitmapImageRep(cgImage: image).representation(using: .png, properties: [:])
    }

    private func opaquePixels(_ view: some View) -> Int {
        let renderer = ImageRenderer(content: view)
        renderer.scale = 2
        guard let image = renderer.cgImage else { return 0 }
        let width = image.width
        let height = image.height
        var pixels = [UInt8](repeating: 0, count: width * height * 4)
        let space = CGColorSpaceCreateDeviceRGB()
        guard
            let context = CGContext(
                data: &pixels, width: width, height: height, bitsPerComponent: 8,
                bytesPerRow: width * 4, space: space,
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
        else { return 0 }
        context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
        return stride(from: 3, to: pixels.count, by: 4).count { pixels[$0] > 0 }
    }

    @Test func frozenTimeRendersDeterministically() throws {
        let view = ThinkingOrb(.searching, size: .size64).orbTime(0.6)
        let first = try #require(png(view))
        let second = try #require(png(view))
        #expect(first == second, "two renders at one frozen instant should be byte-identical")
    }

    /// The guard against the whole design failing quietly: a view that renders empty because
    /// nothing ever advanced its clock still produces a perfectly valid, perfectly blank PNG.
    @Test(arguments: OrbState.allCases)
    func everyStateRendersSomething(_ state: OrbState) {
        let view = ThinkingOrb(state, size: .size64)
            .orbTime(0.6)
            .environment(\.colorScheme, .dark)
        #expect(opaquePixels(view) > 0, "\(state) rendered blank")
    }

    /// Two different instants of an animated state must not produce the same image, or the frozen
    /// clock is being ignored.
    @Test func differentFrozenInstantsDiffer() throws {
        let early = try #require(png(ThinkingOrb(.working, size: .size64).orbTime(0.6)))
        let late = try #require(png(ThinkingOrb(.working, size: .size64).orbTime(3.3)))
        #expect(early != late)
    }

    /// The view is exactly its preset size and does not want to grow.
    @Test(arguments: OrbSize.allCases)
    func rendersAtItsPresetSize(_ size: OrbSize) throws {
        let renderer = ImageRenderer(content: ThinkingOrb(.searching, size: size).orbTime(0.6))
        renderer.scale = 2
        let image = try #require(renderer.cgImage)
        #expect(image.width == Int(size.points * 2))
        #expect(image.height == Int(size.points * 2))
    }
}

#endif
