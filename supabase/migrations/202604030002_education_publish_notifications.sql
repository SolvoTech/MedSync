-- Broadcast in-app notification to users when an education article is published.

create or replace function public.notify_users_on_education_publish()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if new.status <> 'published' then
    return new;
  end if;

  if tg_op = 'UPDATE' and old.status = 'published' then
    return new;
  end if;

  insert into public.notification_logs (
    owner_id,
    notification_type,
    title,
    body,
    reference_id,
    reference_type,
    is_read,
    action_taken,
    scheduled_at,
    delivered_at,
    created_at
  )
  select
    p.id,
    'education_article',
    'Artikel edukasi baru',
    format('Artikel baru telah dipublish: %s', new.title),
    new.id,
    'education_articles',
    false,
    null,
    now(),
    now(),
    now()
  from public.profiles p
  where coalesce(p.account_status, 'active') = 'active'
    and coalesce(p.role, 'user') = 'user';

  return new;
end;
$$;

drop trigger if exists education_articles_notify_on_publish on public.education_articles;
create trigger education_articles_notify_on_publish
after insert or update of status on public.education_articles
for each row execute function public.notify_users_on_education_publish();
