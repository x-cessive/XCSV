# XM8 app design system

Produced 2026-08-11 by a design pass over all six custom XM8 apps. This is the
reference for any future visual work on them. Applying it is staged work, not
all of it has been applied yet - see "Application status" at the bottom.

## Three findings that shaped the design

1. **The slides are `ctrlCreate`'d**, so the forward-declaration trap that killed
   `RscExileXM8SearchEdit` applies to every new class. `RscText`, `RscListbox`
   and `RscStructuredText` are FORWARD DECLARATIONS in `RscDefines.hpp` lines
   7-13. A class inheriting `type` from one of those resolves to nothing and
   `ctrlCreate` dies with `No entry '....type'`. **Every new class must spell out
   `type` and `style` itself.** `RscExileXM8Text` only survives because it
   re-declares them.

2. **Five of the six content groups cannot scroll.** Only `ScoreboardGroup`
   spells out `VScrollbar`. `RscExileXM8ControlsGroupNoHScrollbars` declares
   `class VScrollbar{}` empty over a forward-declared base, so it inherits no
   width and does not render. Standing, Policy, Notes, Prices and Inspector all
   silently CLIP. Any increase in type size makes that visible.

3. **Two different base units are in play.** `RscExileXM8Text` uses
   `min 1.2` -> `0.0400`; `RscExileXM8StructuredText` uses `min 1` -> `0.0333`.
   Structured text is therefore 17% smaller than XM8 chrome at the same nominal
   size, which is a large part of why the apps read as weak.

## Palette

| Role | Hex | RGBA |
| --- | --- | --- |
| canvas (recessed) | `#0E131B` | `{0.055,0.075,0.106,0.55}` |
| surface | `#151C27` | `{0.082,0.110,0.153,0.90}` |
| surface-raised | `#1E2634` | `{0.118,0.149,0.204,0.95}` |
| hairline / track | `#232B38` | `{0.137,0.169,0.220,1}` |
| text-primary | `#E2E7EE` | `{0.886,0.906,0.933,1}` |
| text-secondary (new) | `#A8B2C0` | `{0.659,0.698,0.753,1}` |
| text-muted | `#7E8896` | `{0.494,0.533,0.588,1}` |
| accent / interactive | `#3D9CFF` | `{0.239,0.612,1.000,1}` |
| currency / rank-1 | `#E8B339` | `{0.910,0.702,0.224,1}` |
| positive | `#3FC16A` | `{0.247,0.757,0.416,1}` |
| warning (new) | `#E8963C` | `{0.910,0.588,0.235,1}` |
| danger | `#E05050` | `{0.878,0.314,0.314,1}` |
| rank-2 / rank-3 | `#C0C6CE` / `#B87333` | - |

Only two hues are new and both interpolate between colours already present.
**One accent per screen region.** The header rule is `#3D9CFF` on every app; the
content accent varies by meaning (gold for money, faction colour for standing).
Blue is reserved for chrome and links - which is why body headings move from
`#3D9CFF` to `#E2E7EE` once the accent rule exists under the header bar.

## Type scale

Base unit `U = (((((safezoneW / safezoneH) min 1.2) / 1.2) / 25) * 1)` ~ `0.0400`.
`safezoneW/safezoneH` is >= 1.2 on every real aspect ratio, so the `min` always
clamps and U is effectively constant.

| Level | static `sizeEx` | markup `size` | Use |
| --- | --- | --- | --- |
| Title | `1.05 x U` | `1.25` | app name |
| Section | `0.92 x U` | `1.10` | card names, headings |
| Body | `0.85 x U` | unmarked | prose, rows |
| Caption | `0.72 x U` | `0.85` | labels, footnotes |
| Mono table | - | unmarked on a `0.80 x U` control | scoreboard |

The mechanism: set the structured-text control's own `size` to `0.85 x U` so
UNMARKED text is body size, and the markup multipliers land on the same scale as
the statics. One scale governs both.

**Monospace rule:** a fixed-advance face aligns at ONE size only. The scoreboard
control carries `size = 0.80 x U` and its rows carry **no `size` attribute at
all**, so every span has identical advance by construction. That removes the
"header at 0.85 vs rows at 0.8" drift permanently.

