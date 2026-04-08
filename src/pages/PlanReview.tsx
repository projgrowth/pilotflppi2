import { FileSearch } from "lucide-react";

export default function PlanReview() {
  return (
    <div className="p-6 md:p-8 max-w-7xl">
      <h1 className="text-2xl font-medium mb-6">Plan Review</h1>
      <div className="flex flex-col items-center justify-center py-20 text-center">
        <FileSearch className="h-12 w-12 text-muted-foreground/30 mb-4" />
        <h2 className="text-lg font-medium">No reviews in queue</h2>
        <p className="text-sm text-muted-foreground mt-1">Upload plans to begin AI-powered review</p>
      </div>
    </div>
  );
}
