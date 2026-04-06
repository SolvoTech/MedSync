-- Storage setup for user-uploaded medicine photos.
-- - Public read so images can be rendered directly from `photo_url`.
-- - Authenticated users can only manage files in their own folder prefix.

insert into storage.buckets (
  id,
  name,
  public,
  file_size_limit,
  allowed_mime_types
)
values (
  'medicine-photos',
  'medicine-photos',
  true,
  5242880,
  array['image/jpeg', 'image/png', 'image/webp']
)
on conflict (id) do update
set
  public = excluded.public,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists "Public can read medicine photos" on storage.objects;
create policy "Public can read medicine photos"
  on storage.objects for select
  using (bucket_id = 'medicine-photos');

drop policy if exists "Users can upload own medicine photos" on storage.objects;
create policy "Users can upload own medicine photos"
  on storage.objects for insert
  to authenticated
  with check (
    bucket_id = 'medicine-photos'
    and (storage.foldername(name))[1] = (select auth.uid())::text
  );

drop policy if exists "Users can update own medicine photos" on storage.objects;
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

drop policy if exists "Users can delete own medicine photos" on storage.objects;
create policy "Users can delete own medicine photos"
  on storage.objects for delete
  to authenticated
  using (
    bucket_id = 'medicine-photos'
    and (storage.foldername(name))[1] = (select auth.uid())::text
  );