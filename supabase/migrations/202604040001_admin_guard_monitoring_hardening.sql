-- Hardening for admin-critical actions and runtime monitoring.
-- Goals:
-- 1) Enforce stricter RLS posture on critical tables.
-- 2) Move admin account-status mutation + audit logging behind server-side guard.
-- 3) Provide RPC-based monitoring sink for role/account-status query failures.

alter table if exists public.profiles force row level security;
alter table if exists public.admin_audit_logs force row level security;
alter table if exists public.education_articles force row level security;

create table if not exists public.app_monitoring_logs (
  id uuid primary key default gen_random_uuid(),
  actor_id uuid references public.profiles(id) on delete set null,
  source text not null,
  event_type text not null,
  message text,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  constraint app_monitoring_logs_source_check
    check (char_length(source) between 2 and 64),
  constraint app_monitoring_logs_event_type_check
    check (char_length(event_type) between 2 and 64)
);

alter table public.app_monitoring_logs enable row level security;
alter table public.app_monitoring_logs force row level security;

create index if not exists app_monitoring_logs_actor_created_idx
  on public.app_monitoring_logs (actor_id, created_at desc);

create index if not exists app_monitoring_logs_event_created_idx
  on public.app_monitoring_logs (event_type, created_at desc);

drop policy if exists "Users read own monitoring logs" on public.app_monitoring_logs;
create policy "Users read own monitoring logs"
  on public.app_monitoring_logs for select
  using ((select auth.uid()) = actor_id or (select public.is_admin()));

create or replace function public.admin_insert_audit_log(
  action_name text,
  target_user_id uuid default null,
  metadata jsonb default '{}'::jsonb
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  requester uuid := auth.uid();
  normalized_action text := trim(coalesce(action_name, ''));
begin
  if requester is null then
    raise exception 'You must be authenticated';
  end if;

  if not public.is_admin(requester) then
    raise exception 'Only admin can execute this action';
  end if;

  if normalized_action = '' then
    raise exception 'Action is required';
  end if;

  insert into public.admin_audit_logs (actor_id, target_user_id, action, metadata)
  values (
    requester,
    target_user_id,
    normalized_action,
    coalesce(metadata, '{}'::jsonb)
  );
end;
$$;

revoke all on function public.admin_insert_audit_log(text, uuid, jsonb) from public;
revoke all on function public.admin_insert_audit_log(text, uuid, jsonb) from anon;
grant execute on function public.admin_insert_audit_log(text, uuid, jsonb) to authenticated;

create or replace function public.admin_set_user_account_status(
  target_user_id uuid,
  target_status text,
  target_username text default null
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  requester uuid := auth.uid();
  normalized_status text := lower(trim(coalesce(target_status, '')));
  next_action text;
begin
  if requester is null then
    raise exception 'You must be authenticated';
  end if;

  if not public.is_admin(requester) then
    raise exception 'Only admin can execute this action';
  end if;

  if target_user_id is null then
    raise exception 'Target user is required';
  end if;

  if normalized_status not in ('active', 'suspended') then
    raise exception 'Invalid account status: %', target_status;
  end if;

  if requester = target_user_id and normalized_status = 'suspended' then
    raise exception 'Admin cannot suspend own account';
  end if;

  update public.profiles
  set account_status = normalized_status
  where id = target_user_id;

  if not found then
    raise exception 'Target user not found';
  end if;

  next_action := case
    when normalized_status = 'suspended' then 'suspend_user'
    else 'unsuspend_user'
  end;

  perform public.admin_insert_audit_log(
    next_action,
    target_user_id,
    jsonb_strip_nulls(
      jsonb_build_object(
        'target_status', normalized_status,
        'target_username', nullif(trim(coalesce(target_username, '')), '')
      )
    )
  );
end;
$$;

revoke all on function public.admin_set_user_account_status(uuid, text, text) from public;
revoke all on function public.admin_set_user_account_status(uuid, text, text) from anon;
grant execute on function public.admin_set_user_account_status(uuid, text, text) to authenticated;

create or replace function public.log_client_monitoring_event(
  source_name text,
  event_name text,
  message_text text default null,
  metadata jsonb default '{}'::jsonb
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  requester uuid := auth.uid();
  normalized_source text := left(trim(coalesce(source_name, 'unknown')), 64);
  normalized_event text := left(trim(coalesce(event_name, 'unknown')), 64);
  normalized_message text := null;
begin
  if requester is null then
    raise exception 'You must be authenticated';
  end if;

  if normalized_source = '' then
    normalized_source := 'unknown';
  end if;

  if normalized_event = '' then
    normalized_event := 'unknown';
  end if;

  if message_text is not null then
    normalized_message := left(trim(message_text), 500);
    if normalized_message = '' then
      normalized_message := null;
    end if;
  end if;

  insert into public.app_monitoring_logs (
    actor_id,
    source,
    event_type,
    message,
    metadata
  )
  values (
    requester,
    normalized_source,
    normalized_event,
    normalized_message,
    coalesce(metadata, '{}'::jsonb)
  );
end;
$$;

revoke all on function public.log_client_monitoring_event(text, text, text, jsonb) from public;
revoke all on function public.log_client_monitoring_event(text, text, text, jsonb) from anon;
grant execute on function public.log_client_monitoring_event(text, text, text, jsonb) to authenticated;
