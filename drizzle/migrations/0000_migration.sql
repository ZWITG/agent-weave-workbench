create table public.app_owner (id int primary key default 1 check (id = 1), user_id uuid not null unique, created_at timestamptz not null default now());
grant select on public.app_owner to authenticated;
grant all on public.app_owner to service_role;
alter table public.app_owner enable row level security;
create policy "read own owner row" on public.app_owner for select to authenticated using (user_id = auth.uid());

create or replace function public.is_owner() returns boolean language sql stable security definer set search_path = public as $$
  select exists (select 1 from public.app_owner where user_id = auth.uid())
$$;

create or replace function public.claim_owner() returns boolean language plpgsql security definer set search_path = public as $$
begin
  if auth.uid() is null then return false; end if;
  insert into public.app_owner (id, user_id) values (1, auth.uid()) on conflict (id) do nothing;
  return public.is_owner();
end $$;
grant execute on function public.is_owner() to authenticated;
grant execute on function public.claim_owner() to authenticated;

create table public.agents (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid(),
  name text not null,
  role text not null default '',
  system_prompt text not null default '',
  skills text[] not null default '{}',
  color text not null default 'amber',
  created_at timestamptz not null default now()
);
create table public.workflows (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid(),
  name text not null,
  description text not null default '',
  stages jsonb not null default '[]'::jsonb,
  created_at timestamptz not null default now()
);
create table public.runs (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid(),
  workflow_id uuid references public.workflows(id) on delete set null,
  workflow_name text not null default '',
  status text not null default 'running',
  input text not null default '',
  output text,
  started_at timestamptz not null default now(),
  finished_at timestamptz
);
create table public.run_logs (
  id bigserial primary key,
  run_id uuid not null references public.runs(id) on delete cascade,
  user_id uuid not null default auth.uid(),
  agent_name text not null default 'system',
  kind text not null default 'info',
  message text not null,
  created_at timestamptz not null default now()
);
create table public.knowledge (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid(),
  agent_name text not null default '',
  topic text not null,
  content text not null,
  created_at timestamptz not null default now()
);

grant select, insert, update, delete on public.agents, public.workflows, public.runs, public.run_logs, public.knowledge to authenticated;
grant all on public.agents, public.workflows, public.runs, public.run_logs, public.knowledge to service_role;
grant usage, select on sequence public.run_logs_id_seq to authenticated;

alter table public.agents enable row level security;
alter table public.workflows enable row level security;
alter table public.runs enable row level security;
alter table public.run_logs enable row level security;
alter table public.knowledge enable row level security;

create policy "owner all" on public.agents for all to authenticated using (public.is_owner() and user_id = auth.uid()) with check (public.is_owner() and user_id = auth.uid());
create policy "owner all" on public.workflows for all to authenticated using (public.is_owner() and user_id = auth.uid()) with check (public.is_owner() and user_id = auth.uid());
create policy "owner all" on public.runs for all to authenticated using (public.is_owner() and user_id = auth.uid()) with check (public.is_owner() and user_id = auth.uid());
create policy "owner all" on public.run_logs for all to authenticated using (public.is_owner() and user_id = auth.uid()) with check (public.is_owner() and user_id = auth.uid());
create policy "owner all" on public.knowledge for all to authenticated using (public.is_owner() and user_id = auth.uid()) with check (public.is_owner() and user_id = auth.uid());

alter publication supabase_realtime add table public.run_logs;
alter publication supabase_realtime add table public.runs;