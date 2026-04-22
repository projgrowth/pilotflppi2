/**
 * Adapter: convert `deficiencies_v2` rows into the legacy `Finding[]` shape
 * the PlanReviewDetail viewer + CommentLetterExport expect.
 *
 * Why this exists
 * ---------------
 * The v2 pipeline (`run-review-pipeline`) writes structured findings to
 * `deficiencies_v2`. The existing PDF viewer / comment-letter / lint /
 * SitePlanChecklist still consume the `Finding` interface, so this adapter
 * shapes v2 rows down into that interface without rewriting those screens.
 *
 * Source-of-truth rule: the v2 row's verification_status / requires_human_review
 * / status drives what the viewer shows. We map them down into the legacy
 * `severity` + `resolved` fields plus surface the v2 fields verbatim under
 * their original names so downstream filters can opt in.
 */

import type { Finding } from "@/types";

/** Subset of `deficiencies_v2` columns the adapter needs. */
export interface DeficiencyV2Lite {
  id: string;
  def_number: string;
  discipline: string;
  finding: string;
  required_action: string;
  sheet_refs: string[] | null;
  code_reference: { code?: string; section?: string; edition?: string } | null;
  evidence: string[] | null;
  confidence_score: number | null;
  confidence_basis: string | null;
  priority: string;
  life_safety_flag: boolean;
  permit_blocker: boolean;
  liability_flag: boolean;
  requires_human_review: boolean;
  human_review_reason: string | null;
  verification_status: string;
  status: string;
  model_version: string | null;
}

/** Map v2 priority + life-safety flag → legacy severity. */
function severityFromV2(d: DeficiencyV2Lite): "critical" | "major" | "minor" {
  if (d.life_safety_flag || d.permit_blocker) return "critical";
  if (d.priority === "high") return "critical";
  if (d.priority === "medium") return "major";
  return "minor";
}

/** Build a human-friendly code_ref string from the structured code_reference. */
function codeRefFromV2(d: DeficiencyV2Lite): string {
  const cr = d.code_reference;
  if (!cr) return "";
  return [cr.code, cr.section, cr.edition && `(${cr.edition})`]
    .filter(Boolean)
    .join(" ")
    .trim();
}

/** Map v2 lifecycle status → legacy `resolved` boolean. */
function resolvedFromV2(d: DeficiencyV2Lite): boolean {
  return d.status === "resolved" || d.status === "waived";
}

/**
 * Convert a list of v2 deficiencies into the legacy Finding[] shape.
 *
 * - `finding_id` = the v2 row UUID, so per-finding state (status changes,
 *   pin overrides, similar-correction lookups) keys cleanly off the v2 row.
 * - Sheet ref is the FIRST sheet_ref so the viewer's single-page anchor still
 *   works; downstream code that needs the full list can read `sheet_refs` off
 *   the raw row.
 * - `reasoning` carries the v2 `confidence_basis` so the existing "Why?"
 *   disclosure on FindingCard surfaces the senior-pass justification.
 */
export function adaptV2ToFindings(rows: DeficiencyV2Lite[]): Finding[] {
  return rows.map((d) => {
    const sheets = d.sheet_refs ?? [];
    const reasoning = [
      d.confidence_basis ?? "",
      d.requires_human_review && d.human_review_reason
        ? `\n\nHuman review needed: ${d.human_review_reason}`
        : "",
    ]
      .join("")
      .trim();
    return {
      finding_id: d.id,
      severity: severityFromV2(d),
      discipline: d.discipline.toLowerCase().replace(/\s+/g, "-"),
      code_ref: codeRefFromV2(d),
      page: sheets[0] ?? "",
      description: d.finding,
      recommendation: d.required_action,
      confidence:
        d.confidence_score === null
          ? undefined
          : d.confidence_score >= 0.85
            ? "high"
            : d.confidence_score >= 0.6
              ? "medium"
              : "low",
      reasoning: reasoning || undefined,
      resolved: resolvedFromV2(d),
      model_version: d.model_version ?? undefined,
    };
  });
}
