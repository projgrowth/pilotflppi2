import { useMemo } from "react";
import { useDeficienciesV2, useSheetCoverage, type DeficiencyV2Row } from "@/hooks/useReviewDashboard";

interface Props {
  planReviewId: string;
  projectName: string;
  projectAddress: string;
  jurisdiction: string;
}

export default function ReviewSummaryHeader({
  planReviewId,
  projectName,
  projectAddress,
  jurisdiction,
}: Props) {
  const { data: defs = [] } = useDeficienciesV2(planReviewId);
  const { data: sheets = [] } = useSheetCoverage(planReviewId);

  const stats = useMemo(() => summarize(defs), [defs]);

  const expectedCount = sheets.filter((s) => s.expected).length;
  const presentCount = sheets.filter((s) => s.expected && s.status === "present").length;

  return (
    <div className="rounded-lg border bg-card p-4">
      <div className="mb-3">
        <div className="text-base font-semibold">{projectName}</div>
        <div className="text-xs text-muted-foreground">
          {projectAddress} · {jurisdiction}
        </div>
      </div>

      <div className="flex flex-wrap items-center gap-2 text-xs">
        <Badge tone="critical" count={stats.lifeSafety} label="Life Safety" />
        <Badge tone="warn" count={stats.permitBlocker} label="Permit Blockers" />
        <Badge tone="caution" count={stats.liability} label="Liability Flags" />
        <Badge tone="muted" count={stats.medium} label="Medium" />
        <Badge tone="mutedLight" count={stats.low} label="Low" />
        <span className="ml-2 text-muted-foreground">
          · {stats.humanReview} flagged for Human Review
        </span>
      </div>

      <div className="mt-4 grid grid-cols-1 gap-3 sm:grid-cols-2">
        <ConfidenceGauge value={stats.avgConfidence} />
        <div className="rounded-md border bg-background p-3">
          <div className="text-2xs font-medium uppercase tracking-wide text-muted-foreground">
            Sheet Coverage
          </div>
          <div className="mt-1 text-lg font-semibold tabular-nums">
            {presentCount}{" "}
            <span className="text-sm font-normal text-muted-foreground">of {expectedCount}</span>
          </div>
          <div className="text-2xs text-muted-foreground">expected sheets present</div>
        </div>
      </div>
    </div>
  );
}

function Badge({
  tone,
  count,
  label,
}: {
  tone: "critical" | "warn" | "caution" | "muted" | "mutedLight";
  count: number;
  label: string;
}) {
  const cls =
    tone === "critical"
      ? "bg-destructive/10 text-destructive border-destructive/20"
      : tone === "warn"
        ? "bg-orange-500/10 text-orange-600 border-orange-500/20 dark:text-orange-400"
        : tone === "caution"
          ? "bg-amber-500/10 text-amber-600 border-amber-500/20 dark:text-amber-400"
          : tone === "muted"
            ? "bg-muted text-foreground border-border"
            : "bg-muted/50 text-muted-foreground border-border";
  return (
    <span
      className={`inline-flex items-center gap-1 rounded-md border px-2 py-0.5 font-medium ${cls}`}
    >
      <span className="tabular-nums">{count}</span>
      <span>{label}</span>
    </span>
  );
}

function ConfidenceGauge({ value }: { value: number }) {
  const pct = Math.round(value * 100);
  const color =
    value > 0.85 ? "hsl(var(--conf-high))" : value >= 0.6 ? "hsl(var(--conf-medium))" : "hsl(var(--conf-low))";
  return (
    <div className="rounded-md border bg-background p-3">
      <div className="text-2xs font-medium uppercase tracking-wide text-muted-foreground">
        Avg Confidence
      </div>
      <div className="mt-1 flex items-center gap-3">
        <div className="text-lg font-semibold tabular-nums">{pct}%</div>
        <div className="h-1.5 flex-1 rounded-full bg-muted">
          <div
            className="h-full rounded-full transition-all"
            style={{ width: `${pct}%`, backgroundColor: color }}
          />
        </div>
      </div>
    </div>
  );
}

function summarize(defs: DeficiencyV2Row[]) {
  let lifeSafety = 0;
  let permitBlocker = 0;
  let liability = 0;
  let medium = 0;
  let low = 0;
  let humanReview = 0;
  let confSum = 0;
  let confN = 0;
  for (const d of defs) {
    if (d.life_safety_flag) lifeSafety++;
    else if (d.permit_blocker) permitBlocker++;
    else if (d.liability_flag) liability++;
    else if (d.priority === "medium") medium++;
    else if (d.priority === "low") low++;
    if (d.requires_human_review) humanReview++;
    if (typeof d.confidence_score === "number") {
      confSum += d.confidence_score;
      confN++;
    }
  }
  return {
    lifeSafety,
    permitBlocker,
    liability,
    medium,
    low,
    humanReview,
    avgConfidence: confN ? confSum / confN : 0,
  };
}
