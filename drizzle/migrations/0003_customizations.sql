CREATE TABLE public.customizations (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL,
  config jsonb NOT NULL DEFAULT '{}'::jsonb,
  history jsonb NOT NULL DEFAULT '[]'::jsonb,
  updated_at timestamptz NOT NULL DEFAULT now()
);
GRANT SELECT, INSERT, UPDATE, DELETE ON public.customizations TO authenticated;
GRANT ALL ON public.customizations TO service_role;
ALTER TABLE public.customizations ENABLE ROW LEVEL SECURITY;
CREATE POLICY "owner all" ON public.customizations FOR ALL TO authenticated
  USING (public.is_owner() AND user_id = auth.uid())
  WITH CHECK (public.is_owner() AND user_id = auth.uid());