
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
