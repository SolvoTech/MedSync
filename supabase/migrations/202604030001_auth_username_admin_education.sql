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

drop policy if exists "Admins can read care persons" on care_persons;
create policy "Admins can read care persons"
  on care_persons for select
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

drop policy if exists "Admins can read shared tokens" on shared_access_tokens;
create policy "Admins can read shared tokens"
  on shared_access_tokens for select
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
