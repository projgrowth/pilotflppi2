-- =============================================================================
-- Pipeline quality fixes
--
-- 1. Fix discipline_negative_space case mismatch (was lowercase, pipeline
--    queries TitleCase — checklist was never loading).
-- 2. Add missing Civil, Landscape, Life Safety negative-space entries.
-- 3. Seed fbc_code_sections with the ~60 most-cited FBC sections so citation
--    grounding returns "verified"/"mismatch" instead of "not_found" for every
--    finding.
-- =============================================================================

-- ---------------------------------------------------------------------------
-- 1. Upcase discipline names so they match the DISCIPLINES constant
--    ['Architectural', 'Structural', 'Energy', 'Accessibility',
--     'Product Approvals', 'MEP', 'Life Safety', 'Civil', 'Landscape']
-- ---------------------------------------------------------------------------
UPDATE public.discipline_negative_space
SET discipline = initcap(discipline)
WHERE discipline != initcap(discipline);

-- Also fix multi-word disciplines that initcap gets wrong
UPDATE public.discipline_negative_space SET discipline = 'Product Approvals' WHERE discipline = 'Product_approvals' OR discipline = 'Product approvals';
UPDATE public.discipline_negative_space SET discipline = 'Life Safety'       WHERE discipline = 'Life_safety'       OR discipline = 'Life safety';
-- initcap('mep') = 'Mep' but pipeline constant is 'MEP' — fix explicitly
UPDATE public.discipline_negative_space SET discipline = 'MEP'               WHERE lower(discipline) = 'mep' AND discipline != 'MEP';

-- ---------------------------------------------------------------------------
-- 2. Civil discipline checklist
-- ---------------------------------------------------------------------------
INSERT INTO public.discipline_negative_space (discipline, item_key, description, trigger_condition, fbc_section, sort_order) VALUES
('Civil', 'stormwater_treatment',   'Stormwater quality/quantity treatment volume calculated and system sized', NULL, 'FBC §1612', 10),
('Civil', 'npdes_esc',              'NPDES erosion and sediment control plan present (silt fence, inlet protection, stabilized entrance)', NULL, 'NPDES CGP', 20),
('Civil', 'backflow_preventer',     'RPZ or DCVA backflow preventer shown at building water service tap', NULL, 'FBC-P 608', 30),
('Civil', 'accessible_route_slope', 'Accessible site route from parking to entrance: slopes ≤ 1:20, ramps ≤ 1:12 with landings', NULL, 'FAC 206.2.1', 40),
('Civil', 'drainage_outfall',       'Stormwater outfall to legal conveyance shown (pond, swale, pipe, exfiltration)', NULL, NULL, 50),
('Civil', 'pavement_section',       'Pavement section detail with subgrade, base, and surface course thicknesses', NULL, NULL, 60),
('Civil', 'utility_connections',    'Water service tap, sanitary sewer connection, fire service (if separate) shown', NULL, NULL, 70),
('Civil', 'fdot_driveway',          'FDOT driveway connection permit referenced for state road access', 'jurisdiction LIKE ''%FDOT%''', NULL, 80),
('Civil', 'wmd_erp',                'Water Management District ERP permit number referenced', NULL, NULL, 90)
ON CONFLICT (discipline, item_key) DO NOTHING;

-- ---------------------------------------------------------------------------
-- 3. Landscape discipline checklist
-- ---------------------------------------------------------------------------
INSERT INTO public.discipline_negative_space (discipline, item_key, description, trigger_condition, fbc_section, sort_order) VALUES
('Landscape', 'plant_schedule',        'Plant schedule lists species, quantity, install size (caliper/height), spacing', NULL, NULL, 10),
('Landscape', 'invasive_species',      'No FLEPPC Category I invasive plants (Brazilian pepper, melaleuca, air potato, etc.) in schedule', NULL, 'FS 369.25', 20),
('Landscape', 'rain_sensor',           'Irrigation rain sensor or weather-based controller specified (required on all new automatic systems)', NULL, 'FS 373.62', 30),
('Landscape', 'parking_interior_trees','Parking lot interior trees meet jurisdiction ratio (typically 1 per 10 spaces)', NULL, NULL, 40),
('Landscape', 'buffer_opacity',        'Buffer/screening between incompatible uses meets height and opacity per local ordinance', NULL, NULL, 50),
('Landscape', 'tree_protection',       'Tree protection detail shows fence at dripline (not trunk) for preserved trees', NULL, NULL, 60),
('Landscape', 'sight_triangle',        'Sight-triangle at driveway/intersection clear of shrubs > 36 in. height', NULL, NULL, 70),
('Landscape', 'irrigation_backflow',   'Irrigation backflow preventer (RPZ or PVB) shown at tap', NULL, NULL, 80),
('Landscape', 'turf_limitation',       'Turf grass limited to functional areas per Florida-Friendly guidelines', NULL, 'FS 373.185', 90)
ON CONFLICT (discipline, item_key) DO NOTHING;

