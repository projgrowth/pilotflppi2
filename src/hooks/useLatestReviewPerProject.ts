/**
 * Returns a map of projectId → most-recent plan_review id.
 * Used by Dashboard and Review to route clicks on project cards/rows to the
 * correct destination (/plan-review/:id/dashboard or /review/:projectId).
 *
 * Shared query key "latest-plan-reviews" means one cache entry is reused
 * across all consumers — zero duplicate network requests.
 */
import { useQuery } from "@tanstack/react-query";
import { supabase } from "@/integrations/supabase/client";

export function useLatestReviewPerProject(): Record<string, string> {
  const { data } = useQuery({
    queryKey: ["latest-plan-reviews"],
    queryFn: async () => {
      const { data, error } = await supabase
        .from("plan_reviews")
        .select("id, project_id, round")
        .order("round", { ascending: false });
      if (error) throw error;
      const map: Record<string, string> = {};
      for (const r of data ?? []) {
        if (!map[r.project_id]) map[r.project_id] = r.id;
      }
      return map;
    },
    staleTime: 30_000,
  });
  return data ?? {};
}
