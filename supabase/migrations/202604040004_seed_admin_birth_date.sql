-- Ensure seeded admin profile always has birth_date and admin baseline fields.
-- Safe to run multiple times.

DO $$
DECLARE
  v_admin_username CONSTANT text := 'admin';
  v_internal_email_domain CONSTANT text := 'users.medsync.local';
  v_admin_birth_date CONSTANT date := DATE '1990-01-01';
  v_admin_email text;
  v_admin_id uuid;
  v_profile_trigger_disabled boolean := false;
BEGIN
  v_admin_email := lower(format('%s@%s', v_admin_username, v_internal_email_domain));

  SELECT p.id
    INTO v_admin_id
  FROM public.profiles p
  WHERE lower(coalesce(p.username, '')) = v_admin_username
  LIMIT 1;

  IF v_admin_id IS NULL THEN
    SELECT u.id
      INTO v_admin_id
    FROM auth.users u
    WHERE lower(coalesce(u.email, '')) = v_admin_email
    LIMIT 1;
  END IF;

  IF v_admin_id IS NULL THEN
    RAISE NOTICE 'Admin user not found, skip birth date seeding.';
    RETURN;
  END IF;

  IF EXISTS (
    SELECT 1
    FROM pg_trigger t
    WHERE t.tgrelid = 'public.profiles'::regclass
      AND t.tgname = 'profiles_guard_sensitive_fields'
      AND NOT t.tgisinternal
  ) THEN
    ALTER TABLE public.profiles
      DISABLE TRIGGER profiles_guard_sensitive_fields;
    v_profile_trigger_disabled := true;
  END IF;

  UPDATE public.profiles
  SET
    full_name = coalesce(nullif(trim(full_name), ''), 'Administrator'),
    birth_date = v_admin_birth_date,
    username = coalesce(nullif(lower(trim(username)), ''), v_admin_username),
    role = 'admin',
    account_status = 'active',
    internal_email = coalesce(nullif(lower(trim(internal_email)), ''), v_admin_email),
    updated_at = now()
  WHERE id = v_admin_id;

  IF v_profile_trigger_disabled THEN
    ALTER TABLE public.profiles
      ENABLE TRIGGER profiles_guard_sensitive_fields;
  END IF;
EXCEPTION
  WHEN OTHERS THEN
    IF v_profile_trigger_disabled THEN
      ALTER TABLE public.profiles
        ENABLE TRIGGER profiles_guard_sensitive_fields;
    END IF;
    RAISE;
END $$;
