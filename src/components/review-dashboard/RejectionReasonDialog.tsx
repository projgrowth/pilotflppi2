import { useState } from "react";
import { Loader2, ShieldAlert } from "lucide-react";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import { Button } from "@/components/ui/button";
import { Textarea } from "@/components/ui/textarea";
import { Label } from "@/components/ui/label";
import {
  REJECTION_REASON_LABELS,
  type RejectionReason,
} from "@/hooks/useCorrectionPatterns";
import { cn } from "@/lib/utils";

interface Props {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  defNumber: string;
  finding: string;
  saving?: boolean;
  onConfirm: (reason: RejectionReason, notes: string) => void | Promise<void>;
}

const REASON_KEYS = Object.keys(REJECTION_REASON_LABELS) as RejectionReason[];

export default function RejectionReasonDialog({
  open,
  onOpenChange,
  defNumber,
  finding,
  saving,
  onConfirm,
}: Props) {
  const [reason, setReason] = useState<RejectionReason | null>(null);
  const [notes, setNotes] = useState("");

  async function handleSubmit() {
    if (!reason) return;
    await onConfirm(reason, notes.trim().slice(0, 500));
    // reset for next open
    setReason(null);
    setNotes("");
  }

  return (
    <Dialog
      open={open}
      onOpenChange={(o) => {
        if (!o) {
          setReason(null);
          setNotes("");
        }
        onOpenChange(o);
      }}
    >
      <DialogContent className="max-w-lg">
        <DialogHeader>
          <DialogTitle className="flex items-center gap-2">
            <ShieldAlert className="h-4 w-4 text-destructive" />
            Reject {defNumber} as false positive
          </DialogTitle>
          <DialogDescription className="text-xs">
            Tell the system <em>why</em> so it stops repeating this mistake. Future reviews of
            similar projects will skip findings that match this pattern.
          </DialogDescription>
        </DialogHeader>

        <div className="rounded-md border bg-muted/40 p-3 text-xs italic text-muted-foreground">
          "{finding.length > 200 ? `${finding.slice(0, 200)}…` : finding}"
        </div>

        <div className="space-y-2">
          <Label className="text-xs font-medium">Why is this wrong?</Label>
          <div className="space-y-1.5">
            {REASON_KEYS.map((key) => (
              <button
                key={key}
                type="button"
                onClick={() => setReason(key)}
                className={cn(
                  "flex w-full items-start gap-2 rounded-md border px-3 py-2 text-left text-xs transition-colors",
                  reason === key
                    ? "border-primary bg-primary/10"
                    : "border-border hover:bg-muted/60",
                )}
              >
                <span
                  className={cn(
                    "mt-0.5 inline-block h-3 w-3 shrink-0 rounded-full border",
                    reason === key
                      ? "border-primary bg-primary"
                      : "border-muted-foreground/40",
                  )}
                />
                <span>{REJECTION_REASON_LABELS[key]}</span>
              </button>
            ))}
          </div>
        </div>

        <div className="space-y-1.5">
          <Label htmlFor="rejection-notes" className="text-xs font-medium">
            Notes (optional)
          </Label>
          <Textarea
            id="rejection-notes"
            value={notes}
            onChange={(e) => setNotes(e.target.value.slice(0, 500))}
            placeholder="Anything else the AI should know? (e.g. 'we always defer this to FM inspection')"
            className="min-h-[70px] text-xs"
            maxLength={500}
          />
          <p className="text-right text-[10px] text-muted-foreground">{notes.length}/500</p>
        </div>

        <DialogFooter className="gap-2">
          <Button
            type="button"
            variant="outline"
            size="sm"
            onClick={() => onOpenChange(false)}
            disabled={saving}
          >
            Cancel
          </Button>
          <Button
            type="button"
            variant="destructive"
            size="sm"
            onClick={handleSubmit}
            disabled={!reason || saving}
          >
            {saving ? <Loader2 className="mr-1 h-3.5 w-3.5 animate-spin" /> : null}
            Reject &amp; teach the AI
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}
