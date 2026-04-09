/**
 * County-specific requirements registry for Florida building departments.
 * Controls what supplemental sections, amendment citations, product approval
 * formats, and submission rules appear in generated documents.
 */

export interface CountyRequirements {
  key: string;
  label: string;
  hvhz: boolean;
  /** Coastal Construction Control Line applies */
  cccl: boolean;
  /** Product approval format used */
  productApprovalFormat: "NOA" | "FL#" | "both";
  /** Days allowed for resubmission (default 14) */
  resubmissionDays: number;
  /** County-specific code amendment references */
  amendments: { ref: string; description: string }[];
  /** Supplemental sections required in comment letters */
  supplementalSections: SupplementalSection[];
  /** Building department info for addressee */
  buildingDepartment: {
    name: string;
    officialTitle: string;
    address: string;
  };
  /** Wind speed design requirement (mph) */
  designWindSpeed: string;
  /** Additional submission notes */
  submissionNotes: string[];
  /** Threshold building dollar amount */
  thresholdBuildingAmount: number;
  /** Energy code compliance path preference */
  energyCodePath: "prescriptive" | "performance" | "either";
}

export type SupplementalSection =
  | "wind_mitigation"
  | "wind_mitigation_enhanced"
  | "flood_zone"
  | "threshold_building"
  | "product_approval_table"
  | "noa_table"
  | "cccl_compliance"
  | "energy_compliance";

const DEFAULT_REQUIREMENTS: CountyRequirements = {
  key: "default",
  label: "Default",
  hvhz: false,
  cccl: false,
  productApprovalFormat: "FL#",
  resubmissionDays: 14,
  amendments: [],
  supplementalSections: ["wind_mitigation", "energy_compliance"],
  buildingDepartment: {
    name: "Building Department",
    officialTitle: "Building Official",
    address: "",
  },
  designWindSpeed: "Per ASCE 7-22 Fig. 26.5-1",
  submissionNotes: [],
  thresholdBuildingAmount: 4_000_000,
  energyCodePath: "either",
};

