import { toast } from "sonner";

/**
 * Render an HTML string into a hidden iframe and trigger the browser print
 * dialog. Falls back to a `.html` download if the print dialog is blocked
 * or the iframe never finishes loading.
 *
 * Uses `srcdoc` so synchronous-loading documents (very small HTML) still
 * fire the `onload` handler we attached *before* loading the document.
 */
export function printViaIframe(html: string, fallbackFilename = "document.html"): void {
  const iframe = document.createElement("iframe");
  iframe.style.position = "fixed";
  iframe.style.left = "-9999px";
  iframe.style.top = "-9999px";
  iframe.style.width = "0";
  iframe.style.height = "0";
  iframe.setAttribute("aria-hidden", "true");

  let cleaned = false;
  const cleanup = () => {
    if (cleaned) return;
    cleaned = true;
    if (safetyTimer) clearTimeout(safetyTimer);
    if (iframe.parentNode) iframe.parentNode.removeChild(iframe);
  };

  const downloadFallback = () => {
    try {
      const blob = new Blob([html], { type: "text/html" });
      const url = URL.createObjectURL(blob);
      const a = document.createElement("a");
      a.href = url;
      a.download = fallbackFilename;
      a.click();
      URL.revokeObjectURL(url);
      toast.message("Print dialog blocked — file downloaded instead.");
    } catch {
      toast.error("Could not open print dialog or download file.");
    }
  };

  // Safety timer in case onload never fires (some browsers + srcdoc edge cases)
  const safetyTimer = setTimeout(() => {
    if (cleaned) return;
    downloadFallback();
    cleanup();
  }, 10_000);

  // Attach onload BEFORE setting srcdoc so we never miss synchronous loads.
  iframe.onload = () => {
    setTimeout(() => {
      try {
        iframe.contentWindow?.focus();
        iframe.contentWindow?.print();
        // Give the print dialog time to grab the document, then clean up.
        setTimeout(cleanup, 1500);
      } catch {
        downloadFallback();
        cleanup();
      }
    }, 200);
  };

  document.body.appendChild(iframe);
  // Prefer srcdoc for synchronous-friendly loading.
  iframe.srcdoc = html;

  toast.info('Select "Save as PDF" in the print dialog to download.');
}