**Width budget:** body width `29 * 0.025 = 0.725`; glyph height `0.80 * 0.040 =
0.032`. At 16:9 that is 57-67 characters depending on the face's advance ratio.
The current row under `_w = [4,30,8,7,8]` is **66 characters - on the cliff
edge**. The recommended `_w = [3,20,7,5,6]` is 51.

## Spacing

- **Half-step** `<t size='0.40'><br/></t>` - the only way to get a gap smaller
  than a full blank line. Between a heading and its paragraph.
- **Block gap** `<br/><t size='0.40'><br/></t>` - between paragraphs. Never
  `<br/><br/><br/>`; three breaks reads as a layout error.
- **Section gap** `<br/><t size='0.85'><br/></t>` - before a new heading.
- **Hairline** a run of `_` in `#232B38` at `size='0.85'`, or a real `RscText` of
  `h = 0.002` where it can live outside a scrolling group.
- **Gutter** every label inset `0.016` from its card's left edge. One number,
  app-wide.
- Never start a line with a space. Runs of spaces INSIDE a span are preserved -
  that is the only reason the space-padded board aligns today - but leading
  whitespace is the one place the parser has been seen to trim.

## Layout band - DO NOT CHANGE

```
x 0.050 .. 0.800     y 0.120 .. 0.640
```

`0.640` is one full grid cell clear of GO BACK at `0.680-0.720`. A group reaching
`0.720` covers that button and eats its clicks - that was a multi-day bug.
`0.120` is below the XM8 title bar; going above it collides with the phone
number and clock - that was the next bug.

Standard stops: HeaderBar `y 0.120 h 0.056`, AccentRule `y 0.176 h 0.004`,
Content `y 0.190 h 0.450`.

## Optional hardening

Declare `GoBackButton` **last** in each slide. A control declared later wins
hit-testing, so this makes the covered-button bug impossible rather than merely
absent. Costs nothing if the geometry is already correct.

## Rejected, with reasons - do not re-propose

- **Zebra striping the scoreboard.** Structured text has no per-span background,
  so it needs one `RscText` per row `ctrlCreate`'d into a group whose height
  changes on every refresh. Real machinery for a cosmetic gain, on the exact code
  path that has already produced two multi-day bugs. Rank tinting buys most of
  the scannability for none of the risk.
- **Block glyphs (`U+2588` etc) for the Standing bars.** Arma renders UI text
  from pre-rasterised font atlases; those code points are not guaranteed to be in
  `EtelkaMonospacePro`'s and would render as blanks or tofu, discoverable only
  after a restart. Real `RscText` fill bars are safer and look better.
- **A sticky column header for the scoreboard.** Structured-text controls have a
  small internal inset that statics do not, so a static header would sit 1-3 px
  off the columns it labels. Worse than no sticky header. Revisit only if someone
  can measure it in game.
- **`<img image='#(argb,...)'/>` dividers.** `width`/`height` attribute support
  could not be confirmed from this repo. The `_`-run divider is proven.

## Known unknowns, each with a fallback

- **Multi-span coloured table rows** - whether padding spaces survive a `<t>`
  boundary. Spaces inside a span are preserved, so the parser is not collapsing
  whitespace at all, but the boundary case is untested here. *Symptom if it
  fails:* SCORE/KILLS/DEATHS step left by one character on rows 4+. *Fallback:*
  collapse to a single span, keeping per-rank colour.
- **`align='right'` on the second span of a label/value line** - alignment may
  apply per LINE, in which case the last span's align wins for the whole line.
  *Cheapest place to see it:* the Prices BUY/SELL rows. *Fallback:* label and
  value on separate lines.
- **A fill bar declared `w = 0.000`** - may render as nothing or as a hairline.
  Harmless either way; if a hairline shows, declare `0.001`.

## Application status

Applied so far:
- `VScrollbar` spelled out on every content group (was Scoreboard only).
- Inspector's stored player name escaped before it reaches structured text.

Not yet applied - the full visual redesign (header bars, accent rules, card
surfaces, Standing fill bars, restyled markup for all six apps). It is a large
change that cannot be seen before deploying, so it wants its own pass with the
config structural check run over it.
