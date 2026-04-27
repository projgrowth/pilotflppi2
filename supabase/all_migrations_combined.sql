-- ============================================================
-- Migration: 20260408135240_c43f8527-14b8-499f-8a52-05322b459aab.sql
-- ============================================================

-- Create enums
CREATE TYPE public.project_status AS ENUM (
  'intake', 'plan_review', 'comments_sent', 'resubmitted', 'approved', 
  'permit_issued', 'inspection_scheduled', 'inspection_complete', 
  'certificate_issued', 'on_hold', 'cancelled'
);

CREATE TYPE public.inspection_result AS ENUM ('pass', 'fail', 'partial', 'pending');
CREATE TYPE public.outreach_status AS ENUM ('new', 'contacted', 'responded', 'converted', 'declined');
CREATE TYPE public.milestone_status AS ENUM ('compliant', 'due_soon', 'overdue', 'inspection_scheduled');

-- Profiles table
CREATE TABLE public.profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  full_name TEXT NOT NULL DEFAULT '',
  role TEXT NOT NULL DEFAULT 'reviewer',
  avatar_url TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can read own profile" ON public.profiles FOR SELECT TO authenticated USING (id = auth.uid());
CREATE POLICY "Users can update own profile" ON public.profiles FOR UPDATE TO authenticated USING (id = auth.uid());
CREATE POLICY "Users can insert own profile" ON public.profiles FOR INSERT TO authenticated WITH CHECK (id = auth.uid());

-- Auto-create profile on signup
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  INSERT INTO public.profiles (id, full_name, role)
  VALUES (NEW.id, COALESCE(NEW.raw_user_meta_data->>'full_name', ''), 'reviewer');
  RETURN NEW;
