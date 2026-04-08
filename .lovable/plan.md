

# Elevate Plan Review: Precision, Polish & Reliability

## Current State
The Plan Review workspace has a solid foundation — tabbed detail panel, AI findings grouped by discipline, comment letter streaming, file upload, and HVHZ detection. But several areas lack polish, precision, and reliability.

## Improvements

### 1. Upload-First Wizard with AI Auto-Extraction

Restructure `NewPlanReviewWizard.tsx` from 3 steps to a smarter flow:

```text
[Upload Plans] → [Confirm AI-Extracted Details] → [Launch]
```

- Step 1 becomes a drag-and-drop upload zone (no project form yet)
- After upload, use `pdfjs-dist` in the browser to render page 1 (title block) to a base64 PNG
- Send the image to a new `extract_project_info` action in the AI edge function (using `google/gemini-2.5-pro` for multimodal vision) that returns: project name, address, county, jurisdiction, trade type
- Step 2 pre-fills all fields from the AI extraction — user just confirms or corrects
- HVHZ auto-detected from the extracted county, shown inline
- Existing project matching: if AI-extracted name/address matches a DB project, suggest linking instead of creating new

### 2. Visual Plan Analysis with Real Document Reading

Currently the AI only sees filenames. Upgrade `runAICheck` to send actual page images:

- Use `pdfjs-dist` to render each uploaded PDF page to a ~150 DPI PNG (cap at 10 pages)
- Add a new `plan_review_check_visual` action to the edge function that accepts base64 images as multimodal content parts alongside the system prompt
- Use `google/gemini-2.5-pro` (best for vision + reasoning)
- AI now analyzes actual structural drawings, site plans, and schedules for real code violations
- Extend finding schema with optional `markup` coordinates: `{ page_index, x, y, width, height }` (percentages)

### 3. Visual Markup Overlay on Plans

New `PlanMarkupViewer.tsx` component:

- Renders PDF pages via `pdfjs-dist` canvas with a transparent overlay layer
- Red semi-transparent rectangles at AI-reported coordinates with numbered callout badges
- Click a callout → scrolls to and highlights the corresponding FindingCard
- Click a FindingCard → scrolls the viewer to the correct page and pulses the annotation
- Split-view layout in the Findings tab: PDF viewer left (60%), finding cards right (40%)

### 4. UI Polish & Micro-interactions

- **Review queue cards**: Add the `DeadlineRing` component showing the 21-day statutory countdown from `created_at`
- **Severity donut chart**: Small SVG donut in the overview tab showing critical/major/minor proportions
- **Smooth scan animation**: Replace the grid with a vertical timeline that fills as each discipline completes, with checkmark transitions
- **Finding cards**: Add subtle entrance animations (stagger fade-in), hover lift shadow, and a "resolved" toggle that strikes through the finding
- **Comment letter**: Render as a styled document preview (letterhead, formatted sections) instead of a raw textarea, with an edit mode toggle
- **Empty states**: Illustrated empty states with contextual CTAs instead of plain text
- **Skeleton loading**: Use proper Skeleton components in the detail panel during data fetch

### 5. Reliability & Error Handling

- **Retry logic**: Wrap AI calls with exponential backoff (max 3 retries) for transient failures
- **Optimistic UI**: Show immediate feedback when flagging findings or uploading files
- **File validation**: Check PDF headers before uploading (not just MIME type), show file size and page count
- **Progress tracking**: Real progress bar during multi-page PDF rendering (not just a cycling animation)
- **Auto-save**: Persist comment letter edits to the database with debounced saves
- **Toast improvements**: Use descriptive toasts with action buttons (e.g., "View Findings" after AI check completes)

## Technical Details

### New/Modified Files

| File | Change |
|---|---|
| `src/components/NewPlanReviewWizard.tsx` | Restructure to upload-first flow with AI extraction step |
| `src/lib/pdf-utils.ts` | New: PDF page → base64 image conversion via pdfjs-dist |
| `supabase/functions/ai/index.ts` | Add `extract_project_info` and `plan_review_check_visual` actions with multimodal content |
| `src/components/PlanMarkupViewer.tsx` | New: PDF canvas renderer with annotation overlays |
| `src/components/FindingCard.tsx` | Add resolved toggle, entrance animation, markup link |
| `src/pages/PlanReview.tsx` | Split-view findings tab, deadline rings on queue, severity donut, skeleton states, retry logic |
| `src/components/SeverityDonut.tsx` | New: Small SVG donut chart for finding severity breakdown |
| `src/components/ScanTimeline.tsx` | New: Vertical timeline scanning animation |

### Dependencies
- `pdfjs-dist` — browser-side PDF rendering to canvas

### Models Used
- `google/gemini-2.5-pro` — for multimodal vision tasks (title block extraction, visual plan analysis)
- `google/gemini-3-flash-preview` — for text-only tasks (comment letter generation, code Q&A)

