// Visual evidence crop generator.
//
// Given a source PDF page + an "evidence" verbatim quote string returned by
// the AI, render the page client-side via pdf.js, locate the quote in the
// page's text layer, and crop a padded region around it. The result is a
// base64 PNG suitable for inline display in a deficiency card or for upload
// to storage so it can be embedded in an exported comment letter.
//
// We intentionally do NOT round-trip the bbox through the AI: vector PDFs
// from architects/engineers carry their text as real strings with exact
// coordinates, so `extractPagesTextItems` + `snapToNearestText` (the same
// pipeline used for grid-anchored pin placement, see mem://logic/pin-placement)
// gives us deterministic localization at zero AI cost.

import * as pdfjsLib from "pdfjs-dist";
import {
  extractPagesTextItems,
  snapToNearestText,
  type PDFTextItem,
} from "./pdf-utils";

pdfjsLib.GlobalWorkerOptions.workerSrc = `https://cdnjs.cloudflare.com/ajax/libs/pdf.js/${pdfjsLib.version}/pdf.worker.min.mjs`;

export interface EvidenceCropResult {
  /** data:image/png;base64,... */
  base64: string;
  /** Crop bbox in PERCENT of the rendered page (top-left origin). */
  bbox: { x: number; y: number; w: number; h: number };
  /** Page width / height in pixels at the rendered DPI. */
  pageWidthPx: number;
  pageHeightPx: number;
  /** True if we matched the evidence text in the page's text layer. */
  matched: boolean;
}

/**
 * Pick the text item that best represents `evidence` on `pageItems`.
 * Falls back gracefully:
 *   1. Exact / contains match via snapToNearestText (no grid anchor).
 *   2. First long enough token of `evidence` (split on spaces).
 *   3. null → caller falls back to centered crop.
 */