END;
$$;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Contractors table
CREATE TABLE public.contractors (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  license_number TEXT,
  email TEXT,
  phone TEXT,
  portal_access BOOLEAN NOT NULL DEFAULT false,
  user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
ALTER TABLE public.contractors ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Authenticated users can read contractors" ON public.contractors FOR SELECT TO authenticated USING (true);
CREATE POLICY "Authenticated users can insert contractors" ON public.contractors FOR INSERT TO authenticated WITH CHECK (true);
CREATE POLICY "Authenticated users can update contractors" ON public.contractors FOR UPDATE TO authenticated USING (true);
CREATE POLICY "Authenticated users can delete contractors" ON public.contractors FOR DELETE TO authenticated USING (true);

-- Projects table
CREATE TABLE public.projects (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  address TEXT NOT NULL,
  county TEXT NOT NULL DEFAULT '',
  jurisdiction TEXT NOT NULL DEFAULT '',
  trade_type TEXT NOT NULL DEFAULT 'building',
  services TEXT[] NOT NULL DEFAULT '{}',
  status public.project_status NOT NULL DEFAULT 'intake',
  notice_filed_at TIMESTAMPTZ,
  deadline_at TIMESTAMPTZ,
  assigned_to UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  contractor_id UUID REFERENCES public.contractors(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
ALTER TABLE public.projects ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Authenticated users can read projects" ON public.projects FOR SELECT TO authenticated USING (true);
CREATE POLICY "Authenticated users can insert projects" ON public.projects FOR INSERT TO authenticated WITH CHECK (true);
CREATE POLICY "Authenticated users can update projects" ON public.projects FOR UPDATE TO authenticated USING (true);
CREATE POLICY "Authenticated users can delete projects" ON public.projects FOR DELETE TO authenticated USING (true);

-- Plan reviews table
CREATE TABLE public.plan_reviews (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  project_id UUID NOT NULL REFERENCES public.projects(id) ON DELETE CASCADE,
  file_urls TEXT[] NOT NULL DEFAULT '{}',
  ai_check_status TEXT NOT NULL DEFAULT 'pending',
  ai_findings JSONB DEFAULT '[]',
  reviewer_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  round INTEGER NOT NULL DEFAULT 1,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
ALTER TABLE public.plan_reviews ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Authenticated users can read plan_reviews" ON public.plan_reviews FOR SELECT TO authenticated USING (true);
CREATE POLICY "Authenticated users can insert plan_reviews" ON public.plan_reviews FOR INSERT TO authenticated WITH CHECK (true);
CREATE POLICY "Authenticated users can update plan_reviews" ON public.plan_reviews FOR UPDATE TO authenticated USING (true);

-- Inspections table
CREATE TABLE public.inspections (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  project_id UUID NOT NULL REFERENCES public.projects(id) ON DELETE CASCADE,
  scheduled_at TIMESTAMPTZ,
  inspector_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  inspection_type TEXT NOT NULL DEFAULT 'general',
  result public.inspection_result NOT NULL DEFAULT 'pending',
  virtual BOOLEAN NOT NULL DEFAULT true,
  video_call_url TEXT,
  certificate_issued BOOLEAN NOT NULL DEFAULT false,
  notes TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
ALTER TABLE public.inspections ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Authenticated users can read inspections" ON public.inspections FOR SELECT TO authenticated USING (true);
CREATE POLICY "Authenticated users can insert inspections" ON public.inspections FOR INSERT TO authenticated WITH CHECK (true);
CREATE POLICY "Authenticated users can update inspections" ON public.inspections FOR UPDATE TO authenticated USING (true);

-- Activity log table
CREATE TABLE public.activity_log (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  project_id UUID REFERENCES public.projects(id) ON DELETE CASCADE,
  actor_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  actor_type TEXT NOT NULL DEFAULT 'system',
  event_type TEXT NOT NULL,
  description TEXT NOT NULL,
  metadata JSONB DEFAULT '{}',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
ALTER TABLE public.activity_log ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Authenticated users can read activity_log" ON public.activity_log FOR SELECT TO authenticated USING (true);
CREATE POLICY "Authenticated users can insert activity_log" ON public.activity_log FOR INSERT TO authenticated WITH CHECK (true);

-- Milestone buildings table
CREATE TABLE public.milestone_buildings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  address TEXT NOT NULL,
  building_name TEXT NOT NULL,
  stories INTEGER NOT NULL DEFAULT 1,
  co_issued_date DATE,
  milestone_deadline DATE,
  status public.milestone_status NOT NULL DEFAULT 'compliant',
  contact_name TEXT,
  contact_email TEXT,
  contact_phone TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
ALTER TABLE public.milestone_buildings ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Authenticated users can read milestone_buildings" ON public.milestone_buildings FOR SELECT TO authenticated USING (true);
CREATE POLICY "Authenticated users can insert milestone_buildings" ON public.milestone_buildings FOR INSERT TO authenticated WITH CHECK (true);
CREATE POLICY "Authenticated users can update milestone_buildings" ON public.milestone_buildings FOR UPDATE TO authenticated USING (true);

-- Permit leads table
CREATE TABLE public.permit_leads (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  address TEXT NOT NULL,
  county TEXT NOT NULL DEFAULT '',
  contractor_name TEXT,
  permit_type TEXT NOT NULL DEFAULT '',
  project_value NUMERIC(12,2),
  outreach_status public.outreach_status NOT NULL DEFAULT 'new',
  detected_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
ALTER TABLE public.permit_leads ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Authenticated users can read permit_leads" ON public.permit_leads FOR SELECT TO authenticated USING (true);
CREATE POLICY "Authenticated users can insert permit_leads" ON public.permit_leads FOR INSERT TO authenticated WITH CHECK (true);
CREATE POLICY "Authenticated users can update permit_leads" ON public.permit_leads FOR UPDATE TO authenticated USING (true);

-- ============================================================
-- Migration: 20260408135734_2faf43d5-344e-4423-a696-cb564cf1a2c9.sql
-- ============================================================

-- Create documents storage bucket
INSERT INTO storage.buckets (id, name, public) VALUES ('documents', 'documents', true);

-- RLS policies for documents bucket
CREATE POLICY "Authenticated users can upload documents"
ON storage.objects FOR INSERT TO authenticated
WITH CHECK (bucket_id = 'documents');

CREATE POLICY "Authenticated users can read documents"
ON storage.objects FOR SELECT TO authenticated
USING (bucket_id = 'documents');

CREATE POLICY "Authenticated users can delete documents"
ON storage.objects FOR DELETE TO authenticated
USING (bucket_id = 'documents');

CREATE POLICY "Public can read documents"
ON storage.objects FOR SELECT TO anon
USING (bucket_id = 'documents');

-- ============================================================
-- Migration: 20260408151625_188f8d0a-3135-4878-b183-cd0271655de0.sql
-- ============================================================

-- Anon read policies for testing
CREATE POLICY "Anon users can read projects" ON public.projects FOR SELECT TO anon USING (true);
CREATE POLICY "Anon users can read plan_reviews" ON public.plan_reviews FOR SELECT TO anon USING (true);
CREATE POLICY "Anon users can update plan_reviews" ON public.plan_reviews FOR UPDATE TO anon USING (true);
CREATE POLICY "Anon users can read activity_log" ON public.activity_log FOR SELECT TO anon USING (true);
CREATE POLICY "Anon users can insert activity_log" ON public.activity_log FOR INSERT TO anon WITH CHECK (true);
CREATE POLICY "Anon users can read contractors" ON public.contractors FOR SELECT TO anon USING (true);

-- Storage policies for anon document access
CREATE POLICY "Anon users can upload to documents" ON storage.objects FOR INSERT TO anon WITH CHECK (bucket_id = 'documents');
CREATE POLICY "Anon users can read documents" ON storage.objects FOR SELECT TO anon USING (bucket_id = 'documents');

-- ============================================================
-- Migration: 20260408170931_d2441ca1-7085-4499-a618-336437c0fba8.sql
-- ============================================================
CREATE POLICY "Anon users can insert projects" ON public.projects FOR INSERT TO anon WITH CHECK (true);
CREATE POLICY "Anon users can insert plan_reviews" ON public.plan_reviews FOR INSERT TO anon WITH CHECK (true);
-- ============================================================
-- Migration: 20260408182510_158637f5-4a78-4a25-850c-40d29770a447.sql
-- ============================================================

-- Add persistent finding statuses (keyed by finding index)
ALTER TABLE public.plan_reviews
ADD COLUMN IF NOT EXISTS finding_statuses jsonb DEFAULT '{}'::jsonb;

-- Add previous round findings for diff comparison
ALTER TABLE public.plan_reviews
ADD COLUMN IF NOT EXISTS previous_findings jsonb DEFAULT '[]'::jsonb;

-- ============================================================
-- Migration: 20260408231325_b6533b3b-5ff9-49f4-bce1-1b80a019581c.sql
-- ============================================================

-- 1. CONTRACTORS: Remove anon read policy
DROP POLICY IF EXISTS "Anon users can read contractors" ON public.contractors;

-- 2. PLAN_REVIEWS: Remove all anon policies
DROP POLICY IF EXISTS "Anon users can read plan_reviews" ON public.plan_reviews;
DROP POLICY IF EXISTS "Anon users can insert plan_reviews" ON public.plan_reviews;
DROP POLICY IF EXISTS "Anon users can update plan_reviews" ON public.plan_reviews;

-- 3. PROJECTS: Remove anon policies
DROP POLICY IF EXISTS "Anon users can read projects" ON public.projects;
DROP POLICY IF EXISTS "Anon users can insert projects" ON public.projects;

-- 4. ACTIVITY_LOG: Remove anon policies
DROP POLICY IF EXISTS "Anon users can read activity_log" ON public.activity_log;
DROP POLICY IF EXISTS "Anon users can insert activity_log" ON public.activity_log;

-- ============================================================
-- Migration: 20260408231820_71ead88b-0324-4e1b-9287-ccd89c288b8e.sql
-- ============================================================

-- Remove anon storage policies on documents bucket
DROP POLICY IF EXISTS "Anon users can upload to documents" ON storage.objects;
DROP POLICY IF EXISTS "Anon users can read documents" ON storage.objects;
DROP POLICY IF EXISTS "Public can read documents" ON storage.objects;

-- ============================================================
-- Migration: 20260408232610_e8ebde55-92b1-4fe1-8d25-fbe9ceae6da2.sql
-- ============================================================

-- 1. Make documents bucket private
UPDATE storage.buckets SET public = false WHERE id = 'documents';

-- 2. Prevent profile role self-escalation: replace UPDATE policy
DROP POLICY IF EXISTS "Users can update own profile" ON profiles;

CREATE POLICY "Users can update own profile without role change"
  ON profiles FOR UPDATE
  USING (id = auth.uid())
  WITH CHECK (
    id = auth.uid()
    AND role = (SELECT p.role FROM profiles p WHERE p.id = auth.uid())
  );

-- 3. Scope activity_log INSERT to own actor_id
DROP POLICY IF EXISTS "Authenticated users can insert activity_log" ON activity_log;

CREATE POLICY "Users can only log as themselves"
  ON activity_log FOR INSERT
  TO authenticated
  WITH CHECK (actor_id = auth.uid());

-- ============================================================
-- Migration: 20260409003309_aba524b0-edc8-47ed-86a9-77142c6de78c.sql
-- ============================================================

-- Create firm_settings table
CREATE TABLE public.firm_settings (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID NOT NULL UNIQUE,
  firm_name TEXT NOT NULL DEFAULT '',
  license_number TEXT DEFAULT '',
  email TEXT DEFAULT '',
  phone TEXT DEFAULT '',
  address TEXT DEFAULT '',
  logo_url TEXT DEFAULT '',
  closing_language TEXT DEFAULT '',
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- Enable RLS
ALTER TABLE public.firm_settings ENABLE ROW LEVEL SECURITY;

-- Policies
CREATE POLICY "Users can read own firm settings"
  ON public.firm_settings FOR SELECT
  TO authenticated
  USING (user_id = auth.uid());

CREATE POLICY "Users can insert own firm settings"
  ON public.firm_settings FOR INSERT
  TO authenticated
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can update own firm settings"
  ON public.firm_settings FOR UPDATE
  TO authenticated
  USING (user_id = auth.uid());

-- Auto-update timestamp trigger
CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SET search_path = public;

CREATE TRIGGER update_firm_settings_updated_at
  BEFORE UPDATE ON public.firm_settings
  FOR EACH ROW
  EXECUTE FUNCTION public.update_updated_at_column();

-- ============================================================
-- Migration: 20260409003609_3c63ade0-901c-416d-b00f-5d9bcecc7958.sql
-- ============================================================

-- Create function to auto-advance project status
CREATE OR REPLACE FUNCTION public.auto_advance_project_status()
RETURNS TRIGGER AS $$
DECLARE
  current_status text;
  new_status text := NULL;
BEGIN
  -- For plan_reviews table
  IF TG_TABLE_NAME = 'plan_reviews' THEN
    SELECT status INTO current_status FROM public.projects WHERE id = NEW.project_id;
    
    IF TG_OP = 'INSERT' THEN
      IF current_status = 'intake' THEN
        new_status := 'plan_review';
      END IF;
    ELSIF TG_OP = 'UPDATE' THEN
      IF NEW.ai_check_status = 'complete' AND (OLD.ai_check_status IS DISTINCT FROM 'complete') THEN
        IF current_status IN ('intake', 'plan_review') THEN
          new_status := 'comments_sent';
        END IF;
      END IF;
    END IF;
  END IF;

  -- For inspections table
  IF TG_TABLE_NAME = 'inspections' THEN
    SELECT status INTO current_status FROM public.projects WHERE id = NEW.project_id;
    
    IF TG_OP = 'INSERT' THEN
      IF current_status IN ('intake', 'plan_review', 'comments_sent', 'resubmitted', 'approved', 'permit_issued') THEN
        new_status := 'inspection_scheduled';
      END IF;
    ELSIF TG_OP = 'UPDATE' THEN
      IF NEW.result = 'pass' AND NEW.certificate_issued = true 
         AND (OLD.result IS DISTINCT FROM 'pass' OR OLD.certificate_issued IS DISTINCT FROM true) THEN
        new_status := 'certificate_issued';
      END IF;
    END IF;
  END IF;

  -- Apply the status change
  IF new_status IS NOT NULL THEN
    UPDATE public.projects SET status = new_status::project_status, updated_at = now()
    WHERE id = NEW.project_id;
    
    -- Log to activity_log
    INSERT INTO public.activity_log (event_type, description, project_id, actor_type, metadata)
    VALUES (
      'status_auto_advanced',
      'Project status automatically advanced from ' || current_status || ' to ' || new_status,
      NEW.project_id,
      'system',
      jsonb_build_object('old_status', current_status, 'new_status', new_status, 'trigger_table', TG_TABLE_NAME)
    );
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- Create triggers
CREATE TRIGGER auto_advance_on_plan_review
  AFTER INSERT OR UPDATE ON public.plan_reviews
  FOR EACH ROW
  EXECUTE FUNCTION public.auto_advance_project_status();

CREATE TRIGGER auto_advance_on_inspection
  AFTER INSERT OR UPDATE ON public.inspections
  FOR EACH ROW
  EXECUTE FUNCTION public.auto_advance_project_status();

-- ============================================================
-- Migration: 20260409003632_460aa5b6-4a2d-4122-a011-346e30227306.sql
-- ============================================================

-- Create finding_status_history table
CREATE TABLE public.finding_status_history (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  plan_review_id UUID NOT NULL REFERENCES public.plan_reviews(id) ON DELETE CASCADE,
  finding_index INTEGER NOT NULL,
  old_status TEXT NOT NULL DEFAULT 'open',
  new_status TEXT NOT NULL,
  changed_by UUID NOT NULL,
  changed_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  note TEXT DEFAULT ''
);

-- Enable RLS
ALTER TABLE public.finding_status_history ENABLE ROW LEVEL SECURITY;

-- Policies
CREATE POLICY "Authenticated users can read finding history"
  ON public.finding_status_history FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Users can insert own finding history"
  ON public.finding_status_history FOR INSERT
  TO authenticated
  WITH CHECK (changed_by = auth.uid());

-- Index for fast lookup
CREATE INDEX idx_finding_history_review ON public.finding_status_history(plan_review_id, finding_index);

-- ============================================================
-- Migration: 20260409003837_f9f45500-0170-412d-8fc1-54c97aa708c4.sql
-- ============================================================

-- Create deadline_alerts table
CREATE TABLE public.deadline_alerts (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  project_id UUID NOT NULL REFERENCES public.projects(id) ON DELETE CASCADE,
  alert_type TEXT NOT NULL CHECK (alert_type IN ('7_day', '3_day', '1_day', 'overdue')),
  triggered_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  acknowledged BOOLEAN NOT NULL DEFAULT false,
  UNIQUE (project_id, alert_type)
);

ALTER TABLE public.deadline_alerts ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Authenticated users can read deadline alerts"
  ON public.deadline_alerts FOR SELECT TO authenticated USING (true);

CREATE POLICY "Authenticated users can update deadline alerts"
  ON public.deadline_alerts FOR UPDATE TO authenticated USING (true);

-- Add hold_reason to projects
ALTER TABLE public.projects ADD COLUMN IF NOT EXISTS hold_reason TEXT DEFAULT NULL;

-- Function to check deadlines and generate alerts
CREATE OR REPLACE FUNCTION public.check_deadline_alerts()
RETURNS void AS $$
DECLARE
  proj RECORD;
  days_remaining INTEGER;
BEGIN
  FOR proj IN
    SELECT id, deadline_at, status, hold_reason
    FROM public.projects
    WHERE deadline_at IS NOT NULL
      AND status NOT IN ('certificate_issued', 'cancelled', 'on_hold')
  LOOP
    days_remaining := EXTRACT(DAY FROM (proj.deadline_at - now()));

    -- Overdue
    IF days_remaining <= 0 THEN
      INSERT INTO public.deadline_alerts (project_id, alert_type)
      VALUES (proj.id, 'overdue')
      ON CONFLICT (project_id, alert_type) DO NOTHING;
      
      -- Auto-hold
      IF proj.hold_reason IS NULL THEN
        UPDATE public.projects
        SET status = 'on_hold', hold_reason = 'Deadline expired — auto-hold', updated_at = now()
        WHERE id = proj.id AND status != 'on_hold';
        
        INSERT INTO public.activity_log (event_type, description, project_id, actor_type, metadata)
        VALUES ('deadline_overdue', 'Project auto-held: deadline expired', proj.id, 'system',
          jsonb_build_object('days_remaining', days_remaining));
      END IF;
    END IF;

    -- 1-day warning
    IF days_remaining <= 1 AND days_remaining > 0 THEN
      INSERT INTO public.deadline_alerts (project_id, alert_type)
      VALUES (proj.id, '1_day')
      ON CONFLICT (project_id, alert_type) DO NOTHING;
    END IF;

    -- 3-day warning
    IF days_remaining <= 3 AND days_remaining > 0 THEN
      INSERT INTO public.deadline_alerts (project_id, alert_type)
      VALUES (proj.id, '3_day')
      ON CONFLICT (project_id, alert_type) DO NOTHING;
    END IF;

    -- 7-day warning
    IF days_remaining <= 7 AND days_remaining > 0 THEN
      INSERT INTO public.deadline_alerts (project_id, alert_type)
      VALUES (proj.id, '7_day')
      ON CONFLICT (project_id, alert_type) DO NOTHING;
    END IF;
  END LOOP;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- ============================================================
-- Migration: 20260409003959_d74f9eb6-8c22-4dec-8a88-3749f4f49c1f.sql
-- ============================================================

-- Create plan_review_files table
CREATE TABLE public.plan_review_files (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  plan_review_id UUID NOT NULL REFERENCES public.plan_reviews(id) ON DELETE CASCADE,
  file_path TEXT NOT NULL,
  round INTEGER NOT NULL DEFAULT 1,
  uploaded_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  uploaded_by UUID
);

ALTER TABLE public.plan_review_files ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Authenticated users can read plan review files"
  ON public.plan_review_files FOR SELECT TO authenticated USING (true);

CREATE POLICY "Authenticated users can insert plan review files"
  ON public.plan_review_files FOR INSERT TO authenticated WITH CHECK (true);

CREATE INDEX idx_plan_review_files_review ON public.plan_review_files(plan_review_id, round);

-- Migrate existing file_urls into plan_review_files
INSERT INTO public.plan_review_files (plan_review_id, file_path, round)
SELECT pr.id, unnest(pr.file_urls), pr.round
FROM public.plan_reviews pr
WHERE array_length(pr.file_urls, 1) > 0;

-- ============================================================
-- Migration: 20260409004043_1b6acbcf-38ce-488f-8ca7-6f216bdee4a6.sql
-- ============================================================

-- Add QC columns to plan_reviews
ALTER TABLE public.plan_reviews
  ADD COLUMN IF NOT EXISTS qc_status TEXT NOT NULL DEFAULT 'pending_qc',
  ADD COLUMN IF NOT EXISTS qc_reviewer_id UUID DEFAULT NULL,
  ADD COLUMN IF NOT EXISTS qc_notes TEXT DEFAULT '';

-- ============================================================
-- Migration: 20260409183944_d048a1bd-eee4-4f12-9f79-9cc2aab43170.sql
-- ============================================================

-- Add statutory columns to projects
ALTER TABLE public.projects
  ADD COLUMN IF NOT EXISTS statutory_review_days integer NOT NULL DEFAULT 30,
  ADD COLUMN IF NOT EXISTS statutory_inspection_days integer NOT NULL DEFAULT 10,
  ADD COLUMN IF NOT EXISTS statutory_deadline_at timestamptz,
  ADD COLUMN IF NOT EXISTS review_clock_started_at timestamptz,
  ADD COLUMN IF NOT EXISTS review_clock_paused_at timestamptz;

-- Create statutory_alerts table
CREATE TABLE IF NOT EXISTS public.statutory_alerts (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  project_id uuid NOT NULL REFERENCES public.projects(id) ON DELETE CASCADE,
  alert_type text NOT NULL,
  triggered_at timestamptz NOT NULL DEFAULT now(),
  acknowledged boolean NOT NULL DEFAULT false,
  UNIQUE (project_id, alert_type)
);

ALTER TABLE public.statutory_alerts ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Authenticated users can read statutory alerts"
  ON public.statutory_alerts FOR SELECT TO authenticated USING (true);

CREATE POLICY "Authenticated users can update statutory alerts"
  ON public.statutory_alerts FOR UPDATE TO authenticated USING (true);

CREATE POLICY "System can insert statutory alerts"
  ON public.statutory_alerts FOR INSERT TO authenticated WITH CHECK (true);

-- Function: compute business-day deadline from a start date
CREATE OR REPLACE FUNCTION public.compute_statutory_deadline(
  start_date timestamptz,
  business_days integer
)
RETURNS timestamptz
LANGUAGE plpgsql
IMMUTABLE
SET search_path = public
AS $$
DECLARE
  current_date_val date := start_date::date;
  days_added integer := 0;
BEGIN
  IF start_date IS NULL OR business_days <= 0 THEN
    RETURN NULL;
  END IF;
  
  WHILE days_added < business_days LOOP
    current_date_val := current_date_val + 1;
    -- Skip weekends (6 = Saturday, 0 = Sunday)
    IF EXTRACT(DOW FROM current_date_val) NOT IN (0, 6) THEN
      days_added := days_added + 1;
    END IF;
  END LOOP;
  
  RETURN current_date_val::timestamptz;
END;
$$;

-- Trigger: reset review clock on new plan_review round
CREATE OR REPLACE FUNCTION public.reset_review_clock_on_resubmission()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  UPDATE public.projects
  SET review_clock_started_at = now(),
      review_clock_paused_at = NULL,
      statutory_deadline_at = public.compute_statutory_deadline(now(), COALESCE((SELECT statutory_review_days FROM public.projects WHERE id = NEW.project_id), 30)),
      updated_at = now()
  WHERE id = NEW.project_id;
  
  -- Log clock reset
  INSERT INTO public.activity_log (event_type, description, project_id, actor_type, metadata)
  VALUES (
    'statutory_clock_reset',
    'Statutory review clock reset — new review round ' || NEW.round || ' submitted',
    NEW.project_id,
    'system',
    jsonb_build_object('round', NEW.round)
  );
  
  RETURN NEW;
END;
$$;

CREATE TRIGGER trg_reset_review_clock
  AFTER INSERT ON public.plan_reviews
  FOR EACH ROW
  EXECUTE FUNCTION public.reset_review_clock_on_resubmission();

-- ============================================================
-- Migration: 20260409184612_2fa2cf7c-076c-4dca-a67c-bf99818ebfee.sql
-- ============================================================
-- Add inspection clock tracking column
ALTER TABLE public.projects 
ADD COLUMN IF NOT EXISTS inspection_clock_started_at timestamptz;

-- Add FBC edition field to plan_reviews
ALTER TABLE public.plan_reviews 
ADD COLUMN IF NOT EXISTS fbc_edition text;

-- Add checklist_state to plan_reviews for persistent checklists
ALTER TABLE public.plan_reviews 
ADD COLUMN IF NOT EXISTS checklist_state jsonb DEFAULT '{}'::jsonb;

-- Create trigger function to auto-pause/resume clock on status changes
CREATE OR REPLACE FUNCTION public.auto_manage_statutory_clock()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
BEGIN
  -- Auto-pause clock when comments are sent
  IF NEW.status = 'comments_sent' AND OLD.status IS DISTINCT FROM 'comments_sent' THEN
    NEW.review_clock_paused_at := now();
  END IF;

  -- Resume clock when resubmitted
  IF NEW.status = 'resubmitted' AND OLD.status IS DISTINCT FROM 'resubmitted' THEN
    NEW.review_clock_paused_at := NULL;
    -- If clock wasn't started yet, start it now
    IF NEW.review_clock_started_at IS NULL THEN
      NEW.review_clock_started_at := now();
    END IF;
  END IF;

  RETURN NEW;
END;
$$;

CREATE TRIGGER trg_auto_manage_statutory_clock
BEFORE UPDATE ON public.projects
FOR EACH ROW
EXECUTE FUNCTION public.auto_manage_statutory_clock();

-- Create trigger function to set inspection clock when inspection is scheduled
CREATE OR REPLACE FUNCTION public.set_inspection_clock_on_schedule()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
BEGIN
  -- When a new inspection is created, set the inspection clock if not already set
  UPDATE public.projects
  SET inspection_clock_started_at = COALESCE(inspection_clock_started_at, now()),
      updated_at = now()
  WHERE id = NEW.project_id
    AND inspection_clock_started_at IS NULL;

  RETURN NEW;
END;
$$;

CREATE TRIGGER trg_set_inspection_clock
AFTER INSERT ON public.inspections
FOR EACH ROW
EXECUTE FUNCTION public.set_inspection_clock_on_schedule();
-- ============================================================
-- Migration: 20260409193240_0d173b9c-8ee6-40be-a427-a88ea60c45df.sql
-- ============================================================
ALTER TABLE public.projects ADD COLUMN zoning_data jsonb DEFAULT '{}'::jsonb;
-- ============================================================
-- Migration: 20260409201704_b3580e56-51e8-44a3-b0c0-d04fc807f685.sql
-- ============================================================

-- Add jurisdictions jsonb column to firm_settings
ALTER TABLE public.firm_settings
ADD COLUMN jurisdictions jsonb DEFAULT '[]'::jsonb;

-- Add optional contractor_id FK to permit_leads
ALTER TABLE public.permit_leads
ADD COLUMN contractor_id uuid REFERENCES public.contractors(id) ON DELETE SET NULL;

-- ============================================================
-- Migration: 20260409202927_dd1fc579-0e25-4cd4-b61c-f5f1432c3193.sql
-- ============================================================

-- Fee schedules table
CREATE TABLE public.fee_schedules (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL,
  service_type text NOT NULL DEFAULT 'plan_review',
  trade_type text NOT NULL DEFAULT 'building',
  county text NOT NULL DEFAULT '',
  base_fee numeric(10,2) NOT NULL DEFAULT 0,
  description text NOT NULL DEFAULT '',
  is_active boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.fee_schedules ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can read own fee schedules" ON public.fee_schedules FOR SELECT USING (user_id = auth.uid());
CREATE POLICY "Users can insert own fee schedules" ON public.fee_schedules FOR INSERT WITH CHECK (user_id = auth.uid());
CREATE POLICY "Users can update own fee schedules" ON public.fee_schedules FOR UPDATE USING (user_id = auth.uid());
CREATE POLICY "Users can delete own fee schedules" ON public.fee_schedules FOR DELETE USING (user_id = auth.uid());

CREATE TRIGGER update_fee_schedules_updated_at BEFORE UPDATE ON public.fee_schedules FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

-- Invoices table
CREATE TABLE public.invoices (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL,
  project_id uuid REFERENCES public.projects(id) ON DELETE CASCADE NOT NULL,
  contractor_id uuid REFERENCES public.contractors(id) ON DELETE SET NULL,
  invoice_number text NOT NULL DEFAULT '',
  status text NOT NULL DEFAULT 'draft',
  issued_at timestamptz,
  due_at timestamptz,
  paid_at timestamptz,
  subtotal numeric(10,2) NOT NULL DEFAULT 0,
  tax_rate numeric(5,4) NOT NULL DEFAULT 0,
  tax_amount numeric(10,2) NOT NULL DEFAULT 0,
  total numeric(10,2) NOT NULL DEFAULT 0,
  amount_paid numeric(10,2) NOT NULL DEFAULT 0,
  notes text NOT NULL DEFAULT '',
  custom_footer text NOT NULL DEFAULT '',
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.invoices ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can read own invoices" ON public.invoices FOR SELECT USING (user_id = auth.uid());
CREATE POLICY "Users can insert own invoices" ON public.invoices FOR INSERT WITH CHECK (user_id = auth.uid());
CREATE POLICY "Users can update own invoices" ON public.invoices FOR UPDATE USING (user_id = auth.uid());
CREATE POLICY "Users can delete own invoices" ON public.invoices FOR DELETE USING (user_id = auth.uid());

CREATE TRIGGER update_invoices_updated_at BEFORE UPDATE ON public.invoices FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

-- Invoice line items table
CREATE TABLE public.invoice_line_items (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  invoice_id uuid REFERENCES public.invoices(id) ON DELETE CASCADE NOT NULL,
  description text NOT NULL DEFAULT '',
  quantity integer NOT NULL DEFAULT 1,
  unit_price numeric(10,2) NOT NULL DEFAULT 0,
  total numeric(10,2) NOT NULL DEFAULT 0,
  service_type text,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.invoice_line_items ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can read own invoice line items" ON public.invoice_line_items FOR SELECT
  USING (EXISTS (SELECT 1 FROM public.invoices WHERE invoices.id = invoice_line_items.invoice_id AND invoices.user_id = auth.uid()));
CREATE POLICY "Users can insert own invoice line items" ON public.invoice_line_items FOR INSERT
  WITH CHECK (EXISTS (SELECT 1 FROM public.invoices WHERE invoices.id = invoice_line_items.invoice_id AND invoices.user_id = auth.uid()));
CREATE POLICY "Users can update own invoice line items" ON public.invoice_line_items FOR UPDATE
  USING (EXISTS (SELECT 1 FROM public.invoices WHERE invoices.id = invoice_line_items.invoice_id AND invoices.user_id = auth.uid()));
CREATE POLICY "Users can delete own invoice line items" ON public.invoice_line_items FOR DELETE
  USING (EXISTS (SELECT 1 FROM public.invoices WHERE invoices.id = invoice_line_items.invoice_id AND invoices.user_id = auth.uid()));

-- Auto-generate invoice number function
CREATE OR REPLACE FUNCTION public.generate_invoice_number()
RETURNS text
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT 'FPP-' || to_char(now(), 'YYYY') || '-' || lpad(
    (COALESCE((SELECT COUNT(*) FROM public.invoices WHERE created_at >= date_trunc('year', now())), 0) + 1)::text,
    4, '0'
  );
$$;

-- Index for fast lookups
CREATE INDEX idx_invoices_project_id ON public.invoices(project_id);
CREATE INDEX idx_invoices_user_id ON public.invoices(user_id);
CREATE INDEX idx_invoices_status ON public.invoices(status);
CREATE INDEX idx_invoice_line_items_invoice_id ON public.invoice_line_items(invoice_id);
CREATE INDEX idx_fee_schedules_user_id ON public.fee_schedules(user_id);

-- ============================================================
-- Migration: 20260409204324_3a399cf5-3e45-4776-bbf5-89372dcb8679.sql
-- ============================================================
-- Fix: Profile update policy applies to 'public' role (includes unauthenticated)
-- Drop the existing policy and recreate it scoped to 'authenticated' only
DROP POLICY IF EXISTS "Users can update own profile without role change" ON public.profiles;

CREATE POLICY "Users can update own profile without role change"
  ON public.profiles
  FOR UPDATE
  TO authenticated
  USING (id = auth.uid())
  WITH CHECK (
    (id = auth.uid()) AND (role = (SELECT p.role FROM profiles p WHERE p.id = auth.uid()))
  );
-- ============================================================
-- Migration: 20260414161657_b25a356c-078c-43c7-817f-7b99ed9e5e53.sql
-- ============================================================

-- Create ai_outputs table
CREATE TABLE public.ai_outputs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  project_id uuid REFERENCES public.projects(id) ON DELETE CASCADE,
  input_data jsonb,
  prediction text,
  confidence_score decimal(4,3),
  severity text CHECK (severity IN ('critical','major','minor','admin')),
  model_version text,
  correction_augmented boolean DEFAULT false,
  created_at timestamptz DEFAULT now()
);

ALTER TABLE public.ai_outputs ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Authenticated users can read ai_outputs" ON public.ai_outputs FOR SELECT TO authenticated USING (true);
CREATE POLICY "Authenticated users can insert ai_outputs" ON public.ai_outputs FOR INSERT TO authenticated WITH CHECK (true);
CREATE POLICY "Authenticated users can update ai_outputs" ON public.ai_outputs FOR UPDATE TO authenticated USING (true);

CREATE INDEX idx_ai_outputs_project_id ON public.ai_outputs(project_id);
CREATE INDEX idx_ai_outputs_severity ON public.ai_outputs(severity);

-- Create corrections table
CREATE TABLE public.corrections (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  output_id uuid REFERENCES public.ai_outputs(id) ON DELETE CASCADE,
  user_id uuid NOT NULL,
  original_value text,
  corrected_value text,
  correction_type text CHECK (correction_type IN ('override','edit','flag','dismiss')),
  fbc_section text,
  context_notes text,
  created_at timestamptz DEFAULT now()
);

ALTER TABLE public.corrections ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Authenticated users can read corrections" ON public.corrections FOR SELECT TO authenticated USING (true);
CREATE POLICY "Users can insert own corrections" ON public.corrections FOR INSERT TO authenticated WITH CHECK (user_id = (SELECT auth.uid()));
CREATE POLICY "Users can update own corrections" ON public.corrections FOR UPDATE TO authenticated USING (user_id = (SELECT auth.uid()));

CREATE INDEX idx_corrections_output_id ON public.corrections(output_id);
CREATE INDEX idx_corrections_user_id ON public.corrections(user_id);

-- Create flag_embeddings table
CREATE TABLE public.flag_embeddings (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  correction_id uuid REFERENCES public.corrections(id) ON DELETE CASCADE,
  embedding text, -- stored as serialized vector text
  created_at timestamptz DEFAULT now()
);

ALTER TABLE public.flag_embeddings ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Authenticated users can read flag_embeddings" ON public.flag_embeddings FOR SELECT TO authenticated USING (true);
CREATE POLICY "Authenticated users can insert flag_embeddings" ON public.flag_embeddings FOR INSERT TO authenticated WITH CHECK (true);

CREATE INDEX idx_flag_embeddings_correction_id ON public.flag_embeddings(correction_id);

-- Create review_flags table
CREATE TABLE public.review_flags (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  project_id uuid REFERENCES public.projects(id) ON DELETE CASCADE,
  sheet_ref text,
  detail_ref text,
  fbc_section text,
  description text,
  severity text CHECK (severity IN ('critical','major','minor','admin')),
  confidence text CHECK (confidence IN ('high','medium','low')),
  status text CHECK (status IN ('active','resolved','dismissed')) DEFAULT 'active',
  resolved_at timestamptz,
  resolved_by uuid,
  created_at timestamptz DEFAULT now()
);

ALTER TABLE public.review_flags ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Authenticated users can read review_flags" ON public.review_flags FOR SELECT TO authenticated USING (true);
CREATE POLICY "Authenticated users can insert review_flags" ON public.review_flags FOR INSERT TO authenticated WITH CHECK (true);
CREATE POLICY "Authenticated users can update review_flags" ON public.review_flags FOR UPDATE TO authenticated USING (true);
CREATE POLICY "Authenticated users can delete review_flags" ON public.review_flags FOR DELETE TO authenticated USING (true);

CREATE INDEX idx_review_flags_project_id ON public.review_flags(project_id);
CREATE INDEX idx_review_flags_severity ON public.review_flags(severity);
CREATE INDEX idx_review_flags_confidence ON public.review_flags(confidence);
CREATE INDEX idx_review_flags_status ON public.review_flags(status);

-- Create deficiencies table
CREATE TABLE public.deficiencies (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  fbc_section text NOT NULL,
  title text NOT NULL,
  discipline text CHECK (discipline IN ('architectural','structural','mechanical','electrical','plumbing','energy','accessibility','general')),
  severity text CHECK (severity IN ('critical','major','minor','admin')),
  description text,
  standard_comment_language text,
  is_florida_specific boolean DEFAULT true,
  created_at timestamptz DEFAULT now()
);

ALTER TABLE public.deficiencies ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Authenticated users can read deficiencies" ON public.deficiencies FOR SELECT TO authenticated USING (true);
CREATE POLICY "Authenticated users can insert deficiencies" ON public.deficiencies FOR INSERT TO authenticated WITH CHECK (true);
CREATE POLICY "Authenticated users can update deficiencies" ON public.deficiencies FOR UPDATE TO authenticated USING (true);
CREATE POLICY "Authenticated users can delete deficiencies" ON public.deficiencies FOR DELETE TO authenticated USING (true);

CREATE INDEX idx_deficiencies_discipline ON public.deficiencies(discipline);
CREATE INDEX idx_deficiencies_severity ON public.deficiencies(severity);

-- Seed 25 Florida-specific deficiencies
INSERT INTO public.deficiencies (fbc_section, title, discipline, severity, description, standard_comment_language, is_florida_specific) VALUES
('R802.11', 'Hurricane Strap Connections', 'structural', 'critical', 'Roof-to-wall connections in 130+ mph wind zones require specified hurricane strap type, spacing, and FL Product Approval number.', 'Sheet [X], Detail [X]: Roof-to-wall connections do not specify hurricane strap type, spacing, or FL Product Approval number. Per FBC R802.11 and ASCE 7-22, provide a connector schedule specifying strap model, FL Product Approval #, spacing, and nail pattern for design wind speed of [X] mph.', true),
('R301.2.1.2', 'Wind-Borne Debris Protection', 'architectural', 'critical', 'All glazed openings in wind-borne debris regions must have FL Product Approved impact protection or shutters.', 'Sheet [X]: Glazed opening(s) shown without impact-resistant glazing or approved shutter system. Per FBC R301.2.1.2, all openings in Wind-Borne Debris Regions require FL Product Approved impact protection. Provide product specifications and FL Product Approval numbers for all opening protection.', true),
('1714.5', 'Florida Product Approval Missing', 'general', 'major', 'Products installed in the building envelope require Florida Product Approval numbers on the construction documents.', 'Sheet [X]: Product shown at [location] does not include Florida Product Approval number. Per FBC 1714.5, all products requiring approval must list the FL Product Approval # on the drawings. Revise to include approval numbers for all envelope components.', true),
('R322', 'Flood Zone BFE Compliance', 'structural', 'critical', 'Construction in flood zones must demonstrate Base Flood Elevation compliance and applicable flood-resistant construction methods.', 'Sheet [X]: Project is located in Flood Zone [X] with BFE of [X] ft NAVD88. Plans do not demonstrate finish floor elevation at or above required BFE + freeboard. Per FBC R322, provide flood zone certification, BFE documentation, and confirm lowest floor elevation meets or exceeds [X] ft NAVD88.', true),
('R401.2', 'Energy Code — Form 405 Not Submitted', 'energy', 'major', 'Florida residential projects require Form 405 energy compliance report demonstrating performance path compliance.', 'Energy compliance documentation not included with submittal. Per FBC R401.2, a Florida-specific Form 405 energy compliance report must be submitted and approved prior to permit issuance. Submit a completed Form 405 generated by approved software (EnergyGauge, REScheck-Web FL edition).', true),
('R310', 'Egress Window Dimensions', 'architectural', 'critical', 'Sleeping rooms must have egress windows meeting minimum net clear opening, height, width, and sill height requirements.', 'Sheet [X], Room [X]: Egress window shown does not meet minimum requirements. Per FBC R310.2, required minimums are: net clear opening 5.7 sf (grade floor 5.0 sf), min height 24 in, min width 20 in, max sill height 44 in from floor. Revise window schedule to comply.', false),
('R314', 'Smoke Detector Placement', 'general', 'critical', 'Smoke alarms required in each sleeping room, outside sleeping areas, and on each story including basement.', 'Sheet [X]: Smoke alarm locations not shown or incomplete. Per FBC R314, smoke alarms are required in: each sleeping room, outside each sleeping area, and on each story. Revise electrical plans to show all required smoke alarm locations with interconnect wiring.', false),
('R302.5', 'Garage Separation', 'architectural', 'critical', 'Garage must be separated from dwelling and attic space with specified fire-rated assemblies and self-closing, self-latching doors.', 'Sheet [X]: Garage-to-dwelling separation not clearly detailed. Per FBC R302.5, the garage must be separated from the residence with not less than 1/2-inch gypsum board on the garage side. Door between garage and dwelling must be solid wood, solid steel, or 20-minute fire-rated, self-closing and self-latching. Provide separation details.', false),
('R311', 'Stair/Handrail Dimensions', 'architectural', 'major', 'Stairways must meet minimum width, riser height, tread depth, and handrail requirements.', 'Sheet [X]: Stair details shown do not comply with FBC R311. Required: min width 36 in, max riser 7-3/4 in, min tread 10 in, min headroom 6 ft 8 in. Handrails per R311.7.8: between 34-38 in above nosing, required on at least one side for 4+ risers. Revise stair details to comply.', false),
('M1401.3', 'HVAC — Manual J Not Provided', 'mechanical', 'major', 'HVAC equipment sizing must be supported by Manual J heat load calculation for Florida climate zones.', 'Sheet [X]: HVAC equipment shown without supporting load calculations. Per FBC M1401.3, heating and cooling equipment must be sized per ACCA Manual J. Submit a Florida-specific Manual J load calculation report for the proposed HVAC system. Equipment capacity must match calculated loads within ACCA tolerance.', true),
('E230.66', 'Electrical Panel Clearance', 'electrical', 'major', 'Electrical service panels require minimum 36-inch clearance in front and specific headroom/side clearances.', 'Sheet [X]: Panel location shown does not provide required working clearances. Per FBC E230.66 (NEC 110.26), electrical panels require: minimum 36 in depth in front of panel, 30 in width, 6 ft 6 in headroom. Revise panel location or room dimensions to provide required clearances.', false),
('E230.79', 'Service Entrance Capacity', 'electrical', 'major', 'Service entrance conductor sizing must be adequate for the calculated load per NEC Article 220.', 'Sheet [X]: Service entrance ampacity not specified or appears undersized for the calculated load. Per FBC E230.79 (NEC 230.79), service conductors must have adequate ampacity for the load served. Provide load calculation per NEC Article 220 and confirm service entrance ampacity meets or exceeds calculated demand.', false),
('P2903', 'Plumbing Fixture Unit Count', 'plumbing', 'major', 'Water supply and drain sizing must be based on fixture unit count per FBC plumbing chapters.', 'Sheet [X]: Plumbing fixture schedule provided but water distribution and drain/waste/vent sizing not shown or inadequately sized for fixture unit count. Per FBC P2903, size all water supply pipes based on fixture units. Provide a plumbing riser diagram showing pipe sizes, fixture units, and pressure calculations.', false),
('107.3.4', 'Structural Calculations — Not Signed/Sealed', 'structural', 'major', 'Structural calculations must be signed and sealed by a Florida-licensed engineer of record.', 'Structural calculations submitted are not signed and sealed by a Florida-licensed structural or civil engineer. Per FBC 107.3.4, all structural calculations must bear the signature and seal of the engineer of record licensed in the State of Florida. Resubmit with properly sealed calculations.', true),
('1803', 'Geotechnical Report Required', 'structural', 'major', 'Projects requiring soil bearing capacity verification must include a geotechnical investigation report.', 'Sheet [X]: Foundation design references soil bearing capacity of [X] psf without supporting geotechnical investigation. Per FBC 1803, a geotechnical report prepared by a licensed geotechnical engineer is required. Submit geotechnical report confirming soil bearing values used in foundation design.', false),
('11B-206', 'Accessibility — Path of Travel', 'accessibility', 'critical', 'Projects triggering ADA path of travel requirements must show accessible route from site arrival to all primary function areas.', 'Sheet [X]: Project scope triggers accessible path of travel requirements. Per FBC Chapter 11B and ADA Standards, an accessible route must be provided from site arrival points to all primary function areas. Revise site and floor plans to show compliant accessible route with slopes, curb ramps, and accessible parking per 11B-208.', true),
('R302.3', 'Fire Separation — Party Walls', 'architectural', 'critical', 'Dwelling unit separation walls in townhouses or two-family dwellings require minimum 1-hour fire-resistance rating.', 'Sheet [X]: Party wall between units not detailed to meet fire separation requirements. Per FBC R302.3, dwelling unit separation in two-family dwellings and townhouses requires a minimum 1-hour fire-resistance-rated wall assembly tested per ASTM E119. Provide UL-listed or tested assembly details for all party walls.', false),
('R807', 'Attic Access', 'architectural', 'minor', 'Attics with 30+ inches of vertical height require an access opening of minimum 22x30 inches.', 'Sheet [X]: Attic access opening not shown or undersized. Per FBC R807.1, attics with a clear height of 30 inches or greater require an access opening of not less than 22 by 30 inches. Show attic access location on floor plan with minimum rough opening dimensions of 22 x 30 in.', false),
('G2417', 'Gas Line Pressure Test Documentation', 'mechanical', 'major', 'Gas piping must be tested and approved before concealment. Test documentation must be noted on plans.', 'Sheet [X]: Mechanical plans show gas piping without specifying required pressure test procedure. Per FBC G2417, gas piping must be tested at not less than 1.5 times the maximum operating pressure (minimum 3 psig for pressures of 14 in w.c. or less). Note test requirements and inspection hold point on mechanical drawings.', false),
('R326', 'Pool/Spa Barrier Requirements', 'architectural', 'critical', 'Swimming pools and spas require approved barrier/fence system meeting height, gate, and opening requirements.', 'Sheet [X]: Pool/spa shown without compliant barrier system. Per FBC R326 and Florida Statutes 515, pools require an enclosure barrier with: minimum 4 ft height, maximum 4-inch vertical opening clearance, self-closing/self-latching gates that open away from pool, and no climbable elements. Provide barrier layout and detail on site plan.', true),
('R905', 'Roof Underlayment Specification', 'architectural', 'major', 'Florida roof assemblies require FL Product Approved underlayment systems appropriate to the wind zone.', 'Sheet [X]: Roof assembly shown without specifying underlayment system. Per FBC R905 and Florida requirements, roof underlayment must be FL Product Approved for the applicable wind zone. Provide underlayment specification including FL Product Approval number, installation method, and fastening schedule per manufacturer requirements.', true),
('R403.1.6', 'Anchor Bolt Spacing — Sill Plate', 'structural', 'critical', 'Sill plate anchor bolts must meet spacing and embedment requirements for the design wind speed.', 'Sheet [X]: Foundation plan shows sill plate anchor bolts without confirming spacing meets uplift requirements. Per FBC R403.1.6, anchor bolts must be spaced per the calculated uplift demand for the design wind speed of [X] mph. Provide anchor bolt schedule specifying bolt diameter, embedment, spacing, and connection to foundation per engineered design.', true),
('R402', 'Thermal Envelope — Insulation R-Values', 'energy', 'major', 'Building thermal envelope must meet minimum R-value requirements for Florida climate zone.', 'Sheet [X]: Insulation specifications do not meet Florida Energy Code requirements for Climate Zone [X]. Per FBC R402, minimum requirements are: ceiling R-38, wood frame walls R-13, floor R-13. Revise insulation schedule to comply with FBC Table R402.1.2 for the applicable climate zone and confirm compliance via Form 405.', true),
('107.1', 'Sealed Drawings Required', 'general', 'major', 'Construction documents for permitted work must be signed and sealed by the appropriate licensed design professional.', 'Cover sheet: Construction documents are not signed and sealed by a Florida-licensed design professional. Per FBC 107.1, plans for [building type/scope] must bear the signature and seal of a Florida-licensed [architect/engineer]. Resubmit all sheets with proper professional seal and signature. Verify scope triggers threshold requirements per FBC 471/481.', true);

-- ============================================================
-- Migration: 20260414184541_f05e6317-efef-41e8-8979-24d8adf68235.sql
-- ============================================================
-- Drop existing overly permissive storage policies
DROP POLICY IF EXISTS "Authenticated users can read documents" ON storage.objects;
DROP POLICY IF EXISTS "Authenticated users can upload documents" ON storage.objects;
DROP POLICY IF EXISTS "Authenticated users can delete documents" ON storage.objects;

-- Recreate with ownership checks (files must be under user's ID prefix)
CREATE POLICY "Users can read own documents"
ON storage.objects FOR SELECT
TO authenticated
USING (
  bucket_id = 'documents'
  AND (storage.foldername(name))[1] = auth.uid()::text
);

CREATE POLICY "Users can upload own documents"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'documents'
  AND (storage.foldername(name))[1] = auth.uid()::text
);

CREATE POLICY "Users can delete own documents"
ON storage.objects FOR DELETE
TO authenticated
USING (
  bucket_id = 'documents'
  AND (storage.foldername(name))[1] = auth.uid()::text
);
-- ============================================================
-- Migration: 20260417123300_bdf4650e-aa7a-4f4c-b175-8eb96837557c.sql
-- ============================================================

-- The previous RLS policies required uploads to start with the user's UID,
-- but the app uploads to paths like 'plan-reviews/<reviewId>/...' and
-- 'projects/<projectId>/...'. This caused all PDF uploads to fail silently.
-- Replace with team-wide access for authenticated users.

DROP POLICY IF EXISTS "Users can read own documents" ON storage.objects;
DROP POLICY IF EXISTS "Users can upload own documents" ON storage.objects;
DROP POLICY IF EXISTS "Users can delete own documents" ON storage.objects;
DROP POLICY IF EXISTS "Users can update own documents" ON storage.objects;

CREATE POLICY "Authenticated users can read documents"
ON storage.objects FOR SELECT
TO authenticated
USING (bucket_id = 'documents');

CREATE POLICY "Authenticated users can upload documents"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'documents');

CREATE POLICY "Authenticated users can update documents"
ON storage.objects FOR UPDATE
TO authenticated
USING (bucket_id = 'documents')
WITH CHECK (bucket_id = 'documents');

CREATE POLICY "Authenticated users can delete documents"
ON storage.objects FOR DELETE
TO authenticated
USING (bucket_id = 'documents');

-- ============================================================
-- Migration: 20260417204925_79074405-f852-4ff9-901f-90be90bd62cf.sql
-- ============================================================
-- Tighten storage policies on the 'documents' bucket.
-- Replace open authenticated-any-path policies with path-prefix-scoped policies
-- so files must live under a known prefix (projects/ or plan-reviews/) AND
-- only authenticated users can touch them.

DROP POLICY IF EXISTS "Authenticated users can read documents" ON storage.objects;
DROP POLICY IF EXISTS "Authenticated users can upload documents" ON storage.objects;
DROP POLICY IF EXISTS "Authenticated users can update documents" ON storage.objects;
DROP POLICY IF EXISTS "Authenticated users can delete documents" ON storage.objects;

-- READ: authenticated users can read project & plan-review documents
CREATE POLICY "Authenticated can read project documents"
ON storage.objects
FOR SELECT
TO authenticated
USING (
  bucket_id = 'documents'
  AND (
    (storage.foldername(name))[1] = 'projects'
    OR (storage.foldername(name))[1] = 'plan-reviews'
  )
);

-- INSERT: authenticated users can upload only under known prefixes
CREATE POLICY "Authenticated can upload project documents"
ON storage.objects
FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'documents'
  AND (
    (storage.foldername(name))[1] = 'projects'
    OR (storage.foldername(name))[1] = 'plan-reviews'
  )
);

-- UPDATE: same constraint
CREATE POLICY "Authenticated can update project documents"
ON storage.objects
FOR UPDATE
TO authenticated
USING (
  bucket_id = 'documents'
  AND (
    (storage.foldername(name))[1] = 'projects'
    OR (storage.foldername(name))[1] = 'plan-reviews'
  )
);

-- DELETE: only admins can delete (prevents accidental destruction by any reviewer)
CREATE POLICY "Admins can delete project documents"
ON storage.objects
FOR DELETE
TO authenticated
USING (
  bucket_id = 'documents'
  AND EXISTS (
    SELECT 1 FROM public.profiles
    WHERE profiles.id = auth.uid()
      AND profiles.role = 'admin'
  )
);
-- ============================================================
-- Migration: 20260418000943_a3fdf303-82ef-47c2-bc43-f31b7fb19616.sql
-- ============================================================
ALTER TABLE public.plan_reviews
ADD COLUMN IF NOT EXISTS ai_run_progress jsonb DEFAULT '{}'::jsonb;

COMMENT ON COLUMN public.plan_reviews.ai_run_progress IS 'Tracks AI review pipeline phase + counts so a reviewer can resume after tab close. Shape: { phase, current, total, updated_at }';
-- ============================================================
-- Migration: 20260418002029_8eaf8da0-5f13-4054-9c21-311347c1996c.sql
-- ============================================================
-- Phase 1: user_roles table + has_role() function
-- Additive only. No existing code breaks. Old profiles.role column stays for one release.

-- 1. Role enum
CREATE TYPE public.app_role AS ENUM ('admin', 'reviewer', 'qc', 'viewer');

-- 2. user_roles table (separate from profiles to prevent privilege escalation)
CREATE TABLE public.user_roles (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  role public.app_role NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (user_id, role)
);

ALTER TABLE public.user_roles ENABLE ROW LEVEL SECURITY;

-- 3. SECURITY DEFINER function — bypasses RLS to prevent recursion
CREATE OR REPLACE FUNCTION public.has_role(_user_id uuid, _role public.app_role)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.user_roles
    WHERE user_id = _user_id
      AND role = _role
  )
$$;

-- 4. RLS policies on user_roles
-- Users can read their own roles
CREATE POLICY "Users can read own roles"
ON public.user_roles
FOR SELECT
TO authenticated
USING (user_id = auth.uid());

-- Admins can read all roles
CREATE POLICY "Admins can read all roles"
ON public.user_roles
FOR SELECT
TO authenticated
USING (public.has_role(auth.uid(), 'admin'));

-- Only admins can grant roles
CREATE POLICY "Admins can insert roles"
ON public.user_roles
FOR INSERT
TO authenticated
WITH CHECK (public.has_role(auth.uid(), 'admin'));

-- Only admins can revoke roles
CREATE POLICY "Admins can delete roles"
ON public.user_roles
FOR DELETE
TO authenticated
USING (public.has_role(auth.uid(), 'admin'));

-- 5. Backfill: every existing auth user gets the 'reviewer' role.
-- Anyone whose profiles.role is currently 'admin' also gets the 'admin' role.
INSERT INTO public.user_roles (user_id, role)
SELECT id, 'reviewer'::public.app_role
FROM auth.users
ON CONFLICT (user_id, role) DO NOTHING;

INSERT INTO public.user_roles (user_id, role)
SELECT id, 'admin'::public.app_role
FROM public.profiles
WHERE role = 'admin'
ON CONFLICT (user_id, role) DO NOTHING;

-- 6. Auto-grant 'reviewer' to every new signup via the existing handle_new_user trigger path.
-- We extend handle_new_user rather than add a new trigger to keep one source of truth.
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
BEGIN
  INSERT INTO public.profiles (id, full_name, role)
  VALUES (NEW.id, COALESCE(NEW.raw_user_meta_data->>'full_name', ''), 'reviewer');

  -- Phase 1: also grant baseline 'reviewer' role in user_roles
  INSERT INTO public.user_roles (user_id, role)
  VALUES (NEW.id, 'reviewer'::public.app_role)
  ON CONFLICT (user_id, role) DO NOTHING;

  RETURN NEW;
END;
$function$;
-- ============================================================
-- Migration: 20260418002325_db1f802c-11eb-484a-8487-7da9dfca27b0.sql
-- ============================================================
-- ============================================================
-- Phase 2: Firm tenancy
-- Adds firm_id scoping to every business table.
-- Soft RLS: policies allow firm_id IS NULL for one release as a safety net.
-- ============================================================

-- ----- 1. firms + firm_members -----

CREATE TABLE public.firms (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  owner_user_id uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE public.firm_members (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  firm_id uuid NOT NULL REFERENCES public.firms(id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (firm_id, user_id)
);
CREATE INDEX firm_members_user_id_idx ON public.firm_members(user_id);

ALTER TABLE public.firms ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.firm_members ENABLE ROW LEVEL SECURITY;

-- ----- 2. user_firm_id() helper (SECURITY DEFINER, no recursion) -----

CREATE OR REPLACE FUNCTION public.user_firm_id(_user uuid)
RETURNS uuid
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT firm_id
  FROM public.firm_members
  WHERE user_id = _user
  ORDER BY created_at ASC
  LIMIT 1
$$;

-- RLS for firms / firm_members (use the helper, not self-references)
CREATE POLICY "Members can read own firm"
ON public.firms FOR SELECT TO authenticated
USING (id = public.user_firm_id(auth.uid()) OR public.has_role(auth.uid(), 'admin'));

CREATE POLICY "Admins can insert firms"
ON public.firms FOR INSERT TO authenticated
WITH CHECK (public.has_role(auth.uid(), 'admin'));

CREATE POLICY "Owners can update own firm"
ON public.firms FOR UPDATE TO authenticated
USING (owner_user_id = auth.uid() OR public.has_role(auth.uid(), 'admin'));

CREATE POLICY "Members can read own membership rows"
ON public.firm_members FOR SELECT TO authenticated
USING (user_id = auth.uid() OR firm_id = public.user_firm_id(auth.uid()) OR public.has_role(auth.uid(), 'admin'));

CREATE POLICY "Admins can insert memberships"
ON public.firm_members FOR INSERT TO authenticated
WITH CHECK (public.has_role(auth.uid(), 'admin'));

CREATE POLICY "Admins can delete memberships"
ON public.firm_members FOR DELETE TO authenticated
USING (public.has_role(auth.uid(), 'admin'));

-- ----- 3. Default Firm + backfill memberships -----

INSERT INTO public.firms (id, name, owner_user_id)
VALUES ('00000000-0000-0000-0000-000000000001', 'Default Firm', NULL);

INSERT INTO public.firm_members (firm_id, user_id)
SELECT '00000000-0000-0000-0000-000000000001'::uuid, id
FROM auth.users
ON CONFLICT (firm_id, user_id) DO NOTHING;

-- ----- 4. Add firm_id to every business table + backfill -----

DO $$
DECLARE
  t text;
  business_tables text[] := ARRAY[
    'projects','plan_reviews','contractors','invoices','invoice_line_items',
    'fee_schedules','corrections','ai_outputs','review_flags','deficiencies',
    'permit_leads','milestone_buildings','activity_log','finding_status_history',
    'plan_review_files','deadline_alerts','statutory_alerts','inspections'
  ];
BEGIN
  FOREACH t IN ARRAY business_tables LOOP
    EXECUTE format('ALTER TABLE public.%I ADD COLUMN IF NOT EXISTS firm_id uuid', t);
    EXECUTE format('UPDATE public.%I SET firm_id = ''00000000-0000-0000-0000-000000000001'' WHERE firm_id IS NULL', t);
    EXECUTE format('CREATE INDEX IF NOT EXISTS %I ON public.%I(firm_id)', t || '_firm_id_idx', t);
  END LOOP;
END$$;

-- ----- 5. Default firm_id on insert: trigger that fills firm_id from the caller's membership -----

CREATE OR REPLACE FUNCTION public.set_firm_id_from_user()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NEW.firm_id IS NULL THEN
    NEW.firm_id := public.user_firm_id(auth.uid());
  END IF;
  RETURN NEW;
END;
$$;

DO $$
DECLARE
  t text;
  business_tables text[] := ARRAY[
    'projects','plan_reviews','contractors','invoices','invoice_line_items',
    'fee_schedules','corrections','ai_outputs','review_flags','deficiencies',
    'permit_leads','milestone_buildings','activity_log','finding_status_history',
    'plan_review_files','deadline_alerts','statutory_alerts','inspections'
  ];
BEGIN
  FOREACH t IN ARRAY business_tables LOOP
    EXECUTE format(
      'DROP TRIGGER IF EXISTS set_firm_id ON public.%I; CREATE TRIGGER set_firm_id BEFORE INSERT ON public.%I FOR EACH ROW EXECUTE FUNCTION public.set_firm_id_from_user()',
      t, t
    );
  END LOOP;
END$$;

-- ----- 6. Rewrite every USING (true) policy to firm-scoped (soft: allows firm_id IS NULL) -----

-- Helper macro idea (inlined): drop old broad policies, create scoped ones.
-- We do this table-by-table because policy names differ.

-- projects
DROP POLICY IF EXISTS "Authenticated users can read projects" ON public.projects;
DROP POLICY IF EXISTS "Authenticated users can insert projects" ON public.projects;
DROP POLICY IF EXISTS "Authenticated users can update projects" ON public.projects;
DROP POLICY IF EXISTS "Authenticated users can delete projects" ON public.projects;
CREATE POLICY "Firm members read projects" ON public.projects FOR SELECT TO authenticated
  USING (firm_id IS NULL OR firm_id = public.user_firm_id(auth.uid()) OR public.has_role(auth.uid(),'admin'));
CREATE POLICY "Firm members insert projects" ON public.projects FOR INSERT TO authenticated
  WITH CHECK (firm_id IS NULL OR firm_id = public.user_firm_id(auth.uid()));
CREATE POLICY "Firm members update projects" ON public.projects FOR UPDATE TO authenticated
  USING (firm_id IS NULL OR firm_id = public.user_firm_id(auth.uid()) OR public.has_role(auth.uid(),'admin'));
CREATE POLICY "Firm members delete projects" ON public.projects FOR DELETE TO authenticated
  USING (firm_id IS NULL OR firm_id = public.user_firm_id(auth.uid()) OR public.has_role(auth.uid(),'admin'));

-- plan_reviews
DROP POLICY IF EXISTS "Authenticated users can read plan_reviews" ON public.plan_reviews;
DROP POLICY IF EXISTS "Authenticated users can insert plan_reviews" ON public.plan_reviews;
DROP POLICY IF EXISTS "Authenticated users can update plan_reviews" ON public.plan_reviews;
CREATE POLICY "Firm members read plan_reviews" ON public.plan_reviews FOR SELECT TO authenticated
  USING (firm_id IS NULL OR firm_id = public.user_firm_id(auth.uid()) OR public.has_role(auth.uid(),'admin'));
CREATE POLICY "Firm members insert plan_reviews" ON public.plan_reviews FOR INSERT TO authenticated
  WITH CHECK (firm_id IS NULL OR firm_id = public.user_firm_id(auth.uid()));
CREATE POLICY "Firm members update plan_reviews" ON public.plan_reviews FOR UPDATE TO authenticated
  USING (firm_id IS NULL OR firm_id = public.user_firm_id(auth.uid()) OR public.has_role(auth.uid(),'admin'));

-- contractors
DROP POLICY IF EXISTS "Authenticated users can read contractors" ON public.contractors;
DROP POLICY IF EXISTS "Authenticated users can insert contractors" ON public.contractors;
DROP POLICY IF EXISTS "Authenticated users can update contractors" ON public.contractors;
DROP POLICY IF EXISTS "Authenticated users can delete contractors" ON public.contractors;
CREATE POLICY "Firm members read contractors" ON public.contractors FOR SELECT TO authenticated
  USING (firm_id IS NULL OR firm_id = public.user_firm_id(auth.uid()) OR public.has_role(auth.uid(),'admin'));
CREATE POLICY "Firm members insert contractors" ON public.contractors FOR INSERT TO authenticated
  WITH CHECK (firm_id IS NULL OR firm_id = public.user_firm_id(auth.uid()));
CREATE POLICY "Firm members update contractors" ON public.contractors FOR UPDATE TO authenticated
  USING (firm_id IS NULL OR firm_id = public.user_firm_id(auth.uid()) OR public.has_role(auth.uid(),'admin'));
CREATE POLICY "Firm members delete contractors" ON public.contractors FOR DELETE TO authenticated
  USING (firm_id IS NULL OR firm_id = public.user_firm_id(auth.uid()) OR public.has_role(auth.uid(),'admin'));

-- invoices (already user_id-scoped — keep that AND add firm scope; the firm scope is the OR-guard)
DROP POLICY IF EXISTS "Users can read own invoices" ON public.invoices;
DROP POLICY IF EXISTS "Users can insert own invoices" ON public.invoices;
DROP POLICY IF EXISTS "Users can update own invoices" ON public.invoices;
DROP POLICY IF EXISTS "Users can delete own invoices" ON public.invoices;
CREATE POLICY "Firm members read invoices" ON public.invoices FOR SELECT TO authenticated
  USING (firm_id IS NULL OR firm_id = public.user_firm_id(auth.uid()) OR public.has_role(auth.uid(),'admin'));
CREATE POLICY "Firm members insert invoices" ON public.invoices FOR INSERT TO authenticated
  WITH CHECK (user_id = auth.uid() AND (firm_id IS NULL OR firm_id = public.user_firm_id(auth.uid())));
CREATE POLICY "Firm members update invoices" ON public.invoices FOR UPDATE TO authenticated
  USING (firm_id IS NULL OR firm_id = public.user_firm_id(auth.uid()) OR public.has_role(auth.uid(),'admin'));
CREATE POLICY "Firm members delete invoices" ON public.invoices FOR DELETE TO authenticated
  USING (firm_id IS NULL OR firm_id = public.user_firm_id(auth.uid()) OR public.has_role(auth.uid(),'admin'));

-- invoice_line_items: scope through parent invoice firm_id
DROP POLICY IF EXISTS "Users can read own invoice line items" ON public.invoice_line_items;
DROP POLICY IF EXISTS "Users can insert own invoice line items" ON public.invoice_line_items;
DROP POLICY IF EXISTS "Users can update own invoice line items" ON public.invoice_line_items;
DROP POLICY IF EXISTS "Users can delete own invoice line items" ON public.invoice_line_items;
CREATE POLICY "Firm members read invoice line items" ON public.invoice_line_items FOR SELECT TO authenticated
  USING (EXISTS (SELECT 1 FROM public.invoices i WHERE i.id = invoice_id
    AND (i.firm_id IS NULL OR i.firm_id = public.user_firm_id(auth.uid()) OR public.has_role(auth.uid(),'admin'))));
CREATE POLICY "Firm members insert invoice line items" ON public.invoice_line_items FOR INSERT TO authenticated
  WITH CHECK (EXISTS (SELECT 1 FROM public.invoices i WHERE i.id = invoice_id
    AND (i.firm_id IS NULL OR i.firm_id = public.user_firm_id(auth.uid()))));
CREATE POLICY "Firm members update invoice line items" ON public.invoice_line_items FOR UPDATE TO authenticated
  USING (EXISTS (SELECT 1 FROM public.invoices i WHERE i.id = invoice_id
    AND (i.firm_id IS NULL OR i.firm_id = public.user_firm_id(auth.uid()) OR public.has_role(auth.uid(),'admin'))));
CREATE POLICY "Firm members delete invoice line items" ON public.invoice_line_items FOR DELETE TO authenticated
  USING (EXISTS (SELECT 1 FROM public.invoices i WHERE i.id = invoice_id
    AND (i.firm_id IS NULL OR i.firm_id = public.user_firm_id(auth.uid()) OR public.has_role(auth.uid(),'admin'))));

-- fee_schedules (was user_id-scoped — keep user_id AND add firm scope)
DROP POLICY IF EXISTS "Users can read own fee schedules" ON public.fee_schedules;
DROP POLICY IF EXISTS "Users can insert own fee schedules" ON public.fee_schedules;
DROP POLICY IF EXISTS "Users can update own fee schedules" ON public.fee_schedules;
DROP POLICY IF EXISTS "Users can delete own fee schedules" ON public.fee_schedules;
CREATE POLICY "Firm members read fee schedules" ON public.fee_schedules FOR SELECT TO authenticated
  USING (firm_id IS NULL OR firm_id = public.user_firm_id(auth.uid()) OR public.has_role(auth.uid(),'admin'));
CREATE POLICY "Firm members insert fee schedules" ON public.fee_schedules FOR INSERT TO authenticated
  WITH CHECK (user_id = auth.uid() AND (firm_id IS NULL OR firm_id = public.user_firm_id(auth.uid())));
CREATE POLICY "Firm members update fee schedules" ON public.fee_schedules FOR UPDATE TO authenticated
  USING (firm_id IS NULL OR firm_id = public.user_firm_id(auth.uid()) OR public.has_role(auth.uid(),'admin'));
CREATE POLICY "Firm members delete fee schedules" ON public.fee_schedules FOR DELETE TO authenticated
  USING (firm_id IS NULL OR firm_id = public.user_firm_id(auth.uid()) OR public.has_role(auth.uid(),'admin'));

-- corrections (was user_id-scoped — extend with firm)
DROP POLICY IF EXISTS "Authenticated users can read corrections" ON public.corrections;
DROP POLICY IF EXISTS "Users can insert own corrections" ON public.corrections;
DROP POLICY IF EXISTS "Users can update own corrections" ON public.corrections;
CREATE POLICY "Firm members read corrections" ON public.corrections FOR SELECT TO authenticated
  USING (firm_id IS NULL OR firm_id = public.user_firm_id(auth.uid()) OR public.has_role(auth.uid(),'admin'));
CREATE POLICY "Firm members insert corrections" ON public.corrections FOR INSERT TO authenticated
  WITH CHECK (user_id = auth.uid() AND (firm_id IS NULL OR firm_id = public.user_firm_id(auth.uid())));
CREATE POLICY "Firm members update corrections" ON public.corrections FOR UPDATE TO authenticated
  USING (user_id = auth.uid() AND (firm_id IS NULL OR firm_id = public.user_firm_id(auth.uid())));

-- ai_outputs
DROP POLICY IF EXISTS "Authenticated users can read ai_outputs" ON public.ai_outputs;
DROP POLICY IF EXISTS "Authenticated users can insert ai_outputs" ON public.ai_outputs;
DROP POLICY IF EXISTS "Authenticated users can update ai_outputs" ON public.ai_outputs;
CREATE POLICY "Firm members read ai_outputs" ON public.ai_outputs FOR SELECT TO authenticated
  USING (firm_id IS NULL OR firm_id = public.user_firm_id(auth.uid()) OR public.has_role(auth.uid(),'admin'));
CREATE POLICY "Firm members insert ai_outputs" ON public.ai_outputs FOR INSERT TO authenticated
  WITH CHECK (firm_id IS NULL OR firm_id = public.user_firm_id(auth.uid()));
CREATE POLICY "Firm members update ai_outputs" ON public.ai_outputs FOR UPDATE TO authenticated
  USING (firm_id IS NULL OR firm_id = public.user_firm_id(auth.uid()) OR public.has_role(auth.uid(),'admin'));

-- review_flags
DROP POLICY IF EXISTS "Authenticated users can read review_flags" ON public.review_flags;
DROP POLICY IF EXISTS "Authenticated users can insert review_flags" ON public.review_flags;
DROP POLICY IF EXISTS "Authenticated users can update review_flags" ON public.review_flags;
DROP POLICY IF EXISTS "Authenticated users can delete review_flags" ON public.review_flags;
CREATE POLICY "Firm members read review_flags" ON public.review_flags FOR SELECT TO authenticated
  USING (firm_id IS NULL OR firm_id = public.user_firm_id(auth.uid()) OR public.has_role(auth.uid(),'admin'));
CREATE POLICY "Firm members insert review_flags" ON public.review_flags FOR INSERT TO authenticated
  WITH CHECK (firm_id IS NULL OR firm_id = public.user_firm_id(auth.uid()));
CREATE POLICY "Firm members update review_flags" ON public.review_flags FOR UPDATE TO authenticated
  USING (firm_id IS NULL OR firm_id = public.user_firm_id(auth.uid()) OR public.has_role(auth.uid(),'admin'));
CREATE POLICY "Firm members delete review_flags" ON public.review_flags FOR DELETE TO authenticated
  USING (firm_id IS NULL OR firm_id = public.user_firm_id(auth.uid()) OR public.has_role(auth.uid(),'admin'));

-- deficiencies (this is a code-reference catalog; consider it shared. Allow read for everyone, restrict writes to admin.)
DROP POLICY IF EXISTS "Authenticated users can read deficiencies" ON public.deficiencies;
DROP POLICY IF EXISTS "Authenticated users can insert deficiencies" ON public.deficiencies;
DROP POLICY IF EXISTS "Authenticated users can update deficiencies" ON public.deficiencies;
DROP POLICY IF EXISTS "Authenticated users can delete deficiencies" ON public.deficiencies;
CREATE POLICY "All authenticated read deficiencies" ON public.deficiencies FOR SELECT TO authenticated USING (true);
CREATE POLICY "Admins insert deficiencies" ON public.deficiencies FOR INSERT TO authenticated
  WITH CHECK (public.has_role(auth.uid(),'admin'));
CREATE POLICY "Admins update deficiencies" ON public.deficiencies FOR UPDATE TO authenticated
  USING (public.has_role(auth.uid(),'admin'));
CREATE POLICY "Admins delete deficiencies" ON public.deficiencies FOR DELETE TO authenticated
  USING (public.has_role(auth.uid(),'admin'));

-- permit_leads
DROP POLICY IF EXISTS "Authenticated users can read permit_leads" ON public.permit_leads;
DROP POLICY IF EXISTS "Authenticated users can insert permit_leads" ON public.permit_leads;
DROP POLICY IF EXISTS "Authenticated users can update permit_leads" ON public.permit_leads;
CREATE POLICY "Firm members read permit_leads" ON public.permit_leads FOR SELECT TO authenticated
  USING (firm_id IS NULL OR firm_id = public.user_firm_id(auth.uid()) OR public.has_role(auth.uid(),'admin'));
CREATE POLICY "Firm members insert permit_leads" ON public.permit_leads FOR INSERT TO authenticated
  WITH CHECK (firm_id IS NULL OR firm_id = public.user_firm_id(auth.uid()));
CREATE POLICY "Firm members update permit_leads" ON public.permit_leads FOR UPDATE TO authenticated
  USING (firm_id IS NULL OR firm_id = public.user_firm_id(auth.uid()) OR public.has_role(auth.uid(),'admin'));

-- milestone_buildings
DROP POLICY IF EXISTS "Authenticated users can read milestone_buildings" ON public.milestone_buildings;
DROP POLICY IF EXISTS "Authenticated users can insert milestone_buildings" ON public.milestone_buildings;
DROP POLICY IF EXISTS "Authenticated users can update milestone_buildings" ON public.milestone_buildings;
CREATE POLICY "Firm members read milestone_buildings" ON public.milestone_buildings FOR SELECT TO authenticated
  USING (firm_id IS NULL OR firm_id = public.user_firm_id(auth.uid()) OR public.has_role(auth.uid(),'admin'));
CREATE POLICY "Firm members insert milestone_buildings" ON public.milestone_buildings FOR INSERT TO authenticated
  WITH CHECK (firm_id IS NULL OR firm_id = public.user_firm_id(auth.uid()));
CREATE POLICY "Firm members update milestone_buildings" ON public.milestone_buildings FOR UPDATE TO authenticated
  USING (firm_id IS NULL OR firm_id = public.user_firm_id(auth.uid()) OR public.has_role(auth.uid(),'admin'));

-- activity_log
DROP POLICY IF EXISTS "Authenticated users can read activity_log" ON public.activity_log;
DROP POLICY IF EXISTS "Users can only log as themselves" ON public.activity_log;
CREATE POLICY "Firm members read activity_log" ON public.activity_log FOR SELECT TO authenticated
  USING (firm_id IS NULL OR firm_id = public.user_firm_id(auth.uid()) OR public.has_role(auth.uid(),'admin'));
CREATE POLICY "Firm members insert activity_log" ON public.activity_log FOR INSERT TO authenticated
  WITH CHECK ((actor_id = auth.uid() OR actor_type = 'system') AND (firm_id IS NULL OR firm_id = public.user_firm_id(auth.uid())));

-- finding_status_history
DROP POLICY IF EXISTS "Authenticated users can read finding history" ON public.finding_status_history;
DROP POLICY IF EXISTS "Users can insert own finding history" ON public.finding_status_history;
CREATE POLICY "Firm members read finding history" ON public.finding_status_history FOR SELECT TO authenticated
  USING (firm_id IS NULL OR firm_id = public.user_firm_id(auth.uid()) OR public.has_role(auth.uid(),'admin'));
CREATE POLICY "Firm members insert finding history" ON public.finding_status_history FOR INSERT TO authenticated
  WITH CHECK (changed_by = auth.uid() AND (firm_id IS NULL OR firm_id = public.user_firm_id(auth.uid())));

-- plan_review_files
DROP POLICY IF EXISTS "Authenticated users can read plan review files" ON public.plan_review_files;
DROP POLICY IF EXISTS "Authenticated users can insert plan review files" ON public.plan_review_files;
CREATE POLICY "Firm members read plan review files" ON public.plan_review_files FOR SELECT TO authenticated
  USING (firm_id IS NULL OR firm_id = public.user_firm_id(auth.uid()) OR public.has_role(auth.uid(),'admin'));
CREATE POLICY "Firm members insert plan review files" ON public.plan_review_files FOR INSERT TO authenticated
  WITH CHECK (firm_id IS NULL OR firm_id = public.user_firm_id(auth.uid()));

-- deadline_alerts
DROP POLICY IF EXISTS "Authenticated users can read deadline alerts" ON public.deadline_alerts;
DROP POLICY IF EXISTS "Authenticated users can update deadline alerts" ON public.deadline_alerts;
CREATE POLICY "Firm members read deadline alerts" ON public.deadline_alerts FOR SELECT TO authenticated
  USING (firm_id IS NULL OR firm_id = public.user_firm_id(auth.uid()) OR public.has_role(auth.uid(),'admin'));
CREATE POLICY "Firm members update deadline alerts" ON public.deadline_alerts FOR UPDATE TO authenticated
  USING (firm_id IS NULL OR firm_id = public.user_firm_id(auth.uid()) OR public.has_role(auth.uid(),'admin'));

-- statutory_alerts
DROP POLICY IF EXISTS "Authenticated users can read statutory alerts" ON public.statutory_alerts;
DROP POLICY IF EXISTS "Authenticated users can update statutory alerts" ON public.statutory_alerts;
DROP POLICY IF EXISTS "System can insert statutory alerts" ON public.statutory_alerts;
CREATE POLICY "Firm members read statutory alerts" ON public.statutory_alerts FOR SELECT TO authenticated
  USING (firm_id IS NULL OR firm_id = public.user_firm_id(auth.uid()) OR public.has_role(auth.uid(),'admin'));
CREATE POLICY "Firm members update statutory alerts" ON public.statutory_alerts FOR UPDATE TO authenticated
  USING (firm_id IS NULL OR firm_id = public.user_firm_id(auth.uid()) OR public.has_role(auth.uid(),'admin'));
CREATE POLICY "Firm members insert statutory alerts" ON public.statutory_alerts FOR INSERT TO authenticated
  WITH CHECK (firm_id IS NULL OR firm_id = public.user_firm_id(auth.uid()));

-- inspections
DROP POLICY IF EXISTS "Authenticated users can read inspections" ON public.inspections;
DROP POLICY IF EXISTS "Authenticated users can insert inspections" ON public.inspections;
DROP POLICY IF EXISTS "Authenticated users can update inspections" ON public.inspections;
CREATE POLICY "Firm members read inspections" ON public.inspections FOR SELECT TO authenticated
  USING (firm_id IS NULL OR firm_id = public.user_firm_id(auth.uid()) OR public.has_role(auth.uid(),'admin'));
CREATE POLICY "Firm members insert inspections" ON public.inspections FOR INSERT TO authenticated
  WITH CHECK (firm_id IS NULL OR firm_id = public.user_firm_id(auth.uid()));
CREATE POLICY "Firm members update inspections" ON public.inspections FOR UPDATE TO authenticated
  USING (firm_id IS NULL OR firm_id = public.user_firm_id(auth.uid()) OR public.has_role(auth.uid(),'admin'));

-- ----- 7. Auto-assign new signups to a personal firm (extend handle_new_user) -----

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
DECLARE
  new_firm_id uuid;
BEGIN
  INSERT INTO public.profiles (id, full_name, role)
  VALUES (NEW.id, COALESCE(NEW.raw_user_meta_data->>'full_name', ''), 'reviewer');

  INSERT INTO public.user_roles (user_id, role)
  VALUES (NEW.id, 'reviewer'::public.app_role)
  ON CONFLICT (user_id, role) DO NOTHING;

  -- Phase 2: every new signup gets their own firm.
  INSERT INTO public.firms (name, owner_user_id)
  VALUES (COALESCE(NEW.raw_user_meta_data->>'firm_name', 'My Firm'), NEW.id)
  RETURNING id INTO new_firm_id;

  INSERT INTO public.firm_members (firm_id, user_id)
  VALUES (new_firm_id, NEW.id);

  RETURN NEW;
END;
$function$;
-- ============================================================
-- Migration: 20260420185011_9388def5-faef-480c-9709-107f4797b88d.sql
-- ============================================================
ALTER TABLE public.plan_reviews ADD COLUMN IF NOT EXISTS comment_letter_draft text NOT NULL DEFAULT '';
-- ============================================================
-- Migration: 20260420195749_102a5167-51ed-4d7c-98cc-2906ca78db30.sql
-- ============================================================

-- ============================================================================
-- 1. DISCIPLINE NEGATIVE SPACE (global catalog, admin-managed)
-- ============================================================================
CREATE TABLE public.discipline_negative_space (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  discipline text NOT NULL,
  item_key text NOT NULL,
  description text NOT NULL,
  trigger_condition text,
  fbc_section text,
  sort_order integer NOT NULL DEFAULT 0,
  is_active boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (discipline, item_key)
);
CREATE INDEX idx_dns_discipline ON public.discipline_negative_space(discipline) WHERE is_active;

ALTER TABLE public.discipline_negative_space ENABLE ROW LEVEL SECURITY;

CREATE POLICY "All authenticated read discipline_negative_space"
  ON public.discipline_negative_space FOR SELECT TO authenticated USING (true);
CREATE POLICY "Admins insert discipline_negative_space"
  ON public.discipline_negative_space FOR INSERT TO authenticated
  WITH CHECK (public.has_role(auth.uid(), 'admin'::app_role));
CREATE POLICY "Admins update discipline_negative_space"
  ON public.discipline_negative_space FOR UPDATE TO authenticated
  USING (public.has_role(auth.uid(), 'admin'::app_role));
CREATE POLICY "Admins delete discipline_negative_space"
  ON public.discipline_negative_space FOR DELETE TO authenticated
  USING (public.has_role(auth.uid(), 'admin'::app_role));

CREATE TRIGGER trg_dns_updated_at BEFORE UPDATE ON public.discipline_negative_space
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

-- ============================================================================
-- 2. PROMPT VERSIONS (admin-managed)
-- ============================================================================
CREATE TABLE public.prompt_versions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  prompt_key text NOT NULL,
  version integer NOT NULL,
  system_prompt text NOT NULL,
  fbc_edition text,
  effective_at timestamptz NOT NULL DEFAULT now(),
  is_active boolean NOT NULL DEFAULT true,
  notes text DEFAULT '',
  created_by uuid,
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (prompt_key, version)
);
CREATE INDEX idx_prompt_versions_active ON public.prompt_versions(prompt_key, effective_at DESC) WHERE is_active;

ALTER TABLE public.prompt_versions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Authenticated read prompt_versions"
  ON public.prompt_versions FOR SELECT TO authenticated USING (true);
CREATE POLICY "Admins insert prompt_versions"
  ON public.prompt_versions FOR INSERT TO authenticated
  WITH CHECK (public.has_role(auth.uid(), 'admin'::app_role));
CREATE POLICY "Admins update prompt_versions"
  ON public.prompt_versions FOR UPDATE TO authenticated
  USING (public.has_role(auth.uid(), 'admin'::app_role));

-- ============================================================================
-- 3. FLORIDA JURISDICTIONS (seeded, admin-managed)
-- ============================================================================
CREATE TABLE public.jurisdictions_fl (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  county text NOT NULL UNIQUE,
  fbc_edition text NOT NULL DEFAULT '8th',
  hvhz boolean NOT NULL DEFAULT false,
  coastal boolean NOT NULL DEFAULT false,
  flood_zone_critical boolean NOT NULL DEFAULT false,
  high_volume boolean NOT NULL DEFAULT false,
  local_amendments_url text,
  notes text DEFAULT '',
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX idx_jur_fl_flags ON public.jurisdictions_fl(hvhz, coastal, high_volume);

ALTER TABLE public.jurisdictions_fl ENABLE ROW LEVEL SECURITY;

CREATE POLICY "All authenticated read jurisdictions_fl"
  ON public.jurisdictions_fl FOR SELECT TO authenticated USING (true);
CREATE POLICY "Admins insert jurisdictions_fl"
  ON public.jurisdictions_fl FOR INSERT TO authenticated
  WITH CHECK (public.has_role(auth.uid(), 'admin'::app_role));
CREATE POLICY "Admins update jurisdictions_fl"
  ON public.jurisdictions_fl FOR UPDATE TO authenticated
  USING (public.has_role(auth.uid(), 'admin'::app_role));

CREATE TRIGGER trg_jur_fl_updated_at BEFORE UPDATE ON public.jurisdictions_fl
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

-- Seed all 67 Florida counties with special flags applied
INSERT INTO public.jurisdictions_fl (county, hvhz, coastal, flood_zone_critical, high_volume) VALUES
('Alachua', false, false, false, false),
('Baker', false, false, false, false),
('Bay', false, true, false, false),
('Bradford', false, false, false, false),
('Brevard', false, true, false, false),
('Broward', true, true, false, true),
('Calhoun', false, false, false, false),
('Charlotte', false, true, false, false),
('Citrus', false, true, false, false),
('Clay', false, false, false, false),
('Collier', false, true, true, false),
('Columbia', false, false, false, false),
('DeSoto', false, false, false, false),
('Dixie', false, true, false, false),
('Duval', false, true, false, true),
('Escambia', false, true, false, false),
('Flagler', false, true, false, false),
('Franklin', false, true, false, false),
('Gadsden', false, false, false, false),
('Gilchrist', false, false, false, false),
('Glades', false, false, false, false),
('Gulf', false, true, false, false),
('Hamilton', false, false, false, false),
('Hardee', false, false, false, false),
('Hendry', false, false, false, false),
('Hernando', false, true, false, false),
('Highlands', false, false, false, false),
('Hillsborough', false, true, false, true),
('Holmes', false, false, false, false),
('Indian River', false, true, false, false),
('Jackson', false, false, false, false),
('Jefferson', false, true, false, false),
('Lafayette', false, false, false, false),
('Lake', false, false, false, false),
('Lee', false, true, true, true),
('Leon', false, false, false, false),
('Levy', false, true, false, false),
('Liberty', false, false, false, false),
('Madison', false, false, false, false),
('Manatee', false, true, false, false),
('Marion', false, false, false, false),
('Martin', false, true, false, false),
('Miami-Dade', true, true, false, true),
('Monroe', true, true, true, false),
('Nassau', false, true, false, false),
('Okaloosa', false, true, false, false),
('Okeechobee', false, false, false, false),
('Orange', false, false, false, true),
('Osceola', false, false, false, false),
('Palm Beach', false, true, true, true),
('Pasco', false, true, false, true),
('Pinellas', false, true, false, true),
('Polk', false, false, false, false),
('Putnam', false, false, false, false),
('Santa Rosa', false, true, false, false),
('Sarasota', false, true, true, true),
('Seminole', false, false, false, false),
('St. Johns', false, true, false, false),
('St. Lucie', false, true, false, false),
('Sumter', false, false, false, false),
('Suwannee', false, false, false, false),
('Taylor', false, true, false, false),
('Union', false, false, false, false),
('Volusia', false, true, false, true),
('Wakulla', false, true, false, false),
('Walton', false, true, false, false),
('Washington', false, false, false, false);

-- ============================================================================
-- 4. PROJECT DNA (one per plan_review)
-- ============================================================================
CREATE TABLE public.project_dna (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  plan_review_id uuid NOT NULL UNIQUE REFERENCES public.plan_reviews(id) ON DELETE CASCADE,
  firm_id uuid,
  occupancy_classification text,
  construction_type text,
  total_sq_ft numeric,
  stories integer,
  fbc_edition text,
  jurisdiction text,
  county text,
  hvhz boolean,
  flood_zone text,
  wind_speed_vult integer,
  exposure_category text,
  risk_category text,
  seismic_design_category text,
  has_mezzanine boolean DEFAULT false,
  is_high_rise boolean DEFAULT false,
  mixed_occupancy boolean DEFAULT false,
  raw_extraction jsonb DEFAULT '{}'::jsonb,
  missing_fields text[] DEFAULT '{}'::text[],
  ambiguous_fields text[] DEFAULT '{}'::text[],
  extracted_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX idx_project_dna_review ON public.project_dna(plan_review_id);
CREATE INDEX idx_project_dna_firm ON public.project_dna(firm_id);

ALTER TABLE public.project_dna ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Firm members read project_dna"
  ON public.project_dna FOR SELECT TO authenticated
  USING ((firm_id IS NULL) OR (firm_id = public.user_firm_id(auth.uid())) OR public.has_role(auth.uid(), 'admin'::app_role));
CREATE POLICY "Firm members insert project_dna"
  ON public.project_dna FOR INSERT TO authenticated
  WITH CHECK ((firm_id IS NULL) OR (firm_id = public.user_firm_id(auth.uid())));
CREATE POLICY "Firm members update project_dna"
  ON public.project_dna FOR UPDATE TO authenticated
  USING ((firm_id IS NULL) OR (firm_id = public.user_firm_id(auth.uid())) OR public.has_role(auth.uid(), 'admin'::app_role));

CREATE TRIGGER trg_project_dna_firm BEFORE INSERT ON public.project_dna
  FOR EACH ROW EXECUTE FUNCTION public.set_firm_id_from_user();
CREATE TRIGGER trg_project_dna_updated_at BEFORE UPDATE ON public.project_dna
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

-- ============================================================================
-- 5. SHEET COVERAGE (per plan_review)
-- ============================================================================
CREATE TABLE public.sheet_coverage (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  plan_review_id uuid NOT NULL REFERENCES public.plan_reviews(id) ON DELETE CASCADE,
  firm_id uuid,
  sheet_ref text NOT NULL,
  sheet_title text,
  discipline text,
  status text NOT NULL DEFAULT 'present', -- present | missing_critical | missing_minor | extra
  expected boolean NOT NULL DEFAULT true,
  page_index integer,
  created_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX idx_sheet_coverage_review ON public.sheet_coverage(plan_review_id);
CREATE INDEX idx_sheet_coverage_status ON public.sheet_coverage(plan_review_id, status);

ALTER TABLE public.sheet_coverage ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Firm members read sheet_coverage"
  ON public.sheet_coverage FOR SELECT TO authenticated
  USING ((firm_id IS NULL) OR (firm_id = public.user_firm_id(auth.uid())) OR public.has_role(auth.uid(), 'admin'::app_role));
CREATE POLICY "Firm members insert sheet_coverage"
  ON public.sheet_coverage FOR INSERT TO authenticated
  WITH CHECK ((firm_id IS NULL) OR (firm_id = public.user_firm_id(auth.uid())));
CREATE POLICY "Firm members update sheet_coverage"
  ON public.sheet_coverage FOR UPDATE TO authenticated
  USING ((firm_id IS NULL) OR (firm_id = public.user_firm_id(auth.uid())) OR public.has_role(auth.uid(), 'admin'::app_role));
CREATE POLICY "Firm members delete sheet_coverage"
  ON public.sheet_coverage FOR DELETE TO authenticated
  USING ((firm_id IS NULL) OR (firm_id = public.user_firm_id(auth.uid())) OR public.has_role(auth.uid(), 'admin'::app_role));

CREATE TRIGGER trg_sheet_coverage_firm BEFORE INSERT ON public.sheet_coverage
  FOR EACH ROW EXECUTE FUNCTION public.set_firm_id_from_user();

-- ============================================================================
-- 6. DEFICIENCIES V2 (rich per-review deficiencies)
-- ============================================================================
CREATE TABLE public.deficiencies_v2 (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  plan_review_id uuid NOT NULL REFERENCES public.plan_reviews(id) ON DELETE CASCADE,
  firm_id uuid,
  def_number text NOT NULL, -- "DEF-001"
  discipline text NOT NULL,
  sheet_refs text[] DEFAULT '{}'::text[],
  code_reference jsonb DEFAULT '{}'::jsonb, -- {code:"FBC", section:"1004.5", edition:"8th"}
  finding text NOT NULL,
  required_action text NOT NULL,
  evidence text[] DEFAULT '{}'::text[], -- exact text snippets from plan set
  priority text NOT NULL DEFAULT 'medium', -- high | medium | low
  life_safety_flag boolean NOT NULL DEFAULT false,
  permit_blocker boolean NOT NULL DEFAULT false,
  liability_flag boolean NOT NULL DEFAULT false,
  requires_human_review boolean NOT NULL DEFAULT false,
  human_review_reason text,
  human_review_verify text,
  human_review_method text,
  confidence_score numeric, -- 0..1
  confidence_basis text,
  reviewer_disposition text, -- confirm | reject | modify | null
  reviewer_notes text DEFAULT '',
  status text NOT NULL DEFAULT 'open', -- open | resolved | waived | needs_info
  prompt_version_id uuid REFERENCES public.prompt_versions(id),
  model_version text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX idx_def_v2_review ON public.deficiencies_v2(plan_review_id);
CREATE INDEX idx_def_v2_firm ON public.deficiencies_v2(firm_id);
CREATE INDEX idx_def_v2_priority ON public.deficiencies_v2(plan_review_id, priority);
CREATE INDEX idx_def_v2_human ON public.deficiencies_v2(plan_review_id) WHERE requires_human_review;

ALTER TABLE public.deficiencies_v2 ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Firm members read deficiencies_v2"
  ON public.deficiencies_v2 FOR SELECT TO authenticated
  USING ((firm_id IS NULL) OR (firm_id = public.user_firm_id(auth.uid())) OR public.has_role(auth.uid(), 'admin'::app_role));
CREATE POLICY "Firm members insert deficiencies_v2"
  ON public.deficiencies_v2 FOR INSERT TO authenticated
  WITH CHECK ((firm_id IS NULL) OR (firm_id = public.user_firm_id(auth.uid())));
CREATE POLICY "Firm members update deficiencies_v2"
  ON public.deficiencies_v2 FOR UPDATE TO authenticated
  USING ((firm_id IS NULL) OR (firm_id = public.user_firm_id(auth.uid())) OR public.has_role(auth.uid(), 'admin'::app_role));
CREATE POLICY "Firm members delete deficiencies_v2"
  ON public.deficiencies_v2 FOR DELETE TO authenticated
  USING ((firm_id IS NULL) OR (firm_id = public.user_firm_id(auth.uid())) OR public.has_role(auth.uid(), 'admin'::app_role));

CREATE TRIGGER trg_def_v2_firm BEFORE INSERT ON public.deficiencies_v2
  FOR EACH ROW EXECUTE FUNCTION public.set_firm_id_from_user();
CREATE TRIGGER trg_def_v2_updated_at BEFORE UPDATE ON public.deficiencies_v2
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

-- ============================================================================
-- 7. REVIEW PIPELINE STATUS (per stage)
-- ============================================================================
CREATE TABLE public.review_pipeline_status (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  plan_review_id uuid NOT NULL REFERENCES public.plan_reviews(id) ON DELETE CASCADE,
  firm_id uuid,
  stage text NOT NULL, -- upload | sheet_map | dna_extract | discipline_review | cross_check | deferred_scope | prioritize | complete
  status text NOT NULL DEFAULT 'pending', -- pending | running | complete | error
  started_at timestamptz,
  completed_at timestamptz,
  error_message text,
  metadata jsonb DEFAULT '{}'::jsonb,
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (plan_review_id, stage)
);
CREATE INDEX idx_pipeline_review ON public.review_pipeline_status(plan_review_id);

ALTER TABLE public.review_pipeline_status ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Firm members read pipeline_status"
  ON public.review_pipeline_status FOR SELECT TO authenticated
  USING ((firm_id IS NULL) OR (firm_id = public.user_firm_id(auth.uid())) OR public.has_role(auth.uid(), 'admin'::app_role));
CREATE POLICY "Firm members insert pipeline_status"
  ON public.review_pipeline_status FOR INSERT TO authenticated
  WITH CHECK ((firm_id IS NULL) OR (firm_id = public.user_firm_id(auth.uid())));
CREATE POLICY "Firm members update pipeline_status"
  ON public.review_pipeline_status FOR UPDATE TO authenticated
  USING ((firm_id IS NULL) OR (firm_id = public.user_firm_id(auth.uid())) OR public.has_role(auth.uid(), 'admin'::app_role));

CREATE TRIGGER trg_pipeline_firm BEFORE INSERT ON public.review_pipeline_status
  FOR EACH ROW EXECUTE FUNCTION public.set_firm_id_from_user();
CREATE TRIGGER trg_pipeline_updated_at BEFORE UPDATE ON public.review_pipeline_status
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

-- Enable realtime on pipeline status so the UI updates live
ALTER PUBLICATION supabase_realtime ADD TABLE public.review_pipeline_status;

-- ============================================================================
-- 8. REVIEW FEEDBACK (learning loop)
-- ============================================================================
CREATE TABLE public.review_feedback (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  plan_review_id uuid NOT NULL REFERENCES public.plan_reviews(id) ON DELETE CASCADE,
  firm_id uuid,
  deficiency_id uuid REFERENCES public.deficiencies_v2(id) ON DELETE SET NULL,
  feedback_type text NOT NULL, -- ai_confirmed | ai_rejected | human_added | ai_modified
  notes text DEFAULT '',
  reviewer_id uuid,
  created_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX idx_feedback_review ON public.review_feedback(plan_review_id);

ALTER TABLE public.review_feedback ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Firm members read review_feedback"
  ON public.review_feedback FOR SELECT TO authenticated
  USING ((firm_id IS NULL) OR (firm_id = public.user_firm_id(auth.uid())) OR public.has_role(auth.uid(), 'admin'::app_role));
CREATE POLICY "Firm members insert review_feedback"
  ON public.review_feedback FOR INSERT TO authenticated
  WITH CHECK ((firm_id IS NULL) OR (firm_id = public.user_firm_id(auth.uid())));

CREATE TRIGGER trg_feedback_firm BEFORE INSERT ON public.review_feedback
  FOR EACH ROW EXECUTE FUNCTION public.set_firm_id_from_user();

-- ============================================================================
-- 9. SEED DISCIPLINE NEGATIVE SPACE
-- ============================================================================
INSERT INTO public.discipline_negative_space (discipline, item_key, description, trigger_condition, fbc_section, sort_order) VALUES
-- Architectural / Egress
('architectural', 'construction_type_decl', 'Construction type declaration', NULL, 'FBC §602', 10),
('architectural', 'mixed_occupancy', 'Mixed occupancy analysis', 'mixed_occupancy = true', 'FBC §508', 20),
('architectural', 'travel_distance', 'Travel distance calculations', NULL, 'FBC §1017', 30),
('architectural', 'common_path', 'Common path of travel calculations', NULL, 'FBC §1006.2.1', 40),
('architectural', 'dead_end_corridor', 'Dead-end corridor analysis', NULL, 'FBC §1020.4', 50),
('architectural', 'mezzanine_ratio', 'Mezzanine 1/3 area ratio calculation', 'has_mezzanine = true', 'FBC §505.2', 60),
('architectural', 'accessible_route', 'Accessible route analysis from parking to entrance', NULL, 'FBC §1104', 70),
('architectural', 'stair_pressurization', 'Stair pressurization', 'is_high_rise = true', 'FBC §909', 80),
('architectural', 'horizontal_exit', 'Horizontal exit documentation', NULL, 'FBC §1026', 90),
('architectural', 'occupant_load_posting', 'Occupant load posting locations', NULL, 'FBC §1004.9', 100),

-- Structural
('structural', 'design_basis', 'Design basis statement (Vult, exposure, risk cat, SDC)', NULL, 'FBC §1603', 10),
('structural', 'geotech_ref', 'Geotechnical reference / soil bearing assumption', NULL, 'FBC §1803', 20),
('structural', 'wind_uplift_chain', 'Wind uplift analysis for roof-to-wall-to-foundation', NULL, 'FBC §1609', 30),
('structural', 'cnc_pressures', 'C&C design pressures for cladding vendor design', NULL, 'ASCE 7-16 §30', 40),
('structural', 'delegated_wind', 'Delegated design wind pressure statement', NULL, 'FBC §1603.1.4', 50),
('structural', 'flood_zone_compliance', 'Flood zone compliance', 'coastal = true', 'FBC §1612', 60),
('structural', 'special_inspection', 'Special inspection requirements per FBC §1705', NULL, 'FBC §1705', 70),

-- Energy
('energy', 'lpd_interior', 'LPD compliance documentation (interior)', NULL, 'FBC-EC C405', 10),
('energy', 'lpd_exterior', 'LPD compliance documentation (exterior)', NULL, 'FBC-EC C405.5', 20),
('energy', 'mech_compliance', 'Mechanical compliance (HVAC COP/EER/SEER schedules)', NULL, 'FBC-EC C403', 30),
('energy', 'skylight_perf', 'Skylight energy performance values', NULL, 'FBC-EC C402.4', 40),
('energy', 'ci_layer', 'CI layer placement confirmation (exterior of studs)', NULL, 'FBC-EC C402.1', 50),
('energy', 'alteration_boundary', 'Energy compliance for alterations vs. new work boundary', NULL, 'FBC-EC C503', 60),
('energy', 'economizer', 'HVAC economizer applicability analysis', NULL, 'FBC-EC C403.5', 70),

-- Accessibility
('accessibility', 'accessible_parking_count', 'Accessible parking count vs. total count', NULL, 'FBC-A 208', 10),
('accessibility', 'van_stall', 'Van-accessible stall identification', NULL, 'FBC-A 208.2.4', 20),
('accessibility', 'route_to_entrance', 'Accessible route from parking to entrance shown', NULL, 'FBC-A 206.2.1', 30),
('accessibility', 'vertical_access', 'Vertical access for multi-story (elevator compliance)', 'stories > 1', 'FBC-A 206.2.3', 40),
('accessibility', 'drinking_fountain', 'Drinking fountain hi-lo or equivalent documented', NULL, 'FBC-A 211', 50),
('accessibility', 'baby_changing', 'Baby changing station in all-gender restrooms', NULL, 'FBC-A 226', 60),
('accessibility', 'assistive_listening', 'Assistive listening in A-2 assembly spaces', 'occupancy_classification LIKE ''A-2%''', 'FBC-A 219', 70),

-- Product Approvals
('product_approvals', 'envelope_fpa_noa', 'All exterior envelope components have FPA/NOA', NULL, NULL, 10),
('product_approvals', 'fpa_current', 'FPA revision is current (not expired)', NULL, NULL, 20),
('product_approvals', 'fpa_coverage', 'FPA covers the actual span/pressure/size specified', NULL, NULL, 30),
('product_approvals', 'noa_county', 'Miami-Dade NOAs confirmed applicable to project county', NULL, NULL, 40),
('product_approvals', 'coiling_doors', 'High-speed coiling doors at all exterior openings', NULL, NULL, 50),
('product_approvals', 'impact_wbd', 'Impact resistance confirmed for WBD region', NULL, 'FBC §1609.2', 60),
('product_approvals', 'skylight_hvhz', 'Skylights rated for HVHZ if applicable', 'hvhz = true', 'FBC §2405', 70),

-- MEP
('mep', 'ventilation_schedule', 'Ventilation schedule per ASHRAE 62.1 / FBC Mech §401', NULL, 'FBC-M 401', 10),
('mep', 'auto_repair_co', 'Auto repair garage CO detection and exhaust design', NULL, 'FBC-M 502', 20),
('mep', 'spray_booth_exhaust', 'Spray booth / parts washer exhaust', NULL, 'FBC-M 510', 30),
('mep', 'ev_charging', 'EV charging NEC §625 circuit and GFEP requirements', NULL, 'NEC §625', 40),
('mep', 'emergency_lighting_circuit', 'Emergency lighting circuit source identified', NULL, 'FBC §1008.3', 50),
('mep', 'exit_sign_photometric', 'Exit sign photometric compliance', NULL, 'FBC §1013', 60),
('mep', 'plumbing_fixture_count', 'Plumbing fixture count per occupancy and use', NULL, 'FBC-P 403', 70),
('mep', 'oil_water_separator', 'Oil/water separator compliance per FBC §406.8', NULL, 'FBC-P 1003', 80),
('mep', 'grease_interceptor', 'Grease interceptor', NULL, 'FBC-P 1003.3', 90);

-- ============================================================
-- Migration: 20260421124226_6e9f0c81-1ca7-4ce1-a98a-ba6729876c6b.sql
-- ============================================================

CREATE TABLE public.deferred_scope_items (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  plan_review_id uuid NOT NULL REFERENCES public.plan_reviews(id) ON DELETE CASCADE,
  firm_id uuid,
  category text NOT NULL,
  description text NOT NULL,
  sheet_refs text[] DEFAULT '{}'::text[],
  evidence text[] DEFAULT '{}'::text[],
  required_submittal text DEFAULT '',
  responsible_party text DEFAULT '',
  confidence_score numeric,
  status text NOT NULL DEFAULT 'pending',
  reviewer_notes text DEFAULT '',
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_deferred_scope_items_plan_review ON public.deferred_scope_items(plan_review_id);
CREATE INDEX idx_deferred_scope_items_firm ON public.deferred_scope_items(firm_id);

ALTER TABLE public.deferred_scope_items ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Firm members read deferred_scope_items"
  ON public.deferred_scope_items FOR SELECT TO authenticated
  USING (firm_id IS NULL OR firm_id = public.user_firm_id(auth.uid()) OR public.has_role(auth.uid(), 'admin'::app_role));

CREATE POLICY "Firm members insert deferred_scope_items"
  ON public.deferred_scope_items FOR INSERT TO authenticated
  WITH CHECK (firm_id IS NULL OR firm_id = public.user_firm_id(auth.uid()));

CREATE POLICY "Firm members update deferred_scope_items"
  ON public.deferred_scope_items FOR UPDATE TO authenticated
  USING (firm_id IS NULL OR firm_id = public.user_firm_id(auth.uid()) OR public.has_role(auth.uid(), 'admin'::app_role));

CREATE POLICY "Firm members delete deferred_scope_items"
  ON public.deferred_scope_items FOR DELETE TO authenticated
  USING (firm_id IS NULL OR firm_id = public.user_firm_id(auth.uid()) OR public.has_role(auth.uid(), 'admin'::app_role));

CREATE TRIGGER set_deferred_scope_items_updated_at
  BEFORE UPDATE ON public.deferred_scope_items
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

-- ============================================================
-- Migration: 20260421135646_64e7bb31-6b86-411e-a89b-0c68c28dbd69.sql
-- ============================================================
ALTER TABLE public.deficiencies_v2
ADD COLUMN IF NOT EXISTS verification_status text NOT NULL DEFAULT 'unverified',
ADD COLUMN IF NOT EXISTS verification_notes text NOT NULL DEFAULT '';

CREATE INDEX IF NOT EXISTS idx_deficiencies_v2_verification_status
  ON public.deficiencies_v2 (verification_status);
-- ============================================================
-- Migration: 20260421140644_0a3fbc27-006f-4783-9467-d55e6d880c36.sql
-- ============================================================
-- Reviewer Memory: capture structured rejection reasons and convert
-- them into firm-specific patterns that prime future AI reviews.

CREATE TABLE IF NOT EXISTS public.correction_patterns (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  firm_id uuid,
  discipline text NOT NULL,
  pattern_summary text NOT NULL,            -- short, prompt-friendly summary
  original_finding text NOT NULL,
  original_required_action text NOT NULL DEFAULT '',
  code_reference jsonb DEFAULT '{}'::jsonb,
  rejection_reason text NOT NULL,           -- enum-ish, see below
  reason_notes text NOT NULL DEFAULT '',
  -- Project DNA snapshot at time of rejection (for matching)
  occupancy_classification text,
  construction_type text,
  county text,
  fbc_edition text,
  -- Aggregation
  rejection_count integer NOT NULL DEFAULT 1,
  confirm_count integer NOT NULL DEFAULT 0, -- inverse signal
  last_seen_at timestamptz NOT NULL DEFAULT now(),
  is_active boolean NOT NULL DEFAULT true,  -- reviewers can "un-learn"
  source_deficiency_id uuid,                -- first deficiency that produced it
  source_plan_review_id uuid,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_correction_patterns_firm_active
  ON public.correction_patterns (firm_id, is_active);
CREATE INDEX IF NOT EXISTS idx_correction_patterns_discipline
  ON public.correction_patterns (discipline);

ALTER TABLE public.correction_patterns ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Firm members read correction_patterns"
  ON public.correction_patterns FOR SELECT TO authenticated
  USING ((firm_id IS NULL) OR (firm_id = user_firm_id(auth.uid())) OR has_role(auth.uid(), 'admin'::app_role));

CREATE POLICY "Firm members insert correction_patterns"
  ON public.correction_patterns FOR INSERT TO authenticated
  WITH CHECK ((firm_id IS NULL) OR (firm_id = user_firm_id(auth.uid())));

CREATE POLICY "Firm members update correction_patterns"
  ON public.correction_patterns FOR UPDATE TO authenticated
  USING ((firm_id IS NULL) OR (firm_id = user_firm_id(auth.uid())) OR has_role(auth.uid(), 'admin'::app_role));

CREATE POLICY "Firm members delete correction_patterns"
  ON public.correction_patterns FOR DELETE TO authenticated
  USING ((firm_id IS NULL) OR (firm_id = user_firm_id(auth.uid())) OR has_role(auth.uid(), 'admin'::app_role));

CREATE TRIGGER update_correction_patterns_updated_at
  BEFORE UPDATE ON public.correction_patterns
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER set_correction_patterns_firm_id
  BEFORE INSERT ON public.correction_patterns
  FOR EACH ROW EXECUTE FUNCTION public.set_firm_id_from_user();

-- Track which patterns were applied to each review so reviewers can audit
CREATE TABLE IF NOT EXISTS public.applied_corrections (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  firm_id uuid,
  plan_review_id uuid NOT NULL,
  pattern_id uuid NOT NULL REFERENCES public.correction_patterns(id) ON DELETE CASCADE,
  discipline text NOT NULL,
  pattern_summary text NOT NULL,
  applied_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_applied_corrections_review
  ON public.applied_corrections (plan_review_id);

ALTER TABLE public.applied_corrections ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Firm members read applied_corrections"
  ON public.applied_corrections FOR SELECT TO authenticated
  USING ((firm_id IS NULL) OR (firm_id = user_firm_id(auth.uid())) OR has_role(auth.uid(), 'admin'::app_role));

CREATE POLICY "Firm members insert applied_corrections"
  ON public.applied_corrections FOR INSERT TO authenticated
  WITH CHECK ((firm_id IS NULL) OR (firm_id = user_firm_id(auth.uid())));

CREATE TRIGGER set_applied_corrections_firm_id
  BEFORE INSERT ON public.applied_corrections
  FOR EACH ROW EXECUTE FUNCTION public.set_firm_id_from_user();
-- ============================================================
-- Migration: 20260421145208_ccd6bbcc-a973-484d-a785-27f7c8bd2414.sql
-- ============================================================
ALTER TABLE public.plan_reviews
  ADD COLUMN IF NOT EXISTS pipeline_version text NOT NULL DEFAULT 'v1';

CREATE INDEX IF NOT EXISTS idx_plan_reviews_pipeline_version
  ON public.plan_reviews (pipeline_version);

COMMENT ON COLUMN public.plan_reviews.pipeline_version IS
  'v1 = legacy ai_findings JSONB on this row; v2 = deficiencies_v2 table is the source of truth for this review.';
-- ============================================================
-- Migration: 20260421191223_8639bdcf-497b-4d99-9c04-2d73f622950c.sql
-- ============================================================
-- Canonical FBC code sections: source of truth for citation verification.
CREATE TABLE public.fbc_code_sections (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  edition text NOT NULL DEFAULT '8th',
  code text NOT NULL DEFAULT 'FBC',
  section text NOT NULL,
  title text NOT NULL,
  requirement_text text NOT NULL,
  keywords text[] NOT NULL DEFAULT '{}',
  source_url text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

-- Lookups are always (code, section, edition); make that fast and unique.
CREATE UNIQUE INDEX fbc_code_sections_canonical_idx
  ON public.fbc_code_sections (code, section, edition);

-- Section-only lookup is also common (when the AI omits the edition).
CREATE INDEX fbc_code_sections_section_idx
  ON public.fbc_code_sections (section);

ALTER TABLE public.fbc_code_sections ENABLE ROW LEVEL SECURITY;

CREATE POLICY "All authenticated read fbc_code_sections"
  ON public.fbc_code_sections FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Admins insert fbc_code_sections"
  ON public.fbc_code_sections FOR INSERT
  TO authenticated
  WITH CHECK (public.has_role(auth.uid(), 'admin'::app_role));

CREATE POLICY "Admins update fbc_code_sections"
  ON public.fbc_code_sections FOR UPDATE
  TO authenticated
  USING (public.has_role(auth.uid(), 'admin'::app_role));

CREATE POLICY "Admins delete fbc_code_sections"
  ON public.fbc_code_sections FOR DELETE
  TO authenticated
  USING (public.has_role(auth.uid(), 'admin'::app_role));

CREATE TRIGGER fbc_code_sections_updated_at
  BEFORE UPDATE ON public.fbc_code_sections
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

-- Citation verification fields on deficiencies_v2.
ALTER TABLE public.deficiencies_v2
  ADD COLUMN citation_status text NOT NULL DEFAULT 'unverified',
  ADD COLUMN citation_match_score numeric,
  ADD COLUMN citation_canonical_text text,
  ADD COLUMN citation_grounded_at timestamptz;

-- Cheap lookup for the dashboard "show me the unverifiable findings" view.
CREATE INDEX deficiencies_v2_citation_status_idx
  ON public.deficiencies_v2 (plan_review_id, citation_status);

-- ============================================================
-- Migration: 20260422122406_2b44a3cd-4b6c-42b8-b34c-92e5f171eae4.sql
-- ============================================================
ALTER TABLE public.deficiencies_v2
  ADD COLUMN IF NOT EXISTS evidence_crop_url text,
  ADD COLUMN IF NOT EXISTS evidence_crop_meta jsonb NOT NULL DEFAULT '{}'::jsonb;

COMMENT ON COLUMN public.deficiencies_v2.evidence_crop_url IS
  'Optional URL to a cropped PNG of the source PDF region for this finding, used to embed visual evidence in comment letters.';
COMMENT ON COLUMN public.deficiencies_v2.evidence_crop_meta IS
  'Metadata for the evidence crop: { sheet_ref, page_index, evidence_text, bbox: {x,y,w,h}, generated_at }.';
-- ============================================================
-- Migration: 20260422125751_31c71689-3eb7-4edb-9341-36279bd7fc17.sql
-- ============================================================
-- Enable realtime streaming for deficiencies_v2 + deferred_scope_items
ALTER TABLE public.deficiencies_v2 REPLICA IDENTITY FULL;
ALTER TABLE public.deferred_scope_items REPLICA IDENTITY FULL;

DO $$
BEGIN
  BEGIN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.deficiencies_v2;
  EXCEPTION WHEN duplicate_object THEN
    NULL;
  END;

  BEGIN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.deferred_scope_items;
  EXCEPTION WHEN duplicate_object THEN
    NULL;
  END;
END $$;
-- ============================================================
-- Migration: 20260422130139_f255273a-636b-4dbf-a106-9f7633c72ad6.sql
-- ============================================================
-- Step 1: flip all remaining v1 reviews to v2 (backfill of findings already done via insert tool).
UPDATE public.plan_reviews
SET pipeline_version = 'v2', updated_at = now()
WHERE pipeline_version = 'v1';

-- Step 2: drop the column entirely — the schema now reflects "only v2 exists".
ALTER TABLE public.plan_reviews DROP COLUMN pipeline_version;
-- ============================================================
-- Migration: 20260422130456_cd770783-ec4f-430a-b806-cb8a7b6f45c2.sql
-- ============================================================
ALTER TABLE public.plan_reviews
  ADD COLUMN IF NOT EXISTS pipeline_version text NOT NULL DEFAULT 'v2';
-- ============================================================
-- Migration: 20260422132034_6daeb827-486a-447c-8673-36447b7b555c.sql
-- ============================================================
-- Drop the legacy v1 ai_findings JSONB column from plan_reviews.
-- All readers now use deficiencies_v2 (the v2 pipeline source of truth).
ALTER TABLE public.plan_reviews DROP COLUMN IF EXISTS ai_findings;
-- ============================================================
-- Migration: 20260426000001_firm_scoped_storage_rls.sql
-- ============================================================
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

