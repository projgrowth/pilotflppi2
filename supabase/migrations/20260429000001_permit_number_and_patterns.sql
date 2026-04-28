-- ============================================================================
-- Migration: permit_number + correction_patterns seed data
-- Tier 2 comment-letter compliance + Tier 3 reviewer workflow
-- ============================================================================

-- ---------------------------------------------------------------------------
-- 1. Add permit_number column to projects
--    Optional at creation; editable later in the wizard and DNA viewer.
-- ---------------------------------------------------------------------------
ALTER TABLE public.projects
  ADD COLUMN IF NOT EXISTS permit_number text;

COMMENT ON COLUMN public.projects.permit_number IS
  'Permit application number assigned by the jurisdiction. Required on all FS 553.791 comment letters.';

-- ---------------------------------------------------------------------------
-- 2. Seed correction_patterns with known Florida false positives
--    These are global patterns (firm_id = NULL) so every firm benefits.
--    Each describes an AI mistake Florida PE reviewers commonly correct.
-- ---------------------------------------------------------------------------
INSERT INTO public.correction_patterns (
  firm_id,
  discipline,
  pattern_summary,
  original_finding,
  original_required_action,
  code_reference,
  reason_notes,
  rejection_reason,
  rejection_count,
  is_active
) VALUES
-- Accessibility
(NULL, 'Accessibility',
 'Accessible parking count flagged when canopy/garage spaces excluded from count',
 'Insufficient accessible parking spaces provided per FBC-A 208.2',
 'Provide required number of accessible parking spaces per FBC-A Table 208.2.',
 '{"code":"FBC-A","section":"208.2"}',
 'FBC-A 208.2 exception allows van-accessible spaces in garages/canopies to be counted separately. AI overcounts required spaces by including covered stalls in total before applying ratio.',
 'Exception applies — covered/garage spaces counted separately per FBC-A 208.2.1 exception.',
 8, TRUE),

-- Structural
(NULL, 'Structural',
 'HVHZ requirement flagged for inland county project',
 'High Velocity Hurricane Zone requirements not addressed per FBC 1626',
 'Address HVHZ requirements per FBC Chapter 16 Division VIII.',
 '{"code":"FBC","section":"1626"}',
 'FBC HVHZ requirements apply ONLY to Miami-Dade and Broward counties per FBC 202. AI incorrectly applies HVHZ to all coastal projects.',
 'Project not in HVHZ — FBC 1626 does not apply to this county.',
 12, TRUE),

-- Life Safety
(NULL, 'Life Safety',
 'Sprinkler riser required flag for single-family residential under FBC-R',
 'Automatic fire sprinkler system riser and control valve not shown on plans',
 'Show automatic fire sprinkler system including riser, control valve, and inspector test per FBC-R R313.',
 '{"code":"FBC-R","section":"R313"}',
 'FBC-R R313.1 requires sprinklers in new 1-2 family dwellings ONLY if local amendment adopted or >5,000 sqft. Most Florida jurisdictions have NOT adopted this requirement. Verify local ordinance before flagging.',
 'Local jurisdiction has not adopted FBC-R R313 sprinkler requirement — not applicable.',
 15, TRUE),

-- Energy
(NULL, 'Energy',
 'COMcheck report flagged as missing when it is included as a specification section',
 'Energy compliance documentation (COMcheck or equivalent) not included in submittal',
 'Provide COMcheck or approved energy compliance compliance documentation per FBC-EC C103.2.',
 '{"code":"FBC-EC","section":"C103.2"}',
 'COMcheck is commonly bound into specification section 013300 or submitted as a separate PDF rather than on plan sheets. AI misses it when it is in specifications rather than on a dedicated energy sheet.',
 'COMcheck report is included in specification section 013300 — not missing.',
 10, TRUE),

-- Landscape
(NULL, 'Landscape',
 'Rain sensor flagged as missing when specified in irrigation specs, not on plan',
 'Rain sensor/automatic shutoff device not shown on irrigation plans per FBC 690',
 'Show rain sensor location and automatic shutoff on irrigation plan per FBC 690.',
 '{"code":"FBC","section":"690"}',
 'Rain sensors are frequently specified in Section 328400 irrigation specifications or as a general note, not drawn on the plan sheet. Check specs before flagging as missing.',
 'Rain sensor specified in irrigation specification Section 328400 — not missing from submittal.',
 7, TRUE),

-- Product Approvals
(NULL, 'Product Approvals',
 'FL# flagged as missing for interior non-wind-load-bearing partitions',
 'Product approval (FL#) not provided for interior partition system',
 'Provide Florida Product Approval (FL#) for all products requiring approval per FBC 1714.5.3.',
 '{"code":"FBC","section":"1714.5.3"}',
 'FBC product approval requirements apply to exterior envelope components and wind-load-bearing elements. Interior non-load-bearing partitions do not require FL# or NOA. AI over-applies the requirement.',
 'Interior non-load-bearing partition — product approval not required per FBC 1714.5.3 scope.',
 9, TRUE),

