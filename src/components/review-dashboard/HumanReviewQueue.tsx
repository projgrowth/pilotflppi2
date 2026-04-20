import { useDeficienciesV2 } from "@/hooks/useReviewDashboard";
import DeficiencyCard from "./DeficiencyCard";

interface Props {
  planReviewId: string;
}

export default function HumanReviewQueue({ planReviewId }: Props) {
  const { data: defs = [], isLoading } = useDeficienciesV2(planReviewId);
  const queue = defs.filter((d) => d.requires_human_review);

  if (isLoading) {
    return <div className="rounded-lg border bg-card p-4 text-sm text-muted-foreground">Loading…</div>;
  }
  if (queue.length === 0) {
    return (
      <div className="rounded-lg border bg-card p-6 text-center text-sm text-muted-foreground">
        Nothing requires human review. ✅
      </div>
    );
  }

  return (
    <div className="space-y-3">
      <p className="text-xs text-muted-foreground">
        {queue.length} item{queue.length > 1 ? "s" : ""} flagged for human review. The AI was uncertain — verify each manually before signing off.
      </p>
      {queue.map((d) => (
        <DeficiencyCard key={d.id} planReviewId={planReviewId} def={d} showHumanReviewContext />
      ))}
    </div>
  );
}