-- ---------------------------------------------------------------------------
-- 4. Life Safety discipline checklist
-- ---------------------------------------------------------------------------
INSERT INTO public.discipline_negative_space (discipline, item_key, description, trigger_condition, fbc_section, sort_order) VALUES
('Life Safety', 'exit_count',           'Exit count meets minimum for occupant load (≥2 exits when OL > 49, or common path limits apply)', NULL, 'FBC §1006', 10),
('Life Safety', 'corridor_width',       'Corridor width ≥ 44 in. where serving 30+ occupants; ≥ 36 in. for residential', NULL, 'FBC §1020.2', 20),
('Life Safety', 'exit_separation',      'Exits separated by ≥ 1/3 of diagonal (sprinklered) or ≥ 1/2 (non-sprinklered)', NULL, 'FBC §1007.1', 30),
('Life Safety', 'rated_corridor',       'Fire-rated corridors (1-hour) shown with rated opening protectives where required', NULL, 'FBC §1020.1', 40),
('Life Safety', 'emergency_lighting',   'Emergency egress lighting shown on emergency circuit or battery backup', NULL, 'FBC §1008.3', 50),
('Life Safety', 'exit_signs',           'Exit signs shown at all required exit doors and in corridors', NULL, 'FBC §1013', 60),
('Life Safety', 'sprinkler_riser',      'Sprinkler riser diagram present with area calculation and hydraulic reference', NULL, 'FBC §903', 70),
('Life Safety', 'panic_hardware',       'Panic hardware shown on doors serving assembly OL > 50', NULL, 'FBC §1010.1.10', 80),
('Life Safety', 'exit_discharge',       'Exit discharge route leads directly to public way (not through back-of-house)', NULL, 'FBC §1028', 90),
('Life Safety', 'fdc_location',         'Fire department connection (FDC) location shown on site plan', NULL, 'NFPA 13', 100),
('Life Safety', 'smoke_compartments',   'Smoke compartment separations shown for healthcare (I-2) and high-rise occupancies', 'is_high_rise = true', 'FBC §407', 110),
('Life Safety', 'stair_enclosure',      'Interior exit stairs enclosed in rated shaft (2-hr if 4+ stories)', NULL, 'FBC §1023.2', 120)
ON CONFLICT (discipline, item_key) DO NOTHING;

-- ---------------------------------------------------------------------------
-- 5. Seed fbc_code_sections with the ~60 most-cited sections
--    Source: FBC 7th Edition (2023) — titles and requirement text are
--    paraphrased summaries of the actual section language for token efficiency.
-- ---------------------------------------------------------------------------
INSERT INTO public.fbc_code_sections (code, section, edition, title, requirement_text) VALUES

-- ── Means of Egress (Ch. 10) ──────────────────────────────────────────────
('FBC', '1004.1',   '7th', 'Design Occupant Load',
 'The occupant load used for means of egress design shall be determined by the floor area and occupant load factor per Table 1004.1.2, or the actual number of occupants where greater.'),

('FBC', '1004.9',   '7th', 'Posting of Occupant Load',
 'Every room or space that is an assembly occupancy or has an occupant load of 50 or more shall have the occupant load of the room or space posted in a conspicuous place near the main exit.'),

('FBC', '1005.1',   '7th', 'Minimum Required Egress Width',
 'The minimum width or required capacity of components of the means of egress shall be determined in accordance with the occupant load served and the width per-occupant factor. Stair width: 0.3 in/occupant; level egress: 0.2 in/occupant.'),

('FBC', '1006.2',   '7th', 'Single Exit',
 'Only one exit or exit access doorway is required from spaces or stories where the occupant load, common path of travel, and travel distance do not exceed the limits in Table 1006.2.1 or 1006.3.4.'),

('FBC', '1006.2.1', '7th', 'Single Exit — Space/Story Limits',
 'Single exit is allowed only when occupant loads and common path of travel distances are within the limits of Table 1006.2.1, based on occupancy group and sprinkler status.'),

