import Testing

@testable import ThinkingOrbsGeometry

/// `finalizeFrame` is where this port deliberately diverges from its source, and the golden
/// vectors cannot check it: upstream records depth to six decimals, so an equal-depth run in the
/// fixture pins no particular order and `GoldenComparison` compares those runs unordered. The
/// tie-break is therefore verified here instead, directly.
@Suite struct FinalizeTests {
    private func dot(_ x: Double, z: Double, r: Double = 1, alpha: Double = 1) -> Dot {
        Dot(x: x, y: 0, z: z, r: r, white: 0.5, alpha: alpha)
    }

    /// Pins the contract, not a currently-observable failure: Swift's `sort(by:)` is a stable
    /// merge sort today, so this passes even with the comparator's tie-break removed. The standard
    /// library nonetheless leaves the order of equal elements unspecified, and every `shaping`
    /// frame emits all its dots at z = 0, so the day that changes an entire state would render in
    /// scrambled order with nothing else to catch it.
    @Test func exactDepthTiesKeepEmissionOrder() {
        let input = (0..<64).map { dot(Double($0), z: 0) }
        let frame = finalizeFrame(dots: input, lines: [])
        #expect(frame.dots.map(\.x) == input.map(\.x))
    }

    /// The same, interleaved with distinct depths, so ties are not merely the whole array.
    @Test func tiesKeepEmissionOrderWithinEachDepth() {
        let input = [
            dot(0, z: 1), dot(1, z: 0), dot(2, z: 1), dot(3, z: 0), dot(4, z: 1), dot(5, z: 0),
        ]
        let frame = finalizeFrame(dots: input, lines: [])
        #expect(frame.dots.map(\.x) == [1, 3, 5, 0, 2, 4])
    }

    @Test func sortsFarToNear() {
        let frame = finalizeFrame(dots: [dot(0, z: 2), dot(1, z: -1), dot(2, z: 0.5)], lines: [])
        #expect(frame.dots.map(\.z) == [-1, 0.5, 2])
    }

    @Test func cullsMarksBelowTwoPercentAlpha() {
        let frame = finalizeFrame(
            dots: [dot(0, z: 0, alpha: 0.02), dot(1, z: 1, alpha: 0.0199), dot(2, z: 2, alpha: 0)],
            lines: [
                Line(x1: 0, y1: 0, x2: 1, y2: 1, white: 0.5, alpha: 0.02, width: 1),
                Line(x1: 0, y1: 0, x2: 1, y2: 1, white: 0.5, alpha: 0.019, width: 1),
            ])
        #expect(frame.dots.map(\.x) == [0], "0.02 is kept, below it is dropped")
        #expect(frame.lines.count == 1)
    }

    @Test func clampsRadiusToTheModeFloor() {
        let frame = finalizeFrame(dots: [dot(0, z: 0, r: 0.1), dot(1, z: 1, r: 5)], lines: [], rMin: 0.3)
        #expect(frame.dots.map(\.r) == [0.3, 5])
    }

    /// Culling reads the incoming alpha, and clamping only ever raises a radius, so a dot dropped
    /// for being invisible is dropped whatever its radius would have become.
    @Test func cullingHappensBeforeClamping() {
        let frame = finalizeFrame(dots: [dot(0, z: 0, r: 0.001, alpha: 0.01)], lines: [])
        #expect(frame.dots.isEmpty)
    }

    /// Lines are filtered but never reordered — they are drawn in emission order, before the dots.
    @Test func linesKeepEmissionOrder() {
        let lines = (0..<5).map {
            Line(x1: Double($0), y1: 0, x2: 0, y2: 0, white: 0.5, alpha: 1, width: 1)
        }
        #expect(finalizeFrame(dots: [], lines: lines).lines.map(\.x1) == [0, 1, 2, 3, 4])
    }
}
