import { useState } from "react";
import { Sheet, SheetContent, SheetHeader, SheetTitle } from "@/components/ui/sheet";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Textarea } from "@/components/ui/textarea";
import { Badge } from "@/components/ui/badge";
import { useUpdateInvoice, useDeleteInvoice, useInvoiceLineItems, Invoice } from "@/hooks/useInvoices";
import { format } from "date-fns";
import { Loader2, Send, CheckCircle2, Ban, DollarSign, Unlock, Trash2 } from "lucide-react";
import { toast } from "sonner";

export function InvoiceEditor({ invoice, open, onOpenChange }: { invoice: Invoice; open: boolean; onOpenChange: (o: boolean) => void }) {
  const updateMutation = useUpdateInvoice();
  const deleteMutation = useDeleteInvoice();
  const { data: lineItems } = useInvoiceLineItems(invoice.id);
  const [paymentAmount, setPaymentAmount] = useState("");
  const [isLocked, setIsLocked] = useState(invoice.status !== "draft");

  const remaining = Number(invoice.total || 0) - Number(invoice.amount_paid || 0);

  const handleStatusChange = (newStatus: string) => {
    const updates: Partial<Invoice> & { id: string } = { id: invoice.id, status: newStatus };
    if (newStatus === "sent") updates.issued_at = new Date().toISOString();
    if (newStatus === "void") updates.paid_at = null;
    updateMutation.mutate(updates, { onSuccess: () => onOpenChange(false) });
  };

  const handleRecordPayment = () => {
    const amount = parseFloat(paymentAmount);
    if (!amount || amount <= 0) return;
    const newPaid = Number(invoice.amount_paid || 0) + amount;
    const newStatus = newPaid >= Number(invoice.total) ? "paid" : "partial";
    updateMutation.mutate(
      { id: invoice.id, amount_paid: newPaid, status: newStatus, paid_at: newPaid >= Number(invoice.total) ? new Date().toISOString() : null },
      { onSuccess: () => { setPaymentAmount(""); onOpenChange(false); } }
    );
  };

  const handleDelete = () => {
    if (!confirm("Delete this invoice permanently?")) return;
    deleteMutation.mutate(invoice.id, { onSuccess: () => onOpenChange(false) });
  };

  return (
    <Sheet open={open} onOpenChange={onOpenChange}>
      <SheetContent className="w-full sm:max-w-lg overflow-y-auto">
        <SheetHeader>
          <SheetTitle className="flex items-center gap-2">
            <span className="font-mono">{invoice.invoice_number}</span>
            <Badge variant="secondary" className="capitalize">{invoice.status}</Badge>
          </SheetTitle>
        </SheetHeader>

        <div className="mt-6 space-y-6">
          {/* Totals */}
          <div className="grid grid-cols-3 gap-3">
            <div className="rounded-lg bg-muted/30 p-3 text-center">
              <p className="text-[10px] text-muted-foreground uppercase">Total</p>
              <p className="text-lg font-semibold font-mono">${Number(invoice.total).toLocaleString("en-US", { minimumFractionDigits: 2 })}</p>
            </div>
            <div className="rounded-lg bg-muted/30 p-3 text-center">
              <p className="text-[10px] text-muted-foreground uppercase">Paid</p>
              <p className="text-lg font-semibold font-mono text-green-600">${Number(invoice.amount_paid || 0).toLocaleString("en-US", { minimumFractionDigits: 2 })}</p>
            </div>
            <div className="rounded-lg bg-muted/30 p-3 text-center">
              <p className="text-[10px] text-muted-foreground uppercase">Balance</p>
              <p className={`text-lg font-semibold font-mono ${remaining > 0 ? "text-amber-600" : "text-green-600"}`}>
                ${remaining.toLocaleString("en-US", { minimumFractionDigits: 2 })}
              </p>
            </div>
          </div>

          {/* Line items */}
          <div>
            <h4 className="text-[11px] font-semibold text-muted-foreground uppercase tracking-wider mb-2">Line Items</h4>
            <div className="divide-y rounded-md border text-sm">
              {(lineItems || []).map((li) => (
                <div key={li.id} className="flex items-center justify-between px-3 py-2">
                  <div className="min-w-0 flex-1">
                    <p className="truncate">{li.description}</p>
                    <p className="text-xs text-muted-foreground">{li.quantity} × ${Number(li.unit_price).toFixed(2)}</p>
                  </div>
                  <span className="font-mono ml-3">${Number(li.total).toLocaleString("en-US", { minimumFractionDigits: 2 })}</span>
                </div>
              ))}
            </div>
          </div>

          {/* Details */}
          <div className="space-y-2 text-sm">
            {invoice.due_at && (
              <div className="flex justify-between">
                <span className="text-muted-foreground">Due Date</span>
                <span>{format(new Date(invoice.due_at), "MMM d, yyyy")}</span>
              </div>
            )}
            {invoice.issued_at && (
              <div className="flex justify-between">
                <span className="text-muted-foreground">Issued</span>
                <span>{format(new Date(invoice.issued_at), "MMM d, yyyy")}</span>
              </div>
            )}
            {Number(invoice.tax_rate || 0) > 0 && (
              <div className="flex justify-between">
                <span className="text-muted-foreground">Tax Rate</span>
                <span>{(Number(invoice.tax_rate) * 100).toFixed(2)}%</span>
              </div>
            )}
            {invoice.notes && (
              <div>
                <p className="text-muted-foreground text-xs mb-1">Notes</p>
                <p className="text-sm bg-muted/30 rounded p-2">{invoice.notes}</p>
              </div>
            )}
          </div>

          {/* Actions */}
          <div className="space-y-3 border-t pt-4">
            {/* Record payment */}
            {["sent", "partial"].includes(invoice.status) && (
              <div className="flex gap-2">
                <Input
                  type="number"
                  step="0.01"
                  placeholder={`Amount (max $${remaining.toFixed(2)})`}
                  value={paymentAmount}
                  onChange={(e) => setPaymentAmount(e.target.value)}
                  className="text-sm"
                />
                <Button size="sm" onClick={handleRecordPayment} disabled={!paymentAmount || updateMutation.isPending} className="shrink-0">
                  <DollarSign className="h-3.5 w-3.5 mr-1" /> Record Payment
                </Button>
              </div>
            )}

            <div className="flex flex-wrap gap-2">
              {invoice.status === "draft" && (
                <Button size="sm" onClick={() => handleStatusChange("sent")} disabled={updateMutation.isPending}>
                  <Send className="h-3.5 w-3.5 mr-1" /> Mark as Sent
                </Button>
              )}
              {["sent", "partial"].includes(invoice.status) && (
                <Button size="sm" variant="outline" onClick={() => handleStatusChange("paid")} disabled={updateMutation.isPending}>
                  <CheckCircle2 className="h-3.5 w-3.5 mr-1" /> Mark as Paid
                </Button>
              )}
              {invoice.status !== "void" && invoice.status !== "paid" && (
                <Button size="sm" variant="outline" onClick={() => handleStatusChange("void")} disabled={updateMutation.isPending}>
                  <Ban className="h-3.5 w-3.5 mr-1" /> Void
                </Button>
              )}
              {isLocked && invoice.status !== "void" && (
                <Button size="sm" variant="ghost" onClick={() => setIsLocked(false)}>
                  <Unlock className="h-3.5 w-3.5 mr-1" /> Unlock to Edit
                </Button>
              )}
              {invoice.status === "draft" && (
                <Button size="sm" variant="ghost" className="text-destructive" onClick={handleDelete} disabled={deleteMutation.isPending}>
                  <Trash2 className="h-3.5 w-3.5 mr-1" /> Delete
                </Button>
              )}
            </div>
          </div>
        </div>
      </SheetContent>
    </Sheet>
  );
}
