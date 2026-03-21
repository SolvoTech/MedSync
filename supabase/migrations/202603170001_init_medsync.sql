-- MedSync initial schema
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

create table if not exists care_persons (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references profiles(id) on delete cascade,
  display_name text not null,
  relationship text,
  birth_date date,
  notes text,
  avatar_color text,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

create table if not exists medicines (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references profiles(id) on delete cascade,
  care_person_id uuid references care_persons(id) on delete cascade,
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
  care_person_id uuid references care_persons(id),
  task_type text not null,
  reference_id uuid not null,
  time_slot_id uuid references schedule_time_slots(id),
  scheduled_at timestamptz not null,
  completed_at timestamptz,
  status text default 'pending',
  mood text,
  symptom_notes text,
  notes text,
  created_at timestamptz default now()
);

create table if not exists measurement_reminders (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references profiles(id) on delete cascade,
  care_person_id uuid references care_persons(id),
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
  care_person_id uuid references care_persons(id),
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

create table if not exists shared_access_tokens (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references profiles(id) on delete cascade,
  care_person_id uuid not null references care_persons(id) on delete cascade,
  token text unique not null,
  token_display text not null,
  viewer_name text,
  is_active boolean default true,
  expires_at timestamptz,
  last_accessed_at timestamptz,
  created_at timestamptz default now()
);

alter table profiles enable row level security;
alter table care_persons enable row level security;
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
alter table shared_access_tokens enable row level security;

create policy "Users can manage their own profile"
  on profiles for all using (auth.uid() = id);

create policy "Owner manages their care persons"
  on care_persons for all using (auth.uid() = owner_id);

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

create policy "Owner manages shared tokens"
  on shared_access_tokens for all using (auth.uid() = owner_id);

create index if not exists task_logs_scheduled_at_idx
  on task_logs(owner_id, scheduled_at desc);

create index if not exists task_logs_date_idx
  on task_logs(owner_id, ((scheduled_at at time zone 'utc')::date));

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

