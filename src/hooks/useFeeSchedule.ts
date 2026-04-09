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
        .from("fee_schedules" as any)
        .select("*")
        .order("service_type")
        .order("trade_type");
      if (error) throw error;
      return (data || []) as unknown as FeeSchedule[];
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
        const { id, user_id, created_at, updated_at, ...rest } = fee as any;
        const { error } = await supabase
          .from("fee_schedules" as any)
          .update(rest)
          .eq("id", id);
        if (error) throw error;
      } else {
        const { error } = await supabase
          .from("fee_schedules" as any)
          .insert({ ...fee, user_id: user.id });
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
        .from("fee_schedules" as any)
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
