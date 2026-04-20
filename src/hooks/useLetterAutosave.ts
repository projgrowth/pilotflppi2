import { useEffect, useRef, useState } from "react";
import { supabase } from "@/integrations/supabase/client";

type SaveState = "idle" | "saving" | "saved" | "error";

/**
 * Debounced autosave for the comment letter draft. Persists to
 * `plan_reviews.comment_letter_draft` 1.5s after the last edit.
 *
 * - `dirty` is true while a pending save is queued or in-flight.
 *   Used by the route guard to block tab close / navigation.
 * - `lastSavedAt` drives the "Saved · 4s ago" UI hint.
 */
export function useLetterAutosave(reviewId: string | undefined, value: string, enabled = true) {
  const [state, setState] = useState<SaveState>("idle");
  const [lastSavedAt, setLastSavedAt] = useState<Date | null>(null);
  const [dirty, setDirty] = useState(false);

  const lastSavedValueRef = useRef<string | null>(null);
  const initializedRef = useRef(false);
  const timerRef = useRef<ReturnType<typeof setTimeout> | null>(null);

  // When the review id changes (new review loaded), reset baseline so the next
  // save compares against THIS review's existing draft, not the prior one.
  useEffect(() => {
    initializedRef.current = false;
    lastSavedValueRef.current = null;
    setState("idle");
    setLastSavedAt(null);
    setDirty(false);
  }, [reviewId]);

  useEffect(() => {
    if (!enabled || !reviewId) return;
    // First render after value is hydrated from DB — treat as baseline, no save.
    if (!initializedRef.current) {
      initializedRef.current = true;
      lastSavedValueRef.current = value;
      return;
    }
    if (value === lastSavedValueRef.current) {
      setDirty(false);
      return;
    }
    setDirty(true);
    if (timerRef.current) clearTimeout(timerRef.current);
    timerRef.current = setTimeout(async () => {
      setState("saving");
      const { error } = await supabase
        .from("plan_reviews")
        .update({ comment_letter_draft: value })
        .eq("id", reviewId);
      if (error) {
        setState("error");
      } else {
        lastSavedValueRef.current = value;
        setState("saved");
        setLastSavedAt(new Date());
        setDirty(false);
      }
    }, 1500);

    return () => {
      if (timerRef.current) clearTimeout(timerRef.current);
    };
  }, [value, reviewId, enabled]);

  // Block tab close / refresh if we have unsaved edits.
  useEffect(() => {
    if (!dirty) return;
    const handler = (e: BeforeUnloadEvent) => {
      e.preventDefault();
      e.returnValue = "";
    };
    window.addEventListener("beforeunload", handler);
    return () => window.removeEventListener("beforeunload", handler);
  }, [dirty]);

  return { state, lastSavedAt, dirty };
}
