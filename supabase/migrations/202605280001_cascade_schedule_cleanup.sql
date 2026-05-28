-- Ensure deleting reminder parents also cleans generated schedule/task data.
-- This migration is idempotent for live projects that may have older FK rules.

create index if not exists task_logs_task_type_reference_id_idx
  on public.task_logs (task_type, reference_id);

create or replace function public.delete_task_logs_for_deleted_schedule()
returns trigger
language plpgsql
security invoker
set search_path = public
as $$
begin
  delete from public.task_logs
  where task_type = 'medicine'
    and reference_id = old.id;

  return old;
end;
$$;

create or replace function public.delete_task_logs_for_deleted_measurement_reminder()
returns trigger
language plpgsql
security invoker
set search_path = public
as $$
begin
  delete from public.task_logs
  where task_type = 'measurement'
    and reference_id = old.id;

  return old;
end;
$$;

create or replace function public.delete_task_logs_for_deleted_activity_reminder()
returns trigger
language plpgsql
security invoker
set search_path = public
as $$
begin
  delete from public.task_logs
  where task_type = 'physical_activity'
    and reference_id = old.id;

  return old;
end;
$$;

drop trigger if exists delete_task_logs_before_medicine_schedule_delete
  on public.medicine_schedules;
create trigger delete_task_logs_before_medicine_schedule_delete
before delete on public.medicine_schedules
for each row
execute function public.delete_task_logs_for_deleted_schedule();

drop trigger if exists delete_task_logs_before_measurement_reminder_delete
  on public.measurement_reminders;
create trigger delete_task_logs_before_measurement_reminder_delete
before delete on public.measurement_reminders
for each row
execute function public.delete_task_logs_for_deleted_measurement_reminder();

drop trigger if exists delete_task_logs_before_activity_reminder_delete
  on public.physical_activity_reminders;
create trigger delete_task_logs_before_activity_reminder_delete
before delete on public.physical_activity_reminders
for each row
execute function public.delete_task_logs_for_deleted_activity_reminder();

delete from public.task_logs tl
where tl.task_type = 'medicine'
  and not exists (
    select 1
    from public.medicine_schedules ms
    where ms.id = tl.reference_id
  );

delete from public.task_logs tl
where tl.task_type = 'medicine'
  and exists (
    select 1
    from public.medicine_schedules ms
    where ms.id = tl.reference_id
      and not exists (
        select 1
        from public.medicines m
        where m.id = ms.medicine_id
      )
  );

delete from public.task_logs tl
where tl.task_type = 'measurement'
  and not exists (
    select 1
    from public.measurement_reminders mr
    where mr.id = tl.reference_id
  );

delete from public.task_logs tl
where tl.task_type = 'physical_activity'
  and not exists (
    select 1
    from public.physical_activity_reminders par
    where par.id = tl.reference_id
  );

delete from public.schedule_time_slots sts
where not exists (
  select 1
  from public.medicine_schedules ms
  where ms.id = sts.schedule_id
);

delete from public.schedule_time_slots sts
where exists (
  select 1
  from public.medicine_schedules ms
  where ms.id = sts.schedule_id
    and not exists (
      select 1
      from public.medicines m
      where m.id = ms.medicine_id
    )
);

delete from public.medicine_schedules ms
where not exists (
  select 1
  from public.medicines m
  where m.id = ms.medicine_id
);

update public.measurement_logs ml
set reminder_id = null
where reminder_id is not null
  and not exists (
    select 1
    from public.measurement_reminders mr
    where mr.id = ml.reminder_id
  );

update public.physical_activity_logs pal
set reminder_id = null
where reminder_id is not null
  and not exists (
    select 1
    from public.physical_activity_reminders par
    where par.id = pal.reminder_id
  );

alter table if exists public.medicine_schedules
  drop constraint if exists medicine_schedules_medicine_id_fkey;
alter table if exists public.medicine_schedules
  add constraint medicine_schedules_medicine_id_fkey
  foreign key (medicine_id)
  references public.medicines(id)
  on delete cascade;

alter table if exists public.schedule_time_slots
  drop constraint if exists schedule_time_slots_schedule_id_fkey;
alter table if exists public.schedule_time_slots
  add constraint schedule_time_slots_schedule_id_fkey
  foreign key (schedule_id)
  references public.medicine_schedules(id)
  on delete cascade;

alter table if exists public.measurement_logs
  drop constraint if exists measurement_logs_reminder_id_fkey;
alter table if exists public.measurement_logs
  add constraint measurement_logs_reminder_id_fkey
  foreign key (reminder_id)
  references public.measurement_reminders(id)
  on delete set null;

alter table if exists public.physical_activity_logs
  drop constraint if exists physical_activity_logs_reminder_id_fkey;
alter table if exists public.physical_activity_logs
  add constraint physical_activity_logs_reminder_id_fkey
  foreign key (reminder_id)
  references public.physical_activity_reminders(id)
  on delete set null;

revoke all on function public.delete_task_logs_for_deleted_schedule() from public;
revoke all on function public.delete_task_logs_for_deleted_measurement_reminder() from public;
revoke all on function public.delete_task_logs_for_deleted_activity_reminder() from public;
