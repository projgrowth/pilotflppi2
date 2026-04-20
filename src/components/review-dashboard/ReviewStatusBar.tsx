import { Check, Loader2, X } from "lucide-react";
import { cn } from "@/lib/utils";
import { PIPELINE_STAGES, PipelineRow, usePipelineStatus } from "@/hooks/useReviewDashboard";

interface Props {
  planReviewId: string;
}

export default function ReviewStatusBar({ planReviewId }: Props) {
  const { data: rows = [] } = usePipelineStatus(planReviewId);
  const byStage = new Map(rows.map((r) => [r.stage, r] as const));

  return (
    <div className="rounded-lg border bg-card p-4">
      <div className="mb-3 text-xs font-medium uppercase tracking-wide text-muted-foreground">
        Pipeline Status
      </div>
      <ol className="flex flex-wrap items-start gap-x-1 gap-y-3">
        {PIPELINE_STAGES.map((stage, i) => {
          const row = byStage.get(stage.key);
          const status = row?.status ?? "pending";
          return (
            <li key={stage.key} className="flex items-center">
              <StageDot status={status} index={i + 1} errorMsg={row?.error_message ?? undefined} />
              <div className="ml-2 mr-3 min-w-0">
                <div className="text-xs font-medium">{stage.label}</div>
                <div
                  className={cn(
                    "text-2xs",
                    status === "error" ? "text-destructive" : "text-muted-foreground",
                  )}
                >
                  {labelFor(status)}
                </div>
              </div>
              {i < PIPELINE_STAGES.length - 1 && (
                <div
                  className={cn(
                    "mr-3 h-px w-6 self-center",
                    status === "complete" ? "bg-primary" : "bg-border",
                  )}
                />
              )}
            </li>
          );
        })}
      </ol>
    </div>
  );
}

function labelFor(status: PipelineRow["status"]) {
  switch (status) {
    case "pending":
      return "Pending";
    case "running":
      return "Running…";
    case "complete":
      return "Complete";
    case "error":
      return "Failed";
  }
}

function StageDot({
  status,
  index,
  errorMsg,
}: {
  status: PipelineRow["status"];
  index: number;
  errorMsg?: string;
}) {
  const base =
    "flex h-7 w-7 shrink-0 items-center justify-center rounded-full text-2xs font-semibold";
  if (status === "complete")
    return (
      <div className={cn(base, "bg-primary text-primary-foreground")}>
        <Check className="h-3.5 w-3.5" />
      </div>
    );
  if (status === "running")
    return (
      <div className={cn(base, "bg-accent text-accent-foreground ring-2 ring-accent/30")}>
        <Loader2 className="h-3.5 w-3.5 animate-spin" />
      </div>
    );
  if (status === "error")
    return (
      <div className={cn(base, "bg-destructive text-destructive-foreground")} title={errorMsg}>
        <X className="h-3.5 w-3.5" />
      </div>
    );
  return <div className={cn(base, "bg-muted text-muted-foreground")}>{index}</div>;
}
