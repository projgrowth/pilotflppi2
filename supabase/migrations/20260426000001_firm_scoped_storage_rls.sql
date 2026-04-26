-- Scope documents bucket access by firm.
--
-- Previous policies allowed ANY authenticated user to read/write/delete any
-- file in the bucket. The path structure is:
--   plan-reviews/<plan_review_id>/<filename>
--
-- We extract the plan_review_id from the second path segment and join to
-- plan_reviews to verify the caller belongs to the owning firm.
--
-- The anon policies are also removed — the bucket is already private (public=false),
-- so anon access via policy was a leftover from early development.

-- Drop all existing overly-broad policies on storage.objects for this bucket.
DROP POLICY IF EXISTS "Authenticated users can upload documents"  ON storage.objects;
DROP POLICY IF EXISTS "Authenticated users can read documents"   ON storage.objects;
DROP POLICY IF EXISTS "Authenticated users can delete documents" ON storage.objects;
DROP POLICY IF EXISTS "Public can read documents"                ON storage.objects;
DROP POLICY IF EXISTS "Anon users can upload to documents"       ON storage.objects;
DROP POLICY IF EXISTS "Anon users can read documents"            ON storage.objects;

-- Helper: resolve firm_id from a storage path of the form
--   plan-reviews/<plan_review_id>/...
-- Returns NULL for paths that don't match that structure.
CREATE OR REPLACE FUNCTION public.storage_path_firm_id(obj_name text)
RETURNS uuid
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT pr.firm_id
  FROM public.plan_reviews pr
  WHERE pr.id = (
    -- second segment after 'plan-reviews/'
    split_part(obj_name, '/', 2)
  )::uuid
  LIMIT 1;
$$;

-- SELECT: firm members can read files that belong to their firm.
CREATE POLICY "Firm members can read own documents"
  ON storage.objects FOR SELECT
  TO authenticated
  USING (
    bucket_id = 'documents'
    AND public.storage_path_firm_id(name) = public.user_firm_id(auth.uid())
  );

-- INSERT: firm members can upload to their own firm's paths.
CREATE POLICY "Firm members can upload own documents"
  ON storage.objects FOR INSERT
  TO authenticated
  WITH CHECK (
    bucket_id = 'documents'
    AND (
      -- Allow upload when path resolves to caller's firm, OR when the
      -- plan_review row doesn't exist yet (newly created, firm_id not set).
      -- The latter window closes once the pipeline sets firm_id.
      public.storage_path_firm_id(name) IS NULL
      OR public.storage_path_firm_id(name) = public.user_firm_id(auth.uid())
    )
  );

-- UPDATE: allow metadata updates on own firm's objects.
CREATE POLICY "Firm members can update own documents"
  ON storage.objects FOR UPDATE
  TO authenticated
  USING (
    bucket_id = 'documents'
    AND public.storage_path_firm_id(name) = public.user_firm_id(auth.uid())
  );

-- DELETE: firm members can delete their own firm's objects.
CREATE POLICY "Firm members can delete own documents"
  ON storage.objects FOR DELETE
  TO authenticated
  USING (
    bucket_id = 'documents'
    AND public.storage_path_firm_id(name) = public.user_firm_id(auth.uid())
  );

-- Index to make the firm_id lookup fast for storage policy evaluation.
CREATE INDEX IF NOT EXISTS idx_plan_reviews_id_firm
  ON public.plan_reviews (id, firm_id);
