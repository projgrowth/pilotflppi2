/**
 * PDF rendering pipeline for the plan-review viewer.
 *
 * Handles the messy bits — signing storage URLs, normalising legacy public
 * URL entries, capping at 10 pages per file, attaching file/page provenance
 * — and exposes a single `renderDocumentPages(review)` call plus the
 * progress + cap-info state the banner needs.
 */
import { useCallback, useState } from "react";
import { supabase } from "@/integrations/supabase/client";
import { renderPDFPagesToImages, getPDFPageCount, type PDFPageImage } from "@/lib/pdf-utils";
import type { PlanReviewRow } from "@/types";

export function usePdfPageRender() {
  const [pageImages, setPageImages] = useState<PDFPageImage[]>([]);
  const [pageCapInfo, setPageCapInfo] = useState<{ total: number; rendered: number } | null>(null);
  const [renderingPages, setRenderingPages] = useState(false);
  const [renderProgress, setRenderProgress] = useState(0);

  const renderDocumentPages = useCallback(async (r: PlanReviewRow): Promise<PDFPageImage[]> => {
    if (!r.file_urls || r.file_urls.length === 0) return [];
    setRenderingPages(true);
    setRenderProgress(0);
    try {
      const allImages: PDFPageImage[] = [];
      let totalSheetsAcrossFiles = 0;
      let renderedSheetsAcrossFiles = 0;
      for (let fi = 0; fi < r.file_urls.length; fi++) {
        const storedPath = r.file_urls[fi];
        if (!storedPath) continue;
        // Legacy entries stored full public URLs; new entries store storage paths.
        const filePath = storedPath.includes("/storage/v1/")
          ? storedPath.split("/documents/").pop() || storedPath
          : storedPath;
        const { data: signedData, error: signError } = await supabase.storage
          .from("documents")
          .createSignedUrl(filePath, 3600);
        if (signError || !signedData?.signedUrl) continue;
        const response = await fetch(signedData.signedUrl);
        const blob = await response.blob();
        const fileName = decodeURIComponent(filePath.split("/").pop() || `doc-${fi}.pdf`);
        const file = new File([blob], fileName, { type: "application/pdf" });

        try {
          const total = await getPDFPageCount(file);
          totalSheetsAcrossFiles += total;
          renderedSheetsAcrossFiles += Math.min(total, 10);
        } catch {
          // If page count fails, fall through; render still attempts.
        }

        const images = await renderPDFPagesToImages(file, 10, 150);
        const baseIndex = allImages.length;
        allImages.push(
          ...images.map((img, idx) => ({
            ...img,
            pageIndex: baseIndex + idx,
            fileIndex: fi,
            fileName,
            pageInFile: idx + 1,
          })),
        );
        setRenderProgress(((fi + 1) / r.file_urls.length) * 100);
      }
      setPageImages(allImages);
      setPageCapInfo({ total: totalSheetsAcrossFiles, rendered: renderedSheetsAcrossFiles });
      return allImages;
    } catch {
      return [];
    } finally {
      setRenderingPages(false);
    }
  }, []);

  return {
    pageImages,
    pageCapInfo,
    renderingPages,
    renderProgress,
    renderDocumentPages,
    resetPages: useCallback(() => {
      setPageImages([]);
      setPageCapInfo(null);
    }, []),
  };
}
