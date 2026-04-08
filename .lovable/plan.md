
## Portal-Wide UI/UX Improvements

### 1. Global Page Header Component
**Problem**: Every page has slightly different header styling — inconsistent spacing, font weights, and action button placement.
**Fix**: Create a reusable `PageHeader` component with title, subtitle, breadcrumb, and action slot. Standardizes all pages instantly.

### 2. Breadcrumb Navigation
**Problem**: Deep pages (ProjectDetail, PlanReviewDetail) only have a bare "← Back" button. Users lose context of where they are.
**Fix**: Add breadcrumbs like `Projects / Oceanview Residences` or `Plan Review / R2 — Ocean Tower`. Use the shadcn breadcrumb component already installed.

### 3. Empty States — Consistent & Actionable
**Problem**: Empty states vary wildly — some have giant icons, some have tiny text, some have CTAs, some don't.
**Fix**: Create a reusable `EmptyState` component with icon, title, description, and optional action button. Apply across Dashboard, Projects, Plan Review, Inspections.

### 4. Login Page — Underdeveloped Left Panel
**Problem**: Left branding panel is just "FLPPI" in big text on a green background. Wastes half the screen.
**Fix**: Add the full brand lockup (Florida Private Providers wordmark from sidebar), a tagline ("Licensed Private Provider Services Since 1980"), subtle background texture or pattern, and 2-3 trust indicators (license number, counties served, years of experience).

### 5. Dashboard — Tighter Information Hierarchy
**Problem**: The "FPP Stats Bar" at top (AR92053, 44+ Years, 67 Counties) is static vanity info that takes prime real estate on every visit. Quick Actions are buried at the bottom right.
**Fix**: 
- Remove the static stats bar (this info is already in the sidebar)
- Move Quick Actions to a horizontal row below the greeting
- Make KPI cards clickable (navigate to relevant page)
- Add a subtle divider or section break between areas

### 6. Sidebar — Active State & Visual Hierarchy
**Problem**: Active nav item uses a left border accent which is subtle. Section headers blend in.
**Fix**: Active item gets a filled background pill instead of just a border. Add subtle opacity fade between nav sections.

### 7. Card Hover & Interactive States
**Problem**: List rows (Projects, Plan Review) have `hover:bg-muted/30` which is barely visible. No press/active state.
**Fix**: Stronger hover state (`hover:bg-muted/50`), subtle left-border accent on hover, and `active:scale-[0.995]` for tactile feedback.

### 8. Typography Polish
**Problem**: Page titles use `text-2xl font-medium` which looks flat. No display font usage on main headings.
**Fix**: Page titles use `font-display text-3xl` (Instrument Serif) for character. Keep body text in DM Sans. This matches the sidebar branding.

### 9. Table/List Header Row
**Problem**: Plan Review list has a header row but Projects doesn't. Inconsistent.
**Fix**: Add column headers to the Projects list. Standardize both to use the same header style.

### 10. Status Chip Refinement
**Problem**: Status chips are plain colored text on tinted backgrounds. They work but feel generic.
**Fix**: Add a tiny dot indicator before the label text for visual scanning. Slightly larger padding for better touch targets.

### 11. Skeleton Loading Polish
**Problem**: Skeleton loading states are basic rectangles. Some pages have them, some show a spinner.
**Fix**: Standardize all pages to use skeleton loading that matches the actual content shape. No raw spinners on page-level loads.

### 12. Mobile Responsive Gaps
**Problem**: The sidebar hamburger button overlaps content on mobile. Plan Review detail workspace doesn't adapt.
**Fix**: Add top padding on mobile to account for hamburger button. Plan Review detail stacks panels vertically on mobile.

### Files Changed
| File | Change |
|------|--------|
| `src/components/PageHeader.tsx` | **New** — reusable header with breadcrumb |
| `src/components/EmptyState.tsx` | **New** — reusable empty state |
| `src/pages/Dashboard.tsx` | Remove stats bar, move quick actions up, use PageHeader, clickable KPIs |
| `src/pages/Projects.tsx` | Use PageHeader, add column headers, improve hover states |
| `src/pages/PlanReview.tsx` | Use PageHeader, improve card styling |
| `src/pages/Inspections.tsx` | Use PageHeader, consistent empty state |
| `src/pages/Login.tsx` | Enhance left branding panel |
| `src/components/AppSidebar.tsx` | Filled active state pill |
| `src/components/StatusChip.tsx` | Add dot indicator, better padding |
| `src/components/AppLayout.tsx` | Mobile top padding for hamburger |
| `src/index.css` | Add subtle animation tokens |
