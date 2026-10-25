ALTER TABLE public.runs ADD COLUMN mode text NOT NULL DEFAULT 'run' CHECK (mode IN ('run', 'plan'));
ALTER TABLE public.runs ADD COLUMN plan text;
