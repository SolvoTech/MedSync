-- Add covering indexes for foreign keys flagged by Supabase performance advisor.

create index if not exists care_persons_owner_id_idx
  on public.care_persons (owner_id);

create index if not exists education_articles_author_id_idx
  on public.education_articles (author_id);

create index if not exists measurement_logs_care_person_id_idx
  on public.measurement_logs (care_person_id);

create index if not exists measurement_logs_owner_id_idx
  on public.measurement_logs (owner_id);

create index if not exists measurement_logs_reminder_id_idx
  on public.measurement_logs (reminder_id);

create index if not exists measurement_reminders_care_person_id_idx
  on public.measurement_reminders (care_person_id);

create index if not exists measurement_reminders_owner_id_idx
  on public.measurement_reminders (owner_id);

create index if not exists medicine_schedules_medicine_id_idx
  on public.medicine_schedules (medicine_id);

create index if not exists medicine_schedules_owner_id_idx
  on public.medicine_schedules (owner_id);

create index if not exists medicines_care_person_id_idx
  on public.medicines (care_person_id);

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

create index if not exists shared_access_tokens_care_person_id_idx
  on public.shared_access_tokens (care_person_id);

create index if not exists shared_access_tokens_owner_id_idx
  on public.shared_access_tokens (owner_id);

create index if not exists task_logs_care_person_id_idx
  on public.task_logs (care_person_id);

create index if not exists task_logs_time_slot_id_idx
  on public.task_logs (time_slot_id);
