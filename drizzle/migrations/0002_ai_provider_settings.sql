CREATE TABLE public.ai_settings (
  user_id uuid PRIMARY KEY,
  default_provider text NOT NULL DEFAULT 'lovable' CHECK (default_provider IN ('lovable','ollama','custom')),
  ollama_url text NOT NULL DEFAULT 'http://localhost:11434',
  ollama_model text NOT NULL DEFAULT 'qwen2.5:7b',
  custom_base_url text NOT NULL DEFAULT 'https://api.openai.com/v1',
  custom_api_key text NOT NULL DEFAULT '',
  custom_model text NOT NULL DEFAULT 'gpt-4o-mini',
  updated_at timestamptz NOT NULL DEFAULT now()
);
GRANT SELECT, INSERT, UPDATE, DELETE ON public.ai_settings TO authenticated;
GRANT ALL ON public.ai_settings TO service_role;
ALTER TABLE public.ai_settings ENABLE ROW LEVEL SECURITY;
CREATE POLICY "owner all" ON public.ai_settings FOR ALL TO authenticated
  USING (public.is_owner() AND user_id = auth.uid())
  WITH CHECK (public.is_owner() AND user_id = auth.uid());
ALTER TABLE public.agents ADD COLUMN provider text NOT NULL DEFAULT 'default'
  CHECK (provider IN ('default','lovable','ollama','custom'));