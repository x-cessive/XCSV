# Identity asset pack - XCSV

Repo: **x-cessive/XCSV** (PUBLIC)

## What this is

Public Arma 3 Exile server-operations hub (PowerShell): documentation, repository routing, shared tooling.

Staged identity set: banner, logo, overview diagram, this manifest, and IDENTITY.pdf. Nothing has been pushed to the repo; this directory is the staging area only.

## Files

| File | Spec | Suggested repo path |
|---|---|---|
| banner.png | 1200x630 PNG, drawn on a 400x210 pixel grid, NEAREST x3 | docs/assets/identity/banner.png |
| logo_512.png | 512x512 PNG, drawn on a 128x128 pixel grid, NEAREST x4 | docs/assets/identity/logo_512.png |
| diagram_hub.png | 720x400 PNG, drawn on a 360x200 pixel grid, NEAREST x2 | docs/assets/identity/diagram_hub.png |
| IDENTITY.pdf | Letter, reportlab platypus layout | docs/assets/identity/IDENTITY.pdf |

## Why these subjects

The XCSV identity is the operations table: a gridded tactical map with colored unit markers and a central cyan hub diamond. The logo compresses the same idea to a map panel with four markers feeding one hub; the banner widens it into a full ops-table scene with a dashed amber route. The hub-and-spokes diagram shows XCSV's actual role: one hub routing to every member repo.

## Aesthetic spec

Shared estate aesthetic (locked): true 8-bit pixel art on a 128x128 grid (or clean multiples), NEAREST-neighbor integer scaling only, hard pixels, solid colors, no anti-aliasing, no gradients, no glow, no photorealism. Estate palette only: BG #080C11, TEXT #DCE6EE, DIM #748291, CYAN #62E6D2, CYAN_DIM #2B7067, AMBER #F0AA68, RED #ED746A, GREEN #5CEB96. Pixel typography for all text. Banners carry a 4px CYAN_DIM inner border on BG; logos carry a 2px CYAN_DIM outer border on BG. Public repos get fully generic subject matter.

## Notes

- Public-repo rule honored: subject matter is fully generic for the   domain (no internal references, no estate in-jokes).
- QC: contact-sheet eyeball pass done; every PNG uses 8 or fewer   colors (limit 64); logo legible at 64px.
- Generators kept at ~/workspace/asset-sweep-1/ for regeneration.
