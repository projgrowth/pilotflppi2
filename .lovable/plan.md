

# Site Plan Completeness & Missing Information Detection

## Problem

Building officials reject submittals when required information is missing from plans — not just code violations. The current system finds code compliance issues but doesn't systematically verify that all required plan sheet content, notes, details, and site plan elements are present. A building official will reject a package outright if the site plan is missing a drainage plan, or if there's no survey, or if required notes are absent.

## Solution

Add two new capabilities:

### 1. Site Plan Completeness Checklist (new component)

A comprehensive "Plan Completeness" panel in the review workspace that checks whether required elements exist on the plans. This covers what building officials look for before they even start a code review:

**Site Plan Required Elements:**
- Legal description and survey data
- Property boundaries with dimensions
- Setback lines shown and dimensioned
- Existing/proposed structures with distances to property lines
- Parking layout with ADA spaces, counts, and dimensions
- Driveway locations and sight triangles
- Stormwater/drainage plan or reference
- Utility connections (water, sewer, electric)
- Easements and right-of-way lines
- Tree survey / landscape plan (if required)
- Flood zone designation and BFE (if applicable)
- CCCL line (if coastal)
- Trash enclosure location
- Fire department access and hydrant locations

**General Plan Completeness:**
- Title block complete (project name, address, architect/engineer, seal, date)
- Index of drawings
- Code summary table (occupancy, construction type, area, height, sprinkler)
- Life safety plan (exit paths, occupant loads, exit widths)
- Structural notes (design loads, wind speed, exposure category)
- Energy compliance form (Res: Form 402 or ComCheck, Comm: COMcheck)
- Product approval numbers on specs (NOA/FL#)
- Threshold building designation (if >3 stories or >50ft or >5000sqft per floor)
- Special inspector requirements noted
- FBC edition stated on plans

### 2. Enhanced AI Prompt for Missing Information Detection

Update the AI review prompts to explicitly look for **missing information** — not just code violations. Add a `"missing_info"` category to findings so the system flags sheets that are entirely absent or elements that should appear but don't.

## Files Changed

| File | Change |
|------|--------|
| `src/components/SitePlanChecklist.tsx` | **New** — Comprehensive completeness checklist with auto-detection from AI findings |
| `src/pages/PlanReviewDetail.tsx` | Add "Completeness" as a new right-panel mode |
| `supabase/functions/ai/index.ts` | Add missing-info detection instructions to both plan review prompts |
| `src/components/DisciplineChecklist.tsx` | Expand site discipline items to cover drainage, utilities, landscape, fire access |
| `src/lib/county-utils.ts` | Add `SITE_PLAN_REQUIRED_ELEMENTS` constant for reuse |

## AI Prompt Enhancement

The AI prompts will be updated to include instructions like:

> **MISSING INFORMATION CHECK (Critical for Private Providers):**
> Beyond code violations, flag any of the following that are MISSING from the plans:
> - No site plan sheet at all
> - Site plan missing property boundaries, setbacks, or parking layout
> - No code summary table (occupancy, construction type, allowable area)
> - No life safety / egress plan
> - No structural design criteria (wind speed, exposure, soil bearing)
> - No energy compliance documentation
> - Missing sealed drawings or engineer of record
> - No product approval references on specifications
> - No flood zone or wind speed designation
>
> Use severity "critical" for missing sheets/information that would cause immediate rejection by a building official. Use "major" for incomplete information that needs supplementation.

## Completeness Panel Behavior

- Each item shows a checkbox with three states: Present / Missing / N/A
- AI findings auto-populate "Missing" status when the AI flags missing info
- Reviewer can manually mark items
- A completion percentage bar shows overall readiness
- Items marked "Missing" generate a summary that can be exported as a deficiency notice to the applicant
- County-specific items (CCCL, HVHZ NOA list, threshold building) conditionally appear based on project county

This ensures your review package is airtight before a building official ever sees it.

