
The user wants me to verify the foundation hardening changes end-to-end on the preview. This requires browser automation + a build check. I'm in plan mode (read-only), so I need to present a plan first.

Let me keep this tight — the user knows what they want.

Verification scope:
1. Build/type check is clean
2. Open plan review at current route
3. Run AI check, observe parallel refine reporting
4. Verify image crops render under "Why?"
5. Confirm no regressions from tenancy/finding_id/parallel changes
6. Report findings

I should also do a quick read of the current PlanReviewDetail to know what to look for in the phase indicator (current/total format).
