

## Plan: System-Wide Improvements — Sequential Implementation

This plan implements all discussed improvements in dependency order. Each phase builds on the previous one.

---

### Phase 1: Persist Firm Settings to Database

**Why first**: Every later feature (document templates, email notifications, letterhead) needs firm info from the database, not local state.

- Create a `firm_settings` table (single-row, keyed to user/org) with columns: `firm_name`, `license_number`, `email`, `phone`, `address`, `logo_url`, `closing_language`
- Add RLS: authenticated users can read/update their own firm row
- Update `src/pages/Settings.tsx` to load/save firm settings from the database instead of local state
- Update `CommentLetterExport.tsx` to pull firm info from the DB for letterhead

**Files**: migration SQL, `src/hooks/useFirmSettings.ts` (new), `src/pages/Settings.tsx` (edit), `src/components/CommentLetterExport.tsx` (edit)

---

### Phase 2: Auto-Status Progression

**Why second**: Foundation for all downstream automation (notifications, deadlines, audit trail).

- Create a database trigger function `auto_advance_project_status` that fires on:
  - `plan_reviews` INSERT → set project to `plan_review`
  - `plan_reviews` UPDATE where `ai_check_status = 'complete'` → set project to `comments_sent`
  - `inspections` INSERT → set project to `inspection_scheduled`
  - `inspections` UPDATE where `result = 'pass'` and `certificate_issued = true` → set project to `certificate_issued`
- Add frontend toast notifications when status auto-advances
- Update `ProjectDetail.tsx` to show the auto-progression in the activity feed

**Files**: migration SQL (trigger + function), `src/pages/ProjectDetail.tsx` (minor edit for toast on status change)

---

### Phase 3: Audit Trail on Finding Status Changes

**Why third**: Legal compliance for F.S. 553.791 — every finding change must be timestamped.

- Create a `finding_status_history` table: `id`, `plan_review_id`, `finding_index`, `old_status`, `new_status`, `changed_by`, `changed_at`, `note`
- Add RLS: authenticated can insert (own user), select all
- Update `PlanReviewDetail.tsx` to write a history row every time a finding status chip is toggled
- Add a small expandable "History" section under each finding card showing the change log

**Files**: migration SQL, `src/hooks/useFindingHistory.ts` (new), `src/pages/PlanReviewDetail.tsx` (edit), `src/components/FindingCard.tsx` (edit)

---

### Phase 4: Deadline Enforcement & Alert System

**Why fourth**: Depends on auto-status (Phase 2) for accurate status tracking.

- Add a `deadline_alerts` table: `id`, `project_id`, `alert_type` (7-day, 3-day, 1-day, overdue), `triggered_at`, `acknowledged`
- Create a database function `check_deadline_alerts` that can be called to scan projects and insert alert rows for approaching/passed deadlines
- On the Dashboard, show a persistent banner when any project is overdue or within 1 day
- Add a red "OVERDUE" badge to `StatusChip` and auto-hold projects past deadline (set a `hold_reason` field on projects)
- Update `DeadlineBar` to pulse/animate when critical

**Files**: migration SQL (table + function + `hold_reason` column on projects), `src/components/StatusChip.tsx` (edit), `src/components/DeadlineBar.tsx` (edit), `src/pages/Dashboard.tsx` (edit for banner)

---

### Phase 5: File Versioning for Plan Resubmissions

**Why fifth**: Needed before QC workflow — reviewers need to compare rounds.

- Create a `plan_review_files` table: `id`, `plan_review_id`, `file_path`, `round`, `uploaded_at`, `uploaded_by`
- Migrate existing `file_urls` array data into this table via a one-time migration
- Update `NewPlanReviewWizard.tsx` to insert into `plan_review_files` on upload
- Update `PlanReviewDetail.tsx` to show files grouped by round, with a "Compare Rounds" toggle that shows side-by-side previous round files
- Preserve Round N-1 findings alongside Round N for diff view

**Files**: migration SQL, `src/hooks/usePlanReviewFiles.ts` (new), `src/components/NewPlanReviewWizard.tsx` (edit), `src/pages/PlanReviewDetail.tsx` (edit)

---

### Phase 6: QC Review Workflow

**Why sixth**: Depends on audit trail (Phase 3) and file versioning (Phase 5).

- Add `qc_status` column to `plan_reviews`: `pending_qc`, `qc_approved`, `qc_rejected` (default `pending_qc`)
- Add `qc_reviewer_id` and `qc_notes` columns
- Gate the "Export Comment Letter" and "Send to Contractor" actions behind `qc_status = 'qc_approved'`
- Add a QC review mode in `PlanReviewDetail.tsx`: senior reviewers see an "Approve / Reject" toolbar at the top
- Log QC decisions to `activity_log`

**Files**: migration SQL, `src/pages/PlanReviewDetail.tsx` (edit), `src/components/CommentLetterExport.tsx` (edit — disable if not QC approved), `src/components/CountyDocumentPackage.tsx` (edit)

---

### Phase 7: Contractor Notification Pipeline

**Why last**: Depends on firm settings (Phase 1), QC gate (Phase 6), and document generation being complete.

- Set up email infrastructure using Lovable Cloud email tools
- Create a `send-comment-letter` edge function that:
  - Accepts `plan_review_id`
  - Fetches the project, contractor, findings, and firm settings
  - Generates the comment letter HTML (reusing `buildLetterHTML` logic)
  - Sends to the contractor's email address
  - Logs to `activity_log` with event_type `comments_sent`
- Add a "Send to Contractor" button in the export dropdown (gated behind QC approval from Phase 6)
- Show delivery status in the activity feed

**Files**: edge function `supabase/functions/send-comment-letter/index.ts` (new), `src/pages/PlanReviewDetail.tsx` (edit — add send button), email infrastructure setup

---

### Implementation Approach

Each phase will be implemented fully — database migration, hooks, UI — before moving to the next. After completing each phase, I will verify the build succeeds and the feature integrates with prior phases before proceeding.

Total: 7 sequential phases, approximately 15 files created/edited, 7 database migrations.

