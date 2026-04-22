/**
 * Per-finding triage status (open/resolved/deferred) with debounced JSONB
 * persistence to plan_reviews.finding_statuses, and audit-trail logging on
 * each transition.
 *
 * Hydrates from the review row once when it loads; thereafter the local
 * state is the source of truth and writes are debounced 800ms.
 */
import { useCallback, useEffect, useRef, useState } from "react";
import { supabase } from "@/integrations/supabase/client";
import { logFindingStatusChange } from "@/hooks/useFindingHistory";
import type { FindingStatus } from "@/components/FindingStatusFilter";
import type { PlanReviewRow } from "@/types";

export function useFindingStatuses(
  review: PlanReviewRow | undefined,
  userId: string | undefined,
  refetchHistory: () => void,
) {
  const [findingStatuses, setFindingStatuses] = useState<Record<number, FindingStatus>>({});

  useEffect(() => {
    if (review?.finding_statuses) {
      const loaded: Record<number, FindingStatus> = {};
      for (const [k, v] of Object.entries(review.finding_statuses as Record<string, string>)) {
        loaded[Number(k)] = v as FindingStatus;
      }
      setFindingStatuses(loaded);
    } else {
      setFindingStatuses({});
    }
  }, [review?.id]);

  const statusSaveTimer = useRef<NodeJS.Timeout | null>(null);
  const persistFindingStatuses = useCallback((reviewId: string, statuses: Record<number, FindingStatus>) => {
    if (statusSaveTimer.current) clearTimeout(statusSaveTimer.current);
    statusSaveTimer.current = setTimeout(async () => {
      await supabase
        .from("plan_reviews")
        .update({ finding_statuses: JSON.parse(JSON.stringify(statuses)) })
        .eq("id", reviewId);
    }, 800);
  }, []);

  const updateFindingStatus = useCallback(
    (index: number, status: FindingStatus) => {
      setFindingStatuses((prev) => {
        const oldStatus = prev[index] || "open";
        const next = { ...prev, [index]: status };
        if (review) {
          persistFindingStatuses(review.id, next);
          if (userId && oldStatus !== status) {
            logFindingStatusChange(review.id, index, oldStatus, status, userId).then(() => refetchHistory());
          }
        }
        return next;
      });
    },
    [review, persistFindingStatuses, userId, refetchHistory],
  );

  return { findingStatuses, updateFindingStatus };
}
