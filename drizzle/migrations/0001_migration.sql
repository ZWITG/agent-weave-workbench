create table public.artifacts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid(),
  run_id uuid references public.runs(id) on delete cascade,
  agent_name text not null default '',
  path text not null,
  content text not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (run_id, path)
);
grant select, insert, update, delete on public.artifacts to authenticated;
grant all on public.artifacts to service_role;
alter table public.artifacts enable row level security;
create policy "owner all" on public.artifacts for all to authenticated using (public.is_owner() and user_id = auth.uid()) with check (public.is_owner() and user_id = auth.uid());
alter publication supabase_realtime add table public.artifacts;