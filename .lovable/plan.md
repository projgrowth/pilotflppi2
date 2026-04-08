

# Upgrade Plan Review: Document-Aware AI Analysis & UX Improvements

## Context

The uploaded PDF is a complete set of architectural plans for a **new single-family home at 4644 Higel Ave, City of Sarasota** — Flood Zone AE, referencing FBC 2020 Residential 7th Edition. It includes: Location Plan (A01), Foundation Plan (A02), Floor Plan (A03), Elevations (A04-A05), Roof Plan (A06), Window/Door Schedule (A07), Sections/Details (A08-A09), Electrical Plan (A10), and RCP (A11).

This reveals several gaps in the current system and opportunities for improvement.

---

## Audit of Current Implementation — Issues Found

### 1. AI receives no actual plan data
The AI Pre-Check only sends metadata (project name, address, trade type, county). It never receives the **actual document content** — so findings are entirely fabricated based on project type, not the real plans. This is the single biggest trust problem.

### 2. No document upload flow
There is no way to attach or upload plan documents to a review. The `file_urls` column exists on `plan_reviews` but is never populated or used in the UI.

### 3. Findings parsing is fragile
The code does `result.match(/\[[\s\S]*\]/)` to extract JSON — but the edge function already returns structured output via tool calling. The frontend should just parse `result` directly as JSON.

### 4. No "Download as PDF" for comment letter
The comment letter section mentions PDF download but only has copy. A proper PDF export would make this production-ready.

### 5. Sheet panel is too narrow
`sm:max-w-2xl` for a detailed review workspace is cramped — especially for findings with long descriptions and recommendations.

### 6. No document viewer
Users can't see the plans alongside findings. A side-by-side or tabbed view showing the uploaded PDF next to the findings would be transformative for usability.

### 7. County mismatch in document
The uploaded plans reference "City of Sarasota" and FBC 2020-R 7th Edition, but the AI prompt is hardcoded to FBC 2023. The system should detect and flag code edition discrepancies.

---

## Implementation Plan

### Step 1: Add Document Upload to Plan Review Detail Panel
**Files: `src/pages/PlanReview.tsx`**

- Add a file upload zone (drag-and-drop) inside the review detail sheet
- Upload PDFs to the existing `documents` storage bucket under path `plan-reviews/{review_id}/`
- Save the file URLs to `plan_reviews.file_urls` column
- Show uploaded documents as a list with thumbnail/icon and filename

### Step 2: Parse & Feed Document Content to AI
**Files: `supabase/functions/ai/index.ts`, `src/pages/PlanReview.tsx`**

- When running AI Pre-Check, if `file_urls` exist, fetch the document text (extract via the edge function or pass the parsed text from frontend)
- For the uploaded PDF approach: parse the document client-side using `pdf.js` or server-side, then send extracted text as part of the AI payload
- Simpler approach for now: add a `document_text` field to the payload and have the frontend use the `document--parse_document` pattern — OR just send the document metadata (sheet index, notes, dimensions extracted) as structured context
- Update the AI system prompt to say: "You will receive the actual plan content including sheet listings, structural notes, dimensions, and specifications. Analyze these against the applicable code edition."

### Step 3: Fix Findings JSON Parsing
**File: `src/pages/PlanReview.tsx`**

- The edge function with tool calling already returns `{ content: JSON.stringify(findings) }` — so just `JSON.parse(result)` directly instead of regex matching
- Add proper error boundary for malformed responses

### Step 4: Widen the Review Panel + Add Document Tab
**File: `src/pages/PlanReview.tsx`**

- Widen sheet to `sm:max-w-4xl`
- Add a tabbed interface: **Overview** | **Findings** | **Comment Letter** | **Documents**
- Documents tab shows uploaded PDFs with an embedded viewer (`<iframe>` with the storage URL)

### Step 5: Add PDF Export for Comment Letter
**File: `src/pages/PlanReview.tsx`**

- Use browser `window.print()` with a styled print view as a lightweight PDF solution
- Or generate via a simple edge function that formats the letter as HTML and returns a PDF

### Step 6: Improve Finding Cards
**File: `src/components/FindingCard.tsx`**

- Show finding index number for easy reference in comment letters (e.g., "Finding #3")
- Add a "flag for review" toggle per finding
- Show the sheet reference more prominently (link to document tab)

---

## Technical Details

- **Storage**: Uses existing `documents` bucket (public). Files stored at `plan-reviews/{review_id}/{filename}`
- **No new dependencies needed**: File upload uses native `<input type="file">` + Supabase storage SDK. PDF viewing uses `<iframe>` with the public URL.
- **Edge function changes**: Add `document_context` field handling in the `plan_review_check` action. The prompt already asks for comprehensive findings — now it will have real data to analyze.
- **Files modified**: `src/pages/PlanReview.tsx`, `src/components/FindingCard.tsx`, `supabase/functions/ai/index.ts`
- **No new migrations needed**: `file_urls` column already exists on `plan_reviews`

