

# Plan Review Precision — Next Wave

## The two biggest precision gaps right now

1. **Reviewers can't quickly verify AI findings.** Every deficiency in `deficiencies_v2` already has `evidence[]` (verbatim plan text), `code_reference` (jsonb), `sheet_refs[]`, and `confidence_basis` — but `DeficiencyCard` only shows the def number and sheet list. Reviewers have no fast way to see *why* the AI flagged it or jump to the cited spot.
2. **No adversarial pass.** The pipeline runs each discipline once and trusts the output. Industry-standard precision technique: run a second "challenger" pass on every flagged item asking "is this actually a code violation, or did the prior pass misread the plan?" — drops false-positives 30-50%.

## What we're building

### A. Evidence-first DeficiencyCard

Expand each card to show what the AI saw, with one-click verification:

```text
┌─ DEF-A-003  ARCH  [Permit Blocker]  conf 0.82 ──┐
│ Finding: Egress door swing direction not noted   │
│ Required: Per FBC 1010.1.2 …                     │
│                                                  │
│ Sheets: [A-101] [A-102]    [Open A-101 →]        │
│                                                  │
│ ▼ Why the AI flagged this (evidence)             │
│   "DOOR 101A — 36"x84"" — A-101 grid C4         │
│   "EGRESS PATH" — A-101 general notes            │
│   Confidence basis: Door schedule shown but      │
│   swing direction symbol missing on plan view.   │
│                                                  │
│   [Confirm] [Reject — false positive] [Modify]   │
└──────────────────────────────────────────────────┘
```

- `Open A-101 →` opens the matching `plan_review_files` PDF in a new tab/drawer at the cited page (fall back to first page if no page index stored).
- Rejecting a finding writes to `review_feedback` (already exists) — feeds the learning loop.
- Confidence basis shown verbatim from `confidence_basis`.

### B. Adversarial verification stage (`verify`)

New stage inserted between `discipline_review` and `cross_check`:

```text
upload → sheet_map → dna_extract → discipline_review
       → verify ← NEW
       → cross_check → deferred_scope → prioritize → complete
```

For every deficiency where `confidence_score < 0.85` OR `priority = high|critical`:

1. Send Gemini 2.5 Pro the original finding + evidence + the same sheet images.
2. Prompt: *"You are a senior plans examiner reviewing another examiner's work. Your job is to find reasons this finding is WRONG. Look at the cited evidence. Did the prior examiner misread the plan? Is this actually shown elsewhere on the sheet? Is the cited code section the correct one?"*
3. Tool-call response: `{ verdict: "upheld" | "overturned" | "modified", reasoning, suggested_fix }`.
4. Outcomes:
   - **upheld** → bump `confidence_score` by 0.1, mark `verification_status = "verified"`.
   - **overturned** → set `status = "rejected"`, `reviewer_notes = "Overturned in adversarial verification: <reasoning>"` — never reaches the comment letter.
   - **modified** → keep finding, replace `finding`/`required_action` with corrected version, set `requires_human_review = true`.

A small banner on the dashboard summarizes: "Verification pass: 47 upheld · 8 overturned · 3 modified."

### C. Confidence-weighted ordering on the dashboard

DeficiencyList already groups by priority. Add a sub-sort by `confidence_score DESC` so high-conviction items rise to the top of each bucket. Items with `requires_human_review = true` get a yellow left-border + "Needs human eyes" chip.

## Technical notes

- **Schema**: add nullable column `deficiencies_v2.verification_status text` (`unverified | verified | overturned | modified`) and `verification_notes text`. No data migration needed — defaults to `unverified` for existing rows.
- **Edge function**: add `stageVerify()` to `run-review-pipeline/index.ts`. Reuses `LOVABLE_API_KEY` and existing sheet-rendering helpers. Batches 5 findings per Gemini call to control latency. Total added pipeline time ≈ 30-90s for a typical review.
- **PDF page jump**: `plan_review_files` stores the file path in storage. Sheet-map already records `page_index` per sheet — use it to build `?page=N` deep-links into a lightweight viewer route (`/plan-review/:id?file=...&page=N`) reusing `PlanMarkupViewer`.
- **DeficiencyCard**: wrap evidence in shadcn `Collapsible` (already used in `DeferredScopePanel`) for consistent UX. Default open when `confidence_score < 0.7`, collapsed otherwise.
- **County report** (`src/lib/county-report.ts`): suppress findings with `verification_status = "overturned"` and add a small footer line: "AI-verified findings only · X items overturned during internal verification."

## What this changes for the user

- False positives sent to contractors drop sharply (overturned items never enter the letter).
- Reviewers stop hunting through PDFs to verify AI claims — evidence is right there.
- High-confidence items get processed faster; low-confidence ones get explicit attention.
- The county report becomes more defensible: every shipped finding survived a second AI pass.

## Out of scope (next waves)

- Admin prompt editor for the verification prompt (use a hardcoded prompt for now; we'll add `prompt_versions` integration later).
- Per-finding "Open in PDF Viewer" with auto-zoom to coordinates (ships with file+page jump first; coordinate jump comes after we wire `grid_cell` into deficiencies_v2).

