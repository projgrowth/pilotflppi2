import { useFilteredDeficiencies } from "@/hooks/useFilteredDeficiencies";
import DeficiencyCard from "./DeficiencyCard";

interface Props {
  planReviewId: string;
}

export default function HumanReviewQueue({ planReviewId }: Props) {
  const { isLoading, items } = useFilteredDeficiencies(planReviewId, {
    hideOverturned: true,
    onlyHumanReview: true,
    groupBy: "none",
  });

  if (isLoading) {
    return <div className="rounded-lg border bg-card p-4 text-sm text-muted-foreground">Loading…</div>;
  }
  if (items.length === 0) {
    return (
      <div className="rounded-lg border bg-card p-6 text-center text-sm text-muted-foreground">
        Nothing requires human review. ✅
      </div>
    );
  }

  return (
    <div className="space-y-3">
      <p className="text-xs text-muted-foreground">
        {items.length} item{items.length > 1 ? "s" : ""} flagged for human review. The AI was uncertain — verify each manually before signing off.
      </p>
      {items.map((d) => (
        <DeficiencyCard key={d.id} planReviewId={planReviewId} def={d} showHumanReviewContext />
      ))}
    </div>
  );
}
