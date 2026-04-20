import {
  AlertDialog, AlertDialogAction, AlertDialogCancel, AlertDialogContent,
  AlertDialogDescription, AlertDialogFooter, AlertDialogHeader, AlertDialogTitle,
} from "@/components/ui/alert-dialog";
import { AlertCircle, AlertTriangle, CheckCircle2 } from "lucide-react";
import { cn } from "@/lib/utils";
import type { LintIssue } from "@/lib/letter-linter";

interface Props {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  issues: LintIssue[];
  /** True when at least one error blocks send. Cancel becomes the only option. */
  blocked: boolean;
  onConfirmSend: () => void;
}

export function LetterLintDialog({ open, onOpenChange, issues, blocked, onConfirmSend }: Props) {
  const errors = issues.filter((i) => i.severity === "error");
  const warnings = issues.filter((i) => i.severity === "warning");

  return (
    <AlertDialog open={open} onOpenChange={onOpenChange}>
      <AlertDialogContent className="max-w-lg">
        <AlertDialogHeader>
          <AlertDialogTitle className="flex items-center gap-2">
            {blocked ? (
              <><AlertCircle className="h-4 w-4 text-destructive" /> Fix issues before sending</>
            ) : warnings.length > 0 ? (
              <><AlertTriangle className="h-4 w-4 text-warning" /> Review before sending</>
            ) : (
              <><CheckCircle2 className="h-4 w-4 text-success" /> Ready to send</>
            )}
          </AlertDialogTitle>
          <AlertDialogDescription>
            {blocked
              ? "The letter has blocking issues. Resolve them, then try again."
              : warnings.length > 0
                ? "Confirm the warnings below before sending to the contractor."
                : "Confirm you want to send this letter to the contractor."}
          </AlertDialogDescription>
        </AlertDialogHeader>

        {issues.length > 0 && (
          <div className="space-y-1.5 max-h-[40vh] overflow-y-auto">
            {errors.map((i, idx) => (
              <div key={`e-${idx}`} className="flex items-start gap-2 rounded border border-destructive/30 bg-destructive/5 px-2.5 py-1.5">
                <AlertCircle className="h-3.5 w-3.5 text-destructive shrink-0 mt-0.5" />
                <p className="text-xs text-foreground/85">{i.message}</p>
              </div>
            ))}
            {warnings.map((i, idx) => (
              <div key={`w-${idx}`} className="flex items-start gap-2 rounded border border-warning/30 bg-warning/5 px-2.5 py-1.5">
                <AlertTriangle className="h-3.5 w-3.5 text-warning shrink-0 mt-0.5" />
                <p className="text-xs text-foreground/85">{i.message}</p>
              </div>
            ))}
          </div>
        )}

        <AlertDialogFooter>
          <AlertDialogCancel>{blocked ? "Close" : "Cancel"}</AlertDialogCancel>
          {!blocked && (
            <AlertDialogAction onClick={onConfirmSend}>
              Send anyway
            </AlertDialogAction>
          )}
        </AlertDialogFooter>
      </AlertDialogContent>
    </AlertDialog>
  );
}