const COUNTY_REGISTRY: Record<string, Partial<CountyRequirements>> = {
  "miami-dade": {
    key: "miami-dade",
    label: "Miami-Dade",
    hvhz: true,
    cccl: true,
    productApprovalFormat: "NOA",
    resubmissionDays: 14,
    amendments: [
      { ref: "Miami-Dade Sec. 8A", description: "Local amendments to FBC for HVHZ construction" },
      { ref: "FBC 1626 (HVHZ)", description: "High Velocity Hurricane Zone requirements" },
      { ref: "FBC 1523 (HVHZ)", description: "Enhanced roofing requirements for HVHZ" },
      { ref: "Miami-Dade TAS 201/202/203", description: "Test protocols for impact-resistant products" },
      { ref: "Miami-Dade Resolution R-918-10", description: "Private provider notification requirements" },
    ],
    supplementalSections: [
      "wind_mitigation_enhanced",
      "noa_table",
      "flood_zone",
      "threshold_building",
      "cccl_compliance",
      "energy_compliance",
    ],
    buildingDepartment: {
      name: "Miami-Dade County Regulatory & Economic Resources",
      officialTitle: "Building Official / Director",
      address: "11805 SW 26th Street, Miami, FL 33175",
    },
    designWindSpeed: "≥ 175 mph (Ultimate) per ASCE 7-22 / FBC 1620.2",
    submissionNotes: [
      "All glazed openings require Miami-Dade NOA for impact resistance",
      "Product approval via Miami-Dade Notice of Acceptance (NOA) required — FL# not accepted in HVHZ",
      "40-year recertification / milestone inspection per F.S. 553.899 may apply",
      "Private Provider Notice must be filed with Building Official per Sec. 8A",
    ],
    thresholdBuildingAmount: 4_000_000,
    energyCodePath: "performance",
  },

  broward: {
    key: "broward",
    label: "Broward",
    hvhz: true,
    cccl: true,
    productApprovalFormat: "NOA",
    resubmissionDays: 14,
    amendments: [
      { ref: "Broward County Amendments to FBC Ch. 17", description: "Local structural amendments" },
      { ref: "FBC 1626 (HVHZ)", description: "High Velocity Hurricane Zone requirements" },
      { ref: "Broward County Ordinance 2023-XX", description: "Local building safety amendments" },
    ],
    supplementalSections: [
      "wind_mitigation_enhanced",
      "noa_table",
      "flood_zone",
      "threshold_building",
      "energy_compliance",
    ],
    buildingDepartment: {
      name: "Broward County Environmental Licensing & Building Permitting Division",
      officialTitle: "Chief Building Official",
      address: "1 N. University Drive, Suite 3500, Plantation, FL 33324",
    },
    designWindSpeed: "≥ 175 mph (Ultimate) per ASCE 7-22 / FBC 1620.2",
    submissionNotes: [
      "Products must have valid Miami-Dade NOA or Broward County Evaluation",
      "Broward County requires form references for all product submissions",
      "25-year milestone inspection per F.S. 553.899 may apply",
    ],
    thresholdBuildingAmount: 4_000_000,
    energyCodePath: "performance",
  },

  "palm-beach": {
    key: "palm-beach",
    label: "Palm Beach",
    hvhz: false,
    cccl: true,
    productApprovalFormat: "FL#",
    resubmissionDays: 14,
    amendments: [
      { ref: "Palm Beach County Amendment to FBC Ch. 16", description: "Enhanced wind-borne debris region requirements" },
    ],
    supplementalSections: [
      "wind_mitigation",
      "product_approval_table",
      "flood_zone",
      "threshold_building",
      "energy_compliance",
    ],
    buildingDepartment: {
      name: "Palm Beach County Building Division",
      officialTitle: "Building Official",
      address: "2300 N. Jog Road, West Palm Beach, FL 33411",
    },
    designWindSpeed: "150-160 mph (Ultimate) per ASCE 7-22",
    submissionNotes: [
      "Wind-borne debris region — impact protection required per FBC 1609.1.4",
      "Florida Product Approval (FL#) accepted",
    ],
    energyCodePath: "either",
  },

  hillsborough: {
    key: "hillsborough",
    label: "Hillsborough",
    hvhz: false,
    cccl: false,
    productApprovalFormat: "FL#",
    resubmissionDays: 14,
    amendments: [],
    supplementalSections: ["wind_mitigation", "product_approval_table", "energy_compliance"],
    buildingDepartment: {
      name: "Hillsborough County Building Services",
      officialTitle: "Building Official",
      address: "601 E. Kennedy Blvd, Tampa, FL 33602",
    },
    designWindSpeed: "140-150 mph (Ultimate) per ASCE 7-22",
    submissionNotes: [],
    energyCodePath: "either",
  },

  orange: {
    key: "orange",
    label: "Orange",
    hvhz: false,
    cccl: false,
    productApprovalFormat: "FL#",
    resubmissionDays: 14,
    amendments: [],
    supplementalSections: ["wind_mitigation", "product_approval_table", "energy_compliance"],
    buildingDepartment: {
      name: "Orange County Building Safety Division",
      officialTitle: "Building Official",
      address: "201 S. Rosalind Ave, Orlando, FL 32801",
    },
    designWindSpeed: "130-140 mph (Ultimate) per ASCE 7-22",
    submissionNotes: [],
    energyCodePath: "prescriptive",
  },

  duval: {
    key: "duval",
    label: "Duval",
    hvhz: false,
    cccl: true,
    productApprovalFormat: "FL#",
    resubmissionDays: 14,
    amendments: [],
    supplementalSections: ["wind_mitigation", "product_approval_table", "flood_zone", "energy_compliance"],
    buildingDepartment: {
      name: "City of Jacksonville Building Inspection Division",
      officialTitle: "Building Official",
      address: "214 N. Hogan Street, Jacksonville, FL 32202",
    },
    designWindSpeed: "130-140 mph (Ultimate) per ASCE 7-22",
    submissionNotes: ["Coastal construction control line requirements may apply for oceanfront parcels"],
    energyCodePath: "either",
  },

  pinellas: {
    key: "pinellas",
    label: "Pinellas",
    hvhz: false,
    cccl: true,
    productApprovalFormat: "FL#",
    resubmissionDays: 14,
    amendments: [],
    supplementalSections: ["wind_mitigation", "product_approval_table", "flood_zone", "energy_compliance"],
    buildingDepartment: {
      name: "Pinellas County Building Services",
      officialTitle: "Building Official",
      address: "440 Court Street, Clearwater, FL 33756",
    },
    designWindSpeed: "140-150 mph (Ultimate) per ASCE 7-22",
    submissionNotes: ["Flood zone determination required for all new construction"],
    energyCodePath: "either",
  },

  lee: {
    key: "lee",
    label: "Lee",
    hvhz: false,
    cccl: true,
    productApprovalFormat: "FL#",
    resubmissionDays: 14,
    amendments: [],
    supplementalSections: ["wind_mitigation", "product_approval_table", "flood_zone", "energy_compliance"],
    buildingDepartment: {
      name: "Lee County Community Development",
      officialTitle: "Building Official",
      address: "1500 Monroe Street, Fort Myers, FL 33901",
    },
    designWindSpeed: "150-160 mph (Ultimate) per ASCE 7-22",
    submissionNotes: ["Post-Hurricane Ian rebuilds may have additional requirements"],
    energyCodePath: "either",
  },

  sarasota: {
    key: "sarasota",
    label: "Sarasota",
    hvhz: false,
    cccl: true,
    productApprovalFormat: "FL#",
    resubmissionDays: 14,
    amendments: [],
    supplementalSections: ["wind_mitigation", "product_approval_table", "flood_zone", "energy_compliance"],
    buildingDepartment: {
      name: "Sarasota County Building Services",
      officialTitle: "Building Official",
      address: "1001 Sarasota Center Blvd, Sarasota, FL 34240",
    },
    designWindSpeed: "140-150 mph (Ultimate) per ASCE 7-22",
    submissionNotes: [],
    energyCodePath: "either",
  },

  volusia: {
    key: "volusia",
    label: "Volusia",
    hvhz: false,
    cccl: true,
    productApprovalFormat: "FL#",
    resubmissionDays: 14,
    amendments: [],
    supplementalSections: ["wind_mitigation", "product_approval_table", "flood_zone", "energy_compliance"],
    buildingDepartment: {
      name: "Volusia County Building & Code Administration",
      officialTitle: "Building Official",
      address: "123 W. Indiana Avenue, DeLand, FL 32720",
    },
    designWindSpeed: "130-140 mph (Ultimate) per ASCE 7-22",
    submissionNotes: [],
    energyCodePath: "either",
  },
};

