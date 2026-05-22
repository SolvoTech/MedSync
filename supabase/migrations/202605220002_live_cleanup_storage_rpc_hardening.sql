-- Live cleanup after removing family/shared-view features and adding proof storage.
-- This migration is intentionally idempotent so it is safe for both fresh
-- databases and existing projects that still have older deployed objects.

-- Move the admin helper used by RLS policies out of the exposed public schema.
create schema if not exists private;
revoke all on schema private from public;
grant usage on schema private to anon, authenticated, service_role;

create or replace function private.is_admin(target_user_id uuid default auth.uid())
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.profiles p
    where p.id = coalesce(target_user_id, auth.uid())
      and p.role = 'admin'
  );
$$;

revoke all on function private.is_admin(uuid) from public;
grant execute on function private.is_admin(uuid) to anon, authenticated, service_role;

-- Remove obsolete family/shared-view schema that existed in earlier deploys.
drop table if exists public.shared_access_tokens cascade;
alter table if exists public.task_logs
  drop column if exists care_person_id;
alter table if exists public.measurement_logs
  drop column if exists care_person_id;
alter table if exists public.measurement_reminders
  drop column if exists care_person_id;
alter table if exists public.medicines
  drop column if exists care_person_id;
drop table if exists public.care_persons cascade;

-- Ensure task completion proof columns/index exist on live databases that were
-- deployed before the proof feature migration.
alter table if exists public.task_logs
  add column if not exists completion_proof_photo_path text,
  add column if not exists completion_proof_captured_at timestamptz,
  add column if not exists completion_proof_uploaded_at timestamptz;

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'task_logs_completion_proof_owner_path_check'
      and conrelid = 'public.task_logs'::regclass
  ) then
    alter table public.task_logs
      add constraint task_logs_completion_proof_owner_path_check
      check (
        completion_proof_photo_path is null
        or split_part(completion_proof_photo_path, '/', 1) = owner_id::text
      );
  end if;
end $$;

create index if not exists task_logs_completion_proof_idx
  on public.task_logs (owner_id, completion_proof_uploaded_at desc)
  where completion_proof_photo_path is not null;

-- Replace RLS policies so they call private.is_admin instead of an exposed
-- SECURITY DEFINER function in public.
drop policy if exists "Users can manage their own profile" on public.profiles;
drop policy if exists "Users can view own profile" on public.profiles;
drop policy if exists "Users can insert own profile" on public.profiles;
drop policy if exists "Users can update own profile" on public.profiles;
drop policy if exists "Admins can delete profiles" on public.profiles;

create policy "Users can view own profile"
  on public.profiles for select
  using ((select auth.uid()) = id or (select private.is_admin()));

create policy "Users can insert own profile"
  on public.profiles for insert
  with check ((select auth.uid()) = id or (select private.is_admin()));

create policy "Users can update own profile"
  on public.profiles for update
  using ((select auth.uid()) = id or (select private.is_admin()))
  with check ((select auth.uid()) = id or (select private.is_admin()));

create policy "Admins can delete profiles"
  on public.profiles for delete
  using ((select private.is_admin()));

drop policy if exists "Owner manages medicines" on public.medicines;
drop policy if exists "Admins can read medicines" on public.medicines;
drop policy if exists "Owner or admin reads medicines" on public.medicines;
drop policy if exists "Owner inserts medicines" on public.medicines;
drop policy if exists "Owner updates medicines" on public.medicines;
drop policy if exists "Owner deletes medicines" on public.medicines;

create policy "Owner or admin reads medicines"
  on public.medicines for select
  using ((select auth.uid()) = owner_id or (select private.is_admin()));

create policy "Owner inserts medicines"
  on public.medicines for insert
  with check ((select auth.uid()) = owner_id);

create policy "Owner updates medicines"
  on public.medicines for update
  using ((select auth.uid()) = owner_id)
  with check ((select auth.uid()) = owner_id);

create policy "Owner deletes medicines"
  on public.medicines for delete
  using ((select auth.uid()) = owner_id);

drop policy if exists "Owner manages schedules" on public.medicine_schedules;
drop policy if exists "Admins can read schedules" on public.medicine_schedules;
drop policy if exists "Owner or admin reads schedules" on public.medicine_schedules;
drop policy if exists "Owner inserts schedules" on public.medicine_schedules;
drop policy if exists "Owner updates schedules" on public.medicine_schedules;
drop policy if exists "Owner deletes schedules" on public.medicine_schedules;

