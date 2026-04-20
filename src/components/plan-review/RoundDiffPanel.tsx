import { useState } from "react";
import { ChevronDown, ChevronRight } from "lucide-react";
import { cn } from "@/lib/utils";
import type { Finding } from "@/types";

interface Props {
  round: number;
  newCount: number;
  persistedCount: number;
  newlyResolvedCount: number;
  newlyResolvedFindings: Finding[];
  className?: string;
}

/**
 * Round-over-round diff banner shown at the top of the findings list when
 * viewing R2+. Stops reviewers from re-flagging items the contractor has
 * already fixed by surfacing what changed since the previous round.
 */
export function RoundDiffPanel({ round, newCount, persistedCount, newlyResolvedCount, newlyResolvedFindings, className }: Props) {
  const [expanded, setExpanded] = useState(false);
  const hasResolved = newlyResolvedCount > 0;

  return (
    <div className={cn("rounded-md border border-accent/30 bg-accent/5 overflow-hidden", className)}>
      <button
        onClick={() => hasResolved && setExpanded((e) => !e)}
        className={cn(
          "w-full flex items-center gap-3 px-2.5 py-1.5 text-2xs",
          hasResolved && "hover:bg-accent/10 cursor-pointer"
        )}
        disabled={!hasResolved}
      >
        <span className="font-semibold text-accent uppercase tracking-wide">
          R{round} vs R{round - 1}
        </span>
        <span className="flex items-center gap-1">
          <span className="w-1.5 h-1.5 rounded-full bg-accent" />
          <strong>{newCount}</strong> new
        </span>
        <span className="flex items-center gap-1">
          <span className="w-1.5 h-1.5 rounded-full bg-muted-foreground/50" />
          <strong>{persistedCount}</strong> still open
        </span>
        <span className="flex items-center gap-1">
          <span className="w-1.5 h-1.5 rounded-full bg-success" />
          <strong>{newlyResolvedCount}</strong> resolved
        </span>
        {hasResolved && (
          <span className="ml-auto text-muted-foreground">
            {expanded ? <ChevronDown className="h-3 w-3" /> : <ChevronRight className="h-3 w-3" />}
          </span>
        )}
      </button>
      {expanded && hasResolved && (
        <div className="border-t border-accent/20 bg-card px-2.5 py-2 space-y-1">
          <p className="text-2xs font-semibold uppercase tracking-wide text-muted-foreground mb-1">
            Resolved since R{round - 1}
          </p>
          {newlyResolvedFindings.map((f, i) => (
            <div key={i} className="flex items-start gap-2 text-2xs">
              <span className="w-1 h-1 mt-1.5 rounded-full bg-success shrink-0" />
              <code className="font-mono text-muted-foreground shrink-0">{f.code_ref || "—"}</code>
              <span className="text-foreground/75 line-clamp-1">{f.description}</span>
            </div>
          ))}
        </div>
      )}
    </div>
  );
}
