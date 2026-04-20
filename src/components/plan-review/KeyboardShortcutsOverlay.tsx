import { Dialog, DialogContent, DialogHeader, DialogTitle } from "@/components/ui/dialog";

interface Props {
  open: boolean;
  onOpenChange: (open: boolean) => void;
}

const SHORTCUTS: { keys: string[]; label: string }[] = [
  { keys: ["J"], label: "Next finding" },
  { keys: ["K"], label: "Previous finding" },
  { keys: ["S"], label: "Mark active finding resolved" },
  { keys: ["X"], label: "Mark active finding deferred" },
  { keys: ["O"], label: "Reopen active finding" },
  { keys: ["R"], label: "Reposition active pin" },
  { keys: ["F"], label: "Focus filter / search" },
  { keys: ["←", "→"], label: "Previous / next plan page" },
  { keys: ["+", "−"], label: "Zoom in / out" },
  { keys: ["0"], label: "Fit page to width" },
  { keys: ["Ctrl", "Scroll"], label: "Smooth zoom" },
  { keys: ["?"], label: "Show this overlay" },
  { keys: ["Esc"], label: "Cancel reposition / close overlays" },
];

export function KeyboardShortcutsOverlay({ open, onOpenChange }: Props) {
  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="max-w-md">
        <DialogHeader>
          <DialogTitle className="text-base">Keyboard shortcuts</DialogTitle>
        </DialogHeader>
        <div className="space-y-1.5">
          {SHORTCUTS.map((s) => (
            <div key={s.label} className="flex items-center justify-between gap-3 py-1 border-b border-border/40 last:border-0">
              <span className="text-sm text-foreground/85">{s.label}</span>
              <div className="flex items-center gap-1">
                {s.keys.map((k, i) => (
                  <span key={i} className="inline-flex items-center justify-center min-w-[1.6rem] h-6 px-1.5 rounded border border-border bg-muted/40 text-2xs font-mono font-semibold text-foreground/80">
                    {k}
                  </span>
                ))}
              </div>
            </div>
          ))}
        </div>
        <p className="text-2xs text-muted-foreground pt-1">Shortcuts are disabled while typing in inputs.</p>
      </DialogContent>
    </Dialog>
  );
}