create policy "Owner or admin reads schedules"
  on public.medicine_schedules for select
  using ((select auth.uid()) = owner_id or (select private.is_admin()));

create policy "Owner inserts schedules"
  on public.medicine_schedules for insert
  with check ((select auth.uid()) = owner_id);

create policy "Owner updates schedules"
  on public.medicine_schedules for update
  using ((select auth.uid()) = owner_id)
  with check ((select auth.uid()) = owner_id);

create policy "Owner deletes schedules"
  on public.medicine_schedules for delete
  using ((select auth.uid()) = owner_id);

drop policy if exists "Owner manages schedule time slots" on public.schedule_time_slots;
drop policy if exists "Admins can read schedule slots" on public.schedule_time_slots;
drop policy if exists "Owner or admin reads schedule slots" on public.schedule_time_slots;
drop policy if exists "Owner inserts schedule slots" on public.schedule_time_slots;
drop policy if exists "Owner updates schedule slots" on public.schedule_time_slots;
drop policy if exists "Owner deletes schedule slots" on public.schedule_time_slots;

create policy "Owner or admin reads schedule slots"
  on public.schedule_time_slots for select
  using (
    exists (
      select 1
      from public.medicine_schedules ms
      where ms.id = schedule_time_slots.schedule_id
        and ms.owner_id = (select auth.uid())
    )
    or (select private.is_admin())
  );

create policy "Owner inserts schedule slots"
  on public.schedule_time_slots for insert
  with check (
    exists (
      select 1
      from public.medicine_schedules ms
      where ms.id = schedule_time_slots.schedule_id
        and ms.owner_id = (select auth.uid())
    )
  );

create policy "Owner updates schedule slots"
  on public.schedule_time_slots for update
  using (
    exists (
      select 1
      from public.medicine_schedules ms
      where ms.id = schedule_time_slots.schedule_id
        and ms.owner_id = (select auth.uid())
    )
  )
  with check (
    exists (
      select 1
      from public.medicine_schedules ms
      where ms.id = schedule_time_slots.schedule_id
        and ms.owner_id = (select auth.uid())
    )
  );

create policy "Owner deletes schedule slots"
  on public.schedule_time_slots for delete
  using (
    exists (
      select 1
      from public.medicine_schedules ms
      where ms.id = schedule_time_slots.schedule_id
        and ms.owner_id = (select auth.uid())
    )
  );

drop policy if exists "Owner manages task logs" on public.task_logs;
drop policy if exists "Admins can read task logs" on public.task_logs;
drop policy if exists "Owner or admin reads task logs" on public.task_logs;
drop policy if exists "Owner inserts task logs" on public.task_logs;
drop policy if exists "Owner updates task logs" on public.task_logs;
drop policy if exists "Owner deletes task logs" on public.task_logs;

create policy "Owner or admin reads task logs"
  on public.task_logs for select
  using ((select auth.uid()) = owner_id or (select private.is_admin()));

create policy "Owner inserts task logs"
  on public.task_logs for insert
  with check ((select auth.uid()) = owner_id);

create policy "Owner updates task logs"
  on public.task_logs for update
  using ((select auth.uid()) = owner_id)
  with check ((select auth.uid()) = owner_id);

create policy "Owner deletes task logs"
  on public.task_logs for delete
  using ((select auth.uid()) = owner_id);

drop policy if exists "Owner manages measurement reminders" on public.measurement_reminders;
drop policy if exists "Admins can read measurement reminders" on public.measurement_reminders;
drop policy if exists "Owner or admin reads measurement reminders" on public.measurement_reminders;
drop policy if exists "Owner inserts measurement reminders" on public.measurement_reminders;
drop policy if exists "Owner updates measurement reminders" on public.measurement_reminders;
drop policy if exists "Owner deletes measurement reminders" on public.measurement_reminders;

create policy "Owner or admin reads measurement reminders"
  on public.measurement_reminders for select
  using ((select auth.uid()) = owner_id or (select private.is_admin()));

