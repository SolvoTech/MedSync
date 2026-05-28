-- Address Supabase advisor findings that can be fixed through SQL.

create schema if not exists private;
revoke all on schema private from public;
grant usage on schema private to anon, authenticated, service_role;

create or replace function private.delete_my_account_impl()
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if auth.uid() is null then
    raise exception 'Not authenticated';
  end if;

  delete from auth.users where id = auth.uid();
end;
$$;

create or replace function public.delete_my_account()
returns void
language sql
security invoker
set search_path = public, private
as $$
  select private.delete_my_account_impl();
$$;

revoke all on function public.delete_my_account() from public;
revoke all on function public.delete_my_account() from anon;
grant execute on function public.delete_my_account() to authenticated;

revoke all on function private.delete_my_account_impl() from public;
revoke all on function private.delete_my_account_impl() from anon;
grant execute on function private.delete_my_account_impl() to authenticated;

drop index if exists public.admin_audit_logs_actor_idx;
drop index if exists public.admin_audit_logs_target_idx;
drop index if exists public.measurement_logs_owner_id_idx;
drop index if exists public.physical_activity_logs_owner_id_idx;
drop index if exists public.app_monitoring_logs_actor_created_idx;
drop index if exists public.app_monitoring_logs_event_created_idx;
drop index if exists public.task_logs_completion_proof_idx;
