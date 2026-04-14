

# Remaining Work — Sequential Execution Plan

## Status Check: What's Done

Prompts 1–9 and 14–15 from the suite are implemented. The billing module (fee schedules, invoices, invoice editor, billing tab, dashboard KPIs) is complete. All routes are wired and auth-protected.

## What Remains

Three categories: **security fixes**, **UI polish gaps**, and **functional completeness**.

---

## Execution Order

### Step 1 — Fix AI Edge Function Auth (Security Error)
The `ai` edge function has no JWT validation — anyone with the anon key can burn AI credits. Fix:
- In `supabase/functions/ai/index.ts`: extract `Authorization` header, validate user via `supabase.auth.getUser()`, reject if unauthenticated.
- In `src/lib/ai.ts` (`streamAI`): replace the anon key with the user's session access token from `supabase.auth.getSession()`.

### Step 2 — Fix Storage Bucket RLS (Security Error)
The `documents` bucket lets any authenticated user read/delete any file. Fix via migration:
- Drop existing permissive storage policies on `documents` bucket.
- Create path-based ownership policies: users can only access files under their own `user_id/` prefix using `storage.foldername(name)`.
- Update upload code to prefix file paths with `user.id`.

### Step 3 — Enhance Document Generator (Prompt 10 gaps)
Current `DocumentsGen.tsx` is a stub with cards but no actual generation. Add:
- Pre-flight checklist dialog showing populated vs missing fields when "Generate" is clicked.
- Comment Letter generation: pull `review_flags` for selected project, organize by discipline, render formatted HTML preview.
- Copy-to-clipboard and basic "Download" action for generated content.

### Step 4 — Enhance Deficiencies Page (Prompt 11 gaps)
Current page works but missing:
- "Add to Active Review" popover that lets user pick a project and INSERTs a `review_flags` row from the deficiency data.
- Residential/Commercial filter toggle.
- Item count badge showing filtered results count.

### Step 5 — Enhance Analytics Page (Prompt 12 gaps)
Verify all 5 charts render with real data hooks. Add:
- Date range selector (30d / 90d / 12mo / All Time) that filters chart data.
- Human Correction Rate table at bottom with color-coded HCR% column.
- Review Pipeline Funnel chart (stage counts as descending bars).

### Step 6 — Seed Jurisdictions Data (Prompt 13 gap)
Check if the 12 jurisdiction rows from the prompt suite were seeded. If not, create a migration to INSERT them. Verify the Jurisdictions page displays all fields (wind zone tags, flood zone, portal links, registration status badges).

### Step 7 — Mobile Polish Pass (Prompt 14 gaps)
- Dashboard: 2-column KPI grid on mobile, card-based active reviews (not table).
- ReviewDetail: "View Plans" bottom sheet toggle, "Field Mode" switch filtering to Critical/Major only, persisted in localStorage.
- All tables: horizontal scroll wrapper on mobile.

### Step 8 — Final Verification
- TypeScript build check (`tsc --noEmit`).
- Navigate all routes, confirm no console errors.
- Re-run security scan to verify fixes landed.

---

## Technical Notes

- Each step is self-contained and verifiable before moving to the next.
- Steps 1–2 are security fixes (highest priority).
- Steps 3–7 are UI/feature completeness from the prompt suite.
- Step 8 is the post-implementation checklist rerun.
- All work uses existing patterns (hooks, shared components, Supabase client).