('FBC', '1007.1',   '7th', 'Exit and Exit Access Doorway Configuration',
 'Required exits and exit access doorways shall be positioned so that the path of egress travel is not more than one-half of the overall diagonal dimension of the area served where the space is not sprinklered, and one-third where sprinklered.'),

('FBC', '1008.3',   '7th', 'Emergency Power for Illumination',
 'The means of egress illumination shall be connected to an emergency power system as provided in Section 2702 where the system is interrupted.'),

('FBC', '1013.1',   '7th', 'Where Required — Exit Signs',
 'Exits and exit access doors shall be marked by an approved exit sign readily visible from any direction of egress travel.'),

('FBC', '1017.1',   '7th', 'Exit Access Travel Distance',
 'Exits shall be so located on each story that the maximum length of exit access travel, measured from the most remote point within a story to the entrance to an exit along the natural and unobstructed path of egress travel, does not exceed the distances given in Table 1017.1.'),

('FBC', '1020.1',   '7th', 'Construction — Corridors',
 'Corridors shall be fire-resistance rated in accordance with Table 1020.1. The corridor walls shall be constructed as fire partitions in accordance with Section 708.'),

('FBC', '1020.2',   '7th', 'Width — Corridors',
 'The minimum width of a corridor shall be not less than that determined per Section 1005.1 or the values in Table 1020.2, but not less than 44 inches, except 36 inches for corridors serving an occupant load of 50 or fewer.'),

('FBC', '1020.4',   '7th', 'Dead Ends',
 'Where more than one exit or exit access doorway is required, the exit access shall be arranged such that there are no dead ends in corridors more than 20 feet (6096 mm) in length where the corridor is not sprinklered, or 50 feet (15 240 mm) in length where the corridor is sprinklered.'),

('FBC', '1023.2',   '7th', 'Enclosures — Interior Exit Stairways',
 'Interior exit stairways and interior exit ramps shall be enclosed with fire barriers constructed in accordance with Section 707. Enclosure shall have a fire-resistance rating of not less than 2 hours where connecting four stories or more, and not less than 1 hour where connecting less than four stories.'),

('FBC', '1026.1',   '7th', 'Horizontal Exits',
 'Horizontal exits shall comply with the requirements of this section and Sections 1007 through 1022.'),

('FBC', '1028.1',   '7th', 'Exit Discharge',
 'Exits shall discharge directly to the exterior of the building. The exit discharge shall provide a direct, unobstructed accessible path of egress travel to a public way.'),

('FBC', '1010.1',   '7th', 'Doors — General',
 'Egress doors shall be readily openable from the egress side without the use of a key or special knowledge or effort.'),

('FBC', '1010.1.10','7th', 'Panic and Fire Exit Hardware',
 'Rooms or spaces with an occupant load of more than 50 persons and in Group A or E occupancies, doors in the means of egress shall not be provided with a latch or lock unless it is panic hardware.'),

-- ── Fire Protection (Ch. 9) ────────────────────────────────────────────────
('FBC', '903.2',    '7th', 'Where Required — Automatic Sprinkler Systems',
 'Approved automatic sprinkler systems in new buildings and structures shall be provided in the locations described in Sections 903.2.1 through 903.2.12.'),

('FBC', '903.3.1.1','7th', 'NFPA 13 Sprinkler Systems',
 'Where the provisions of this code require that a building or portion thereof be equipped throughout with an automatic sprinkler system in accordance with this section, sprinklers shall be installed throughout in accordance with NFPA 13.'),

('FBC', '905.3',    '7th', 'Where Required — Standpipe Systems',
 'Standpipe systems shall be provided in new buildings and structures in accordance with this section.'),

('FBC', '907.2',    '7th', 'Where Required — Fire Alarm and Detection Systems',
 'An approved fire alarm system installed in accordance with the provisions of this code and NFPA 72 shall be provided in new buildings and structures in the locations specified in Sections 907.2.1 through 907.2.24.'),

-- ── Fire Resistance (Ch. 7) ────────────────────────────────────────────────
('FBC', '706.1',    '7th', 'Fire Walls',
 'Fire walls shall comply with this section. Where fire walls are used to allow unlimited area buildings or to separate portions of a building for the purpose of using different construction types, the fire walls shall be constructed in accordance with NFPA 221.'),