create policy "Owner inserts measurement reminders"
  on public.measurement_reminders for insert
  with check ((select auth.uid()) = owner_id);

create policy "Owner updates measurement reminders"
  on public.measurement_reminders for update
  using ((select auth.uid()) = owner_id)
  with check ((select auth.uid()) = owner_id);

create policy "Owner deletes measurement reminders"
  on public.measurement_reminders for delete
  using ((select auth.uid()) = owner_id);

drop policy if exists "Owner manages measurement logs" on public.measurement_logs;
drop policy if exists "Admins can read measurement logs" on public.measurement_logs;
drop policy if exists "Owner or admin reads measurement logs" on public.measurement_logs;
drop policy if exists "Owner inserts measurement logs" on public.measurement_logs;
drop policy if exists "Owner updates measurement logs" on public.measurement_logs;
drop policy if exists "Owner deletes measurement logs" on public.measurement_logs;

create policy "Owner or admin reads measurement logs"
  on public.measurement_logs for select
  using ((select auth.uid()) = owner_id or (select private.is_admin()));

create policy "Owner inserts measurement logs"
  on public.measurement_logs for insert
  with check ((select auth.uid()) = owner_id);

create policy "Owner updates measurement logs"
  on public.measurement_logs for update
  using ((select auth.uid()) = owner_id)
  with check ((select auth.uid()) = owner_id);

create policy "Owner deletes measurement logs"
  on public.measurement_logs for delete
  using ((select auth.uid()) = owner_id);

drop policy if exists "Owner manages activity reminders" on public.physical_activity_reminders;
drop policy if exists "Admins can read activity reminders" on public.physical_activity_reminders;
drop policy if exists "Owner or admin reads activity reminders" on public.physical_activity_reminders;
drop policy if exists "Owner inserts activity reminders" on public.physical_activity_reminders;
drop policy if exists "Owner updates activity reminders" on public.physical_activity_reminders;
drop policy if exists "Owner deletes activity reminders" on public.physical_activity_reminders;

create policy "Owner or admin reads activity reminders"
  on public.physical_activity_reminders for select
  using ((select auth.uid()) = owner_id or (select private.is_admin()));

create policy "Owner inserts activity reminders"
  on public.physical_activity_reminders for insert
  with check ((select auth.uid()) = owner_id);

create policy "Owner updates activity reminders"
  on public.physical_activity_reminders for update
  using ((select auth.uid()) = owner_id)
  with check ((select auth.uid()) = owner_id);

create policy "Owner deletes activity reminders"
  on public.physical_activity_reminders for delete
  using ((select auth.uid()) = owner_id);

drop policy if exists "Owner manages activity logs" on public.physical_activity_logs;
drop policy if exists "Admins can read activity logs" on public.physical_activity_logs;
drop policy if exists "Owner or admin reads activity logs" on public.physical_activity_logs;
drop policy if exists "Owner inserts activity logs" on public.physical_activity_logs;
drop policy if exists "Owner updates activity logs" on public.physical_activity_logs;
drop policy if exists "Owner deletes activity logs" on public.physical_activity_logs;

create policy "Owner or admin reads activity logs"
  on public.physical_activity_logs for select
  using ((select auth.uid()) = owner_id or (select private.is_admin()));

create policy "Owner inserts activity logs"
  on public.physical_activity_logs for insert
  with check ((select auth.uid()) = owner_id);

create policy "Owner updates activity logs"
  on public.physical_activity_logs for update
  using ((select auth.uid()) = owner_id)
  with check ((select auth.uid()) = owner_id);

create policy "Owner deletes activity logs"
  on public.physical_activity_logs for delete
  using ((select auth.uid()) = owner_id);

drop policy if exists "Owner manages notification logs" on public.notification_logs;
drop policy if exists "Admins can read notification logs" on public.notification_logs;
drop policy if exists "Owner or admin reads notification logs" on public.notification_logs;
drop policy if exists "Owner inserts notification logs" on public.notification_logs;
drop policy if exists "Owner updates notification logs" on public.notification_logs;
drop policy if exists "Owner deletes notification logs" on public.notification_logs;

create policy "Owner or admin reads notification logs"
  on public.notification_logs for select
  using ((select auth.uid()) = owner_id or (select private.is_admin()));

