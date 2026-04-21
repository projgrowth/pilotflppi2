// Shared helper to scroll a finding card into view and briefly highlight it.
// Used by the dedupe audit trail to jump from a merge entry to the underlying
// deficiency card on the Deficiencies tab.
export function scrollToFinding(id: string, opts?: { delayMs?: number }) {
  const delay = opts?.delayMs ?? 0;
  window.setTimeout(() => {
    const el = document.getElementById(`finding-${id}`);
    if (!el) return;
    el.scrollIntoView({ behavior: "smooth", block: "start" });
    el.classList.add("ring-2", "ring-primary", "ring-offset-2");
    window.setTimeout(() => {
      el.classList.remove("ring-2", "ring-primary", "ring-offset-2");
    }, 1800);
  }, delay);
}
