-- ============================================================
-- Beta safety: ensure every authenticated user can insert projects
-- and plan_reviews, regardless of firm setup.
--
-- The "Firm members insert" policies allow firm_id IS NULL, which
-- covers users without a firm. But if the set_firm_id trigger resolves
-- a non-null firm_id and it mismatches, the check fails.
-- This migration widens the INSERT policies to allow any authenticated
-- user while we're in beta, and backfills firms for existing users.
-- ============================================================

-- 1. Ensure every auth user has a personal firm (backfill for users who
--    signed up before the auto-firm trigger was deployed).
DO $$
DECLARE
  u record;
  new_firm_id uuid;
BEGIN
  FOR u IN
    SELECT id, raw_user_meta_data->>'full_name' AS full_name,
           raw_user_meta_data->>'firm_name'  AS firm_name
    FROM auth.users
    WHERE id NOT IN (SELECT user_id FROM public.firm_members)
  LOOP
    INSERT INTO public.firms (name, owner_user_id)
    VALUES (COALESCE(u.firm_name, 'My Firm'), u.id)
    RETURNING id INTO new_firm_id;

    INSERT INTO public.firm_members (firm_id, user_id)
    VALUES (new_firm_id, u.id)
    ON CONFLICT (firm_id, user_id) DO NOTHING;
  END LOOP;
END$$;

-- 2. Widen INSERT policies on projects and plan_reviews to allow any
--    authenticated user (beta mode: any reviewer can create work).
DROP POLICY IF EXISTS "Firm members insert projects"   ON public.projects;
DROP POLICY IF EXISTS "Firm members insert plan_reviews" ON public.plan_reviews;

CREATE POLICY "Authenticated users can insert projects"
  ON public.projects FOR INSERT TO authenticated
  WITH CHECK (true);

CREATE POLICY "Authenticated users can insert plan_reviews"
  ON public.plan_reviews FOR INSERT TO authenticated
  WITH CHECK (true);

-- 3. Also widen storage INSERT to allow any authenticated upload
--    (firm-scoped reads remain in place).
DROP POLICY IF EXISTS "Firm members can upload own documents" ON storage.objects;

CREATE POLICY "Authenticated users can upload documents"
  ON storage.objects FOR INSERT TO authenticated
  WITH CHECK (bucket_id = 'documents');
