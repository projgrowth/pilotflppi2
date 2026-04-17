

## What's still wrong

Despite the prior pass, the model is still doing the heavy lifting "by eye" and the viewer trusts whatever coordinates come back. Three structural problems remain:

### 1. The model places pins on the WHOLE sheet image with no anchor
Even at 220 DPI, an E-size sheet is densely packed. Asking the model to land within a few percent of a 4-inch detail is unreliable. We never give the model a coordinate grid, never tile dense sheets, never ask it to name a nearby drawing element by what's printed near it. It guesses, and 4-8% off is still half a sheet away.

### 2. We don't verify the pin actually shows the right thing
The validator only checks that `page_index` is in range and clamps box size. It never crops the model's reported box and asks "does this region actually contain what you described?" — so a wildly off pin survives untouched.

### 3. The viewer shows the pin with zero "this is approximate" signal
Every pin renders identically whether the AI was certain or guessing. Users can't tell which findings to spot-check, and the only escape hatch is the manual reposition flow.

The user picked **"show approximate pin"** — keep the pin, but be honest about its accuracy, and stop pretending precision we don't have.

## Fix plan — 3 patches

### Patch 1 — Grid overlay + anchor text in the AI prompt (`supabase/functions/ai/index.ts`)
- Before sending each image, draw a faint **10×10 percent grid** with row letters A-J and column numbers 0-9 on each PNG (client-side canvas overlay during vision render). Tell the model: "Cell H7 means x=70-80%, y=70-80%."
- Add two REQUIRED schema fields per finding:
  - `grid_cell`: e.g. "H7" — the cell containing the element's center.
  - `nearest_text`: a short string the model can literally read on the sheet within ~5% of the pin (a callout number, a dimension, a sheet note number, a schedule row label, a grid line letter, "TYP", etc.). Empty string if nothing readable.
- The viewer no longer trusts raw `x/y` blindly: if `grid_cell` exists, **the pin center is set to the cell's center** and `x/y` is treated as a refinement within that cell (clamped to ±5% of cell center). This bounds the worst-case error to one grid cell.

### Patch 2 — Confidence-aware pin styling + "approximate" badge (`PlanMarkupViewer.tsx`, `FindingCard.tsx`)
- Add `pin_confidence` derived in code: `high` when `nearest_text` matches OCR'd text near the pin (next bullet) OR the user has manually repositioned it, `medium` when only `grid_cell` is present, `low` when neither.
- Render:
  - **High** → solid red crosshair (current).
  - **Medium** → dashed red crosshair + small "~" overlay.
  - **Low** → dashed amber crosshair + "approx" label + a faint 10% radius "search ring" around it so the user knows where to look.
- Sheet badge gets a confidence dot (green/amber/grey).
- FindingCard shows an "Approximate location — verify on sheet" hint when confidence < high, with the existing reposition button promoted as the primary action for those cards.

### Patch 3 — Cheap verification pass with `nearest_text` (`PlanReviewDetail.tsx` post-parse)
- After findings come back, for each finding's pin region, render a small crop of the display image at the pinned cell (we already have it in memory). Run a fast text-similarity check: extract any ASCII text the AI returned in `nearest_text` and verify the same string (or a substring ≥4 chars) appears in the description block we already have for that sheet. (We're not doing OCR — just comparing what the AI said is "near" the pin to its own description text and the page filename. It's a sanity check, not OCR ground truth.)
- If `nearest_text` is empty AND `grid_cell` is empty → mark `pin_confidence: "low"` and skip drawing the pin's box-fill (only the crosshair + search ring renders, so the user isn't misled by a precise-looking rectangle).

## Files touched
- `src/lib/pdf-utils.ts` — add `renderPDFPagesForVisionWithGrid(file, dpi)` that overlays a 10×10 alpha-grid + cell labels onto each rendered page before returning base64.
- `src/types/index.ts` — extend `MarkupData` with optional `grid_cell?: string`, `nearest_text?: string`, `pin_confidence?: "high" | "medium" | "low"`.
- `supabase/functions/ai/index.ts` — prompt rewrite (explain the grid, require `grid_cell` + `nearest_text`); tool schema gains those two fields.
- `src/pages/PlanReviewDetail.tsx` — post-parse: convert `grid_cell` → coordinate refinement, compute `pin_confidence`, persist into `markup`.
- `src/components/PlanMarkupViewer.tsx` — three-tier pin styling, search-ring for low confidence, dashed strokes for medium.
- `src/components/FindingCard.tsx` — "Approximate — verify" hint + promoted reposition button when confidence ≠ high.

## What I'm NOT doing
- No real OCR (Tesseract, etc.) — the verification step uses cheap string comparison only. A real OCR loop is a separate, larger investment.
- No automatic reposition — when confidence is low we surface it; the human still places the final pin.
- No new DB column — `pin_confidence` rides inside the existing `markup` JSON on `ai_findings`, so no migration needed.

## Verification after build
- Re-run AI on a 3-file plan set → every finding has a grid cell and nearest-text string in the markup JSON.
- Findings about a specific detail land within one grid cell (~10%) of the right element, not half a sheet away.
- Low-confidence pins show the dashed amber crosshair + search ring; high-confidence pins keep the current solid red crosshair.
- Manually-repositioned pins are upgraded to `high` confidence and never get downgraded on reload.