create policy "Owner inserts notification logs"
  on public.notification_logs for insert
  with check ((select auth.uid()) = owner_id);

create policy "Owner updates notification logs"
  on public.notification_logs for update
  using ((select auth.uid()) = owner_id)
  with check ((select auth.uid()) = owner_id);

create policy "Owner deletes notification logs"
  on public.notification_logs for delete
  using ((select auth.uid()) = owner_id);

drop policy if exists "Owner manages streak" on public.user_streaks;
drop policy if exists "Admins can read streaks" on public.user_streaks;
drop policy if exists "Owner or admin reads streaks" on public.user_streaks;
drop policy if exists "Owner inserts streaks" on public.user_streaks;
drop policy if exists "Owner updates streaks" on public.user_streaks;
drop policy if exists "Owner deletes streaks" on public.user_streaks;

create policy "Owner or admin reads streaks"
  on public.user_streaks for select
  using ((select auth.uid()) = owner_id or (select private.is_admin()));

create policy "Owner inserts streaks"
  on public.user_streaks for insert
  with check ((select auth.uid()) = owner_id);

create policy "Owner updates streaks"
  on public.user_streaks for update
  using ((select auth.uid()) = owner_id)
  with check ((select auth.uid()) = owner_id);

create policy "Owner deletes streaks"
  on public.user_streaks for delete
  using ((select auth.uid()) = owner_id);

drop policy if exists "Admins can read admin audit logs" on public.admin_audit_logs;
drop policy if exists "Admins can insert admin audit logs" on public.admin_audit_logs;

create policy "Admins can read admin audit logs"
  on public.admin_audit_logs for select
  using ((select private.is_admin()));

create policy "Admins can insert admin audit logs"
  on public.admin_audit_logs for insert
  with check ((select private.is_admin()) and actor_id = (select auth.uid()));

drop policy if exists "Users read own monitoring logs" on public.app_monitoring_logs;
drop policy if exists "Users insert own monitoring logs" on public.app_monitoring_logs;

create policy "Users read own monitoring logs"
  on public.app_monitoring_logs for select
  using ((select auth.uid()) = actor_id or (select private.is_admin()));

create policy "Users insert own monitoring logs"
  on public.app_monitoring_logs for insert
  with check ((select auth.uid()) = actor_id);

drop policy if exists "Users can read published education articles" on public.education_articles;
drop policy if exists "Admins can manage education articles" on public.education_articles;
drop policy if exists "Admins can insert education articles" on public.education_articles;
drop policy if exists "Admins can update education articles" on public.education_articles;
drop policy if exists "Admins can delete education articles" on public.education_articles;

create policy "Users can read published education articles"
  on public.education_articles for select
  using (status = 'published' or (select private.is_admin()));

create policy "Admins can insert education articles"
  on public.education_articles for insert
  with check ((select private.is_admin()));

create policy "Admins can update education articles"
  on public.education_articles for update
  using ((select private.is_admin()))
  with check ((select private.is_admin()));

create policy "Admins can delete education articles"
  on public.education_articles for delete
  using ((select private.is_admin()));

-- Recreate helper functions with the private admin helper. Admin/monitoring RPCs
-- can run as invoker because RLS policies now permit only valid admin/owner writes.
create or replace function public.guard_profile_sensitive_fields()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  requester_is_admin boolean := private.is_admin(auth.uid());
begin
  if new.username is not null then
    new.username := lower(trim(new.username));
  end if;

  if tg_op = 'INSERT' then
    if not requester_is_admin and new.id is distinct from auth.uid() then
      raise exception 'Cannot create profile for another user';
    end if;

    if not requester_is_admin then
      new.role := 'user';
      new.account_status := 'active';
    end if;
  elsif tg_op = 'UPDATE' then
    if not requester_is_admin then
      if old.id is distinct from auth.uid() then
        raise exception 'Cannot update another user profile';
      end if;

      if new.role is distinct from old.role then
        raise exception 'Only admin can change role';
      end if;

      if new.account_status is distinct from old.account_status then
        raise exception 'Only admin can change account status';
      end if;

      if new.internal_email is distinct from old.internal_email then
        raise exception 'Only admin can change internal email';
      end if;
    end if;
  end if;

  new.updated_at := now();
  return new;
end;
$$;

