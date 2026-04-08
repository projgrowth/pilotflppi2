

# PermitPilot — Operations Platform Build Plan

## Overview
PermitPilot is a full-stack SaaS operations platform for Florida Private Providers (FPP), a licensed private building inspection and plan review firm. It centralizes project tracking, AI-powered plan review, deadline management, inspections, and contractor communication around Florida's 21-day statutory permit clock.

---

## Phase 1: Foundation — Design System, Layout & Auth

### 1.1 Design System Setup
- Configure Tailwind with custom color tokens: `--bg: #FAFAF9`, `--surface: #FFFFFF`, `--border: #E8E5E0`, `--accent: #C9A84C` (gold), `--teal: #2A9D8F`, `--navy: #0B1F3A`, plus danger/warn/success colors
- Import Google Fonts: **Instrument Serif** (logo only), **DM Sans** (UI body), **DM Mono** (permit IDs, countdowns)
- Define component primitives: 8px radius cards, 6px radius inputs/buttons, 4px chips, 1px borders only, subtle shadows (`0 1px 3px rgba(0,0,0,0.06)`)
- Build reusable StatusChip component with 10% opacity backgrounds per status type

### 1.2 Supabase Cloud Setup — Database Schema
Create all 8 tables with RLS:
- `contractors` — name, license, email, phone, portal_access
- `projects` — address, county, jurisdiction, trade_type, services[], status, notice_filed_at, deadline_at, assigned_to
- `plan_reviews` — project_id, file_urls[], ai_check_status, ai_findings (jsonb), reviewer_id, round
- `inspections` — project_id, scheduled_at, inspector_id, inspection_type, result, virtual, video_call_url, certificate_issued
- `activity_log` — project_id, actor_id, actor_type, event_type, description, metadata (jsonb)
- `milestone_buildings` — address, building_name, stories, co_issued_date, milestone_deadline, status
- `permit_leads` — address, county, contractor_name, permit_type, project_value, outreach_status
- Seed data: 1 user, 3 contractors, 5 projects, 8 activity log entries, 2 milestone buildings, 3 permit leads

### 1.3 Auth & Layout Shell
- Supabase email/password auth on `/login` page
- Auth guard wrapping all routes except `/login` and `/portal`
- Fixed 240px sidebar: hexagon icon + "PermitPilot" in Instrument Serif + "Florida Private Providers" subtext
- Nav sections: **OPERATIONS** (Dashboard, Projects, Plan Review, Inspections, Deadlines) / **INTELLIGENCE** (AI Briefing, Milestone Radar, Lead Radar) / **MANAGE** (Contractors, Documents, Settings)
- Active nav: 2px left gold border + accent-dim bg + gold text
- Bottom: user avatar chip with name, role, settings caret
- Mobile responsive: sidebar collapses to hamburger at 768px
- All routes configured via React Router v6

---

## Phase 2: Core Operations Screens

### 2.1 Dashboard (`/dashboard`)
- Greeting: "Good morning, [Name]." 24px weight-500 + date below in 14px text-secondary
- 4 KPI cards: Active Projects, Critical Deadlines (red if >0), Avg Review Time, Completed MTD — white cards, 1px border, big number 32px
- Recent Projects list: borderless rows (64px tall) with project name, address, trade chip, county, status chip, "Day X of 21" badge, chevron
- Bottom 60/40 split: AI Briefing feed (colored dots + messages + timestamps) | Quick Actions (New Intake, Schedule Inspection, Run AI Check, Find Leads)

### 2.2 Projects List (`/projects`)
- Filter pill tabs: All / Plan Review / Inspection / Pending / Complete (gold underline active)
- Search input (real-time client filter) + Sort dropdown (Deadline/Created/Status)
- Data table: checkbox, project name+address, contractor, trade chip, county, status chip, deadline countdown (color-coded), assigned avatar, actions menu
- Bulk actions bar on selection: reassign, export, mark complete
- 25 per page with pagination + empty state