/**
 * Get the full county requirements config for a given county key.
 * Falls back to sensible defaults for unknown counties.
 */
export function getCountyRequirements(county: string): CountyRequirements {
  const key = county.toLowerCase().trim();
  const override = COUNTY_REGISTRY[key];
  if (!override) return { ...DEFAULT_REQUIREMENTS, key, label: county };
  return { ...DEFAULT_REQUIREMENTS, ...override } as CountyRequirements;
}

/** Get a human-readable label for a supplemental section */
export function getSupplementalSectionLabel(section: SupplementalSection): string {
  const labels: Record<SupplementalSection, string> = {
    wind_mitigation: "Wind Mitigation Summary",
    wind_mitigation_enhanced: "Enhanced Wind Mitigation (HVHZ)",
    flood_zone: "Flood Zone Compliance Statement",
    threshold_building: "Threshold Building Disclosure",
    product_approval_table: "Product Approval Checklist (FL#)",
    noa_table: "Notice of Acceptance (NOA) Table",
    cccl_compliance: "Coastal Construction Control Line Compliance",
    energy_compliance: "Energy Code Compliance Path",
  };
  return labels[section] || section;
}

/** List all registered county keys */
export function getRegisteredCounties(): string[] {
  return Object.keys(COUNTY_REGISTRY);
}