revoke all on function public.guard_profile_sensitive_fields() from public;
revoke all on function public.guard_profile_sensitive_fields() from anon;
revoke all on function public.guard_profile_sensitive_fields() from authenticated;

create or replace function public.admin_insert_audit_log(
  action_name text,
  target_user_id uuid default null,
  metadata jsonb default '{}'::jsonb
)
returns void
language plpgsql
security invoker
set search_path = public
as $$
declare
  requester uuid := auth.uid();
  normalized_action text := trim(coalesce(action_name, ''));
begin
  if requester is null then
    raise exception 'You must be authenticated';
  end if;

  if not private.is_admin(requester) then
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
security invoker
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

  if not private.is_admin(requester) then
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
security invoker
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

create or replace function public.notify_users_on_education_publish()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if new.status <> 'published' then
    return new;
  end if;

  if tg_op = 'UPDATE' and old.status = 'published' then
    return new;
  end if;

  insert into public.notification_logs (
    owner_id,
    notification_type,
    title,
    body,
    reference_id,
    reference_type,
    is_read,
    action_taken,
    scheduled_at,
    delivered_at,
    created_at
  )
  select
    p.id,
    'education_article',
    'Artikel edukasi baru',
    format('Artikel baru telah dipublish: %s', new.title),
    new.id,
    'education_articles',
    false,
    null,
    now(),
    now(),
    now()
  from public.profiles p
  where coalesce(p.account_status, 'active') = 'active'
    and coalesce(p.role, 'user') = 'user';

  return new;
end;
$$;

revoke all on function public.notify_users_on_education_publish() from public;
revoke all on function public.notify_users_on_education_publish() from anon;
revoke all on function public.notify_users_on_education_publish() from authenticated;

revoke all on function public.delete_my_account() from public;
revoke all on function public.delete_my_account() from anon;
grant execute on function public.delete_my_account() to authenticated;

revoke all on function public.is_admin(uuid) from public;
revoke all on function public.is_admin(uuid) from anon;
revoke all on function public.is_admin(uuid) from authenticated;

-- Storage buckets and policies.
insert into storage.buckets (
  id,
  name,
  public,
  file_size_limit,
  allowed_mime_types
)
values
  (
    'avatars',
    'avatars',
    true,
    3145728,
    array['image/jpeg', 'image/png', 'image/webp']
  ),
  (
    'education-covers',
    'education-covers',
    true,
    5242880,
    array['image/jpeg', 'image/png', 'image/webp']
  ),
  (
    'medicine-photos',
    'medicine-photos',
    true,
    5242880,
    array['image/jpeg', 'image/png', 'image/webp']
  ),
  (
    'task-completion-proofs',
    'task-completion-proofs',
    false,
    5242880,
    array['image/jpeg', 'image/png', 'image/webp']
  )
on conflict (id) do update
set
  public = excluded.public,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists "Anyone can view avatars" on storage.objects;
drop policy if exists "Avatar images are publicly accessible" on storage.objects;
drop policy if exists "Public can read avatar images" on storage.objects;
drop policy if exists "Users can upload their own avatar" on storage.objects;
drop policy if exists "Users can upload their own avatars" on storage.objects;
drop policy if exists "Users can upload own avatar images" on storage.objects;
drop policy if exists "Users can update their own avatar" on storage.objects;
drop policy if exists "Users can update their own avatars" on storage.objects;
drop policy if exists "Users can update own avatar images" on storage.objects;
drop policy if exists "Users can delete their own avatar" on storage.objects;
drop policy if exists "Users can delete their own avatars" on storage.objects;
drop policy if exists "Users can delete own avatar images" on storage.objects;

create policy "Users can upload own avatar images"
  on storage.objects for insert
  to authenticated
  with check (
    bucket_id = 'avatars'
    and (storage.foldername(name))[1] = (select auth.uid())::text
  );

create policy "Users can update own avatar images"
  on storage.objects for update
  to authenticated
  using (
    bucket_id = 'avatars'
    and (storage.foldername(name))[1] = (select auth.uid())::text
  )
  with check (
    bucket_id = 'avatars'
    and (storage.foldername(name))[1] = (select auth.uid())::text
  );

