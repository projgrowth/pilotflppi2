
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
