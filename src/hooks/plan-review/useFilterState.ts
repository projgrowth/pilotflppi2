/**
 * Consolidated filter state management using useReducer.
 * 
 * Instead of 4 separate useState calls (statusFilter, confidenceFilter, 
 * disciplineFilter, sheetFilter), this hook groups them into a single
 * reducer, reducing re-renders and making the state shape explicit.
 */
import { useReducer, useCallback } from "react";
import type { FindingStatus } from "@/components/FindingStatusFilter";
import type { ConfidenceFilter } from "@/components/BulkTriageFilters";

export interface FilterState {
  status: FindingStatus | "all";
  confidence: ConfidenceFilter;
  discipline: string | "all";
  sheet: string | "all";
}

type FilterAction =
  | { type: "SET_STATUS"; payload: FindingStatus | "all" }
  | { type: "SET_CONFIDENCE"; payload: ConfidenceFilter }
  | { type: "SET_DISCIPLINE"; payload: string | "all" }
  | { type: "SET_SHEET"; payload: string | "all" }
  | { type: "RESET" };

const initialState: FilterState = {
  status: "all",
  confidence: "all",
  discipline: "all",
  sheet: "all",
};

function filterReducer(state: FilterState, action: FilterAction): FilterState {
  switch (action.type) {
    case "SET_STATUS":
      return { ...state, status: action.payload };
    case "SET_CONFIDENCE":
      return { ...state, confidence: action.payload };
    case "SET_DISCIPLINE":
      return { ...state, discipline: action.payload };
    case "SET_SHEET":
      return { ...state, sheet: action.payload };
    case "RESET":
      return initialState;
    default:
      return state;
  }
}

export function useFilterState() {
  const [state, dispatch] = useReducer(filterReducer, initialState);

  const setStatus = useCallback((status: FindingStatus | "all") => {
    dispatch({ type: "SET_STATUS", payload: status });
  }, []);

  const setConfidence = useCallback((confidence: ConfidenceFilter) => {
    dispatch({ type: "SET_CONFIDENCE", payload: confidence });
  }, []);

  const setDiscipline = useCallback((discipline: string | "all") => {
    dispatch({ type: "SET_DISCIPLINE", payload: discipline });
  }, []);

  const setSheet = useCallback((sheet: string | "all") => {
    dispatch({ type: "SET_SHEET", payload: sheet });
  }, []);

  const reset = useCallback(() => {
    dispatch({ type: "RESET" });
  }, []);

  return {
    filters: state,
    setStatus,
    setConfidence,
    setDiscipline,
    setSheet,
    reset,
  };
}
