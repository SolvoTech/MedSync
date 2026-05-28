-- Keep foreign key columns covered after removing unused non-FK indexes.

create index if not exists admin_audit_logs_actor_idx
  on public.admin_audit_logs (actor_id);

create index if not exists admin_audit_logs_target_idx
  on public.admin_audit_logs (target_user_id);

create index if not exists app_monitoring_logs_actor_created_idx
  on public.app_monitoring_logs (actor_id, created_at desc);

create index if not exists measurement_logs_owner_id_idx
  on public.measurement_logs (owner_id);

create index if not exists physical_activity_logs_owner_id_idx
  on public.physical_activity_logs (owner_id);
