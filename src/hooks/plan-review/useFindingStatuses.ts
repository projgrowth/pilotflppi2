/**
 * Per-finding triage status (open/resolved/deferred) with direct persistence
 * to deficiencies_v2.status on the individual row.
 *
 * Previously this wrote to plan_reviews.finding_statuses (a JSONB blob keyed
 * by integer index). That approach caused a race condition: two browser tabs
 * would each read the blob, update their copy, and overwrite each other.
 *
 * Now each status toggle issues a targeted UPDATE to the deficiency row by
 * its UUID, which is safe under concurrent access. The integer-index interface
 * is preserved so no other files need to change.
 *
 * Status is initialised from the findings already loaded by usePlanReviewData
 * (which reads deficiencies_v2.status). The legacy finding_statuses JSONB on
 * plan_reviews is no longer read or written.
 */
import { useCallback, useEffect, useRef, useState } from "react";
import { supabase } from "@/integrations/supabase/client";
import { logFindingStatusChange } from "@/hooks/useFindingHistory";
import type { FindingStatus } from "@/components/FindingStatusFilter";
import type { Finding } from "@/components/FindingCard";

export function useFindingStatuses(
  review: { id: string } | undefined,
  userId: string | undefined,
  refetchHistory: () => void,
  findings: Finding[] = [],
) {
  const [findingStatuses, setFindingStatuses] = useState<Record<number, FindingStatus>>({});

  // Hydrate from the loaded findings (deficiencies_v2.status via adapter).
  // Re-run whenever the finding list changes (new pipeline run, realtime push).
  useEffect(() => {
    const loaded: Record<number, FindingStatus> = {};
    findings.forEach((f, i) => {
      loaded[i] = f.resolved ? "resolved" : "open";
    });
    setFindingStatuses(loaded);
  }, [findings]);

  const saveTimer = useRef<ReturnType<typeof setTimeout> | null>(null);

  const persistStatus = useCallback(
    (deficiencyId: string, status: FindingStatus) => {
      if (saveTimer.current) clearTimeout(saveTimer.current);
      saveTimer.current = setTimeout(async () => {
        // "deferred" → stored as "waived" in deficiencies_v2 (matches DB enum)
        const dbStatus = status === "deferred" ? "waived" : status;
        await supabase
          .from("deficiencies_v2")
          .update({ status: dbStatus, updated_at: new Date().toISOString() })
          .eq("id", deficiencyId);
      }, 600);
    },
    [],
  );

  const updateFindingStatus = useCallback(
    (index: number, status: FindingStatus) => {
      const deficiencyId = findings[index]?.finding_id;
      setFindingStatuses((prev) => {
        const oldStatus = prev[index] ?? "open";
        if (oldStatus === status) return prev;
        const next = { ...prev, [index]: status };
        if (deficiencyId) {
          persistStatus(deficiencyId, status);
        }
        if (review && userId && oldStatus !== status) {
          logFindingStatusChange(review.id, index, oldStatus, status, userId).then(
            () => refetchHistory(),
          );
        }
        return next;
      });
    },
    [findings, review, userId, persistStatus, refetchHistory],
  );

  return { findingStatuses, updateFindingStatus };
}
