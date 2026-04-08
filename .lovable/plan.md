

# Fix: Remove Auth Blocking

## Problem
The app has no route-level auth guard, but two things still create friction:
1. **`/login` route is still accessible** — if the user navigates there, `Login.tsx` shows a blank screen during auth loading (`if (loading) return null`)
2. **`AppSidebar` calls `useAuth()`** — the sidebar shows "User" with empty initials and a "Sign out" button, which may confuse things if `signOut()` is called

## Changes

### 1. `src/pages/Index.tsx` — no change needed (already redirects to `/dashboard`)

### 2. `src/pages/Login.tsx` — redirect to dashboard unconditionally
Replace the entire component to just redirect to `/dashboard`, so if someone hits `/login` they go straight to the app.

### 3. `src/components/AppSidebar.tsx` — remove auth dependency
- Remove `useAuth()` import and usage
- Hardcode user display to "Admin" / "AD" initials
- Remove the "Sign out" button entirely

### 4. `src/contexts/AuthContext.tsx` — keep as-is
Leave it in place so it doesn't break imports, but it won't gate anything.

These 2 file edits will fully remove any auth-related friction from the UI.

