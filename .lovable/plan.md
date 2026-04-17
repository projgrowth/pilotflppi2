

# Why the red boxes don't land where the comments say

## Root causes (confirmed in code)

The pin-placement system has 4 distinct alignment problems stacking on top of each other:

### 1. The model is guessing coordinates by eye, on a downscaled image
`renderPDFPagesToImages` rasterizes each PDF page at **150 DPI** then sends the resulting PNG to Gemini as a flat image. The model has no native PDF coordinate system to work with — it eyeballs pixel positions and converts to a 0-100% guess. On a dense E-sized sheet (36"×24") rendered at 150 DPI, a 5% width box covers ~270 px, which is a *huge* region. Off by 4% horizontally → off by half a sheet.

### 2. The page-index gets corrupted on multi-file uploads
In `renderDocumentPages` (PlanReviewDetail.tsx line 272), images from each PDF are concatenated into `allImages` and re-indexed sequentially across files:
```
allImages.push(...images.map((img, idx) => ({ ...img, pageIndex: allImages.length + idx })))
```
But the AI is called with **all images flat in one array** (line 315: `images.map((img) => img.base64)`) and the prompt tells it `page_index: <0-based index of the image where the issue is>`. The model doesn't know which file each image came from — and it tends to anchor `page_index: 0` because the title block is the first image regardless of file. So findings about Sheet S-201 (image #4) get pinned to the cover sheet of file #1.

### 3. No sheet/title-block grounding
The AI gets the raw image but is never told "this image is sheet A-201". It invents a `page` field (e.g. "S-101") *and* a `page_index` independently — and the two often disagree. The viewer ignores `page` entirely and trusts only `page_index`, so the user sees the comment say "Sheet S-101" while the box is actually drawn on whatever page_index the model wrote.

### 4. Bounding-box dimensions are arbitrary
The schema only requires `x, y, width, height` as percentages with no upper bound on box size and no lower bound on precision. The system prompt suggests `width 5-30, height 3-20`, and the model defaults to ~10×5 boxes that visually cover an entire detail callout instead of the specific element. There's no concept of a *pin* (point) vs a *region* (box) — everything is a fat rectangle.

## What I propose to fix (4 patches, prompt + code, no schema changes)

### Patch A — Tighten the prompt with sheet grounding & precision rules
Rewrite the `plan_review_check_visual` system prompt to:
- **Index every image by its sheet name first**: model returns a `page` string that MUST match what's visible in the title block of that image, AND the `page_index` MUST be the array index of that exact image.
- **Internal reasoning step**: "Before each finding, identify (a) which image you're looking at, (b) the sheet number visible on it, (c) the *specific element* (a callout, dimension, note block, detail bubble) the deficiency relates to."
- **Box sizing rules**: pin-style box for point issues (max 4% × 4%), region box only when the finding spans a clearly bounded area (max 15% × 10%). Center the box on the element, not on the surrounding whitespace.
- **Anchor descriptions**: every `description` must reference a visual landmark on the sheet ("at the NW corner of the foundation plan, near grid B-2", "in the door schedule, row 4") so the user can verify the pin even if it drifts.

### Patch B — Send page metadata to the model + validate page_index in code
- In `renderDocumentPages`, keep a `fileIndex` and `pageInFile` on each image so we can round-trip.
- When calling the AI, also send a parallel `image_manifest` array: `[{ index: 0, file: "Architectural.pdf", page_in_file: 1 }, ...]` so the model is grounded to which file/page each image is.
- After parsing findings, **validate** every `markup.page_index` is in range. If a finding's `page` (sheet name string) clearly references a different page than `page_index`, log a warning and try to remap by matching the sheet string against any image where the title-block OCR matches. Drop the markup (showing finding without a pin) rather than show a wrong pin.

### Patch C — Render at higher DPI for vision, lower DPI for display
Two-tier rendering:
- **Display canvas**: 150 DPI as today (fast, small base64 in memory).
- **AI vision**: 220 DPI for the images we actually send to Gemini — gives the model meaningfully more pixel detail to localize against. Pages stay in memory only during the AI call, then GC'd.

### Patch D — Add a "pin" affordance + sheet label on each annotation
In `PlanMarkupViewer`:
- If a finding's box is ≤ 4% × 4%, render it as a **target crosshair pin** (small circle with crosshair) instead of a rectangle — visually communicates "approximate point" rather than "this exact rectangle is wrong".
- Show the sheet name (`finding.page`) on the annotation badge alongside the number, so users see "S-201 · #3" — they can immediately verify they're on the correct sheet even if the pin is off by a few percent.
- Add a "Wrong location?" link in the FindingCard that opens a one-click manual reposition mode (drag the pin to the correct spot, save back to `ai_findings.markup`). This feeds the existing AI learning loop so future runs improve.

## Files touched
- `supabase/functions/ai/index.ts` — rewrite `plan_review_check_visual` system prompt + add explicit sheet-grounding instructions in the tool schema descriptions
- `src/lib/pdf-utils.ts` — add `renderPDFPagesForVision(file, dpi=220)` variant; keep current 150 DPI for display
- `src/pages/PlanReviewDetail.tsx` — track `fileIndex`/`pageInFile` per image, build `image_manifest`, send vision-DPI images to AI, validate `page_index` post-parse
- `src/components/PlanMarkupViewer.tsx` — pin-vs-box rendering based on box size, sheet-label badge, manual reposition mode
- `src/components/FindingCard.tsx` — add "Wrong location? Reposition" action
- New migration: optional `human_corrected_markup` boolean column on `review_flags` so the learning loop knows which pins are user-corrected gold data

## What I'm NOT doing
- Not switching to a different vision model (Gemini 2.5 Pro is fine; the issue is grounding, not model quality)
- Not building a full PDF-coordinate extraction system (would require server-side PDF parsing — disproportionate for the gain)
- Not removing the box rendering — some findings genuinely cover a region (a whole missing schedule, a whole egress path) and need a box

## Verification after implementation
- Re-run AI check on a 3-file plan set — every finding's sheet badge matches the sheet visible in the viewer
- Findings about sheet S-201 land on S-201, not the cover sheet of file #1
- Point-style issues (missing dimension, missing seal) render as pins, not 30% × 20% rectangles
- Manual reposition saves back to DB and pin appears in the corrected location on next load

