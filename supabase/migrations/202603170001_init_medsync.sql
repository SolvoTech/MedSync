-- MEDISNA initial schema
create extension if not exists pgcrypto;

create table if not exists profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text not null,
  birth_date date,
  avatar_url text,
  theme_mode text default 'system',
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

create table if not exists medicines (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references profiles(id) on delete cascade,
  name text not null,
  dosage text,
  medicine_type text default 'tablet',
  stock_current integer default 0,
  stock_unit text default 'tablet',
  stock_low_threshold integer default 5,
  stock_reminder_at integer default 3,
  notes text,
  color text,
  icon text,
  photo_url text,
  is_active boolean default true,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

create table if not exists medicine_schedules (
  id uuid primary key default gen_random_uuid(),
  medicine_id uuid not null references medicines(id) on delete cascade,
  owner_id uuid not null references profiles(id) on delete cascade,
  schedule_name text,
  repeat_type text default 'daily',
  repeat_days integer[],
  interval_days integer default 1,
  start_date date not null,
  end_date date,
  is_active boolean default true,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

create table if not exists schedule_time_slots (
  id uuid primary key default gen_random_uuid(),
  schedule_id uuid not null references medicine_schedules(id) on delete cascade,
  time_of_day time not null,
  dosage_amount numeric default 1,
  dosage_unit text default 'tablet',
  with_food boolean default false,
  notes text,
  notification_enabled boolean default true,
  notification_before_minutes integer default 0,
  followup_enabled boolean default false,
  followup_after_minutes integer default 15,
  created_at timestamptz default now()
);

create table if not exists task_logs (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references profiles(id) on delete cascade,
  task_type text not null,
  reference_id uuid not null,
  time_slot_id uuid references schedule_time_slots(id),
  scheduled_at timestamptz not null,
  completed_at timestamptz,
  status text default 'pending',
  mood text,
  symptom_notes text,
  notes text,
  completion_proof_photo_path text,
  completion_proof_captured_at timestamptz,
  completion_proof_uploaded_at timestamptz,
  created_at timestamptz default now(),
  constraint task_logs_completion_proof_owner_path_check
    check (
      completion_proof_photo_path is null
      or split_part(completion_proof_photo_path, '/', 1) = owner_id::text
    )
);

create table if not exists measurement_reminders (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references profiles(id) on delete cascade,
  measurement_type text not null,
  custom_name text,
  repeat_type text default 'daily',
  repeat_days integer[],
  interval_days integer default 1,
  time_of_day time not null,
  start_date date not null,
  end_date date,
  target_value text,
  unit text,
  is_active boolean default true,
  notification_enabled boolean default true,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

create table if not exists measurement_logs (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references profiles(id) on delete cascade,
  reminder_id uuid references measurement_reminders(id),
  measurement_type text not null,
  value_primary numeric not null,
  value_secondary numeric,
  unit text,
  notes text,
  measured_at timestamptz not null default now(),
  source text default 'manual',
  created_at timestamptz default now()
);

create table if not exists physical_activity_reminders (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references profiles(id) on delete cascade,
  activity_type text not null,
  custom_name text,
  icon text,
  color text,
  repeat_type text default 'daily',
  repeat_days integer[],
  time_of_day time not null,
  duration_minutes integer,
  target_value numeric,
  target_unit text,
  start_date date not null,
  end_date date,
  is_active boolean default true,
  notification_enabled boolean default true,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

create table if not exists physical_activity_logs (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references profiles(id) on delete cascade,
  reminder_id uuid references physical_activity_reminders(id),
  activity_type text not null,
  actual_value numeric,
  unit text,
  duration_minutes integer,
  notes text,
  performed_at timestamptz not null default now(),
  source text default 'manual',
  created_at timestamptz default now()
);

create table if not exists notification_logs (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references profiles(id) on delete cascade,
  notification_type text not null,
  title text not null,
  body text not null,
  reference_id uuid,
  reference_type text,
  is_read boolean default false,
  action_taken text,
  scheduled_at timestamptz not null,
  delivered_at timestamptz,
  created_at timestamptz default now()
);

create table if not exists user_streaks (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid unique not null references profiles(id) on delete cascade,
  current_streak integer default 0,
  longest_streak integer default 0,
  last_completed_date date,
  streak_start_date date,
  updated_at timestamptz default now()
);

alter table profiles enable row level security;
alter table medicines enable row level security;
alter table medicine_schedules enable row level security;
alter table schedule_time_slots enable row level security;
alter table task_logs enable row level security;
alter table measurement_reminders enable row level security;
alter table measurement_logs enable row level security;
alter table physical_activity_reminders enable row level security;
alter table physical_activity_logs enable row level security;
alter table notification_logs enable row level security;
alter table user_streaks enable row level security;

create policy "Users can manage their own profile"
  on profiles for all using (auth.uid() = id);

create policy "Owner manages medicines"
  on medicines for all using (auth.uid() = owner_id);

create policy "Owner manages schedules"
  on medicine_schedules for all using (auth.uid() = owner_id);

create policy "Owner manages schedule time slots"
  on schedule_time_slots for all using (
    exists (
      select 1
      from medicine_schedules ms
      where ms.id = schedule_time_slots.schedule_id
        and ms.owner_id = auth.uid()
    )
  );

create policy "Owner manages task logs"
  on task_logs for all using (auth.uid() = owner_id);

create policy "Owner manages measurement reminders"
  on measurement_reminders for all using (auth.uid() = owner_id);

create policy "Owner manages measurement logs"
  on measurement_logs for all using (auth.uid() = owner_id);

create policy "Owner manages activity reminders"
  on physical_activity_reminders for all using (auth.uid() = owner_id);

create policy "Owner manages activity logs"
  on physical_activity_logs for all using (auth.uid() = owner_id);

create policy "Owner manages notification logs"
  on notification_logs for all using (auth.uid() = owner_id);

create policy "Owner manages streak"
  on user_streaks for all using (auth.uid() = owner_id);

create index if not exists task_logs_scheduled_at_idx
  on task_logs(owner_id, scheduled_at desc);

create index if not exists task_logs_date_idx
  on task_logs(owner_id, ((scheduled_at at time zone 'utc')::date));

create index if not exists task_logs_completion_proof_idx
  on public.task_logs (owner_id, completion_proof_uploaded_at desc)
  where completion_proof_photo_path is not null;

create index if not exists notif_logs_created_at_idx
  on notification_logs(owner_id, created_at desc);

-- Allow authenticated users to permanently delete their own auth account.
-- Deleting auth.users row cascades to profiles and all owner-linked tables.
create or replace function public.delete_my_account()
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

revoke all on function public.delete_my_account() from public;
grant execute on function public.delete_my_account() to authenticated;



-- Consolidated from: 202604030001_auth_username_admin_education.sql

-- Username auth, admin control center, and education foundations.

alter table if exists profiles
  add column if not exists username text,
  add column if not exists role text not null default 'user',
  add column if not exists account_status text not null default 'active',
  add column if not exists internal_email text;

alter table profiles
  drop constraint if exists profiles_role_check;
alter table profiles
  add constraint profiles_role_check
  check (role in ('user', 'admin'));

alter table profiles
  drop constraint if exists profiles_account_status_check;
alter table profiles
  add constraint profiles_account_status_check
  check (account_status in ('active', 'suspended'));

create unique index if not exists profiles_username_unique_idx
  on profiles ((lower(username)))
  where username is not null;

create unique index if not exists profiles_internal_email_unique_idx
  on profiles (internal_email)
  where internal_email is not null;

create index if not exists profiles_role_status_idx
  on profiles (role, account_status);

update profiles p
set
  username = coalesce(
    p.username,
    concat(
      coalesce(
        nullif(
          lower(
            regexp_replace(
              split_part(coalesce(u.email, ''), '@', 1),
              '[^a-z0-9_]',
              '_',
              'g'
            )
          ),
          ''
        ),
        'user'
      ),
      '_',
      substr(p.id::text, 1, 6)
    )
  ),
  internal_email = coalesce(
    p.internal_email,
    lower(
      coalesce(
        u.email,
        concat('legacy_', substr(p.id::text, 1, 8), '@users.medsync.local')
      )
    )
  ),
  role = coalesce(p.role, 'user'),
  account_status = coalesce(p.account_status, 'active')
from auth.users u
where p.id = u.id;

update profiles
set
  username = coalesce(username, concat('user_', substr(id::text, 1, 8))),
  internal_email = coalesce(
    internal_email,
    concat('legacy_', substr(id::text, 1, 8), '@users.medsync.local')
  )
where username is null
   or internal_email is null;

create or replace function public.is_admin(target_user_id uuid default auth.uid())
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

revoke all on function public.is_admin(uuid) from public;
grant execute on function public.is_admin(uuid) to authenticated;

create or replace function public.guard_profile_sensitive_fields()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  requester_is_admin boolean := public.is_admin(auth.uid());
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

drop trigger if exists profiles_guard_sensitive_fields on profiles;
create trigger profiles_guard_sensitive_fields
before insert or update on profiles
for each row execute function public.guard_profile_sensitive_fields();

drop policy if exists "Users can manage their own profile" on profiles;
drop policy if exists "Users can view own profile" on profiles;
drop policy if exists "Users can insert own profile" on profiles;
drop policy if exists "Users can update own profile" on profiles;
drop policy if exists "Admins can delete profiles" on profiles;

create policy "Users can view own profile"
  on profiles for select
  using (auth.uid() = id or public.is_admin());

create policy "Users can insert own profile"
  on profiles for insert
  with check (auth.uid() = id or public.is_admin());

create policy "Users can update own profile"
  on profiles for update
  using (auth.uid() = id or public.is_admin())
  with check (auth.uid() = id or public.is_admin());

create policy "Admins can delete profiles"
  on profiles for delete
  using (public.is_admin());

drop policy if exists "Admins can read medicines" on medicines;
create policy "Admins can read medicines"
  on medicines for select
  using (public.is_admin());

drop policy if exists "Admins can read schedules" on medicine_schedules;
create policy "Admins can read schedules"
  on medicine_schedules for select
  using (public.is_admin());

drop policy if exists "Admins can read schedule slots" on schedule_time_slots;
create policy "Admins can read schedule slots"
  on schedule_time_slots for select
  using (public.is_admin());

drop policy if exists "Admins can read task logs" on task_logs;
create policy "Admins can read task logs"
  on task_logs for select
  using (public.is_admin());

drop policy if exists "Admins can read measurement reminders" on measurement_reminders;
create policy "Admins can read measurement reminders"
  on measurement_reminders for select
  using (public.is_admin());

drop policy if exists "Admins can read measurement logs" on measurement_logs;
create policy "Admins can read measurement logs"
  on measurement_logs for select
  using (public.is_admin());

drop policy if exists "Admins can read activity reminders" on physical_activity_reminders;
create policy "Admins can read activity reminders"
  on physical_activity_reminders for select
  using (public.is_admin());

drop policy if exists "Admins can read activity logs" on physical_activity_logs;
create policy "Admins can read activity logs"
  on physical_activity_logs for select
  using (public.is_admin());

drop policy if exists "Admins can read notification logs" on notification_logs;
create policy "Admins can read notification logs"
  on notification_logs for select
  using (public.is_admin());

drop policy if exists "Admins can read streaks" on user_streaks;
create policy "Admins can read streaks"
  on user_streaks for select
  using (public.is_admin());

create table if not exists admin_audit_logs (
  id uuid primary key default gen_random_uuid(),
  actor_id uuid not null references profiles(id) on delete cascade,
  target_user_id uuid references profiles(id) on delete set null,
  action text not null,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

alter table admin_audit_logs enable row level security;

create index if not exists admin_audit_logs_actor_idx
  on admin_audit_logs (actor_id, created_at desc);

create index if not exists admin_audit_logs_target_idx
  on admin_audit_logs (target_user_id, created_at desc);

drop policy if exists "Admins can read admin audit logs" on admin_audit_logs;
create policy "Admins can read admin audit logs"
  on admin_audit_logs for select
  using (public.is_admin());

drop policy if exists "Admins can insert admin audit logs" on admin_audit_logs;
create policy "Admins can insert admin audit logs"
  on admin_audit_logs for insert
  with check (public.is_admin() and actor_id = auth.uid());

create table if not exists education_articles (
  id uuid primary key default gen_random_uuid(),
  author_id uuid not null references profiles(id) on delete restrict,
  title text not null,
  slug text not null,
  summary text,
  content text not null,
  cover_url text,
  category text,
  status text not null default 'draft',
  published_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint education_articles_status_check
    check (status in ('draft', 'published'))
);

alter table education_articles enable row level security;

create unique index if not exists education_articles_slug_unique_idx
  on education_articles (slug);

create index if not exists education_articles_status_published_idx
  on education_articles (status, published_at desc);

create or replace function public.touch_education_article()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  new.updated_at := now();

  if new.status = 'published' and new.published_at is null then
    new.published_at := now();
  end if;

  if new.status <> 'published' then
    new.published_at := null;
  end if;

  return new;
end;
$$;

drop trigger if exists education_articles_touch on education_articles;
create trigger education_articles_touch
before insert or update on education_articles
for each row execute function public.touch_education_article();

drop policy if exists "Users can read published education articles" on education_articles;
create policy "Users can read published education articles"
  on education_articles for select
  using (status = 'published' or public.is_admin());

drop policy if exists "Admins can manage education articles" on education_articles;
create policy "Admins can manage education articles"
  on education_articles for all
  using (public.is_admin())
  with check (public.is_admin());


-- Consolidated from: 202604030002_education_publish_notifications.sql

-- Broadcast in-app notification to users when an education article is published.

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

drop trigger if exists education_articles_notify_on_publish on public.education_articles;
create trigger education_articles_notify_on_publish
after insert or update of status on public.education_articles
for each row execute function public.notify_users_on_education_publish();


-- Consolidated from: 202604030003_fk_performance_indexes.sql

-- Add covering indexes for foreign keys flagged by Supabase performance advisor.

create index if not exists education_articles_author_id_idx
  on public.education_articles (author_id);

create index if not exists measurement_logs_owner_id_idx
  on public.measurement_logs (owner_id);

create index if not exists measurement_logs_reminder_id_idx
  on public.measurement_logs (reminder_id);

create index if not exists measurement_reminders_owner_id_idx
  on public.measurement_reminders (owner_id);

create index if not exists medicine_schedules_medicine_id_idx
  on public.medicine_schedules (medicine_id);

create index if not exists medicine_schedules_owner_id_idx
  on public.medicine_schedules (owner_id);

create index if not exists medicines_owner_id_idx
  on public.medicines (owner_id);

create index if not exists physical_activity_logs_owner_id_idx
  on public.physical_activity_logs (owner_id);

create index if not exists physical_activity_logs_reminder_id_idx
  on public.physical_activity_logs (reminder_id);

create index if not exists physical_activity_reminders_owner_id_idx
  on public.physical_activity_reminders (owner_id);

create index if not exists schedule_time_slots_schedule_id_idx
  on public.schedule_time_slots (schedule_id);

create index if not exists task_logs_time_slot_id_idx
  on public.task_logs (time_slot_id);
