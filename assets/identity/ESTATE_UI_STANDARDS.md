# Estate UI Standards (2026-09-27)

One aesthetic, every repo. Generalized from the station-app polish pass; applies estate-wide.

## Visual identity (locked)

- Palette: BG `#080C11`, TEXT `#DCE6EE`, DIM `#748291`, CYAN `#62E6D2`, CYAN_DIM `#2B7067`, AMBER `#F0AA68`, RED `#ED746A`, GREEN `#5CEB96`. Nothing else.
- Pixel art: 128×128 grid, NEAREST ×4, solid colors, no anti-aliasing, no gradients.
- Sound: 22050Hz mono 16-bit WAV chiptune.

## Interface principles

1. **One card, one job.** Never show the same card twice — compact on the main view, expanded detail in its sheet or screen. Copies drift.
2. **One view per dataset.** Don't build three screens over the same data — one view with filters.
3. **Status stays visible.** Connection, sync, and health indicators live persistently in the chrome — never buried at the bottom of settings.
4. **Stale data is a bug, not a badge.** If a refresh is broken, fix the fetch; if it fails, show "unavailable" — never present days-old data with a warning label as if that's fine.
5. **Empty states are designed.** Say what it is, why it's empty, what happens next. Never a debug dump.
6. **One sheet pattern.** All modals/sheets share header, drag handle, close, padding, and type scale.
7. **One type scale, one spacing scale.** The last 5% is a full audit.
8. **Core job above the fold.** Whatever the app is for must be visible without scrolling on a phone viewport.
9. **Touch targets ≥ 48dp.** Verify dim-text contrast at small sizes.
10. **Micro-interactions.** Progress ticks smoothly, transitions consistent, pressed states everywhere tappable.

## Repo placement

This file rides with the identity pack in `assets/identity/`. The art (logo, banner, diagram) is the visual half; this is the interface half.
