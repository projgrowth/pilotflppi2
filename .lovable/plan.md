

# Plan Review Cleanup Wave

Four targeted refactors to tighten the dashboard, share logic across surfaces, and shrink the largest component. No behavior regressions — every change preserves what's currently shown, just packaged better.

## 1. Consolidate dashboard banners into one "Review Health" strip

Today `ReviewDashboard.tsx` stacks five full-width cards before the tabs even appear:

```text
ReviewStatusBar      (pipeline stage progress)
VerificationBanner   (X upheld · Y overturned · Z modified)
ReviewerMemoryCard   (N learned corrections applied)
CrossCheckBanner     (cross-discipline conflicts)
ReviewSummaryHeader  (project name / address / jurisdiction)
```

Replace with a single `ReviewHealthStrip` component — one bordered card, two rows:

- **Row 1 (always visible)**: project name · address · jurisdiction · current pipeline stage chip · status pill (moves down from the page header).
- **Row 2 (compact metric chips)**: `Verification 47/8/3` · `Memory 23 applied` · `Cross-check 2 conflicts` · `Pipeline ▸ verify`. Each chip is a `Popover` trigger — click to expand the full banner content inline. Conflict/overturned counts > 0 get an amber accent border (per Core memory rule: static accent, no animation).

Cuts ~600px of vertical real estate on first paint. Tabs land above the fold on a 1213px viewport.

## 2. Split `DeficiencyCard.tsx` into focused sub-components

Current file is ~500 lines mixing display, evidence collapsibles, rejection dialog wiring, and PDF deep-link logic. Split into:

```text
src/components/review-dashboard/deficiency/
  DeficiencyCard.tsx         (orchestrator, ~80 lines)
  DeficiencyHeader.tsx       (def number, badges, confidence, sheet chips, "Open Sheet →")
  DeficiencyEvidence.tsx     (Collapsible: evidence[], confidence_basis)
  DeficiencyActions.tsx      (Confirm / Reject / Modify buttons + dialog wiring)
```

Each piece receives `def: DeficiencyV2Row` plus narrow callbacks. Pure presentational where possible. Existing `DeficiencyCard` import path stays the same (re-export from the new orchestrator) so no other files need to change.

## 3. Extract shared filter/sort logic into `useFilteredDeficiencies`

Right now `DeficiencyList.tsx` hides overturned items and sorts by severity → human-review → confidence. `HumanReviewQueue.tsx` does its own filtering and ordering. The two will drift.

Create `src/hooks/useFilteredDeficiencies.ts`:

```ts
useFilteredDeficiencies(planReviewId, {
  hideOverturned?: boolean,        // default true
  onlyHumanReview?: boolean,       // default false
  groupBy?: 'discipline' | 'none', // default 'discipline'
})
```

Returns `{ items, grouped, counts: { total, hidden, humanReview } }`. Both `DeficiencyList` and `HumanReviewQueue` consume it. Sort logic (`severityRank`, `compareDefs`) moves into the hook file as pure helpers — unit-testable.

## 4. Extract `determineStatus()` to `src/lib/review-status.ts`

Currently lives at the bottom of `ReviewDashboard.tsx` and is called only there, but `county-report.ts` re-derives status from the same fields with subtly different logic. Move to:

```text
src/lib/review-status.ts
  - determineReviewStatus(defs): ReviewStatus
  - REVIEW_STATUS_LABELS: Record<ReviewStatus, { label, tone }>
  - StatusPill component (moved from ReviewDashboard)
```

`county-report.ts` imports it so the report header and the dashboard pill can never disagree. `StatusPill` becomes shareable for the new health strip and any future surface (e.g. project list row).

## Bonus polish included

- `CrossCheckBanner` content collapses by default behind its chip in the new strip — only expands when count > 0 or user clicks.
- Plan-viewer deep-link from `DeficiencyHeader` opens in the same tab when the user is already inside `/plan-review/:id`, new tab otherwise — fewer orphan tabs.

## Files

**New**
- `src/components/review-dashboard/ReviewHealthStrip.tsx`
- `src/components/review-dashboard/deficiency/DeficiencyHeader.tsx`
- `src/components/review-dashboard/deficiency/DeficiencyEvidence.tsx`
- `src/components/review-dashboard/deficiency/DeficiencyActions.tsx`
- `src/hooks/useFilteredDeficiencies.ts`
- `src/lib/review-status.ts`

**Modified**
- `src/pages/ReviewDashboard.tsx` — replace 5 banners with `<ReviewHealthStrip>`, import status from new lib
- `src/components/review-dashboard/DeficiencyCard.tsx` — slim orchestrator, re-exports unchanged
- `src/components/review-dashboard/DeficiencyList.tsx` — consume `useFilteredDeficiencies`
- `src/components/review-dashboard/HumanReviewQueue.tsx` — consume `useFilteredDeficiencies`
- `src/lib/county-report.ts` — import `determineReviewStatus` instead of local copy

**Untouched** (intentionally — still mounted inside the new strip's popovers)
- `ReviewStatusBar.tsx`, `VerificationBanner.tsx`, `ReviewerMemoryCard.tsx`, `CrossCheckBanner.tsx`, `ReviewSummaryHeader.tsx`

## What the user sees

- Dashboard opens with tabs visible above the fold instead of after a wall of banners.
- Same information, one click away inside metric chips.
- Deficiency cards render identically but are now half the file size each — faster to iterate on.
- Status pill on the dashboard and status text in the generated PDF report can never disagree again.

