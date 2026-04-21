
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
