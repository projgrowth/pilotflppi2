

# Plan Review UX & Error-Prevention Improvements

Goal: make Plan Review faster, calmer, and harder to mess up. Below are concrete changes grouped by impact. We can ship in waves.

---

## Wave 1 — Prevent the most common mistakes (high impact, low risk)

1. **Confirm-before-destructive actions**
   - Add confirm dialogs (with "don't ask again" per session) for: deleting findings, marking all resolved, regenerating the comment letter (overwrites edits), starting a new round, sending to contractor.
   - Today these fire instantly — easy to lose work.

2. **Autosave + dirty-state guard on the comment letter**
   - Debounced autosave (1.5s) to `plan_reviews.comment_letter_draft` (new column) + visible "Saved · 2s ago" indicator.
   - Block route changes / tab close with `beforeunload` if unsaved.
   - Today the textarea is in-memory only — refresh wipes it.

3. **Upload safety net**
   - Pre-upload checks: file type (PDF only), size cap (e.g. 100 MB/file), page-count sanity (warn >150 pages).
   - Per-file progress bar + cancel button + retry-on-fail (no silent failures).
   - Block "Run AI Check" while any upload is still in flight.

4. **QC gate visible everywhere**
   - Single source of truth chip ("Pending QC / Approved / Rejected") shown in topbar AND on the Send button. Disable Send + Document Package generation until QC = approved (already partially done — finish it).
   - Show *who* approved/rejected and *when*.

---

## Wave 2 — Reduce cognitive load while reviewing

5. **Keyboard-first navigation**
   - `j/k` — next/prev finding (auto-scroll PDF to its pin)
   - `r` — toggle resolve, `o` — reopen, `f` — flag for QC, `/` — focus search
   - `?` — overlay listing all shortcuts
   - Power users stop hunting through accordions.

6. **Pin ↔ card sync**
   - Clicking a pin on the PDF highlights + scrolls its card; clicking a card highlights its pin and centers the PDF on it. Add a soft pulse animation so the eye finds it.
   - Currently the link is one-way and easy to lose.

7. **Smart defaults on the findings list**
   - Auto-collapse discipline groups beyond the first 3; only "Critical" stays open by default.
   - Sticky "Active filters" summary chip ("3 filters · 12 of 47 findings") with one-click clear.

8. **Inline evidence preview**
   - "Why?" already shows crops — add a one-click "Open in PDF" that jumps to the exact page+zoom. Removes the manual hunt.

---

## Wave 3 — Catch AI errors before they reach the contractor

9. **Confidence-based triage lane**
   - Auto-bucket findings into **High confidence** (collapsed, pre-checked), **Needs review** (expanded), **Low confidence** (muted, requires explicit confirm to include in letter).
   - Forces human eyes on uncertain items, reduces false-positives shipped to contractor.

10. **Duplicate / conflict detection**
    - Flag findings that cite the same FBC section + same sheet within 50px of each other → suggest merge.
    - Flag findings that contradict resolved findings from prior rounds → "This was resolved in R1, still flagging?"

11. **Side-by-side round diff**
    - When viewing R2+, show a "What changed since R1?" panel: resolved, still-open, newly-found. Stops reviewers from re-flagging things the contractor already fixed.

12. **Pre-send letter linter**
    - Before "Send to Contractor": run checks for empty FBC sections, missing sheet refs, placeholder text (`[TODO]`, `XXX`), findings with no description. Show a blocking checklist.

---

## Wave 4 — Ambient reliability

13. **Activity timeline drawer**
    - Right-side drawer showing every state change (uploads, AI runs, status changes, QC actions) with actor + timestamp. Pulled from `activity_log` + `finding_status_history`. Useful for "wait, who resolved that?".

14. **Recover from AI failures gracefully**
    - If a refine page fails, show it inline on its finding card with a "Retry this page" button instead of failing the whole batch.
    - Persist `ai_run_progress` so a refresh mid-run doesn't restart from zero.

15. **Empty/loading states that teach**
    - Replace generic spinners with stage-specific skeletons ("Extracting sheets… 4/12", "Analyzing electrical scope…"). Reviewers stop wondering if it's stuck.

---

## Suggested first ship (recommended)

**Wave 1 + items 5, 6, 11** in one PR:
- Autosave + unsaved-changes guard on the letter
- Confirm dialogs for destructive actions
- Upload validation + progress + cancel
- `j/k/r/?` keyboard shortcuts with overlay
- Pin ↔ card bi-directional highlight
- R2+ "What changed since last round" diff panel

Highest leverage on error prevention with minimal surface-area change.

---

## Technical notes

- Letter autosave needs a new `plan_reviews.comment_letter_draft text` column + a debounced mutation hook.
- Keyboard shortcuts: a single `usePlanReviewHotkeys` hook in `PlanReviewDetail.tsx` listening on `document`, gated when an input is focused.
- Pin↔card sync: lift `selectedFindingId` state to `PlanReviewDetail` and pass to both `PlanMarkupViewer` and `FindingCard`.
- Round diff: compare current `ai_findings` against `previous_findings` (already stored) by `finding_id`; render as a collapsed banner above the findings list.
- Pre-send linter: pure client-side validators in `src/lib/letter-linter.ts`; surfaces in a dialog before the existing Send action.
- Confidence triage: read existing `confidence` field on findings, bucket in render layer only — no schema change.

