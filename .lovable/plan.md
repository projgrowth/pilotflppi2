

# UI/UX Improvement & Cleanup Plan

## Issues Found

### A. Inconsistent Page Layout Patterns
- **Contractors**, **LeadRadar**, **MilestoneRadar**, **AIBriefing** use raw `<h1>` tags with `p-6 md:p-8` padding instead of the standardized `PageHeader` component and `p-8 md:p-10` padding used elsewhere.
- Creates visual inconsistency when navigating between pages.

### B. Duplicate Content Between Pages
- **Dashboard** and **AI Briefing** both show the same KPI cards (Active Projects, Due This Week, Statutory Alerts, Completed MTD) and Activity Feed. AI Briefing duplicates ~60% of the Dashboard.
- **Dashboard** has a statutory overdue banner; **AI Briefing** has its own nearly identical statutory alert banner.
- Fix: Remove KPI cards and Activity Feed from AI Briefing. Focus that page purely on the AI tools (County Code Assistant + Quick Q&A).

### C. Redundant Quick Actions on Dashboard
- "Schedule Inspection" just navigates to `/inspections` (same as sidebar link).
- "Find Leads" just navigates to `/lead-radar` (same as sidebar link).
- These add clutter without unique value. Keep only "New Intake" and "Run AI Check" as dashboard quick actions.

### D. Unused Components (Dead Code)
- `src/components/NavLink.tsx` -- not imported anywhere
- `src/components/RoundNavigator.tsx` -- not imported anywhere
- These should be deleted.

### E. Inconsistent Empty States
- **Contractors**, **LeadRadar**, **MilestoneRadar**, **Documents** use inline empty state JSX instead of the shared `EmptyState` component. Should use the shared component for consistency.

### F. Dual Toaster Setup
- `App.tsx` renders both `<Toaster />` (from `ui/toaster`) and `<Sonner />` (from `ui/sonner`). The app exclusively uses `toast` from `sonner`. The shadcn `Toaster` is unused and can be removed along with `src/components/ui/toaster.tsx` and `src/hooks/use-toast.ts` / `src/components/ui/use-toast.ts`.

### G. Card Border Inconsistency
- Some cards use `shadow-subtle border` (Documents, Settings), others use just `shadow-subtle` (Dashboard). Should standardize: `shadow-subtle` only, no explicit border.

### H. Filter Pill Pattern Inconsistency
- Deadlines uses `filter-pills` utility class. Projects uses `filter-pills` too. But Plan Review page has no filters despite having multiple statuses. Consistent pattern is good but the PlanReview list page would benefit from status filters.

---

## Proposed Changes

### 1. Standardize All Pages on PageHeader + Consistent Padding
Files: `Contractors.tsx`, `LeadRadar.tsx`, `MilestoneRadar.tsx`, `AIBriefing.tsx`
- Replace raw `<h1>` with `<PageHeader title="..." />` 
- Change padding to `p-8 md:p-10`

### 2. Remove Duplicate Content from AI Briefing
File: `AIBriefing.tsx`
- Remove KPI cards row (duplicates Dashboard)
- Remove Activity Feed section (duplicates Dashboard)
- Remove statutory alert banner (duplicates Dashboard overdue banner)
- Keep only: County Code Assistant (full width, taller) + Quick Code Q&A below it
- This makes AI Briefing a focused tool page, not a second dashboard

### 3. Slim Down Dashboard Quick Actions
File: `Dashboard.tsx`
- Remove "Schedule Inspection" and "Find Leads" buttons (accessible via sidebar)
- Keep "New Intake" (primary) and "Run AI Check" (secondary)

### 4. Delete Unused Components
- Delete `src/components/NavLink.tsx`
- Delete `src/components/RoundNavigator.tsx`

### 5. Remove Unused Toaster
Files: `App.tsx`, `src/components/ui/toaster.tsx`, `src/components/ui/use-toast.ts`, `src/hooks/use-toast.ts`
- Remove `<Toaster />` from App.tsx (keep only `<Sonner />`)
- Delete `toaster.tsx`, `use-toast.ts` files (unused -- app uses sonner exclusively)

### 6. Standardize Empty States
Files: `Contractors.tsx`, `LeadRadar.tsx`, `MilestoneRadar.tsx`, `Documents.tsx`
- Replace inline empty state JSX with `<EmptyState />` component

### 7. Standardize Card Borders
Files: `Documents.tsx`, `Settings.tsx`, `Inspections.tsx`
- Remove explicit `border` class from cards (keep only `shadow-subtle`)
- Settings cards: remove `border` from Card wrappers

### 8. Add Status Filter to Plan Review List
File: `PlanReview.tsx`
- Add filter pills row: "All", "Pending", "Running", "Complete", "Error"
- Uses existing `filter-pills` / `filter-pill` utility classes from index.css

---

## Summary of Deletions
| File | Reason |
|------|--------|
| `src/components/NavLink.tsx` | Never imported |
| `src/components/RoundNavigator.tsx` | Never imported |
| `src/components/ui/toaster.tsx` | App uses sonner, not shadcn toaster |
| `src/components/ui/use-toast.ts` | Accompanies unused toaster |
| `src/hooks/use-toast.ts` | Accompanies unused toaster |

No logic, data, or routing changes -- purely cosmetic, cleanup, and deduplication.

