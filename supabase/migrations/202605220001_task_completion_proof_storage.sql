-- Private storage for task completion proof photos.
-- Photos are evidence only; task completion is not validated by photo content.

insert into storage.buckets (
  id,
  name,
  public,
  file_size_limit,
  allowed_mime_types
)
values (
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

drop policy if exists "Owners and admins can read task completion proofs" on storage.objects;
create policy "Owners and admins can read task completion proofs"
  on storage.objects for select
  to authenticated
  using (
    bucket_id = 'task-completion-proofs'
    and (
      (storage.foldername(name))[1] = (select auth.uid())::text
      or (select public.is_admin())
    )
  );

drop policy if exists "Users can upload own task completion proofs" on storage.objects;
create policy "Users can upload own task completion proofs"
  on storage.objects for insert
  to authenticated
  with check (
    bucket_id = 'task-completion-proofs'
    and (storage.foldername(name))[1] = (select auth.uid())::text
  );

drop policy if exists "Users can update own task completion proofs" on storage.objects;
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

drop policy if exists "Users can delete own task completion proofs" on storage.objects;
create policy "Users can delete own task completion proofs"
  on storage.objects for delete
  to authenticated
  using (
    bucket_id = 'task-completion-proofs'
    and (storage.foldername(name))[1] = (select auth.uid())::text
  );
