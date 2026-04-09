

# Fix Document Linking & PDF Generation

## Problems Identified

1. **Broken plan review file downloads**: The `plan_review_files` table stores full URLs (e.g., `https://...supabase.co/storage/v1/object/public/documents/plan-reviews/...`) in `file_path`, but `handleDownloadDoc` passes this full URL to `supabase.storage.from("documents").download()`, which prepends the bucket path again, causing a 400 error (visible in network logs).

2. **No actual PDF generation**: Comment Letters, Product Checklists, and Inspection Readiness Packets are all generated as HTML files (`.html`), not PDFs. Building officials expect PDF documents.

3. **Document list doesn't refresh after generation**: When a Comment Letter or Checklist is saved to storage via `persistToStorage`, the project documents query isn't invalidated, so the new file doesn't appear in the Documents tab until page refresh.

4. **Plan review navigation is generic**: Clicking a plan review in ProjectDetail navigates to `/plan-review` (the list page), not to the specific review at `/plan-review/:id`.

## Plan

### 1. Fix plan review file path handling
In `ProjectDetail.tsx`, update `handleDownloadDoc` to detect when `storagePath` is a full URL. If so, extract just the relative path (everything after `/object/public/documents/` or `/object/documents/`), or use a signed URL approach since the bucket is private.

Also fix the plan review file listing — strip the full URL prefix to get the relative storage path.

### 2. Add real PDF generation using browser print-to-PDF
Update `CommentLetterExport` and `CountyDocumentPackage` to:
- Keep the HTML generation as-is (it's well-structured)
- Change download buttons to trigger `window.print()` via the hidden iframe approach (already exists for print) but with a "Save as PDF" instruction, OR
- Use a proper client-side HTML-to-PDF approach using the existing iframe + `print()` pattern but saving the file as `.pdf` via the browser's print dialog

Since true client-side PDF generation without a library is limited, the pragmatic fix is:
- Rename outputs from `.html` to indicate they're print-ready
- Add a "Save as PDF" button that opens the print dialog (users select "Save as PDF" in their browser)
- Persist the HTML to storage for later reference

### 3. Invalidate document queries after generation
After `persistToStorage` succeeds, invalidate `["project-documents", projectId]` so the Documents tab updates immediately.

### 4. Fix plan review navigation
Update the plan review click handler in `ProjectDetail.tsx` to navigate to `/plan-review/${r.id}` instead of `/plan-review`.

## Files Changed

| File | Change |
|------|--------|
| `src/pages/ProjectDetail.tsx` | Fix file path extraction for plan review files; fix plan review navigation to specific review ID; invalidate queries after upload |
| `src/components/CommentLetterExport.tsx` | Add query invalidation after persist; ensure print/save-as-PDF flow works properly |
| `src/components/CountyDocumentPackage.tsx` | Add query invalidation after persist |

## Technical Details

The core download fix in `ProjectDetail.tsx`:
```typescript
// Extract relative path from full URL if needed
function getRelativeStoragePath(filePath: string): string {
  const publicPrefix = "/storage/v1/object/public/documents/";
  const authPrefix = "/storage/v1/object/documents/";
  const idx = filePath.indexOf(publicPrefix);
  if (idx !== -1) return filePath.substring(idx + publicPrefix.length);
  const idx2 = filePath.indexOf(authPrefix);
  if (idx2 !== -1) return filePath.substring(idx2 + authPrefix.length);
  return filePath;
}
```

For plan review files, since the bucket is private, use `createSignedUrl` instead of `download` with the public path.

