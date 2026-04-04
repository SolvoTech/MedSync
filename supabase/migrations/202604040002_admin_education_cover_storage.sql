-- Storage hardening for admin-managed education article covers.
-- - Uses a dedicated public bucket so article covers can be rendered by all clients.
-- - Restricts write operations to authenticated admins only.
-- - Keeps object paths scoped to the uploader user id prefix.

insert into storage.buckets (
  id,
  name,
  public,
  file_size_limit,
  allowed_mime_types
)
values (
  'education-covers',
  'education-covers',
  true,
  5242880,
  array['image/jpeg', 'image/png', 'image/webp']
)
on conflict (id) do update
set
  public = excluded.public,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists "Public can read education cover images" on storage.objects;
create policy "Public can read education cover images"
  on storage.objects for select
  using (bucket_id = 'education-covers');

drop policy if exists "Admins can upload education cover images" on storage.objects;
create policy "Admins can upload education cover images"
  on storage.objects for insert
  to authenticated
  with check (
    bucket_id = 'education-covers'
    and (select public.is_admin())
    and (storage.foldername(name))[1] = (select auth.uid())::text
  );

drop policy if exists "Admins can update education cover images" on storage.objects;
create policy "Admins can update education cover images"
  on storage.objects for update
  to authenticated
  using (
    bucket_id = 'education-covers'
    and (select public.is_admin())
    and (storage.foldername(name))[1] = (select auth.uid())::text
  )
  with check (
    bucket_id = 'education-covers'
    and (select public.is_admin())
    and (storage.foldername(name))[1] = (select auth.uid())::text
  );

drop policy if exists "Admins can delete education cover images" on storage.objects;
create policy "Admins can delete education cover images"
  on storage.objects for delete
  to authenticated
  using (
    bucket_id = 'education-covers'
    and (select public.is_admin())
    and (storage.foldername(name))[1] = (select auth.uid())::text
  );
