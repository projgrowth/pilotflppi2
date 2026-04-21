import { useFilteredDeficiencies } from "@/hooks/useFilteredDeficiencies";
import DeficiencyCard from "./DeficiencyCard";

interface Props {
  planReviewId: string;
}

export default function DeficiencyList({ planReviewId }: Props) {
  const { isLoading, grouped, counts } = useFilteredDeficiencies(planReviewId, {
    hideOverturned: true,
    groupBy: "discipline",
  });

  if (isLoading) {
    return <div className="rounded-lg border bg-card p-4 text-sm text-muted-foreground">Loading deficiencies…</div>;
  }
  if (counts.total === 0) {
    return (
      <div className="rounded-lg border bg-card p-6 text-center text-sm text-muted-foreground">
        No deficiencies recorded yet for this review.
      </div>
    );
  }

  return (
    <div className="space-y-6">
      {grouped.map(([discipline, items]) => (
        <section key={discipline}>
          <h3 className="mb-2 text-sm font-semibold capitalize">
            {discipline.replace(/_/g, " ")}{" "}
            <span className="text-xs font-normal text-muted-foreground">({items.length})</span>
          </h3>
          <div className="space-y-3">
            {items.map((d) => (
              <DeficiencyCard key={d.id} planReviewId={planReviewId} def={d} />
            ))}
          </div>
        </section>
      ))}
    </div>
  );
}
