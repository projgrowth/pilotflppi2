

## Revised Plan: Plan Review Overhaul — Routing, UX, and PDF Fixes

### Problems to Fix

1. **Comment Letter PDF blocked by browser**: Uses `window.open()` + `window.print()` which popup blockers kill. Replace with in-browser PDF generation using `jspdf` or a Blob download approach.
2. **Document preview broken**: `<iframe src={supabaseUrl}>` fails due to Content-Disposition headers. Replace with the existing `pdfjs-dist` renderer already in the codebase.
3. **Plan Review cramped in a Sheet drawer**: The entire review workspace lives inside a `<Sheet>` side panel. Convert to a full-page route `/plan-review/:id` for a proper workspace experience.
4. **No deep linking**: Can't share or bookmark a specific review. Adding a route fixes this.
5. **Cheesy icons**: Emoji 📄 in FindingCard (line 167), excessive decorative icons throughout. Strip to functional-only icons.
6. **Finding click doesn't auto-navigate to plan location**: Clicking a finding should auto-load page images and scroll to the annotation. Currently requires manually clicking "Load Annotations" first.

### What Changes

**1. Route restructure** — `src/App.tsx`, new `src/pages/PlanReviewDetail.tsx`
- Add route `/plan-review/:id`
- Keep `/plan-review` as the list/index page (extract from current file)
- Detail page gets the full viewport — no Sheet wrapper
- Back button returns to list

**2. Fix document preview** — `src/pages/PlanReviewDetail.tsx` (Docs tab)
- Replace `<iframe src={url}>` (line 1050) with fetch → blob → `renderPDFPagesToImages()` (already exists in codebase)
- Reuse `PlanMarkupViewer` component for document viewing

**3. Fix Comment Letter export** — `src/components/CommentLetterExport.tsx`
- Replace `window.open()` + `window.print()` with Blob-based approach:
  - Build HTML string (already done)
  - Create an `<iframe>` in the DOM, write HTML, call `contentWindow.print()` for Print
  - For Export PDF: use the same print dialog (browser Save as PDF) but with a clear CTA, OR generate a downloadable HTML file
- Alternative: use `html2canvas` + `jspdf` for a true `.pdf` download without popups

**4. Auto-load annotations on finding click** — `src/pages/PlanReviewDetail.tsx`
- When `handleLocateFinding(index)` is called and `pageImages` is empty, auto-trigger `renderDocumentPages()` first, then set the active finding
- Remove the manual "Load Annotations" button — always auto-load when findings have markup data

**5. Clean up icons** — Multiple files
- `FindingCard.tsx` line 167: Replace `📄` emoji with nothing (just "Sheet: {page}")
- Remove purely decorative icons from buttons where text is sufficient
- Sidebar: already clean, keep as-is

**6. Contractor info in review header** — `src/pages/PlanReviewDetail.tsx`
- Update query to join `projects → contractors` via `contractor_id`
- Show contractor name, email, phone in the review header card
- Add mailto: link for quick contact

### Files

| File | Action |
|------|--------|
| `src/App.tsx` | Add `/plan-review/:id` route |
| `src/pages/PlanReview.tsx` | Strip down to list-only (remove Sheet detail, ~500 lines removed) |
| `src/pages/PlanReviewDetail.tsx` | **New** — full-page review workspace extracted from PlanReview.tsx |
| `src/components/CommentLetterExport.tsx` | Fix PDF export to avoid popup blockers |
| `src/components/FindingCard.tsx` | Remove emoji icon, clean up decorative elements |
| `src/components/PlanMarkupViewer.tsx` | Minor — ensure auto-scroll works on initial load |

### Comment Letter Fix Detail

```text
Current (broken):
  window.open("", "_blank")  →  popup blocked  →  nothing happens

Fixed approach:
  1. Create hidden <iframe> in DOM
  2. Write letter HTML into iframe
  3. Call iframe.contentWindow.print()
  4. Remove iframe after print dialog closes
  
  No popup. No new tab. Works in all browsers.
```

### Route Structure

```text
/plan-review          →  Review list (cards with project info)
/plan-review/:id      →  Full-page workspace (tabs: Overview, Findings, Checklist, Letter, Docs)
```

The detail page uses `useParams` to load the specific review and renders the full workspace with proper back navigation.

### Auto-annotation Flow

```text
User clicks finding card "Locate on plan"
  → Check if pageImages loaded
    → No  → auto-fetch PDFs, render pages, then set activeFindingIndex
    → Yes → set activeFindingIndex immediately
  → PlanMarkupViewer scrolls to annotation
  → Finding card highlights with ring
```