### 2.3 Project Detail (`/projects/:id`)
- Left 65%: vertical event timeline (intake → plan_review → comments → resubmit → permit → inspection → certificate) with colored nodes, gold ring for active, gray/dashed for future
- Below timeline: tabbed panels (Documents, Plan Review, Inspections, Activity Log, Notes)
- Right 35% sticky sidebar: metadata card, **21-day circular SVG progress ring** (stroke color: green days 1-14, amber 15-18, red 19-21; DM Mono center number), quick action buttons, document list

### 2.4 Deadlines (`/deadlines`)
- Horizontal bar timeline: each project = one row with project name + address, bar filling over 21 days, days remaining label
- Color logic: green (1-14), amber (15-18), red (19-21), dark red bg row for overdue
- Filter tabs: All / Critical (≤3 days) / This Week / Upcoming

---

## Phase 3: Inspections, CRM & Documents

### 3.1 Inspections (`/inspections`)
- Weekly calendar grid with scheduled virtual inspection slots
- Each slot: project name, trade, inspector, video call link
- "Start Inspection" side panel: auto-generated project brief, trade-specific checklist, Pass/Fail/Partial buttons, notes, "Generate Certificate" button

### 3.2 Contractors CRM (`/contractors`)
- Contacts table: name, license, email, phone, total projects, portal access toggle
- Add/edit contractor modal with form validation

### 3.3 Documents (`/documents`)
- File storage interface using Supabase Storage
- Certificate archive with download links
- Upload functionality with drag-and-drop

### 3.4 Settings (`/settings`)
- Firm info management
- User management (invite, roles)
- Jurisdiction list configuration

---

## Phase 4: AI Intelligence Features

### 4.1 AI Edge Function
- Single Supabase Edge Function at `supabase/functions/ai/index.ts`
- POST endpoint with `{ action, payload }` routing to 6 actions:
  - `plan_review_check` — analyze uploaded PDFs against Florida Building Code
  - `generate_comment_letter` — formal code-cited deficiency letter
  - `generate_inspection_brief` — pre-inspection briefing (max 200 words)
  - `generate_outreach_email` — contractor outreach for Lead Radar
  - `generate_milestone_outreach` — building manager milestone email
  - `answer_code_question` — FBC code Q&A
- Uses Claude API via Lovable AI Gateway, streaming where possible

### 4.2 Plan Review (`/plan-review` + `/plan-review/:id`)
- Queue view listing pending reviews
- Split screen: left = PDF viewer, right = AI analysis panel
- "Run AI Pre-Check" button → animated scanning bar → findings list (severity badge + code ref + page + description + recommendation)
- "Generate Comment Letter" → streams into editable textarea
- "Send to Contractor" → logs to activity_log

### 4.3 Milestone Radar (`/milestone-radar`)
- Card list: building name, address, CO year, milestone deadline, status badge, contact info
- Color coding: Red = overdue, Amber = within 90 days, Gray = 90+ days
- "Launch Outreach" button: Claude generates personalized email per building

### 4.4 Lead Radar (`/lead-radar`)
- Table: address, permit type, contractor, estimated value, detection date, outreach status
- "Generate Outreach" per row: Claude writes personalized contractor email

---

## Phase 5: Contractor Portal, Email & Realtime

### 5.1 Contractor Portal (`/portal`)
- Separate public auth (portal credentials from contractors table)
- View active projects and status
- Upload revised plans
- Download certificates
- Self-schedule inspections
- Minimal branding: FPP wordmark in navy, off-white bg, no sidebar

### 5.2 Email Integration (Resend)
- 6 triggered email templates: intake confirmation, comment letter, Day 14 warning, Day 19 urgent alert, inspection confirmation with video link, Certificate of Completion
- Plain HTML: white bg, navy FPP wordmark header, DM Sans 14px, gold CTA button

### 5.3 Supabase Realtime Subscriptions
- `activity_log` inserts → push to AI Briefing feed on dashboard
- `projects` updates → refresh deadline counters
- `permit_leads` inserts → show toast notification for new leads

---

## Quality Requirements (Applied Throughout)
- TypeScript strict mode, no `any` types
- All Supabase queries fully typed
- Skeleton loading states on all async data (pulse gray bars, not spinners)
- Error boundaries on every route
- React Hook Form + Zod validation on all forms
- Proper empty states everywhere: icon + headline + body + optional CTA
- Mobile responsive to 768px

