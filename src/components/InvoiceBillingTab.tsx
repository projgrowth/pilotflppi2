import { useState } from "react";
import { useProjectInvoices, useUpdateInvoice, useDeleteInvoice, Invoice } from "@/hooks/useInvoices";
import { Card, CardContent } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { GenerateInvoiceDialog } from "@/components/GenerateInvoiceDialog";
import { InvoiceEditor } from "@/components/InvoiceEditor";
import { Plus, FileText, DollarSign } from "lucide-react";
import { format } from "date-fns";

const statusColors: Record<string, string> = {
  draft: "bg-muted text-muted-foreground",
  sent: "bg-blue-100 text-blue-800 dark:bg-blue-900/30 dark:text-blue-300",
  paid: "bg-green-100 text-green-800 dark:bg-green-900/30 dark:text-green-300",
  partial: "bg-amber-100 text-amber-800 dark:bg-amber-900/30 dark:text-amber-300",
  overdue: "bg-destructive/10 text-destructive",
  void: "bg-muted text-muted-foreground line-through",
};

export function InvoiceBillingTab({ projectId, contractorId }: { projectId: string; contractorId?: string | null }) {
  const { data: invoices, isLoading } = useProjectInvoices(projectId);
  const [generateOpen, setGenerateOpen] = useState(false);
  const [editingInvoice, setEditingInvoice] = useState<Invoice | null>(null);
  const updateMutation = useUpdateInvoice();
  const deleteMutation = useDeleteInvoice();

  const totalBilled = (invoices || []).filter((i) => i.status !== "void").reduce((s, i) => s + Number(i.total || 0), 0);
  const totalPaid = (invoices || []).filter((i) => i.status !== "void").reduce((s, i) => s + Number(i.amount_paid || 0), 0);

  if (isLoading) {
    return <div className="space-y-3">{Array.from({ length: 2 }).map((_, i) => <div key={i} className="h-16 rounded bg-muted animate-pulse" />)}</div>;
  }

  return (
    <>
      <Card className="shadow-subtle">
        <CardContent className="p-5">
          <div className="flex items-center justify-between mb-4">
            <h3 className="text-[11px] font-semibold text-muted-foreground uppercase tracking-wider">Billing</h3>
            <Button size="sm" variant="outline" onClick={() => setGenerateOpen(true)}>
              <Plus className="h-3.5 w-3.5 mr-1" /> New Invoice
            </Button>
          </div>

          {/* Summary */}
          <div className="grid grid-cols-2 gap-4 mb-5">
            <div className="rounded-lg bg-muted/30 p-3">
              <p className="text-[10px] text-muted-foreground uppercase tracking-wider">Total Billed</p>
              <p className="text-lg font-semibold font-mono">${totalBilled.toLocaleString("en-US", { minimumFractionDigits: 2 })}</p>
            </div>
            <div className="rounded-lg bg-muted/30 p-3">
              <p className="text-[10px] text-muted-foreground uppercase tracking-wider">Total Paid</p>
              <p className="text-lg font-semibold font-mono text-green-600">${totalPaid.toLocaleString("en-US", { minimumFractionDigits: 2 })}</p>
            </div>
          </div>

          {/* Invoice list */}
          {(invoices || []).length === 0 ? (
            <div className="text-center py-8">
              <FileText className="h-8 w-8 text-muted-foreground/30 mx-auto mb-2" />
              <p className="text-sm text-muted-foreground">No invoices yet</p>
              <p className="text-xs text-muted-foreground mt-1">Generate an invoice to start billing for this project</p>
            </div>
          ) : (
            <div className="divide-y rounded-md border">
              {(invoices || []).map((inv) => (
                <div
                  key={inv.id}
                  className="flex items-center justify-between px-4 py-3 hover:bg-muted/30 transition-colors cursor-pointer"
                  onClick={() => setEditingInvoice(inv)}
                >
                  <div className="min-w-0">
                    <div className="flex items-center gap-2">
                      <span className="text-sm font-medium font-mono">{inv.invoice_number}</span>
                      <Badge className={`text-[10px] ${statusColors[inv.status] || ""}`}>{inv.status}</Badge>
                    </div>
                    <p className="text-xs text-muted-foreground mt-0.5">
                      {inv.created_at && format(new Date(inv.created_at), "MMM d, yyyy")}
                      {inv.due_at && ` · Due ${format(new Date(inv.due_at), "MMM d")}`}
                    </p>
                  </div>
                  <div className="text-right ml-4">
                    <p className="text-sm font-semibold font-mono">${Number(inv.total || 0).toLocaleString("en-US", { minimumFractionDigits: 2 })}</p>
                    {Number(inv.amount_paid || 0) > 0 && Number(inv.amount_paid) < Number(inv.total) && (
                      <p className="text-[10px] text-muted-foreground">Paid: ${Number(inv.amount_paid).toLocaleString("en-US", { minimumFractionDigits: 2 })}</p>
                    )}
                  </div>
                </div>
              ))}
            </div>
          )}
        </CardContent>
      </Card>

      <GenerateInvoiceDialog
        open={generateOpen}
        onOpenChange={setGenerateOpen}
        projectId={projectId}
        contractorId={contractorId || null}
      />

      {editingInvoice && (
        <InvoiceEditor
          invoice={editingInvoice}
          open={!!editingInvoice}
          onOpenChange={(open) => !open && setEditingInvoice(null)}
        />
      )}
    </>
  );
}
