-- Optimize RLS policy evaluation and remove overlapping permissive SELECT policies.
-- This keeps the same access model:
-- - Owners can insert/update/delete their own records.
-- - Admins can read user-owned records.
-- - Admins can fully manage education articles.

-- Profiles: keep existing behavior but avoid per-row auth function re-evaluation.
drop policy if exists "Users can view own profile" on profiles;
drop policy if exists "Users can insert own profile" on profiles;
drop policy if exists "Users can update own profile" on profiles;

create policy "Users can view own profile"
  on profiles for select
  using ((select auth.uid()) = id or (select public.is_admin()));

create policy "Users can insert own profile"
  on profiles for insert
  with check ((select auth.uid()) = id or (select public.is_admin()));

create policy "Users can update own profile"
  on profiles for update
  using ((select auth.uid()) = id or (select public.is_admin()))
  with check ((select auth.uid()) = id or (select public.is_admin()));

-- Admin audit logs: avoid per-row auth function re-evaluation in INSERT check.
drop policy if exists "Admins can insert admin audit logs" on admin_audit_logs;

create policy "Admins can insert admin audit logs"
  on admin_audit_logs for insert
  with check ((select public.is_admin()) and actor_id = (select auth.uid()));

-- care_persons
drop policy if exists "Owner manages their care persons" on care_persons;
drop policy if exists "Admins can read care persons" on care_persons;

create policy "Owner or admin reads care persons"
  on care_persons for select
  using ((select auth.uid()) = owner_id or (select public.is_admin()));

create policy "Owner inserts care persons"
  on care_persons for insert
  with check ((select auth.uid()) = owner_id);

create policy "Owner updates care persons"
  on care_persons for update
  using ((select auth.uid()) = owner_id)
  with check ((select auth.uid()) = owner_id);

create policy "Owner deletes care persons"
  on care_persons for delete
  using ((select auth.uid()) = owner_id);

-- medicines
drop policy if exists "Owner manages medicines" on medicines;
drop policy if exists "Admins can read medicines" on medicines;

create policy "Owner or admin reads medicines"
  on medicines for select
  using ((select auth.uid()) = owner_id or (select public.is_admin()));

create policy "Owner inserts medicines"
  on medicines for insert
  with check ((select auth.uid()) = owner_id);

create policy "Owner updates medicines"
  on medicines for update
  using ((select auth.uid()) = owner_id)
  with check ((select auth.uid()) = owner_id);

create policy "Owner deletes medicines"
  on medicines for delete
  using ((select auth.uid()) = owner_id);

-- medicine_schedules
drop policy if exists "Owner manages schedules" on medicine_schedules;
drop policy if exists "Admins can read schedules" on medicine_schedules;

create policy "Owner or admin reads schedules"
  on medicine_schedules for select
  using ((select auth.uid()) = owner_id or (select public.is_admin()));

create policy "Owner inserts schedules"
  on medicine_schedules for insert
  with check ((select auth.uid()) = owner_id);

create policy "Owner updates schedules"
  on medicine_schedules for update
  using ((select auth.uid()) = owner_id)
  with check ((select auth.uid()) = owner_id);

create policy "Owner deletes schedules"
  on medicine_schedules for delete
  using ((select auth.uid()) = owner_id);

-- schedule_time_slots
drop policy if exists "Owner manages schedule time slots" on schedule_time_slots;
drop policy if exists "Admins can read schedule slots" on schedule_time_slots;

create policy "Owner or admin reads schedule slots"
  on schedule_time_slots for select
  using (
    (
      exists (
        select 1
        from medicine_schedules ms
        where ms.id = schedule_time_slots.schedule_id
          and ms.owner_id = (select auth.uid())
      )
    )
    or (select public.is_admin())
  );

create policy "Owner inserts schedule slots"
  on schedule_time_slots for insert
  with check (
    exists (
      select 1
      from medicine_schedules ms
      where ms.id = schedule_time_slots.schedule_id
        and ms.owner_id = (select auth.uid())
    )
  );

create policy "Owner updates schedule slots"
  on schedule_time_slots for update
  using (
    exists (
      select 1
      from medicine_schedules ms
      where ms.id = schedule_time_slots.schedule_id
        and ms.owner_id = (select auth.uid())
    )
  )
  with check (
    exists (
      select 1
      from medicine_schedules ms
      where ms.id = schedule_time_slots.schedule_id
        and ms.owner_id = (select auth.uid())
    )
  );

create policy "Owner deletes schedule slots"
  on schedule_time_slots for delete
  using (
    exists (
      select 1
      from medicine_schedules ms
      where ms.id = schedule_time_slots.schedule_id
        and ms.owner_id = (select auth.uid())
    )
  );

-- task_logs
drop policy if exists "Owner manages task logs" on task_logs;
drop policy if exists "Admins can read task logs" on task_logs;

create policy "Owner or admin reads task logs"
  on task_logs for select
  using ((select auth.uid()) = owner_id or (select public.is_admin()));

create policy "Owner inserts task logs"
  on task_logs for insert
  with check ((select auth.uid()) = owner_id);

create policy "Owner updates task logs"
  on task_logs for update
  using ((select auth.uid()) = owner_id)
  with check ((select auth.uid()) = owner_id);

create policy "Owner deletes task logs"
  on task_logs for delete
  using ((select auth.uid()) = owner_id);

-- measurement_reminders
drop policy if exists "Owner manages measurement reminders" on measurement_reminders;
drop policy if exists "Admins can read measurement reminders" on measurement_reminders;