create policy "Users can delete own avatar images"
  on storage.objects for delete
  to authenticated
  using (
    bucket_id = 'avatars'
    and (storage.foldername(name))[1] = (select auth.uid())::text
  );

drop policy if exists "Public can read education cover images" on storage.objects;
drop policy if exists "Admins can upload education cover images" on storage.objects;
drop policy if exists "Admins can update education cover images" on storage.objects;
drop policy if exists "Admins can delete education cover images" on storage.objects;

create policy "Admins can upload education cover images"
  on storage.objects for insert
  to authenticated
  with check (
    bucket_id = 'education-covers'
    and (select private.is_admin())
    and (storage.foldername(name))[1] = (select auth.uid())::text
  );

create policy "Admins can update education cover images"
  on storage.objects for update
  to authenticated
  using (
    bucket_id = 'education-covers'
    and (select private.is_admin())
    and (storage.foldername(name))[1] = (select auth.uid())::text
  )
  with check (
    bucket_id = 'education-covers'
    and (select private.is_admin())
    and (storage.foldername(name))[1] = (select auth.uid())::text
  );

create policy "Admins can delete education cover images"
  on storage.objects for delete
  to authenticated
  using (
    bucket_id = 'education-covers'
    and (select private.is_admin())
    and (storage.foldername(name))[1] = (select auth.uid())::text
  );

drop policy if exists "Anyone can view medicine photos" on storage.objects;
drop policy if exists "Public can read medicine photos" on storage.objects;
drop policy if exists "Users can view their own medicine photos" on storage.objects;
drop policy if exists "Users can upload medicine photos" on storage.objects;
drop policy if exists "Users can upload their own medicine photos" on storage.objects;
drop policy if exists "Users can upload own medicine photos" on storage.objects;
drop policy if exists "Users can update medicine photos" on storage.objects;
drop policy if exists "Users can update their own medicine photos" on storage.objects;
drop policy if exists "Users can update own medicine photos" on storage.objects;
drop policy if exists "Users can delete medicine photos" on storage.objects;
drop policy if exists "Users can delete their own medicine photos" on storage.objects;
drop policy if exists "Users can delete own medicine photos" on storage.objects;

create policy "Users can upload own medicine photos"
  on storage.objects for insert
  to authenticated
  with check (
    bucket_id = 'medicine-photos'
    and (storage.foldername(name))[1] = (select auth.uid())::text
  );

create policy "Users can update own medicine photos"
  on storage.objects for update
  to authenticated
  using (
    bucket_id = 'medicine-photos'
    and (storage.foldername(name))[1] = (select auth.uid())::text
  )
  with check (
    bucket_id = 'medicine-photos'
    and (storage.foldername(name))[1] = (select auth.uid())::text
  );

create policy "Users can delete own medicine photos"
  on storage.objects for delete
  to authenticated
  using (
    bucket_id = 'medicine-photos'
    and (storage.foldername(name))[1] = (select auth.uid())::text
  );

drop policy if exists "Owners and admins can read task completion proofs" on storage.objects;
drop policy if exists "Users can upload own task completion proofs" on storage.objects;
drop policy if exists "Users can update own task completion proofs" on storage.objects;
drop policy if exists "Users can delete own task completion proofs" on storage.objects;

create policy "Owners and admins can read task completion proofs"
  on storage.objects for select
  to authenticated
  using (
    bucket_id = 'task-completion-proofs'
    and (
      (storage.foldername(name))[1] = (select auth.uid())::text
      or (select private.is_admin())
    )
  );

create policy "Users can upload own task completion proofs"
  on storage.objects for insert
  to authenticated
  with check (
    bucket_id = 'task-completion-proofs'
    and (storage.foldername(name))[1] = (select auth.uid())::text
  );

create policy "Users can update own task completion proofs"
  on storage.objects for update
  to authenticated
  using (
    bucket_id = 'task-completion-proofs'
    and (storage.foldername(name))[1] = (select auth.uid())::text
  )
  with check (
    bucket_id = 'task-completion-proofs'
    and (storage.foldername(name))[1] = (select auth.uid())::text
  );

create policy "Users can delete own task completion proofs"
  on storage.objects for delete
  to authenticated
  using (
    bucket_id = 'task-completion-proofs'
    and (storage.foldername(name))[1] = (select auth.uid())::text
  );
