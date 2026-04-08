

## Portal UX Overhaul — Document Viewer, Dashboard, and Navigation

### Core Problem
The document viewer (site plans, inspections) handles massive PDFs poorly — no pan/drag, zoom is clunky, no fit-to-width, and navigating large documents is frustrating. The dashboard lacks task-oriented focus, and the overall flow between modules feels disconnected.

---

### 1. Document Viewer Overhaul — `PlanMarkupViewer.tsx`

**Current issues**: Zoom uses CSS `transform: scale()` which doesn't reflow the scroll container properly. No drag-to-pan. No fit-to-width/fit-to-page. No minimap or page thumbnails for large documents.

**Changes**:
- **Drag-to-pan**: Add mouse-down drag scrolling on the canvas area (cursor: grab/grabbing). Hold space+drag or just click-drag on empty areas.
- **Scroll-wheel zoom**: Ctrl+scroll or pinch to zoom, centered on cursor position (not top-left origin).
- **Fit controls**: Add "Fit Width" and "Fit Page" buttons to toolbar. Calculate zoom based on container dimensions vs image dimensions.
- **Zoom presets**: Replace free-form zoom with preset buttons: 50%, 75%, 100%, 150%, 200% plus fit-width/fit-page.
- **Page thumbnails strip**: Add a collapsible vertical thumbnail strip on the left edge showing miniature page previews. Click to jump. Highlight current page.
- **Keyboard shortcuts**: Arrow keys for page nav, +/- for zoom, 0 for fit-width.

**File**: `src/components/PlanMarkupViewer.tsx`

### 2. Dashboard Reorganization — `Dashboard.tsx`

**Current issues**: Generic KPI cards don't drive action. Activity feed is passive. No sense of "what do I need to do right now?"

**Changes**:
- **Replace KPI row with "Needs Attention" queue**: Show items that need action — reviews awaiting AI check, inspections today, approaching deadlines. Each item is a clickable row that navigates directly to the action.
- **Collapse activity feed into a compact timeline**: Move to a small right column or bottom section. Keep it but reduce prominence.
- **Add "In Progress" section**: Show currently open plan reviews with progress indicators (findings count, status).
- **Quick stats become a subtle inline bar** at the top (e.g., "5 active · 2 due this week · 1 inspection today") instead of 4 large cards.

**File**: `src/pages/Dashboard.tsx`

### 3. Plan Review Detail — Responsive Split Panel

**Current issues**: Right panel is fixed 420px, doesn't work on smaller screens. Left panel has no pan/drag for PDFs.

**Changes**:
- **Make split resizable**: Use `react-resizable-panels` (already in project as `src/components/ui/resizable.tsx`) to let users drag the divider between document viewer and findings panel.
- **Collapsible right panel**: Add a toggle button to collapse/expand the right panel. When collapsed, show a thin icon strip.
- **Mobile stack**: On screens < 1024px, stack vertically with the document viewer on top and findings in a bottom drawer.

**File**: `src/pages/PlanReviewDetail.tsx`

### 4. Inspections — Document Attachment Viewer

**Current issues**: Inspections page has no document viewing. For site inspections with large plans, there's no way to reference documents.

**Changes**:
- **Add document reference to inspection sheet**: When an inspection is opened, show a "View Plans" button that opens the associated project's plan documents in a modal using PlanMarkupViewer.
- Keep the inspection sheet focused on checklist/results, but add easy access to reference documents.

**File**: `src/pages/Inspections.tsx`

### 5. Global Navigation Polish

**Changes**:
- **Breadcrumb trail on all detail pages**: PlanReviewDetail already has back button; add breadcrumbs (Dashboard > Projects > Project Name > Plan Review R1).
- **Keyboard shortcut hints**: Add subtle shortcut hints in sidebar items (visible on hover) for power users.

**Files**: `src/pages/PlanReviewDetail.tsx`, `src/pages/ProjectDetail.tsx`

---

### Technical Summary

| File | Change |
|------|--------|
| `src/components/PlanMarkupViewer.tsx` | Major rewrite — drag-to-pan, scroll zoom, fit controls, page thumbnails, keyboard nav |
| `src/pages/Dashboard.tsx` | Restructure to action-oriented "Needs Attention" queue |
| `src/pages/PlanReviewDetail.tsx` | Resizable split panels, collapsible right panel, breadcrumbs |
| `src/pages/Inspections.tsx` | Add plan document reference in inspection sheet |
| `src/pages/ProjectDetail.tsx` | Add breadcrumbs |

### Priority Order
1. PlanMarkupViewer (biggest pain point — large document navigation)
2. PlanReviewDetail resizable panels
3. Dashboard reorganization
4. Inspections document reference
5. Breadcrumbs & navigation polish

