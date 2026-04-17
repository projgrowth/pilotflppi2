

# Knip Cleanup Plan

## The blocker (and fix)
Knip can't load `playwright.config.ts` because `lovable-agent-playwright-config` isn't installed in the sandbox. **Fix**: add a `knip.json` that ignores `playwright.config.ts` and `playwright-fixture.ts` and the playwright dependency, so knip runs cleanly without needing the missing package. The Playwright files themselves stay untouched (they're used by the agent test runner, not the app).

## Verified findings (manually re-checked against `src/App.tsx` routes & grep)

### Unused files — DELETE (9)
Genuine orphans. All confirmed with grep — zero references outside themselves.
- `src/App.css` — Vite default leftover; `src/index.css` is the real stylesheet
- `src/components/KpiCard.tsx`
- `src/components/QcPendingWidget.tsx`
- `src/components/shared/ConfidenceBadge.tsx` (sibling `ConfidenceBar.tsx` is the one in use)
- `src/hooks/useDashboardStats.ts`
- `src/pages/Deadlines.tsx` — no `/deadlines` route in `App.tsx`
- `src/pages/Documents.tsx` — `App.tsx` routes `/documents` to `DocumentsGen`, not this file
- `src/pages/PlanReview.tsx` — `App.tsx` only has `/plan-review/:id` → `PlanReviewDetail`; no list page route

### Unused UI primitives — DELETE (22)
shadcn boilerplate that was never wired up. Each verified with `grep -rn "from.*ui/<name>"` returning zero hits outside the file itself:
`alert-dialog, alert, aspect-ratio, avatar, breadcrumb, calendar, carousel, chart, context-menu, drawer, hover-card, input-otp, menubar, navigation-menu, pagination, radio-group, separator, sidebar, slider, toast, toggle-group, toggle`

### KEEP (knip flagged but verified in use or intentional)
- `supabase/functions/*` — edge functions; out of scope per task constraints
- `src/integrations/supabase/types.ts` exports (`Tables`, `Enums`, etc.) — auto-generated, do not touch
- `playwright.config.ts`, `playwright-fixture.ts`, `@playwright/test` — agent test runner uses them
- `lovable-tagger`, `tailwindcss-animate`, `@tailwindcss/typography`, `autoprefixer` — build/PostCSS plugins (knip can't see PostCSS config refs)
- `@testing-library/react`, `jsdom` — vitest setup

### Unused dependencies — REMOVE from `package.json` (18)
Only the radix packages whose UI files we're deleting + 3 unused utility libs. Each maps 1:1 to a deleted file or to nothing:
- `@radix-ui/react-alert-dialog` (alert-dialog.tsx)
- `@radix-ui/react-aspect-ratio` (aspect-ratio.tsx)
- `@radix-ui/react-avatar` (avatar.tsx)
- `@radix-ui/react-context-menu` (context-menu.tsx)
- `@radix-ui/react-hover-card` (hover-card.tsx)
- `@radix-ui/react-menubar` (menubar.tsx)
- `@radix-ui/react-navigation-menu` (navigation-menu.tsx)
- `@radix-ui/react-radio-group` (radio-group.tsx)
- `@radix-ui/react-separator` (separator.tsx)
- `@radix-ui/react-slider` (slider.tsx)
- `@radix-ui/react-toast` (toast.tsx)
- `@radix-ui/react-toggle` (toggle.tsx)
- `@radix-ui/react-toggle-group` (toggle-group.tsx)
- `embla-carousel-react` (carousel.tsx)
- `input-otp` (input-otp.tsx)
- `react-day-picker` (calendar.tsx)
- `vaul` (drawer.tsx)
- `@types/dompurify` — `dompurify` v3 ships its own types; this is dead weight

### Unused exports — leave alone
The 56 unused named exports (e.g. `buttonVariants`, `DialogPortal`, `SheetClose`, `getStatutoryDeadlineDate`) all live in files that ARE used. Pruning them is risky (shadcn re-exports are commonly used later, lib helpers may be referenced by upcoming features) and high-noise for low value. **Skip.**

## Execution steps (after approval)

1. Add `knip.json` so future runs work without the sandbox workaround
2. Delete 9 source files + 22 UI primitives = **31 files removed**
3. Remove 18 entries from `package.json` dependencies
4. Run `tsc --noEmit` — must pass with 0 errors
5. Re-run knip — confirm "Unused files: 0" (apart from the still-ignored playwright/edge-function set)

## Expected outcome
- 31 fewer source files
- 18 fewer npm packages
- Clean knip baseline that runs in CI without the playwright module being installed

