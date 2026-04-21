import { useState } from "react";
import { Brain, ChevronDown, ChevronUp, BookOpen, EyeOff, Loader2 } from "lucide-react";
import { useQueryClient } from "@tanstack/react-query";
import { toast } from "sonner";
import { cn } from "@/lib/utils";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import {
  useAppliedCorrections,
  setPatternActive,
} from "@/hooks/useCorrectionPatterns";

interface Props {
  planReviewId: string;
}

export default function ReviewerMemoryCard({ planReviewId }: Props) {
  const qc = useQueryClient();
  const { data: applied = [], isLoading } = useAppliedCorrections(planReviewId);
  const [open, setOpen] = useState(false);
  const [unlearningId, setUnlearningId] = useState<string | null>(null);

  if (isLoading || applied.length === 0) return null;

  async function unlearn(patternId: string) {
    setUnlearningId(patternId);
    try {
      await setPatternActive(patternId, false);
      toast.success("Pattern un-learned — it will no longer suppress findings.");
      qc.invalidateQueries({ queryKey: ["correction_patterns"] });
      qc.invalidateQueries({ queryKey: ["applied_corrections", planReviewId] });
    } catch {
      toast.error("Could not un-learn pattern");
    } finally {
      setUnlearningId(null);
    }
  }

  return (
    <div className="rounded-lg border border-primary/30 bg-primary/5">
      <button
        type="button"
        onClick={() => setOpen((o) => !o)}
        className="flex w-full items-center justify-between gap-3 px-4 py-3 text-left"
      >
        <div className="flex flex-wrap items-center gap-x-3 gap-y-1">
          <div className="flex items-center gap-2">
            <Brain className="h-4 w-4 text-primary" />
            <span className="text-sm font-medium">
              Reviewer Memory active · {applied.length} learned correction
              {applied.length === 1 ? "" : "s"} applied
            </span>
          </div>
          <span className="text-xs text-muted-foreground">
            Patterns rejected in past reviews were used to prime the AI.
          </span>
        </div>
        {open ? (
          <ChevronUp className="h-4 w-4 text-muted-foreground" />
        ) : (
          <ChevronDown className="h-4 w-4 text-muted-foreground" />
        )}
      </button>

      {open && (
        <div className="space-y-2 border-t border-primary/20 px-4 py-3">
          <p className="text-xs text-muted-foreground">
            These patterns were injected into the discipline-review prompt so the AI would not
            re-flag them. Click <em>Un-learn</em> if a pattern has gotten stale (e.g. code edition
            changed).
          </p>
          <ul className="space-y-2">
            {applied.map((row) => {
              const pattern = row.pattern;
              const code = pattern?.code_reference;
              const codeStr = code
                ? [code.code, code.section, code.edition && `(${code.edition})`]
                    .filter(Boolean)
                    .join(" ")
                : null;
              return (
                <li
                  key={row.id}
                  className="rounded-md border bg-background/60 p-3 text-xs"
                >
                  <div className="flex flex-wrap items-center gap-2">
                    <Badge variant="outline" className="font-mono">
                      {row.discipline}
                    </Badge>
                    {codeStr && (
                      <Badge variant="secondary" className="font-mono">
                        {codeStr}
                      </Badge>
                    )}
                    {pattern && pattern.rejection_count > 1 && (
                      <span className="text-[10px] text-muted-foreground">
                        rejected {pattern.rejection_count}× in past reviews
                      </span>
                    )}
                    {pattern && (
                      <Button
                        size="sm"
                        variant="ghost"
                        className={cn(
                          "ml-auto h-7 gap-1 px-2 text-2xs text-muted-foreground hover:text-destructive",
                        )}
                        onClick={() => unlearn(pattern.id)}
                        disabled={unlearningId === pattern.id}
                      >
                        {unlearningId === pattern.id ? (
                          <Loader2 className="h-3 w-3 animate-spin" />
                        ) : (
                          <EyeOff className="h-3 w-3" />
                        )}
                        Un-learn
                      </Button>
                    )}
                  </div>
                  <p className="mt-1.5 text-foreground">{row.pattern_summary}</p>
                  {pattern?.reason_notes && (
                    <p className="mt-1 flex items-start gap-1.5 text-muted-foreground">
                      <BookOpen className="mt-0.5 h-3 w-3 shrink-0" />
                      <span className="italic">{pattern.reason_notes}</span>
                    </p>
                  )}
                </li>
              );
            })}
          </ul>
        </div>
      )}
    </div>
  );
}
