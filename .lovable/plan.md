

# Fix: Legacy ReviewDetail Shows Empty Shell for Projects Without Plan Reviews

## Problem
When navigating to `/review/:id` for a project that has no `plan_reviews` record (like this "intake" status project), the redirect can't fire and the user sees a non-functional page — empty "Plan Sheet Viewer", zero flags, no actionable UI.

## Solution
Replace the legacy ReviewDetail fallback with a meaningful empty state that either:
1. Shows a clear message explaining no review has been started yet
2. Provides a "Start Plan Review" button that creates a `plan_reviews` record and navigates to the functional `/plan-review/:id` page

## Changes

### `src/pages/ReviewDetail.tsx`
- After the redirect check completes and finds no plan review (`redirectChecked === true`), render a centered empty state instead of the full review shell
- Empty state shows: project name, status badge, message "No plan review has been started for this project", and a "Start Plan Review" button
- The button inserts a new `plan_reviews` row (round 1, status "in_progress") for this project, then navigates to `/plan-review/:newId`
- While redirect is being checked, show a loading spinner instead of the empty shell

### No other files modified.