function findEvidenceItem(pageItems: PDFTextItem[], evidence: string): PDFTextItem | null {
  const cleaned = evidence.replace(/\s+/g, " ").trim();
  if (!cleaned) return null;
  const direct = snapToNearestText(pageItems, cleaned, null);
  if (direct) return direct;
  // Fall back: try the longest individual word (likely a callout / number).
  const tokens = cleaned
    .split(/[\s,;:.()"]+/)
    .filter((t) => t.length >= 3)
    .sort((a, b) => b.length - a.length);
  for (const t of tokens) {
    const hit = snapToNearestText(pageItems, t, null);
    if (hit) return hit;
  }
  return null;
}

/**
 * Render a single PDF page at the given DPI to an offscreen canvas and
 * return the canvas plus its viewport. Caller is responsible for cleanup.
 */
async function renderPageCanvas(
  file: File,
  pageInFile: number,
  dpi = 200,
): Promise<{ canvas: HTMLCanvasElement; widthPx: number; heightPx: number; items: PDFTextItem[] }> {
  const arrayBuffer = await file.arrayBuffer();
  const pdf = await pdfjsLib.getDocument({ data: arrayBuffer }).promise;
  const pageNum = Math.max(1, Math.min(pdf.numPages, pageInFile));
  const page = await pdf.getPage(pageNum);
  const viewport = page.getViewport({ scale: dpi / 72 });

  const canvas = document.createElement("canvas");
  canvas.width = viewport.width;
  canvas.height = viewport.height;
  const ctx = canvas.getContext("2d")!;
  await page.render({ canvasContext: ctx, viewport }).promise;

  // Re-extract text items from JUST this page (extractPagesTextItems goes top-down).
  // We need pageNum-th set, so render a fresh extraction restricted to this page.
  // Simplest: re-open via existing helper but slice.
  const allItems = await extractPagesTextItems(file, pdf.numPages);
  const items = allItems[pageNum - 1] ?? [];

  return { canvas, widthPx: viewport.width, heightPx: viewport.height, items };
}

/**
 * Generate a cropped PNG of the region around `evidenceText` on the given
 * page of the given PDF file. The crop is padded for context: at least
 * 18% of page width / 12% of page height around the matched bbox center.
 */
export async function generateEvidenceCrop(opts: {
  file: File;
  /** 1-based page number within the source PDF. */
  pageInFile: number;
  evidenceText: string;
  /** Render DPI for the source page (higher = sharper crop, slower). */
  dpi?: number;
  /** Padding in PERCENT of page dimensions around the matched item. */
  padPctX?: number;
  padPctY?: number;
}): Promise<EvidenceCropResult> {
  const dpi = opts.dpi ?? 200;
  const padX = opts.padPctX ?? 9; // each side
  const padY = opts.padPctY ?? 6;

  const { canvas, widthPx, heightPx, items } = await renderPageCanvas(
    opts.file,
    opts.pageInFile,
    dpi,
  );

  const hit = findEvidenceItem(items, opts.evidenceText);

  // Build a percent-coord bbox around the hit (or page center as fallback).
  const cx = hit ? hit.x : 50;
  const cy = hit ? hit.y : 50;
  const minHalfW = padX;
  const minHalfH = padY;
  const halfW = Math.max((hit?.width ?? 0) / 2 + padX, minHalfW);
  const halfH = Math.max((hit?.height ?? 0) / 2 + padY, minHalfH);

  let x = Math.max(0, cx - halfW);
  let y = Math.max(0, cy - halfH);
  let w = Math.min(100 - x, halfW * 2);
  let h = Math.min(100 - y, halfH * 2);

  // Keep crop a sensible size — at least 22% × 14%, no more than 60% × 45%.
  const minWPct = 22, minHPct = 14, maxWPct = 60, maxHPct = 45;
  if (w < minWPct) {
    const grow = (minWPct - w) / 2;
    x = Math.max(0, x - grow);
    w = Math.min(100 - x, minWPct);
  }
  if (h < minHPct) {
    const grow = (minHPct - h) / 2;
    y = Math.max(0, y - grow);
    h = Math.min(100 - y, minHPct);
  }
  if (w > maxWPct) w = maxWPct;
  if (h > maxHPct) h = maxHPct;

  // Pixel coordinates on the rendered canvas.
  const px = Math.round((x / 100) * widthPx);
  const py = Math.round((y / 100) * heightPx);
  const pw = Math.round((w / 100) * widthPx);
  const ph = Math.round((h / 100) * heightPx);

  const out = document.createElement("canvas");
  out.width = pw;
  out.height = ph;
  const octx = out.getContext("2d")!;
  octx.drawImage(canvas, px, py, pw, ph, 0, 0, pw, ph);

  // If we found a hit, draw a soft highlight box on top of the crop so the
  // reviewer's eye lands on the exact quoted text.
  if (hit) {
    const itemPxX = (hit.x / 100) * widthPx - px - ((hit.width / 100) * widthPx) / 2;
    const itemPxY = (hit.y / 100) * heightPx - py - ((hit.height / 100) * heightPx) / 2;
    const itemPxW = Math.max(20, (hit.width / 100) * widthPx);
    const itemPxH = Math.max(14, (hit.height / 100) * heightPx);
    octx.save();
    octx.fillStyle = "rgba(234, 179, 8, 0.18)"; // amber/200ish
    octx.fillRect(itemPxX, itemPxY, itemPxW, itemPxH);
    octx.lineWidth = 2;
    octx.strokeStyle = "rgba(217, 119, 6, 0.95)"; // amber/600
    octx.strokeRect(itemPxX, itemPxY, itemPxW, itemPxH);
    octx.restore();
  }

  const base64 = out.toDataURL("image/png");

  // Cleanup canvases.
  canvas.width = 0;
  canvas.height = 0;
  out.width = 0;
  out.height = 0;

  return {
    base64,
    bbox: { x, y, w, h },
    pageWidthPx: widthPx,
    pageHeightPx: heightPx,
    matched: !!hit,
  };
}

/**
 * Convert a `data:image/png;base64,...` string into a Blob suitable for
 * `supabase.storage.from(bucket).upload(...)`.
 */
export function dataUrlToBlob(dataUrl: string): Blob {
  const [header, b64] = dataUrl.split(",");
  const mime = /data:(.*?);base64/.exec(header)?.[1] ?? "image/png";
  const binary = atob(b64);
  const len = binary.length;
  const bytes = new Uint8Array(len);
  for (let i = 0; i < len; i++) bytes[i] = binary.charCodeAt(i);
  return new Blob([bytes], { type: mime });
}
