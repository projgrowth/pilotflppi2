import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { supabase } from "@/integrations/supabase/client";
import { useAuth } from "@/contexts/AuthContext";
import { toast } from "sonner";

export interface FeeSchedule {
  id: string;
  user_id: string;
  service_type: string;
  trade_type: string;
  county: string;
  base_fee: number;
  description: string;
  is_active: boolean;
  created_at: string;
  updated_at: string;
}

export function useFeeSchedules() {
  const { user } = useAuth();
  return useQuery({
    queryKey: ["fee-schedules", user?.id],
    queryFn: async () => {
      const { data, error } = await supabase
        .from("fee_schedules")
        .select("*")
        .order("service_type")
        .order("trade_type");
      if (error) throw error;
      return (data || []) as FeeSchedule[];
    },
    enabled: !!user,
  });
}

export function useSaveFeeSchedule() {
  const { user } = useAuth();
  const qc = useQueryClient();

  return useMutation({
    mutationFn: async (fee: Partial<FeeSchedule> & { id?: string }) => {
      if (!user) throw new Error("Not authenticated");
      if (fee.id) {
        const { id, user_id: _uid, created_at: _ca, updated_at: _ua, ...rest } = fee;
        const { error } = await supabase
          .from("fee_schedules")
          .update(rest)
          .eq("id", id);
        if (error) throw error;
      } else {
        const { error } = await supabase
          .from("fee_schedules")
          .insert({
            service_type: fee.service_type ?? "plan_review",
            trade_type: fee.trade_type ?? "building",
            county: fee.county ?? "",
            base_fee: fee.base_fee ?? 0,
            description: fee.description ?? "",
            is_active: fee.is_active ?? true,
            user_id: user.id,
          });
        if (error) throw error;
      }
    },
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ["fee-schedules"] });
      toast.success("Fee schedule saved");
    },
    onError: (err) => toast.error(err instanceof Error ? err.message : "Failed to save"),
  });
}

export function useDeleteFeeSchedule() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: async (id: string) => {
      const { error } = await supabase
        .from("fee_schedules")
        .delete()
        .eq("id", id);
      if (error) throw error;
    },
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ["fee-schedules"] });
      toast.success("Fee deleted");
    },
    onError: (err) => toast.error(err instanceof Error ? err.message : "Failed to delete"),
  });
}
