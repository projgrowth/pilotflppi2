/**
 * Shared domain types used across multiple components/pages.
 * Component-local prop interfaces stay where they're used; only
 * shapes referenced by 2+ files belong here.
 */

export interface ContractorInfo {
  id: string;
  name: string;
  email: string | null;
  phone: string | null;
  license_number: string | null;
}

export interface ProjectInfo {
  id: string;
  name: string;
  address: string;
  trade_type: string;
  county: string;
  jurisdiction: string;
  contractor: ContractorInfo | null;
}

export interface MarkupData {
  page_index: number;
  x?: number;
  y?: number;
  width?: number;
  height?: number;
  annotations?: { x: number; y: number; width: number; height: number; label?: string }[];
}

export interface Finding {
  severity: string;
  discipline?: string;
  code_ref: string;
  county_specific?: boolean;
  page: string;
  description: string;
  recommendation: string;
  confidence?: string;
  markup?: MarkupData;
  resolved?: boolean;
}

export type FindingStatus = "open" | "resolved" | "deferred";

/** Row shape returned from the `plan_reviews` table with embedded project. */
export interface PlanReviewRow {
  id: string;
  project_id: string;
  ai_check_status: string;
  ai_findings: unknown;
  file_urls: string[];
  round: number;
  created_at: string;
  finding_statuses?: Record<string, string> | null;
  previous_findings?: unknown;
  project?: ProjectInfo | null;
  qc_status?: string;
  qc_reviewer_id?: string | null;
  qc_notes?: string;
}
