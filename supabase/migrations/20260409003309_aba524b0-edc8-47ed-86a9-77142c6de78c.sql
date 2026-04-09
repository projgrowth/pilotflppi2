
-- Create firm_settings table
CREATE TABLE public.firm_settings (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID NOT NULL UNIQUE,
  firm_name TEXT NOT NULL DEFAULT '',
  license_number TEXT DEFAULT '',
  email TEXT DEFAULT '',
  phone TEXT DEFAULT '',
  address TEXT DEFAULT '',
  logo_url TEXT DEFAULT '',
  closing_language TEXT DEFAULT '',
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- Enable RLS
ALTER TABLE public.firm_settings ENABLE ROW LEVEL SECURITY;

-- Policies
CREATE POLICY "Users can read own firm settings"
  ON public.firm_settings FOR SELECT
  TO authenticated
  USING (user_id = auth.uid());

CREATE POLICY "Users can insert own firm settings"
  ON public.firm_settings FOR INSERT
  TO authenticated
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can update own firm settings"
  ON public.firm_settings FOR UPDATE
  TO authenticated
  USING (user_id = auth.uid());

-- Auto-update timestamp trigger
CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SET search_path = public;

CREATE TRIGGER update_firm_settings_updated_at
  BEFORE UPDATE ON public.firm_settings
  FOR EACH ROW
  EXECUTE FUNCTION public.update_updated_at_column();
