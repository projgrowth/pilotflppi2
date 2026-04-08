

# Fix: Enable Plan Review Without Authentication

## Problem
All tables (projects, plan_reviews, etc.) have RLS policies that only allow `authenticated` users. Since there's no logged-in user in the preview, all queries return empty arrays and the Plan Review page shows nothing.

## Solution
Add temporary `anon` SELECT policies to the tables needed by Plan Review so the page works without authentication. This unblocks testing immediately.

### Migration: Add anon read policies

Add SELECT policies for the `anon` role on these tables:
- `projects` — needed to load project details
- `plan_reviews` — needed to load reviews and findings
- `activity_log` — used by dashboard

Also add anon INSERT and UPDATE on `plan_reviews` so the AI pre-check can save results, and anon INSERT on `activity_log` for logging.

```sql
-- Allow anonymous read access for testing
CREATE POLICY "Anon users can read projects" ON public.projects FOR SELECT TO anon USING (true);
CREATE POLICY "Anon users can read plan_reviews" ON public.plan_reviews FOR SELECT TO anon USING (true);
CREATE POLICY "Anon users can update plan_reviews" ON public.plan_reviews FOR UPDATE TO anon USING (true);
CREATE POLICY "Anon users can read activity_log" ON public.activity_log FOR SELECT TO anon USING (true);
CREATE POLICY "Anon users can insert activity_log" ON public.activity_log FOR INSERT TO anon WITH CHECK (true);
```

Additionally, add anon read on `contractors` since projects query joins it, and anon access to the `documents` storage bucket for file uploads.

```sql
CREATE POLICY "Anon users can read contractors" ON public.contractors FOR SELECT TO anon USING (true);

-- Storage: allow anon uploads to documents bucket
CREATE POLICY "Anon users can upload to documents" ON storage.objects FOR INSERT TO anon WITH CHECK (bucket_id = 'documents');
CREATE POLICY "Anon users can read documents" ON storage.objects FOR SELECT TO anon USING (bucket_id = 'documents');
```

### No code changes needed
The Plan Review page code is already correct — it just needs data access. Once RLS allows anon reads, the page will load the 4 existing plan reviews and the full flow (upload, AI pre-check, findings, comment letter) can be tested.

---

## Technical Details
- **Files modified**: None (migration only)
- **Migration**: 1 migration adding anon RLS policies
- **Risk**: These are permissive test-only policies. They should be removed or replaced with proper auth before production.