create policy "Owner or admin reads measurement reminders"
  on measurement_reminders for select
  using ((select auth.uid()) = owner_id or (select public.is_admin()));

create policy "Owner inserts measurement reminders"
  on measurement_reminders for insert
  with check ((select auth.uid()) = owner_id);

create policy "Owner updates measurement reminders"
  on measurement_reminders for update
  using ((select auth.uid()) = owner_id)
  with check ((select auth.uid()) = owner_id);

create policy "Owner deletes measurement reminders"
  on measurement_reminders for delete
  using ((select auth.uid()) = owner_id);

-- measurement_logs
drop policy if exists "Owner manages measurement logs" on measurement_logs;
drop policy if exists "Admins can read measurement logs" on measurement_logs;

create policy "Owner or admin reads measurement logs"
  on measurement_logs for select
  using ((select auth.uid()) = owner_id or (select public.is_admin()));

create policy "Owner inserts measurement logs"
  on measurement_logs for insert
  with check ((select auth.uid()) = owner_id);

create policy "Owner updates measurement logs"
  on measurement_logs for update
  using ((select auth.uid()) = owner_id)
  with check ((select auth.uid()) = owner_id);

create policy "Owner deletes measurement logs"
  on measurement_logs for delete
  using ((select auth.uid()) = owner_id);

-- physical_activity_reminders
drop policy if exists "Owner manages activity reminders" on physical_activity_reminders;
drop policy if exists "Admins can read activity reminders" on physical_activity_reminders;

create policy "Owner or admin reads activity reminders"
  on physical_activity_reminders for select
  using ((select auth.uid()) = owner_id or (select public.is_admin()));

create policy "Owner inserts activity reminders"
  on physical_activity_reminders for insert
  with check ((select auth.uid()) = owner_id);

create policy "Owner updates activity reminders"
  on physical_activity_reminders for update
  using ((select auth.uid()) = owner_id)
  with check ((select auth.uid()) = owner_id);

create policy "Owner deletes activity reminders"
  on physical_activity_reminders for delete
  using ((select auth.uid()) = owner_id);

-- physical_activity_logs
drop policy if exists "Owner manages activity logs" on physical_activity_logs;
drop policy if exists "Admins can read activity logs" on physical_activity_logs;

create policy "Owner or admin reads activity logs"
  on physical_activity_logs for select
  using ((select auth.uid()) = owner_id or (select public.is_admin()));

create policy "Owner inserts activity logs"
  on physical_activity_logs for insert
  with check ((select auth.uid()) = owner_id);

create policy "Owner updates activity logs"
  on physical_activity_logs for update
  using ((select auth.uid()) = owner_id)
  with check ((select auth.uid()) = owner_id);

create policy "Owner deletes activity logs"
  on physical_activity_logs for delete
  using ((select auth.uid()) = owner_id);

-- notification_logs
drop policy if exists "Owner manages notification logs" on notification_logs;
drop policy if exists "Admins can read notification logs" on notification_logs;

create policy "Owner or admin reads notification logs"
  on notification_logs for select
  using ((select auth.uid()) = owner_id or (select public.is_admin()));

create policy "Owner inserts notification logs"
  on notification_logs for insert
  with check ((select auth.uid()) = owner_id);

create policy "Owner updates notification logs"
  on notification_logs for update
  using ((select auth.uid()) = owner_id)
  with check ((select auth.uid()) = owner_id);

create policy "Owner deletes notification logs"
  on notification_logs for delete
  using ((select auth.uid()) = owner_id);

-- user_streaks
drop policy if exists "Owner manages streak" on user_streaks;
drop policy if exists "Admins can read streaks" on user_streaks;

create policy "Owner or admin reads streaks"
  on user_streaks for select
  using ((select auth.uid()) = owner_id or (select public.is_admin()));

create policy "Owner inserts streaks"
  on user_streaks for insert
  with check ((select auth.uid()) = owner_id);

create policy "Owner updates streaks"
  on user_streaks for update
  using ((select auth.uid()) = owner_id)
  with check ((select auth.uid()) = owner_id);

create policy "Owner deletes streaks"
  on user_streaks for delete
  using ((select auth.uid()) = owner_id);

-- shared_access_tokens
drop policy if exists "Owner manages shared tokens" on shared_access_tokens;
drop policy if exists "Admins can read shared tokens" on shared_access_tokens;

create policy "Owner or admin reads shared tokens"
  on shared_access_tokens for select
  using ((select auth.uid()) = owner_id or (select public.is_admin()));

create policy "Owner inserts shared tokens"
  on shared_access_tokens for insert
  with check ((select auth.uid()) = owner_id);

create policy "Owner updates shared tokens"
  on shared_access_tokens for update
  using ((select auth.uid()) = owner_id)
  with check ((select auth.uid()) = owner_id);

create policy "Owner deletes shared tokens"
  on shared_access_tokens for delete
  using ((select auth.uid()) = owner_id);

-- education_articles: keep one SELECT policy and split admin manage policy by action
-- to avoid overlapping permissive SELECT policies.
drop policy if exists "Users can read published education articles" on education_articles;
drop policy if exists "Admins can manage education articles" on education_articles;

create policy "Users can read published education articles"
  on education_articles for select
  using (status = 'published' or (select public.is_admin()));

create policy "Admins can insert education articles"
  on education_articles for insert
  with check ((select public.is_admin()));

create policy "Admins can update education articles"
  on education_articles for update
  using ((select public.is_admin()))
  with check ((select public.is_admin()));

create policy "Admins can delete education articles"
  on education_articles for delete
  using ((select public.is_admin()));
