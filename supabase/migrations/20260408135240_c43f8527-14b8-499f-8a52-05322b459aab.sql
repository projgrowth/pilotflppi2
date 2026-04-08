
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