('FBC', '708.1',    '7th', 'Fire Partitions',
 'The following wall assemblies shall comply with this section: walls separating dwelling units, walls separating sleeping units, corridor walls, and elevator lobby walls.'),

-- ── Occupancy (Ch. 3 / 5 / 6) ─────────────────────────────────────────────
('FBC', '508.1',    '7th', 'Mixed Occupancies',
 'Each portion of a building shall be individually classified in accordance with Section 302.1. Where a building contains more than one occupancy group, the building or portion thereof shall comply with the applicable provisions of Section 508.2, 508.3, or 508.4.'),

('FBC', '505.2',    '7th', 'Mezzanines — Area Limitation',
 'The aggregate area of a mezzanine or mezzanines within a room shall be not greater than one-third of the floor area of that room.'),

('FBC', '403.1',    '7th', 'High-Rise Buildings',
 'The provisions of Sections 403.1 through 403.6 shall apply to buildings with an occupied floor located more than 75 feet above the lowest level of fire department vehicle access.'),

-- ── Structural (Ch. 16) ────────────────────────────────────────────────────
('FBC', '1603.1',   '7th', 'Required Information on Construction Documents',
 'Construction documents shall show the size, section and relative locations of structural members with floor levels, column centers and offsets dimensioned. Design loads and other information pertinent to the structural design required by Sections 1603.1.1 through 1603.1.9 shall be indicated on the construction documents.'),

('FBC', '1604.3',   '7th', 'Serviceability',
 'Structural systems and members thereof shall be designed to have adequate stiffness to limit deflections, lateral drift, vibration, or any other deformations that adversely affect the intended use and performance of buildings and other structures.'),

('FBC', '1609.1',   '7th', 'Applications — Wind Loads',
 'Buildings, structures and parts thereof shall be designed to withstand the minimum wind loads prescribed herein. Decreases in wind loads shall not be made for the effect of shielding by other structures.'),

('FBC', '1609.3',   '7th', 'Basic Wind Speed',
 'The basic wind speed, V, used in the determination of design wind loads for buildings and other structures shall be determined from Figures 1609.3(1) through 1609.3(8).'),

('FBC', '1612.1',   '7th', 'Construction in Flood Hazard Areas',
 'Buildings and structures constructed in whole or in part in flood hazard areas, including A or V Zones as established in Table 1612.3, shall be designed and constructed in accordance with ASCE 24.'),

('FBC', '1705.1',   '7th', 'Special Inspections Required',
 'The building official is authorized to require special inspections and structural tests for any construction work covered by this code. The special inspector shall be a qualified person who shall demonstrate competence, to the satisfaction of the building official, for inspection of the particular type of construction or operation requiring special inspection.'),

('FBC', '1803.1',   '7th', 'General — Geotechnical Investigations',
 'Geotechnical investigations shall be conducted and reports prepared by a registered design professional.'),

-- ── Accessibility (Ch. 11) ────────────────────────────────────────────────
('FBC', '1104.1',   '7th', 'Accessible Route — Where Required',
 'Accessible routes within a site shall be provided from public transportation stops, accessible parking spaces, accessible passenger loading zones, and public streets or sidewalks to the accessible building entrance.'),

-- Florida Accessibility Code (FAC) — FBC adopts by reference
('FAC', '206.2.3',  '7th', 'Multi-Story Buildings — Elevator Requirement',
 'In Florida, an accessible route connecting each story is required in buildings with three or more stories OR in buildings where a story has 3,000 or more square feet. This is more stringent than the federal ADA standard.'),

('FAC', '208.2',    '7th', 'Parking — Minimum Number',
 'Parking spaces complying with the accessible parking requirements shall be provided in accordance with Table 208.2, based on the total number of parking spaces provided in the parking facility.'),

('FAC', '604.3',    '7th', 'Water Closet — Clearance',
 'Clearance around a water closet shall be 60 inches minimum measured perpendicular from the side wall and 56 inches minimum measured perpendicular from the rear wall.'),

('FAC', '404.2.4',  '7th', 'Doors — Maneuvering Clearances',
 'Minimum maneuvering clearances at doors and gates shall comply with Table 404.2.4.1. Required maneuvering clearances shall be free of protrusions from the floor to a height of 34 inches minimum above the floor.'),

-- ── Energy (FBC-Energy / FBC-EC) ──────────────────────────────────────────
('FBC-EC', 'C402.1', '7th', 'Building Envelope — Opaque Element Insulation',
 'Opaque elements of the building thermal envelope shall comply with the requirements of Section C402.1.2, C402.1.3, or C402.1.4 based on climate zone.'),

