import { useState } from "react";
import { ChevronDown, ChevronRight, AlertTriangle } from "lucide-react";
import { useProjectDna } from "@/hooks/useReviewDashboard";
import { cn } from "@/lib/utils";

interface Props {
  planReviewId: string;
  jurisdictionMismatch?: boolean;
}

const FIELD_LABELS: Record<string, string> = {
  occupancy_classification: "Occupancy Classification",
  construction_type: "Construction Type",
  total_sq_ft: "Total Sq Ft",
  stories: "Stories",
  fbc_edition: "FBC Edition",
  jurisdiction: "Jurisdiction",
  county: "County",
  hvhz: "HVHZ",
  flood_zone: "Flood Zone",
  wind_speed_vult: "Wind Speed (Vult)",
  exposure_category: "Exposure Category",
  risk_category: "Risk Category",
  seismic_design_category: "Seismic Design Category",
  has_mezzanine: "Has Mezzanine",
  is_high_rise: "High Rise",
  mixed_occupancy: "Mixed Occupancy",
};

export default function ProjectDNAViewer({ planReviewId, jurisdictionMismatch }: Props) {
  const { data: dna } = useProjectDna(planReviewId);
  const [open, setOpen] = useState(true);

  if (!dna) {
    return (
      <div className="rounded-lg border bg-card p-4 text-sm text-muted-foreground">
        Project DNA not yet extracted.
      </div>
    );
  }

  const missing = new Set(dna.missing_fields ?? []);
  const ambiguous = new Set(dna.ambiguous_fields ?? []);

  return (
    <div className="rounded-lg border bg-card">
      <button
        type="button"
        onClick={() => setOpen((o) => !o)}
        className="flex w-full items-center justify-between p-4 text-left"
      >
        <div className="flex items-center gap-2">
          {open ? <ChevronDown className="h-4 w-4" /> : <ChevronRight className="h-4 w-4" />}
          <span className="text-sm font-semibold">Project DNA</span>
          {missing.size > 0 && (
            <span className="inline-flex items-center gap-1 rounded bg-destructive/10 px-1.5 py-0.5 text-2xs font-medium text-destructive">
              <AlertTriangle className="h-3 w-3" />
              {missing.size} missing
            </span>
          )}
          {jurisdictionMismatch && (
            <span className="rounded bg-orange-500/10 px-1.5 py-0.5 text-2xs font-medium text-orange-600 dark:text-orange-400">
              Jurisdiction mismatch
            </span>
          )}
        </div>
        <span className="text-xs text-muted-foreground">Sanity check before trusting the review</span>
      </button>

      {open && (
        <div className="border-t">
          <table className="w-full text-xs">
            <tbody>
              {Object.entries(FIELD_LABELS).map(([key, label]) => {
                const v = (dna as unknown as Record<string, unknown>)[key];
                const isMissing = missing.has(key) || v === null || v === undefined || v === "";
                const isAmbiguous = ambiguous.has(key);
                return (
                  <tr key={key} className="border-b last:border-b-0">
                    <td className="w-1/2 px-4 py-2 font-medium text-muted-foreground">{label}</td>
                    <td
                      className={cn(
                        "px-4 py-2",
                        isMissing && "bg-destructive/5 font-medium text-destructive",
                        !isMissing && isAmbiguous && "bg-orange-500/5 text-orange-600 dark:text-orange-400",
                      )}
                    >
                      {isMissing ? "MISSING" : formatValue(v)}
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        </div>
      )}
    </div>
  );
}

function formatValue(v: unknown): string {
  if (typeof v === "boolean") return v ? "Yes" : "No";
  if (v === null || v === undefined) return "—";
  return String(v);
}