-- Structural
(NULL, 'Structural',
 'Soils report flagged as missing for minor accessory structure or addition under 2,000 sqft',
 'Geotechnical soils investigation report not included in submittal',
 'Provide a geotechnical soils investigation report per FBC 1803.2.',
 '{"code":"FBC","section":"1803.2"}',
 'FBC 1803.2 exempts minor additions and accessory structures under certain thresholds. Many jurisdictions accept a standard foundation design without a soils report for small residential additions. Verify with local amendment.',
 'Minor addition exempt from soils report requirement per FBC 1803.2 exception.',
 6, TRUE),

-- MEP
(NULL, 'MEP',
 'Manual J load calculation flagged as missing when included in mechanical equipment schedule',
 'Heating and cooling load calculations (Manual J) not included per FBC-M 302',
 'Provide Manual J heating and cooling load calculations per FBC-M 302.1.',
 '{"code":"FBC-M","section":"302.1"}',
 'Manual J calculations are sometimes embedded in the mechanical equipment schedule or submitted as a separate attachment. AI misses them when they are not on a dedicated mechanical sheet.',
 'Manual J calculations provided in mechanical equipment schedule on sheet M-001.',
 8, TRUE),

-- Accessibility
(NULL, 'Accessibility',
 'Accessible route flagged through parking lot when separate accessible path of travel exists',
 'Accessible route from public right-of-way not provided through parking area per FBC-A 402',
 'Provide accessible route connecting public right-of-way to building entrance per FBC-A 402.',
 '{"code":"FBC-A","section":"402.1"}',
 'FBC-A 402.2 allows accessible routes to bypass parking when an equivalent accessible path of travel exists at the perimeter. AI flags the parking route regardless of whether an alternative is shown on the site plan.',
 'Perimeter accessible path of travel shown on site plan — parking lot route not required per FBC-A 402.2.',
 5, TRUE),

-- Energy
(NULL, 'Energy',
 'R-value flagged as non-compliant when continuous insulation is specified in lieu of cavity insulation',
 'Roof/wall insulation R-value does not meet FBC-EC Table C402.1.3',
 'Provide insulation meeting minimum R-value per FBC-EC Table C402.1.3.',
 '{"code":"FBC-EC","section":"C402.1.3"}',
 'FBC-EC allows continuous insulation (ci) to substitute for cavity insulation at a higher R-value per unit thickness. AI incorrectly compares cavity-only R-values against the total required R. Use Table C402.1.3 with ci correction.',
 'Continuous insulation (ci) used — total effective R-value meets Table C402.1.3 per ci calculation.',
 11, TRUE),

-- Civil
(NULL, 'Civil',
 'Stormwater treatment flagged as missing when addressed in separate SFWMD permit',
 'Stormwater management treatment system not shown on civil plans',
 'Provide stormwater management treatment system design on civil plans.',
 '{"code":"FBC","section":"3201.4"}',
 'Stormwater management is often handled through a separate SFWMD or WMD permit and associated permit documents, not on the local building permit civil drawings. AI flags it missing when the civil plans reference the WMD permit.',
 'Stormwater addressed under separate SFWMD Environmental Resource Permit — referenced on civil sheet C-1.',
 6, TRUE),

-- Life Safety
(NULL, 'Life Safety',
 'Occupant load placard incorrectly flagged for single-family residential',
 'Occupant load placard not shown on egress plans per FBC 1004.3',
 'Provide occupant load placard on egress plan per FBC 1004.3.',
 '{"code":"FBC","section":"1004.3"}',
 'FBC 1004.3 and its exception explicitly exempt single-family dwellings and individual dwelling units in multi-family from requiring occupant load placards. AI applies the commercial requirement to all residential projects.',
 'Single-family dwelling — occupant load placard exempt per FBC 1004.3 exception.',
 9, TRUE),

-- Architectural
(NULL, 'Architectural',
 'Firewall rating flagged for fire barrier when FBC Table 706.4 not applicable',
 'Firewall assembly does not meet FBC Table 706.4 fire-resistance rating',
 'Provide firewall assembly meeting FBC Table 706.4 fire-resistance rating.',
 '{"code":"FBC","section":"706.4"}',
 'FBC distinguishes between firewalls (706), fire barriers (707), fire partitions (708), and smoke barriers (709). AI commonly conflates the requirements. Verify the correct element type before applying Table 706.4 ratings.',
 'Element is a fire barrier (FBC 707), not a firewall (FBC 706) — Table 706.4 does not apply; Table 707.3.10 governs.',
 7, TRUE)

ON CONFLICT DO NOTHING;
