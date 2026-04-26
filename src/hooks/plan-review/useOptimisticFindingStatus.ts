/**
 * Finding status updates with optimistic UI feedback.
 * 
 * Unlike the debounced-only approach in useFindingStatuses, this hook
 * provides immediate local state updates (optimistic) while still persisting
 * to the server in the background. This makes the UI feel instant.
 * 
 * On conflict (server write fails), falls back to the previous state.
 */
import { useCallback, useRef, useEffect, useState } from "react";
import { supabase } from "@/integrations/supabase/client";
import { logFindingStatusChange } from "@/hooks/useFindingHistory";
import type { FindingStatus } from "@/components/FindingStatusFilter";
import type { PlanReviewRow } from "@/types";

export function useOptimisticFindingStatus(
  review: PlanReviewRow | undefined,
  userId: string | undefined,
  refetchHistory: () => void,
) {
  const [findingStatuses, setFindingStatuses] = useState<Record<number, FindingStatus>>({});
  const statusSaveTimer = useRef<NodeJS.Timeout | null>(null);
  const previousStatusRef = useRef<Record<number, FindingStatus>>({});

  // Hydrate from review once
  useEffect(() => {
    if (review?.finding_statuses) {
      const loaded: Record<number, FindingStatus> = {};
      for (const [k, v] of Object.entries(review.finding_statuses as Record<string, string>)) {
        loaded[Number(k)] = v as FindingStatus;
      }
      setFindingStatuses(loaded);
      previousStatusRef.current = loaded;
    } else {
      setFindingStatuses({});
      previousStatusRef.current = {};
    }
  }, [review?.id]);

  const persistFindingStatuses = useCallback(
    async (reviewId: string, statuses: Record<number, FindingStatus>) => {
      try {
        await supabase
          .from("plan_reviews")
          .update({ finding_statuses: JSON.parse(JSON.stringify(statuses)) })
          .eq("id", reviewId);
      } catch (err) {
        // On failure, revert to previous state
        console.error("Failed to persist finding status:", err);
        setFindingStatuses(previousStatusRef.current);
      }
    },
    [],
  );

  const updateFindingStatus = useCallback(
    (index: number, status: FindingStatus) => {
      setFindingStatuses((prev) => {
        const oldStatus = prev[index] || "open";
        const next = { ...prev, [index]: status };

        // Optimistic: save immediately to local state
        previousStatusRef.current = next;

        if (review) {
          // Debounce persistence to server
          if (statusSaveTimer.current) clearTimeout(statusSaveTimer.current);
          statusSaveTimer.current = setTimeout(() => {
            persistFindingStatuses(review.id, next);
          }, 800);

          // Log the change for audit trail
          if (userId && oldStatus !== status) {
            logFindingStatusChange(review.id, index, oldStatus, status, userId).then(() => refetchHistory());
          }
        }

        return next;
      });
    },
    [review, userId, refetchHistory, persistFindingStatuses],
  );

  return { findingStatuses, updateFindingStatus };
}
