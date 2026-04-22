// Inline visual evidence snippet for a deficiency card. Lazy-renders a
// pdf.js cropped PNG of the region around the AI's verbatim evidence quote
// so reviewers can verify a finding without opening the full plan set.
//
// "Pin to letter" persists the cropped PNG to Storage and writes its public
// URL onto the deficiency, where CommentLetterExport will pick it up to
// embed in the printed/exported comment letter.

import { useState } from "react";
import { useMutation, useQueryClient } from "@tanstack/react-query";
import { ImageOff, Loader2, Pin, PinOff, ExternalLink } from "lucide-react";
import { useEvidenceCrop } from "@/hooks/useEvidenceCrop";
import { dataUrlToBlob } from "@/lib/evidence-crop";
import { supabase } from "@/integrations/supabase/client";
import { Button } from "@/components/ui/button";
import { Skeleton } from "@/components/ui/skeleton";
import { toast } from "sonner";

interface Props {
  planReviewId: string;
  deficiencyId: string;
  sheetRef: string | null;
  evidenceText: string;
  /** Existing pinned crop URL, if any. When set, we show that directly. */
  pinnedUrl: string | null;
}

export default function EvidenceSnippet({
  planReviewId,
  deficiencyId,
  sheetRef,
  evidenceText,
  pinnedUrl,
}: Props) {
  // If a pinned crop already exists, show it without re-rendering pdf.js.
  const [forceRegenerate, setForceRegenerate] = useState(false);
  const useLive = forceRegenerate || !pinnedUrl;

  const crop = useEvidenceCrop({
    planReviewId,
    sheetRef,
    evidenceText,
    enabled: useLive,
  });

  const qc = useQueryClient();

  const pinMutation = useMutation({
    mutationFn: async () => {
      if (!crop.result) throw new Error("Crop not ready yet");
      const blob = dataUrlToBlob(crop.result.base64);
      const path = `evidence-crops/${planReviewId}/${deficiencyId}.png`;
      const { error: uploadErr } = await supabase.storage
        .from("documents")
        .upload(path, blob, { upsert: true, contentType: "image/png" });
      if (uploadErr) throw uploadErr;
      const { data: signed, error: signErr } = await supabase.storage
        .from("documents")
        .createSignedUrl(path, 60 * 60 * 24 * 365);
      if (signErr || !signed?.signedUrl) {
        throw new Error(signErr?.message ?? "Could not sign crop URL");
      }
      const meta = {
        sheet_ref: sheetRef,
        evidence_text: evidenceText.slice(0, 240),
        bbox: crop.result.bbox,
        page_in_file: crop.pageInFile,
        file_path: crop.filePath,
        generated_at: new Date().toISOString(),
      };
      const { error: updErr } = await supabase
        .from("deficiencies_v2")
        .update({ evidence_crop_url: signed.signedUrl, evidence_crop_meta: meta })
        .eq("id", deficiencyId);
      if (updErr) throw updErr;
      return signed.signedUrl;
    },
    onSuccess: () => {
      toast.success("Pinned to comment letter");
      qc.invalidateQueries({ queryKey: ["deficiencies_v2", planReviewId] });
      qc.invalidateQueries({ queryKey: ["plan_review", planReviewId] });
      setForceRegenerate(false);
    },
    onError: (e) => {
      toast.error(e instanceof Error ? e.message : "Pin failed");
    },
  });

  const unpinMutation = useMutation({
    mutationFn: async () => {
      const path = `evidence-crops/${planReviewId}/${deficiencyId}.png`;
      await supabase.storage.from("documents").remove([path]);
      const { error } = await supabase
        .from("deficiencies_v2")
        .update({ evidence_crop_url: null, evidence_crop_meta: {} })
        .eq("id", deficiencyId);
      if (error) throw error;
    },
    onSuccess: () => {
      toast.success("Removed from comment letter");
      qc.invalidateQueries({ queryKey: ["deficiencies_v2", planReviewId] });
      qc.invalidateQueries({ queryKey: ["plan_review", planReviewId] });
    },
  });

  // ---------- pinned-only short-circuit ----------
  if (pinnedUrl && !useLive) {
    return (
      <div className="space-y-2 rounded-md border border-emerald-500/30 bg-emerald-500/5 p-2">
        <div className="flex items-center justify-between gap-2 text-2xs">
          <span className="flex items-center gap-1 font-medium uppercase tracking-wide text-emerald-700 dark:text-emerald-400">
            <Pin className="h-3 w-3" /> Pinned crop · embeds in letter
          </span>
          <div className="flex items-center gap-1">
            <Button
              size="sm"
              variant="ghost"
              className="h-6 px-2 text-2xs"
              onClick={() => setForceRegenerate(true)}
            >
              Regenerate
            </Button>
            <Button
              size="sm"
              variant="ghost"
              className="h-6 px-2 text-2xs text-destructive"
              disabled={unpinMutation.isPending}
              onClick={() => unpinMutation.mutate()}
            >
              <PinOff className="mr-1 h-3 w-3" /> Unpin
            </Button>
          </div>
        </div>
        <img
          src={pinnedUrl}
          alt={`Evidence crop for ${sheetRef ?? "sheet"}`}
          className="w-full rounded border border-border bg-background"
          loading="lazy"
        />
      </div>
    );
  }

  // ---------- live render states ----------
  if (!sheetRef) {
    return (
      <p className="text-2xs italic text-muted-foreground">
        No sheet reference — can't render visual evidence.
      </p>
    );
  }

  if (crop.status === "loading" || crop.status === "idle") {
    return (
      <div className="space-y-2">
        <div className="flex items-center gap-2 text-2xs text-muted-foreground">
          <Loader2 className="h-3 w-3 animate-spin" /> Rendering sheet {sheetRef}…
        </div>
        <Skeleton className="h-32 w-full" />
      </div>
    );
  }

  if (crop.status === "no_match") {
    return (
      <div className="flex items-center gap-2 rounded-md border border-dashed border-border bg-muted/30 p-2 text-2xs text-muted-foreground">
        <ImageOff className="h-3 w-3" />
        Sheet {sheetRef} not in coverage map — open the plan set to verify manually.
      </div>
    );
  }

  if (crop.status === "error" || !crop.result) {
    return (
      <div className="flex items-center gap-2 rounded-md border border-destructive/30 bg-destructive/5 p-2 text-2xs text-destructive">
        <ImageOff className="h-3 w-3" />
        Couldn't render crop: {crop.error ?? "unknown error"}
      </div>
    );
  }

  return (
    <div className="space-y-2">
      <div className="flex items-center justify-between gap-2 text-2xs text-muted-foreground">
        <span className="font-medium uppercase tracking-wide">
          Sheet {sheetRef}
          {crop.pageInFile != null && (
            <span className="ml-1 font-mono normal-case text-muted-foreground/70">
              · p.{crop.pageInFile}
            </span>
          )}
          {!crop.result.matched && (
            <span className="ml-1 italic normal-case text-amber-600 dark:text-amber-400">
              (approx — quote not located in text layer)
            </span>
          )}
        </span>
        <div className="flex items-center gap-1">
          <Button
            size="sm"
            variant="ghost"
            className="h-6 px-2 text-2xs"
            onClick={() => {
              if (!crop.result) return;
              const w = window.open();
              if (w) {
                w.document.write(
                  `<title>Evidence ${sheetRef}</title><body style="margin:0;background:#000"><img src="${crop.result.base64}" style="max-width:100%;display:block;margin:auto"/></body>`,
                );
              }
            }}
          >
            <ExternalLink className="mr-1 h-3 w-3" /> Full size
          </Button>
          <Button
            size="sm"
            variant="outline"
            className="h-6 px-2 text-2xs"
            disabled={pinMutation.isPending}
            onClick={() => pinMutation.mutate()}
          >
            <Pin className="mr-1 h-3 w-3" />
            {pinMutation.isPending ? "Pinning…" : "Pin to letter"}
          </Button>
        </div>
      </div>
      <img
        src={crop.result.base64}
        alt={`Evidence crop for ${sheetRef}`}
        className="w-full rounded border border-border bg-background"
        loading="lazy"
      />
    </div>
  );
}
