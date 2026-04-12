-- Enforce ON DELETE CASCADE from medicines -> medicine_schedules
-- and from medicine_schedules -> schedule_time_slots.
-- This migration is defensive against schema drift in production.

begin;

-- Cleanup potential orphan rows before recreating FK constraints.
delete from public.schedule_time_slots sts
where not exists (
  select 1
  from public.medicine_schedules ms
  where ms.id = sts.schedule_id
);

delete from public.medicine_schedules ms
where not exists (
  select 1
  from public.medicines m
  where m.id = ms.medicine_id
);

-- Recreate medicine_schedules -> medicines FK with ON DELETE CASCADE.
do $$
declare
  rec record;
begin
  for rec in
    select c.conname
    from pg_constraint c
    join pg_class t on t.oid = c.conrelid
    join pg_namespace n on n.oid = t.relnamespace
    join pg_class rt on rt.oid = c.confrelid
    join pg_namespace rn on rn.oid = rt.relnamespace
    where c.contype = 'f'
      and n.nspname = 'public'
      and t.relname = 'medicine_schedules'
      and rn.nspname = 'public'
      and rt.relname = 'medicines'
  loop
    execute format(
      'alter table public.medicine_schedules drop constraint %I',
      rec.conname
    );
  end loop;
end
$$;

alter table public.medicine_schedules
  add constraint medicine_schedules_medicine_id_fkey
  foreign key (medicine_id)
  references public.medicines(id)
  on delete cascade;

-- Recreate schedule_time_slots -> medicine_schedules FK with ON DELETE CASCADE.
do $$
declare
  rec record;
begin
  for rec in
    select c.conname
    from pg_constraint c
    join pg_class t on t.oid = c.conrelid
    join pg_namespace n on n.oid = t.relnamespace
    join pg_class rt on rt.oid = c.confrelid
    join pg_namespace rn on rn.oid = rt.relnamespace
    where c.contype = 'f'
      and n.nspname = 'public'
      and t.relname = 'schedule_time_slots'
      and rn.nspname = 'public'
      and rt.relname = 'medicine_schedules'
  loop
    execute format(
      'alter table public.schedule_time_slots drop constraint %I',
      rec.conname
    );
  end loop;
end
$$;

alter table public.schedule_time_slots
  add constraint schedule_time_slots_schedule_id_fkey
  foreign key (schedule_id)
  references public.medicine_schedules(id)
  on delete cascade;

commit;
