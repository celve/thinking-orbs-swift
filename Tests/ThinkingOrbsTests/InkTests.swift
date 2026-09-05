import Foundation
import Testing

@testable import ThinkingOrbs
@testable import ThinkingOrbsGeometry

@Suite struct InkTests {
    /// The grey is quantised to eight bits before it ever reaches a colour, so the port lands on
    /// the same values the web and React Native painters do rather than merely close ones.
    @Test func greyIsQuantisedToEightBits() {
        let ink = OrbInk(dark: false)
        for step in 0...255 {
            let white = Double(step) / 255
            let (grey, _) = ink.components(white: white, alpha: 1)
            #expect(grey == (white * 255).rounded() / 255)
        }
    }

    /// On a dark substrate the ink value is mirrored, so near dots read bright.
    @Test func darkMirrorsTheInkValue() {
        for step in 0...255 {
            let white = Double(step) / 255
            let light = OrbInk(dark: false).components(white: white, alpha: 1).grey
            let dark = OrbInk(dark: true).components(white: white, alpha: 1).grey
            #expect(abs((light + dark) - 1) < 1e-9, "at white \(white)")
        }
    }

    /// Eleven dots in `solving` carry a negative ink value. Unclamped, a dark substrate would
    /// mirror -0.058 to 1.058 and overflow the byte.
    @Test func negativeInkClampsRatherThanOverflowing() {
        let (grey, _) = OrbInk(dark: true).components(white: -0.057894, alpha: 1)
        #expect(grey == 1)
    }

    /// Four dots in `weaving` exceed an alpha of one. CSS clamps `rgba()`; SwiftUI does not.
    @Test func alphaAboveOneClamps() {
        let (_, opacity) = OrbInk(dark: true).components(white: 0.5, alpha: 1.014756)
        #expect(opacity == 1)
    }

    /// Both out-of-range values really do occur, so neither clamp is speculative.
    @Test func theGoldenDataActuallyLeavesRange() {
        var sawNegativeWhite = false
        var sawAlphaAboveOne = false
        for state in OrbState.allCases {
            for size in OrbSize.allCases {
                for t in [0.6, 1.7, 3.3, 5.1] {
                    for dot in OrbFrame(state: state, size: size, at: t).dots {
                        if dot.white < 0 { sawNegativeWhite = true }
                        if dot.alpha > 1 { sawAlphaAboveOne = true }
                    }
                }
            }
        }
        #expect(sawNegativeWhite)
        #expect(sawAlphaAboveOne)
    }
}
