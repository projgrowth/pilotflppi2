import { useState, useMemo } from "react";
import { useNavigate } from "react-router-dom";
import { useInvoices, useUpdateInvoice, Invoice } from "@/hooks/useInvoices";
import { PageHeader } from "@/components/PageHeader";
import { Card } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Badge } from "@/components/ui/badge";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { InvoiceEditor } from "@/components/InvoiceEditor";
import { EmptyState } from "@/components/EmptyState";
import { FileText, Search, DollarSign } from "lucide-react";
import { format } from "date-fns";

const STATUS_OPTIONS = [
  { value: "all", label: "All Statuses" },
  { value: "draft", label: "Draft" },
  { value: "sent", label: "Sent" },
  { value: "paid", label: "Paid" },
  { value: "partial", label: "Partial" },
  { value: "overdue", label: "Overdue" },
  { value: "void", label: "Void" },
];

const statusColors: Record<string, string> = {
  draft: "bg-muted text-muted-foreground",
  sent: "bg-blue-100 text-blue-800 dark:bg-blue-900/30 dark:text-blue-300",
  paid: "bg-green-100 text-green-800 dark:bg-green-900/30 dark:text-green-300",
  partial: "bg-amber-100 text-amber-800 dark:bg-amber-900/30 dark:text-amber-300",
  overdue: "bg-destructive/10 text-destructive",
  void: "bg-muted text-muted-foreground line-through",
};

export default function Invoices() {
  const navigate = useNavigate();
  const { data: invoices, isLoading } = useInvoices();
  const updateMutation = useUpdateInvoice();
  const [statusFilter, setStatusFilter] = useState("all");
  const [search, setSearch] = useState("");
  const [editingInvoice, setEditingInvoice] = useState<Invoice | null>(null);

  const filtered = useMemo(() => {
    let list = invoices || [];

    // Auto-mark overdue
    const now = new Date();
    list = list.map((inv) => {
      if (["sent", "partial"].includes(inv.status) && inv.due_at && new Date(inv.due_at) < now) {
        return { ...inv, status: "overdue" };
      }
      return inv;
    });

    if (statusFilter !== "all") {
      list = list.filter((i) => i.status === statusFilter);
    }
    if (search.trim()) {
      const q = search.toLowerCase();
      list = list.filter(
        (i) =>
          i.invoice_number.toLowerCase().includes(q) ||
          i.project?.name?.toLowerCase().includes(q) ||
          i.contractor?.name?.toLowerCase().includes(q)
      );
    }
    return list;
  }, [invoices, statusFilter, search]);

  const totalOutstanding = filtered
    .filter((i) => ["sent", "partial", "overdue"].includes(i.status))
    .reduce((s, i) => s + (Number(i.total || 0) - Number(i.amount_paid || 0)), 0);

  return (
    <div className="p-8 md:p-10 max-w-6xl">
      <PageHeader
        title="Invoices"
        subtitle={`${filtered.length} invoice${filtered.length !== 1 ? "s" : ""} · $${totalOutstanding.toLocaleString("en-US", { minimumFractionDigits: 2 })} outstanding`}
      />

      {/* Filters */}
      <div className="flex items-center gap-3 mb-6">
        <div className="relative flex-1 max-w-xs">
          <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-muted-foreground" />
          <Input
            placeholder="Search invoices..."
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            className="pl-9 text-sm"
          />
        </div>
        <Select value={statusFilter} onValueChange={setStatusFilter}>
          <SelectTrigger className="w-[150px] text-sm">
            <SelectValue />
          </SelectTrigger>
          <SelectContent>
            {STATUS_OPTIONS.map((o) => (
              <SelectItem key={o.value} value={o.value}>{o.label}</SelectItem>
            ))}
          </SelectContent>
        </Select>
      </div>

      {isLoading ? (
        <div className="space-y-3">
          {Array.from({ length: 5 }).map((_, i) => (
            <div key={i} className="h-16 rounded bg-muted animate-pulse" />
          ))}
        </div>
      ) : filtered.length === 0 ? (
        <EmptyState
          icon={FileText}
          title="No invoices"
          description={search || statusFilter !== "all" ? "Try adjusting your filters" : "Invoices will appear here when created from project billing tabs"}
        />
      ) : (
        <Card className="shadow-subtle">
          <div className="grid grid-cols-[1fr_120px_100px_100px] gap-2 px-5 py-3 border-b text-[11px] font-semibold text-muted-foreground uppercase tracking-wider">
            <span>Invoice / Project</span>
            <span>Status</span>
            <span className="text-right">Total</span>
            <span className="text-right">Balance</span>
          </div>
          <div className="divide-y">
            {filtered.map((inv) => {
              const balance = Number(inv.total || 0) - Number(inv.amount_paid || 0);
              return (
                <div
                  key={inv.id}
                  className="grid grid-cols-[1fr_120px_100px_100px] gap-2 items-center px-5 py-3 hover:bg-muted/30 transition-colors cursor-pointer"
                  onClick={() => setEditingInvoice(inv)}
                >
                  <div className="min-w-0">
                    <p className="text-sm font-medium font-mono">{inv.invoice_number}</p>
                    <p className="text-xs text-muted-foreground truncate">
                      {inv.project?.name || "—"}
                      {inv.contractor?.name && ` · ${inv.contractor.name}`}
                    </p>
                    {inv.due_at && <p className="text-[10px] text-muted-foreground">Due {format(new Date(inv.due_at), "MMM d")}</p>}
                  </div>
                  <Badge className={`text-[10px] w-fit ${statusColors[inv.status] || ""}`}>{inv.status}</Badge>
                  <span className="text-sm font-mono text-right">${Number(inv.total).toLocaleString("en-US", { minimumFractionDigits: 2 })}</span>
                  <span className={`text-sm font-mono text-right ${balance > 0 ? "text-amber-600" : "text-green-600"}`}>
                    ${balance.toLocaleString("en-US", { minimumFractionDigits: 2 })}
                  </span>
                </div>
              );
            })}
          </div>
        </Card>
      )}

      {editingInvoice && (
        <InvoiceEditor
          invoice={editingInvoice}
          open={!!editingInvoice}
          onOpenChange={(open) => !open && setEditingInvoice(null)}
        />
      )}
    </div>
  );
}
