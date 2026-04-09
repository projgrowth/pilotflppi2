import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { supabase } from "@/integrations/supabase/client";
import { useAuth } from "@/contexts/AuthContext";
import { toast } from "sonner";

export interface Invoice {
  id: string;
  user_id: string;
  project_id: string;
  contractor_id: string | null;
  invoice_number: string;
  status: string;
  issued_at: string | null;
  due_at: string | null;
  paid_at: string | null;
  subtotal: number;
  tax_rate: number;
  tax_amount: number;
  total: number;
  amount_paid: number;
  notes: string;
  custom_footer: string;
  created_at: string;
  updated_at: string;
  // joined
  project?: { name: string; address: string };
  contractor?: { name: string; email: string | null };
}

export interface InvoiceLineItem {
  id: string;
  invoice_id: string;
  description: string;
  quantity: number;
  unit_price: number;
  total: number;
  service_type: string | null;
  sort_order: number;
  created_at: string;
}

export function useInvoices() {
  const { user } = useAuth();
  return useQuery({
    queryKey: ["invoices"],
    queryFn: async () => {
      const { data, error } = await supabase
        .from("invoices" as any)
        .select("*, project:projects(name, address), contractor:contractors(name, email)")
        .order("created_at", { ascending: false });
      if (error) throw error;
      return (data || []) as unknown as Invoice[];
    },
    enabled: !!user,
  });
}

export function useProjectInvoices(projectId: string | undefined) {
  const { user } = useAuth();
  return useQuery({
    queryKey: ["invoices", "project", projectId],
    queryFn: async () => {
      const { data, error } = await supabase
        .from("invoices" as any)
        .select("*, contractor:contractors(name, email)")
        .eq("project_id", projectId!)
        .order("created_at", { ascending: false });
      if (error) throw error;
      return (data || []) as unknown as Invoice[];
    },
    enabled: !!user && !!projectId,
  });
}

export function useInvoiceLineItems(invoiceId: string | undefined) {
  return useQuery({
    queryKey: ["invoice-line-items", invoiceId],
    queryFn: async () => {
      const { data, error } = await supabase
        .from("invoice_line_items" as any)
        .select("*")
        .eq("invoice_id", invoiceId!)
        .order("sort_order");
      if (error) throw error;
      return (data || []) as unknown as InvoiceLineItem[];
    },
    enabled: !!invoiceId,
  });
}

export function useCreateInvoice() {
  const { user } = useAuth();
  const qc = useQueryClient();
  return useMutation({
    mutationFn: async (params: {
      project_id: string;
      contractor_id?: string | null;
      invoice_number: string;
      due_at?: string | null;
      notes?: string;
      tax_rate?: number;
      custom_footer?: string;
      line_items: { description: string; quantity: number; unit_price: number; service_type?: string; sort_order: number }[];
    }) => {
      if (!user) throw new Error("Not authenticated");
      const { line_items, ...invoiceData } = params;
      const subtotal = line_items.reduce((s, li) => s + li.quantity * li.unit_price, 0);
      const taxRate = invoiceData.tax_rate || 0;
      const taxAmount = Math.round(subtotal * taxRate * 100) / 100;
      const total = subtotal + taxAmount;

      const { data: inv, error } = await supabase
        .from("invoices" as any)
        .insert({
          ...invoiceData,
          user_id: user.id,
          subtotal,
          tax_amount: taxAmount,
          total,
          status: "draft",
        })
        .select("id")
        .single();
      if (error) throw error;

      const invoiceId = (inv as any).id;
      if (line_items.length > 0) {
        const rows = line_items.map((li) => ({
          invoice_id: invoiceId,
          description: li.description,
          quantity: li.quantity,
          unit_price: li.unit_price,
          total: li.quantity * li.unit_price,
          service_type: li.service_type || null,
          sort_order: li.sort_order,
        }));
        const { error: liErr } = await supabase.from("invoice_line_items" as any).insert(rows);
        if (liErr) throw liErr;
      }
      return invoiceId as string;
    },
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ["invoices"] });
      toast.success("Invoice created");
    },
    onError: (err) => toast.error(err instanceof Error ? err.message : "Failed to create invoice"),
  });
}

export function useUpdateInvoice() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: async ({ id, ...updates }: Partial<Invoice> & { id: string }) => {
      const { project, contractor, user_id, created_at, updated_at, ...rest } = updates as any;
      const { error } = await supabase
        .from("invoices" as any)
        .update(rest)
        .eq("id", id);
      if (error) throw error;
    },
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ["invoices"] });
      toast.success("Invoice updated");
    },
    onError: (err) => toast.error(err instanceof Error ? err.message : "Failed to update"),
  });
}

export function useDeleteInvoice() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: async (id: string) => {
      const { error } = await supabase.from("invoices" as any).delete().eq("id", id);
      if (error) throw error;
    },
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ["invoices"] });
      toast.success("Invoice deleted");
    },
    onError: (err) => toast.error(err instanceof Error ? err.message : "Failed to delete"),
  });
}

export function useGenerateInvoiceNumber() {
  return useMutation({
    mutationFn: async () => {
      const { data, error } = await supabase.rpc("generate_invoice_number" as any);
      if (error) throw error;
      return data as string;
    },
  });
}

// Revenue stats for dashboard
export function useRevenueStats() {
  const { user } = useAuth();
  return useQuery({
    queryKey: ["revenue-stats"],
    queryFn: async () => {
      const { data: invoices, error } = await supabase
        .from("invoices" as any)
        .select("status, total, amount_paid, paid_at, due_at");
      if (error) throw error;
      const all = (invoices || []) as any[];
      const now = new Date();
      const monthStart = new Date(now.getFullYear(), now.getMonth(), 1).toISOString();

      const revenueMTD = all
        .filter((i) => i.status === "paid" && i.paid_at && i.paid_at >= monthStart)
        .reduce((s, i) => s + Number(i.amount_paid || 0), 0);

      const outstanding = all
        .filter((i) => ["sent", "partial"].includes(i.status))
        .reduce((s, i) => s + (Number(i.total || 0) - Number(i.amount_paid || 0)), 0);

      const overdue = all
        .filter((i) => ["sent", "partial"].includes(i.status) && i.due_at && new Date(i.due_at) < now)
        .reduce((s, i) => s + (Number(i.total || 0) - Number(i.amount_paid || 0)), 0);

      const overdueCount = all.filter((i) => ["sent", "partial"].includes(i.status) && i.due_at && new Date(i.due_at) < now).length;

      return { revenueMTD, outstanding, overdue, overdueCount };
    },
    enabled: !!user,
  });
}
