import { useState, useEffect } from "react";
import { useParams, useNavigate } from "react-router-dom";
import { useProjects } from "@/hooks/useProjects";
import { supabase } from "@/integrations/supabase/client";
import { useAuth } from "@/contexts/AuthContext";
import { Button } from "@/components/ui/button";
import { ArrowLeft, Pencil } from "lucide-react";
import { toast } from "sonner";

export default function ReviewDetail() {
  const { id: projectId } = useParams<{ id: string }>();
  const navigate = useNavigate();
  const { user } = useAuth();
  const { data: projects } = useProjects();

  const project = projects?.find((p) => p.id === projectId);

  const [redirectChecked, setRedirectChecked] = useState(false);
  const [creating, setCreating] = useState(false);

  // Auto-redirect to the functional plan review page if a plan_review exists
  useEffect(() => {
    if (!projectId) return;
    supabase
      .from("plan_reviews")
      .select("id")
      .eq("project_id", projectId)
      .order("round", { ascending: false })
      .limit(1)
      .then(({ data }) => {
        if (data && data.length > 0) {
          navigate(`/plan-review/${data[0].id}`, { replace: true });
        } else {
          setRedirectChecked(true);
        }
      });
  }, [projectId, navigate]);

  const handleStartReview = async () => {
    if (!projectId || !user?.id) return;
    setCreating(true);
    const { data, error } = await supabase
      .from("plan_reviews")
      .insert({ project_id: projectId, round: 1, reviewer_id: user.id })
      .select("id")
      .single();
    if (error || !data) {
      toast.error("Failed to create plan review");
      setCreating(false);
      return;
    }
    navigate(`/plan-review/${data.id}`, { replace: true });
  };

  // Show loading while checking for existing plan review
  if (!redirectChecked) {
    return (
      <div className="flex items-center justify-center h-[calc(100vh-56px)]">
        <div className="h-8 w-8 border-4 border-primary border-t-transparent rounded-full animate-spin" />
      </div>
    );
  }

  // No plan review exists — show empty state with CTA
  return (
    <div className="flex flex-col items-center justify-center h-[calc(100vh-56px)] text-center px-4">
      <div className="mb-4 flex h-14 w-14 items-center justify-center rounded-full bg-muted/60">
        <Pencil className="h-6 w-6 text-muted-foreground/40" />
      </div>
      <h2 className="text-lg font-semibold text-foreground">{project?.name || "Project"}</h2>
      <p className="text-sm text-muted-foreground mt-1 max-w-sm">
        No plan review has been started for this project yet. Start one to begin reviewing plans and flagging issues.
      </p>
      <div className="flex gap-2 mt-6">
        <Button variant="outline" onClick={() => navigate("/review")}>
          <ArrowLeft className="h-4 w-4 mr-1" /> Back to Reviews
        </Button>
        <Button onClick={handleStartReview} disabled={creating}>
          {creating ? "Creating…" : "Start Plan Review"}
        </Button>
      </div>
    </div>
  );
}
