

# Plan Review Cleanup — Wave 2

Three changes, sequenced so each one shrinks the surface area for the next. All preserve current behavior.

## 1. Live deficiency stream on the dashboard

Today the pipeline writes to `deficiencies_v2` over 2–3 minutes, but the dashboard only refetches when the user clicks a tab or React Query stale-times out. Reviewers stare at "Discipline Review running…" with zero visible progress.

Add a realtime subscription mirroring the existing `review_pipeline_status` one:

```text
src/hooks/useReviewDashboard.ts
  useDeficienciesV2(planReviewId) → already exists
  + subscribe to postgres_changes on deficiencies_v2 filtered by plan_review_id
  + on INSERT/UPDATE/DELETE → qc.invalidateQueries(["deficiencies_v2", planReviewId])

  useDeferredScopeItems(planReviewId)
  + same treatment, filtered by plan_review_id
```

DB migration: `ALTER PUBLICATION supabase_realtime ADD TABLE public.deficiencies_v2, public.deferred_scope_items;` plus `REPLICA IDENTITY FULL` on both so deletes carry the row.

Result: as each discipline expert finishes, its findings appear in the list in real time. No polling, no manual refresh. Same pattern already proven for the pipeline stepper.

## 2. Retire the v1 pipeline branch

Database confirms only 8 plan_reviews still have `pipeline_version = 'v1'`. Every code path now carries dead weight:

- `PlanReviewDetail.tsx` (1721 lines) has `runAICheck`, finding-status JSONB writes, pin reposition, "new round" — all gated on `pipeline_version === 'v1'`. Roughly 600 lines.
- `deficiency-adapter.ts` exists only because v1 reads `ai_findings` and v2 reads `deficiencies_v2`.
- `ProjectDetail.tsx` counts findings off `ai_findings`.

Approach:

a. **Backfill migration**: for the 8 v1 reviews, create empty `deficiencies_v2` rows from their `ai_findings` JSONB so nothing visually disappears, then flip `pipeline_version = 'v2'`.
b. **Code purge**: delete the v1 branches in `PlanReviewDetail.tsx` (runAICheck, in-place finding edits, pin reposition writes to `ai_findings`, "new round" via legacy path). Replace with a "Run Pipeline" button that just calls the v2 edge function — same one the dashboard uses.
c. **Adapter retirement**: `adaptV2ToFindings` keeps the old `Finding` shape for `PlanMarkupViewer`, `LetterPanel`, `SitePlanChecklist`, etc. — keep it, but it now has only one input source.
d. **ProjectDetail**: count findings via `deficiencies_v2` instead of `ai_findings`.

Net deletion: ~700 lines, one persistent source of confusion gone.

## 3. Split `PlanReviewDetail.tsx` (1721 → ~400 line shell)

Even after the v1 purge, the file mixes routing, data fetching, AI orchestration, PDF rendering, finding filters, comment-letter editing, lint, county checklist, and round comparison. Split into:

```text
src/pages/PlanReviewDetail.tsx              (shell + layout + tabs, ~400 lines)
src/hooks/plan-review/
  usePlanReviewData.ts          (review row + rounds + history queries)
  useFindingFilters.ts          (status/severity/discipline/confidence filtering + URL sync)
  useRunPipeline.ts             (Run Pipeline button → edge fn, progress, toasts)
src/components/plan-review/
  FindingsListPanel.tsx         (the right-hand findings tab body)
  RoundsTimelinePanel.tsx       (round comparison drawer trigger + content)
```

Pure refactor — same imports, same JSX output, same routes. Lets us iterate on individual concerns (e.g. finding filters) without scrolling 1700 lines.

## Bonus polish bundled

- **Reviewer feels the AI working**: as part of #1, add a "N findings so far" counter chip on the pipeline stepper that ticks up live during `discipline_review`.
- **Optimistic confirms**: when a reviewer clicks Confirm/Reject on a deficiency, mutate React Query cache immediately, then send the DB write — the realtime echo from #1 reconciles. Removes the 200ms "did it save?" pause on every triage click.
- **`pipeline_version` column dropped** from `plan_reviews` once the 8 legacy rows are flipped — schema reflects reality.

## Files

**New**
- `src/hooks/plan-review/usePlanReviewData.ts`
- `src/hooks/plan-review/useFindingFilters.ts`
- `src/hooks/plan-review/useRunPipeline.ts`
- `src/components/plan-review/FindingsListPanel.tsx`
- `src/components/plan-review/RoundsTimelinePanel.tsx`
- Migration: `add_realtime_deficiencies_v2.sql` + `drop_pipeline_version.sql`

**Modified**
- `src/hooks/useReviewDashboard.ts` — realtime subscriptions on `deficiencies_v2` + `deferred_scope_items`; optimistic mutation helpers
- `src/pages/PlanReviewDetail.tsx` — purge v1 branches, extract panels/hooks, ~400 lines
- `src/pages/ProjectDetail.tsx` — count findings from `deficiencies_v2`
- `src/lib/deficiency-adapter.ts` — drop the v1 input branch, simplify
- `src/types/index.ts` — drop `pipeline_version` from `PlanReviewRow`

**Deleted (after v1 backfill)**
- All `if (pipeline_version === 'v1')` blocks across `PlanReviewDetail.tsx` and the legacy `runAICheck` orchestration

## What the user sees

- Open a fresh review, click Run Pipeline → deficiencies pop into the list one by one as each discipline expert finishes, like a chat completion. No more "running… running… DONE 47 findings appear at once."
- Confirm/Reject feels instant.
- Codebase has one pipeline, one source of truth, one detail page that fits in a screen.

