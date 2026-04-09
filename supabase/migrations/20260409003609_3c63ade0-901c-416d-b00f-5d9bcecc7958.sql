
-- Create function to auto-advance project status
CREATE OR REPLACE FUNCTION public.auto_advance_project_status()
RETURNS TRIGGER AS $$
DECLARE
  current_status text;
  new_status text := NULL;
BEGIN
  -- For plan_reviews table
  IF TG_TABLE_NAME = 'plan_reviews' THEN
    SELECT status INTO current_status FROM public.projects WHERE id = NEW.project_id;
    
    IF TG_OP = 'INSERT' THEN
      IF current_status = 'intake' THEN
        new_status := 'plan_review';
      END IF;
    ELSIF TG_OP = 'UPDATE' THEN
      IF NEW.ai_check_status = 'complete' AND (OLD.ai_check_status IS DISTINCT FROM 'complete') THEN
        IF current_status IN ('intake', 'plan_review') THEN
          new_status := 'comments_sent';
        END IF;
      END IF;
    END IF;
  END IF;

  -- For inspections table
  IF TG_TABLE_NAME = 'inspections' THEN
    SELECT status INTO current_status FROM public.projects WHERE id = NEW.project_id;
    
    IF TG_OP = 'INSERT' THEN
      IF current_status IN ('intake', 'plan_review', 'comments_sent', 'resubmitted', 'approved', 'permit_issued') THEN
        new_status := 'inspection_scheduled';
      END IF;
    ELSIF TG_OP = 'UPDATE' THEN
      IF NEW.result = 'pass' AND NEW.certificate_issued = true 
         AND (OLD.result IS DISTINCT FROM 'pass' OR OLD.certificate_issued IS DISTINCT FROM true) THEN
        new_status := 'certificate_issued';
      END IF;
    END IF;
  END IF;

  -- Apply the status change
  IF new_status IS NOT NULL THEN
    UPDATE public.projects SET status = new_status::project_status, updated_at = now()
    WHERE id = NEW.project_id;
    
    -- Log to activity_log
    INSERT INTO public.activity_log (event_type, description, project_id, actor_type, metadata)
    VALUES (
      'status_auto_advanced',
      'Project status automatically advanced from ' || current_status || ' to ' || new_status,
      NEW.project_id,
      'system',
      jsonb_build_object('old_status', current_status, 'new_status', new_status, 'trigger_table', TG_TABLE_NAME)
    );
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- Create triggers
CREATE TRIGGER auto_advance_on_plan_review
  AFTER INSERT OR UPDATE ON public.plan_reviews
  FOR EACH ROW
  EXECUTE FUNCTION public.auto_advance_project_status();

CREATE TRIGGER auto_advance_on_inspection
  AFTER INSERT OR UPDATE ON public.inspections
  FOR EACH ROW
  EXECUTE FUNCTION public.auto_advance_project_status();
