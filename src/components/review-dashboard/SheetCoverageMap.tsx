import { useMemo } from "react";
import { useSheetCoverage, type SheetCoverageRow } from "@/hooks/useReviewDashboard";
import { cn } from "@/lib/utils";
import {
  Tooltip,
  TooltipContent,
  TooltipTrigger,
} from "@/components/ui/tooltip";

interface Props {
  planReviewId: string;
}

const STATUS_LABEL: Record<SheetCoverageRow["status"], string> = {
  present: "Present",
  missing_critical: "Missing (Critical)",
  missing_minor: "Missing (Minor)",
  extra: "Unexpected / Extra",
};

export default function SheetCoverageMap({ planReviewId }: Props) {
  const { data: sheets = [] } = useSheetCoverage(planReviewId);

  const counts = useMemo(() => {
    const c = { present: 0, missing_critical: 0, missing_minor: 0, extra: 0 };
    for (const s of sheets) c[s.status]++;
    return c;
  }, [sheets]);

  if (sheets.length === 0) {
    return (
      <div className="rounded-lg border bg-card p-4 text-sm text-muted-foreground">
        Sheet coverage not yet computed.
      </div>
    );
  }

  return (
    <div className="rounded-lg border bg-card p-4">
      <div className="mb-3 flex items-center justify-between">
        <div className="text-sm font-semibold">Sheet Coverage</div>
        <div className="flex flex-wrap gap-3 text-2xs text-muted-foreground">
          <Legend color="bg-emerald-500" label={`Present ${counts.present}`} />
          <Legend color="bg-destructive" label={`Missing-Critical ${counts.missing_critical}`} />
          <Legend color="bg-amber-500" label={`Missing-Minor ${counts.missing_minor}`} />
          <Legend color="bg-sky-500" label={`Extra ${counts.extra}`} />
        </div>
      </div>
      <div className="grid grid-cols-[repeat(auto-fill,minmax(70px,1fr))] gap-2">
        {sheets.map((s) => (
          <Tooltip key={s.id}>
            <TooltipTrigger asChild>
              <div
                className={cn(
                  "flex h-14 cursor-default flex-col items-center justify-center rounded-md border px-1 text-2xs font-mono",
                  statusBg(s.status),
                )}
              >
                <span className="font-semibold">{s.sheet_ref}</span>
                {s.discipline && <span className="opacity-80">{s.discipline}</span>}
              </div>
            </TooltipTrigger>
            <TooltipContent className="text-xs">
              <div className="font-medium">{s.sheet_ref}</div>
              {s.sheet_title && <div className="text-muted-foreground">{s.sheet_title}</div>}
              <div>{STATUS_LABEL[s.status]}</div>
            </TooltipContent>
          </Tooltip>
        ))}
      </div>
    </div>
  );
}

function statusBg(s: SheetCoverageRow["status"]) {
  switch (s) {
    case "present":
      return "bg-emerald-500/10 border-emerald-500/30 text-emerald-700 dark:text-emerald-400";
    case "missing_critical":
      return "bg-destructive/10 border-destructive/40 text-destructive";
    case "missing_minor":
      return "bg-amber-500/10 border-amber-500/40 text-amber-700 dark:text-amber-400";
    case "extra":
      return "bg-sky-500/10 border-sky-500/40 text-sky-700 dark:text-sky-400";
  }
}

function Legend({ color, label }: { color: string; label: string }) {
  return (
    <span className="inline-flex items-center gap-1">
      <span className={cn("h-2 w-2 rounded-sm", color)} />
      {label}
    </span>
  );
}
