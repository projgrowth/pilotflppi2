

# AI-Powered Zoning Auto-Fill from Site Plans

## Overview

Add a file upload button to the Zoning tab that lets users upload a site plan image/PDF. The AI (Gemini vision) analyzes it and extracts zoning data (lot area, setbacks, zoning district, building footprint, stories, etc.), pre-filling the form fields.

## Changes

### 1. New AI action: `extract_zoning_data` (edge function)

Add to `supabase/functions/ai/index.ts`:
- New system prompt instructing Gemini to extract all `ZoningData` fields from a site plan image (lot area, footprint, setbacks, zoning district, occupancy groups, parking, etc.)
- New tool schema matching the `ZoningData` interface for structured extraction
- Register it as a multimodal action so it uses vision with `gemini-2.5-pro`

### 2. Update `ZoningAnalysisPanel.tsx`

Add an "AI Auto-Fill" section at the top of the form card:
- File input accepting images (PNG/JPG) and PDFs
- For PDFs: convert first page to image using pdfjs-dist (already in the project) before sending
- Upload button with loading state ("Analyzing site plan...")
- On success: merge extracted values into the form state (only overwrite fields that the AI returned non-null values for)
- Toast showing how many fields were extracted
- Visual indicator showing which fields were AI-populated vs manually entered

### 3. File flow

```text
User uploads site plan image/PDF
  → (If PDF, render page 1 to canvas → base64)
  → Call supabase.functions.invoke("ai", { action: "extract_zoning_data", payload: { images: [base64] } })
  → Parse structured response
  → Merge into ZoningData state
  → Compliance checks auto-recalculate
```

## Files Modified

| File | Change |
|------|--------|
| `supabase/functions/ai/index.ts` | Add `extract_zoning_data` prompt, tool schema, register as multimodal |
| `src/components/ZoningAnalysisPanel.tsx` | Add file upload UI, AI extraction handler, merge logic |

No database changes needed — zoning data is already stored as JSONB.

