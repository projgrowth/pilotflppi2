import { createContext, useCallback, useContext, useMemo, useRef, useState, type ReactNode } from "react";
import {
  AlertDialog, AlertDialogAction, AlertDialogCancel, AlertDialogContent,
  AlertDialogDescription, AlertDialogFooter, AlertDialogHeader, AlertDialogTitle,
} from "@/components/ui/alert-dialog";
import { Checkbox } from "@/components/ui/checkbox";
import { cn } from "@/lib/utils";

export interface ConfirmOptions {
  title: string;
  description?: string;
  confirmLabel?: string;
  cancelLabel?: string;
  /** A stable key. If provided, "don't ask again this session" is offered. */
  rememberKey?: string;
  /** "destructive" makes the confirm button red. Default "default". */
  variant?: "default" | "destructive";
}

type ConfirmFn = (opts: ConfirmOptions) => Promise<boolean>;

const ConfirmContext = createContext<ConfirmFn | null>(null);

export function ConfirmProvider({ children }: { children: ReactNode }) {
  const [open, setOpen] = useState(false);
  const [opts, setOpts] = useState<ConfirmOptions | null>(null);
  const [dontAsk, setDontAsk] = useState(false);
  const resolverRef = useRef<((v: boolean) => void) | null>(null);
  // Per-session "don't ask again" map (in-memory, resets on full reload).
  const skipMapRef = useRef<Set<string>>(new Set());

  const confirm = useCallback<ConfirmFn>((options) => {
    if (options.rememberKey && skipMapRef.current.has(options.rememberKey)) {
      return Promise.resolve(true);
    }
    setOpts(options);
    setDontAsk(false);
    setOpen(true);
    return new Promise<boolean>((resolve) => {
      resolverRef.current = resolve;
    });
  }, []);

  const handle = (result: boolean) => {
    if (result && dontAsk && opts?.rememberKey) {
      skipMapRef.current.add(opts.rememberKey);
    }
    setOpen(false);
    resolverRef.current?.(result);
    resolverRef.current = null;
  };

  const value = useMemo(() => confirm, [confirm]);

  return (
    <ConfirmContext.Provider value={value}>
      {children}
      <AlertDialog open={open} onOpenChange={(o) => { if (!o) handle(false); }}>
        <AlertDialogContent>
          <AlertDialogHeader>
            <AlertDialogTitle>{opts?.title}</AlertDialogTitle>
            {opts?.description && (
              <AlertDialogDescription>{opts.description}</AlertDialogDescription>
            )}
          </AlertDialogHeader>
          {opts?.rememberKey && (
            <label className="flex items-center gap-2 text-xs text-muted-foreground cursor-pointer">
              <Checkbox
                checked={dontAsk}
                onCheckedChange={(v) => setDontAsk(v === true)}
              />
              Don't ask again this session
            </label>
          )}
          <AlertDialogFooter>
            <AlertDialogCancel onClick={() => handle(false)}>
              {opts?.cancelLabel || "Cancel"}
            </AlertDialogCancel>
            <AlertDialogAction
              onClick={() => handle(true)}
              className={cn(
                opts?.variant === "destructive" &&
                  "bg-destructive text-destructive-foreground hover:bg-destructive/90"
              )}
            >
              {opts?.confirmLabel || "Confirm"}
            </AlertDialogAction>
          </AlertDialogFooter>
        </AlertDialogContent>
      </AlertDialog>
    </ConfirmContext.Provider>
  );
}

export function useConfirm(): ConfirmFn {
  const ctx = useContext(ConfirmContext);
  if (!ctx) throw new Error("useConfirm must be used inside <ConfirmProvider>");
  return ctx;
}
