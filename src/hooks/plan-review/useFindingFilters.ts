/**
 * Four-axis filter + grouping logic for the findings list panel.
 *
 * Inputs: the raw findings array + the per-finding status map.
 * Outputs: filtered subset, grouped-by-discipline maps, counts per axis,
 * a stable global-index map (so JSX can render grouped lists while keeping
 * a single linear index for selection / keyboard nav), plus bulk-resolve
 * helpers scoped to whatever subset is currently visible.
 */
import { useMemo } from "react";
import { DISCIPLINE_ORDER } from "@/lib/county-utils";
import type { Finding } from "@/components/FindingCard";
import type { FindingStatus } from "@/components/FindingStatusFilter";
import type { ConfidenceFilter } from "@/components/BulkTriageFilters";

export interface FindingFilterState {
  status: FindingStatus | "all";
  confidence: ConfidenceFilter;
  discipline: string | "all";
  sheet: string | "all";
}

function groupFindingsByDiscipline(findings: Finding[]): Record<string, Finding[]> {
  const groups: Record<string, Finding[]> = {};
  for (const f of findings) {
    const d = f.discipline || "structural";
    if (!groups[d]) groups[d] = [];
    groups[d].push(f);
  }
  return groups;
}

export function useFindingFilters(
  findings: Finding[],
  findingStatuses: Record<number, FindingStatus>,
  filters: FindingFilterState,
) {
  return useMemo(() => {
    const grouped = groupFindingsByDiscipline(findings);

    // Optimize filtering: use Set for O(1) lookups instead of Array.includes
    const filtered = findings.filter((f, i) => {
      if (filters.status !== "all" && (findingStatuses[i] || "open") !== filters.status) return false;
      if (filters.confidence !== "all" && (f.markup?.pin_confidence || "low") !== filters.confidence) return false;
      if (filters.discipline !== "all" && (f.discipline || "structural") !== filters.discipline) return false;
      if (filters.sheet !== "all" && (f.page || "Unknown").trim() !== filters.sheet) return false;
      return true;
    });
    const filteredSet = new Set(filtered);
    const filteredGrouped = groupFindingsByDiscipline(filtered);

    // Count confidence levels efficiently
    let highCount = 0;
    let mediumCount = 0;
    let lowCount = 0;
    for (const f of findings) {
      const conf = f.markup?.pin_confidence || "low";
      if (conf === "high") highCount++;
      else if (conf === "medium") mediumCount++;
      else lowCount++;
    }
    const confidenceCounts: Record<ConfidenceFilter, number> = {
      all: findings.length,
      high: highCount,
      medium: mediumCount,
      low: lowCount,
    };

    const disciplinesPresent = Array.from(new Set(findings.map((f) => f.discipline || "structural"))).sort(
      (a, b) =>
        DISCIPLINE_ORDER.indexOf(a as (typeof DISCIPLINE_ORDER)[number]) -
        DISCIPLINE_ORDER.indexOf(b as (typeof DISCIPLINE_ORDER)[number]),
    );
    const sheetsPresent = Array.from(new Set(findings.map((f) => (f.page || "Unknown").trim()))).sort();

    // Use Set for O(1) lookup instead of Array.includes
    const visibleIndices: number[] = [];
    let visibleResolvedCount = 0;
    for (let i = 0; i < findings.length; i++) {
      if (filteredSet.has(findings[i])) {
        visibleIndices.push(i);
        if (findingStatuses[i] === "resolved") visibleResolvedCount++;
      }
    }
    const allVisibleResolved = visibleIndices.length > 0 && visibleResolvedCount === visibleIndices.length;

    // Count statuses efficiently
    let criticalCount = 0;
    let majorCount = 0;
    let minorCount = 0;
    let openCount = 0;
    let resolvedCount = 0;
    let deferredCount = 0;
    
    for (let i = 0; i < findings.length; i++) {
      const f = findings[i];
      if (f.severity === "critical") criticalCount++;
      else if (f.severity === "major") majorCount++;
      else if (f.severity === "minor") minorCount++;

      const status = findingStatuses[i] || "open";
      if (status === "open") openCount++;
      else if (status === "resolved") resolvedCount++;
      else if (status === "deferred") deferredCount++;
    }

    // Stable global index across grouped accordion sections so keyboard nav
    // and selection always reference one canonical index.
    let counter = 0;
    const globalIndexMap = new Map<Finding, number>();
    for (const d of DISCIPLINE_ORDER) {
      if (!grouped[d]) continue;
      for (const f of grouped[d]) {
        globalIndexMap.set(f, counter++);
      }
    }

    return {
      grouped,
      filtered,
      filteredGrouped,
      confidenceCounts,
      disciplinesPresent,
      sheetsPresent,
      visibleIndices,
      allVisibleResolved,
      criticalCount,
      majorCount,
      minorCount,
      openCount,
      resolvedCount,
      deferredCount,
      globalIndexMap,
    };
  }, [findings, findingStatuses, filters.status, filters.confidence, filters.discipline, filters.sheet]);
}

/**
 * Round-over-round diff bookkeeping. Returned shape mirrors what the round
 * banner renders: per-finding "new"/"carried" classification + roll-up
 * counts. Empty when this is round 1 or there's no prior snapshot.
 */
export function useRoundDiff(findings: Finding[], previousFindings: Finding[], round: number) {
  return useMemo(() => {
    const diffMap = new Map<number, "new" | "carried">();
    let newCount = 0;
    let persistedCount = 0;
    let newlyResolvedCount = 0;
    const hasRoundDiff = round > 1 && previousFindings.length > 0;

    if (hasRoundDiff) {
      const findingKey = (f: Finding) => `${(f.code_ref || "").trim().toLowerCase()}|${(f.page || "").trim().toLowerCase()}`;
      const prevKeys = new Set(previousFindings.map(findingKey));
      const currKeys = new Set(findings.map(findingKey));
      for (let i = 0; i < findings.length; i++) {
        const k = findingKey(findings[i]);
        if (prevKeys.has(k)) {
          diffMap.set(i, "carried");
          persistedCount++;
        } else {
          diffMap.set(i, "new");
          newCount++;
        }
      }
      for (const pk of prevKeys) {
        if (!currKeys.has(pk)) newlyResolvedCount++;
      }
    }

    return { diffMap, newCount, persistedCount, newlyResolvedCount, hasRoundDiff };
  }, [findings, previousFindings, round]);
}
