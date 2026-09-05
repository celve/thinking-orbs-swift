# thinking-orbs-swift

Dotted thought-orb loading indicators for Swift: nine hand-tuned states, two sizes, plain
greyscale circles on a SwiftUI canvas.

A **state** is one verb an agent can be doing — searching, solving, weaving — drawn as a
genuinely 3D field of dots that carries depth in dot size and ink weight alone. There are no
gradients, no filters and no shaders anywhere in it. This is a port of
[thinking-orbs](https://github.com/Jakubantalik/thinking-orbs), whose TypeScript engine is the
source of truth; the tuning lives upstream and is vendored here as data, not re-derived.

## Use

```swift
import ThinkingOrbs

ThinkingOrb(.searching)                       // 64pt, live clock
ThinkingOrb(.working, size: .size20)          // the inline-text design, not a scaled 64
ThinkingOrb(.solving, speed: 1.5)             // multiplies the preset's baked speed
```

The nine states are `working`, `searching`, `solving`, `listening`, `connecting`, `weaving`,
`composing`, `breathing` and `shaping`. The two sizes are separate designs rather than a scale
factor, each with its own dot count, dot size and speed.

Colour comes from the environment: light dots under `.dark`, dark dots under `.light`. Every
instance reads one process-wide clock, so two orbs in the same state stay in phase however far
apart they were created, and `accessibilityReduceMotion` renders a single static frame.

```swift
GalleryView().orbTime(0.6)                    // freeze a whole subtree at one instant
```

`orbTime` is needed, not merely convenient, whenever an orb is rendered into a still image:
`ImageRenderer` never fires `onAppear` and never advances a `TimelineView`, so without it a
snapshot captures whatever the first evaluation happened to produce.

## Verifying

Upstream ships golden vectors — every dot of every state at four instants — and the port is
checked against them dot by dot rather than by eye.

```bash
swift test                                    # 43 tests, including all 72 golden cases
Scripts/smoke.sh                              # tables are current; all 36 frames rasterise
Scripts/generate-tables.sh                    # after re-vendoring Spec/
swift run OrbsSnapshot out/                   # frozen frames to eyeball against the web demo
swift run OrbsSnapshot out/ --animate         # looping GIFs, one per state plus a sheet of all nine
```

Two comparisons are deliberately not strict, and both are documented where they live. Preset
resolution is compared exactly, with `==`, because upstream emits `resolved` unrounded and every
scaling operation is IEEE-exact. Dot geometry is compared at upstream's own 1e-4 tolerance, except
within a run of dots recording the same depth: upstream sorts on full precision and only then
rounds to six decimals, so a face-on band lands in the file as a run of equal depths whose true
values differ by around 1e-16 — residues decided by the last bit of `sin`, where V8's libm and
Darwin's disagree. Three cases fall in that band; they are named in `GoldenVectorTests`, and
everything else is ordered strictly.

## What it costs

Measured on an M4 at 60Hz, in release, as a percentage of one core:

| | CPU |
| --- | --- |
| one orb animating | ~5.8% |
| nine orbs animating | ~12.5% |
| any number, frozen with `orbTime` | 0% |

Geometry is a small part of that — the worst state, `composing` at 64pt, rebuilds all 566 dots in
0.153 ms, which is 0.9% of a core at 60fps. The rest is SwiftUI redrawing and compositing a canvas
sixty times a second, so the marginal cost of a second orb is far below the first one's.

`TimelineView(.animation)` keeps redrawing a window that is minimised or off screen, so an orb
left running is a cost that continues when nobody can see it. The view stops animating while the
application reports itself occluded, but that gate fails open — it starts animating and only stops
on an observed transition — so a host that wants a guarantee should pass `paused`, or freeze with
`orbTime`, which measures at zero. Reduced motion already renders one static frame.

Run `swift run -c release OrbsSnapshot --bench` to reproduce the geometry figures.

## Layout

| Target | Holds |
| --- | --- |
| `ThinkingOrbsGeometry` | The engine: primitives, the nine modes, preset scaling. Foundation only, so the golden vectors run headlessly. |
| `ThinkingOrbs` | The SwiftUI binding — the view, the clock, the thirty-line painter. |
| `OrbsCodegen` | Turns `Spec/orbs-spec.json` into the generated tables. Not a product. |
| `OrbsSnapshot` | Frozen frames as PNGs, named as upstream's parity harness names them, and looping GIFs under `--animate`. Not a product. |

`Spec/` is vendored from upstream at the commit named in `Spec/UPSTREAM`; `Reference/` is its
engine verbatim, kept so the transcription can be reviewed side by side. Only the base profiles,
the preset table and the option keys are generated — the scaling rules are hand-ported, because
the spec states them only in prose, and it omits three things the golden data depends on.

## Credits

[thinking-orbs](https://github.com/Jakubantalik/thinking-orbs) by Jakub Antalik (MIT), whose
engine, tuning and golden vectors this port carries over, and whose own port plan sketched the
Swift package it never got. Notices are in `ThirdPartyLicenses/`.
