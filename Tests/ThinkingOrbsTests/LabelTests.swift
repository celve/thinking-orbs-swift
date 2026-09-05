import Foundation
import Testing

@testable import ThinkingOrbsGeometry

@Suite struct LabelTests {
    /// The nine labels are hand-carried rather than generated, so they are checked against the
    /// spec. Note `breathing` reads "Thinking…", not "Breathing…", and every label ends in a
    /// single ellipsis character rather than three dots.
    @Test func labelsMatchTheSpec() throws {
        let root = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let data = try Data(contentsOf: root.appendingPathComponent("Spec/orbs-spec.json"))
        struct Spec: Decodable { let labels: [String: String] }
        let labels = try JSONDecoder().decode(Spec.self, from: data).labels

        #expect(labels.count == OrbState.allCases.count)
        for state in OrbState.allCases {
            let want = try #require(labels[state.rawValue])
            #expect(state.accessibilityLabel == want, "\(state.rawValue)")
            #expect(want.hasSuffix("\u{2026}"), "\(state.rawValue) should end in an ellipsis")
        }
        #expect(OrbState.breathing.accessibilityLabel == "Thinking\u{2026}")
    }
}