('FBC-EC', 'C402.4', '7th', 'Fenestration — Maximum Area and Performance',
 'The vertical fenestration area of each space-conditioning zone shall not exceed the maximum prescribed. Fenestration U-factor and SHGC shall comply with Table C402.4.'),

('FBC-EC', 'C403.1', '7th', 'Mechanical Systems — General',
 'Mechanical systems and equipment shall comply with the requirements of Section C403.'),

('FBC-EC', 'C403.5', '7th', 'Economizers — HVAC',
 'Each cooling system serving a single zone shall be equipped with economizer capability unless it meets one of the exceptions in Section C403.5.'),

('FBC-EC', 'C405.2', '7th', 'Interior Lighting — Automatic Controls',
 'Interior lighting systems shall comply with this section. Occupancy sensors shall be provided in spaces specified in Section C405.2.1.'),

('FBC-EC', 'C405.3', '7th', 'Interior Lighting Power',
 'Interior lighting power installed in a building shall comply with the building area method of Table C405.3.2(1) or the space-by-space method of Table C405.3.2(2).'),

-- ── MEP — Mechanical (FBC-M) ──────────────────────────────────────────────
('FBC-M', '401.1',  '7th', 'Ventilation — General',
 'Mechanical ventilation shall be provided in buildings in accordance with this chapter. Occupied spaces shall be ventilated by natural or mechanical means.'),

('FBC-M', '403.3',  '7th', 'Outdoor Air Rate',
 'Outdoor air ventilation rates shall comply with ASHRAE 62.1 or the values in Table 403.3.1.1, whichever is greater.'),

('FBC-M', '502.1',  '7th', 'Auto Repair Facilities — Exhaust Systems',
 'Mechanical exhaust systems for enclosed parking garages and auto repair facilities shall comply with this section.'),

-- ── MEP — Plumbing (FBC-P) ───────────────────────────────────────────────
('FBC-P', '403.1',  '7th', 'Minimum Plumbing Facilities',
 'Plumbing fixtures shall be provided for the type of occupancy and in the minimum number shown in Table 403.1.'),

('FBC-P', '608.1',  '7th', 'Backflow Prevention — General',
 'A potable water supply system shall be designed, installed, and maintained in such a manner so as to prevent contamination from nonpotable liquids, solids, or gases being introduced into the potable water supply through cross-connections or any other piping connections to the system.'),

('FBC-P', '1003.1', '7th', 'Interceptors and Separators — General',
 'Interceptors and separators shall be provided to prevent the discharge of oil, grease, sand, and other substances harmful or hazardous to the building drainage system, the public sewer, or sewage treatment plant or processes.'),

-- ── Product Approvals (Rule 61G20) ────────────────────────────────────────
('FBC', '1609.2',   '7th', 'Protection of Openings — Wind-Borne Debris',
 'In wind-borne debris regions, glazing in buildings shall be protected from wind-borne debris. Glazing protection shall comply with ASTM E1886, ASTM E1996, or other approved test method per Table 1609.1.2.'),

('FBC', '2405.5',   '7th', 'Skylights — Safety Glazing',
 'Skylights shall comply with the requirements of Chapter 24 and shall be tested in accordance with ASTM E331 and ASTM E547. In High-Velocity Hurricane Zones, skylights shall additionally comply with the requirements of this section.'),

-- ── Special Inspections ───────────────────────────────────────────────────
('FBC', '1704.1',   '7th', 'Special Inspections — Statement of Special Inspections',
 'Where special inspection or testing is required by Table 1705.2, 1705.3, 1705.4, 1705.5 or 1705.12, or otherwise required by the building official, the registered design professional in responsible charge shall prepare a statement of special inspections in accordance with Section 1704.3.'),

('FBC', '1705.2',   '7th', 'Special Inspections — Steel',
 'Special inspections for structural steel shall be performed in accordance with AISC 360, Chapter N.'),

('FBC', '1705.3',   '7th', 'Special Inspections — Concrete',
 'Special inspections and tests of concrete construction shall comply with the requirements of ACI 318.'),

('FBC', '1705.12',  '7th', 'Special Inspections — Wind Resistance',
 'Special inspections for wind resistance shall be provided for main windforce-resisting systems, cladding and exterior components.')

ON CONFLICT (code, section, edition) DO NOTHING;
