

## Plan: Rebrand PermitPilot to Florida Private Providers + Portal Improvements

### Analysis of floridaprivateproviders.com

The FPP website uses:
- **Colors**: Deep forest green (#2D5A3D-ish), warm off-white/cream backgrounds, dark charcoal text, gold/amber accents
- **Logo**: Text-based "Florida / PRIVATE PROVIDERS" with a horizontal rule between
- **Typography**: Clean sans-serif body, serif for display headings
- **Tone**: Professional, trustworthy, Florida-centric. Key stats: License #AR92053, 44+ years, 67 counties, 2,500+ projects, Google 5.0
- **Structure**: "Three Simple Steps" flow, testimonials, FAQ, leadership team

### What needs to change

**1. Branding overhaul (colors, logo, metadata)**
- Update CSS custom properties: primary to deep green (#1B4332), accent to warm gold (#C9A84C stays), teal replaced with forest green
- Sidebar: dark green instead of navy
- Replace the hexagon SVG logo with text-based "Florida / PRIVATE PROVIDERS" matching their wordmark
- Update `index.html` title and meta tags to "Florida Private Providers — PermitPilot"
- Update sidebar brand text from "PermitPilot" subtitle to "Licensed Private Provider"

**2. Login page — real auth with branded experience**
- Currently just redirects to dashboard (no auth gate)
- Build a proper login/signup page with FPP branding: logo, green gradient background, email/password form, Google sign-in
- Add route protection so unauthenticated users are redirected to /login

**3. Dashboard refinements**
- Add the FPP stats bar (License #AR92053, 44+ Yrs, 67 Counties) as a subtle footer or header element
- Refine greeting area with company branding context

**4. Missing functional pages**
- **AI Briefing, Milestone Radar, Lead Radar, Documents**: Audit these pages — ensure they query real data and have no placeholder content
- **Contractors page**: Verify it works with the database

**5. Overall polish**
- Green color scheme throughout all components (buttons, chips, rings, donut charts)
- Card borders and hover states using the new green palette
- Consistent use of the FPP green for active sidebar items instead of gold

### Files to modify

| File | Change |
|------|--------|
| `src/index.css` | Update all CSS custom properties to FPP green palette |
| `tailwind.config.ts` | No structural changes needed (uses CSS vars) |
| `index.html` | Update title, meta tags to FPP branding |
| `src/components/AppSidebar.tsx` | Replace logo SVG with FPP wordmark, update brand text |
| `src/pages/Login.tsx` | Build full auth page with email/password, Google sign-in, FPP branding |
| `src/contexts/AuthContext.tsx` | Already functional — no changes needed |
| `src/App.tsx` | Add auth guard wrapper for protected routes |
| `src/pages/Dashboard.tsx` | Add license/stats bar, refine branding references |
| `src/pages/AIBriefing.tsx` | Audit for mock data |
| `src/pages/LeadRadar.tsx` | Audit for mock data |
| `src/pages/MilestoneRadar.tsx` | Audit for mock data |
| `src/pages/Documents.tsx` | Audit for mock data |
| `src/pages/Contractors.tsx` | Audit for mock data |

### Color palette mapping

```text
Current (Navy/Gold)          →  FPP (Green/Gold)
──────────────────────────────────────────────────
--primary: navy #0B1F3A      →  forest green #1B4332
--sidebar-bg: navy           →  dark green #14332A
--accent: gold #C9A84C       →  gold #C9A84C (keep)
--teal: #2A9D8F              →  sage green #2D6A4F
--background: cream          →  warm cream (keep)
--border: warm tan           →  slightly greener neutral
```

### Auth flow

```text
User visits any route
  → AuthGuard checks session
    → No session → redirect /login
    → Has session → render AppLayout + children

/login page:
  ┌─────────────────────────────┐
  │  Florida                    │
  │  PRIVATE PROVIDERS          │
  │  ───────────────────        │
  │                             │
  │  [Email input]              │
  │  [Password input]          │
  │  [Sign In button — green]   │
  │  ── or ──                   │
  │  [Continue with Google]     │
  │                             │
  │  Don't have an account?     │
  │  Sign up                    │
  └─────────────────────────────┘
```

### Estimated scope
- 10-12 files modified
- 1 new component (AuthGuard or inline in App.tsx)
- No database migrations needed
- Auth configuration: enable Google OAuth via cloud tools

