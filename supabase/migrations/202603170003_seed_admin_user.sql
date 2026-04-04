-- Seed default admin account for development/testing.
-- Username: admin
-- Password: password
-- Internal auth email (derived from username): admin@users.medsync.local
--
-- This migration is idempotent:
-- - creates the admin user if missing,
-- - updates password if user already exists,
-- - enforces admin role on the matching profile.

DO $$
DECLARE
  v_admin_username CONSTANT text := 'admin';
  v_admin_password CONSTANT text := 'password';
  v_admin_birth_date CONSTANT date := DATE '1990-01-01';
  v_internal_email_domain CONSTANT text := 'users.medsync.local';
  v_admin_email text;
  v_admin_id uuid;
  v_profile_trigger_disabled boolean := false;
BEGIN
  v_admin_email := lower(format('%s@%s', v_admin_username, v_internal_email_domain));

  SELECT u.id
    INTO v_admin_id
  FROM auth.users u
  WHERE lower(coalesce(u.email, '')) = v_admin_email
  LIMIT 1;

  IF EXISTS (
    SELECT 1
    FROM public.profiles p
    WHERE lower(coalesce(p.username, '')) = v_admin_username
      AND (v_admin_id IS NULL OR p.id <> v_admin_id)
  ) THEN
    RAISE EXCEPTION
      'Cannot seed admin: username "%" is already used by another account.',
      v_admin_username;
  END IF;

  IF EXISTS (
    SELECT 1
    FROM public.profiles p
    WHERE lower(coalesce(p.internal_email, '')) = v_admin_email
      AND (v_admin_id IS NULL OR p.id <> v_admin_id)
  ) THEN
    RAISE EXCEPTION
      'Cannot seed admin: internal email "%" is already used by another account.',
      v_admin_email;
  END IF;

  IF v_admin_id IS NULL THEN
    v_admin_id := gen_random_uuid();

    INSERT INTO auth.users (
      instance_id,
      id,
      aud,
      role,
      email,
      encrypted_password,
      email_confirmed_at,
      confirmation_sent_at,
      confirmation_token,
      recovery_token,
      email_change_token_new,
      email_change,
      email_change_token_current,
      reauthentication_token,
      email_change_confirm_status,
      is_sso_user,
      is_anonymous,
      raw_app_meta_data,
      raw_user_meta_data,
      created_at,
      updated_at
    ) VALUES (
      '00000000-0000-0000-0000-000000000000',
      v_admin_id,
      'authenticated',
      'authenticated',
      v_admin_email,
      crypt(v_admin_password, gen_salt('bf')),
      now(),
      now(),
      '',
      '',
      '',
      '',
      '',
      '',
      0,
      false,
      false,
      jsonb_build_object('provider', 'email', 'providers', ARRAY['email']),
      jsonb_build_object('username', v_admin_username, 'full_name', 'Administrator'),
      now(),
      now()
    );
  ELSE
    UPDATE auth.users
    SET
      encrypted_password = crypt(v_admin_password, gen_salt('bf')),
      email_confirmed_at = coalesce(email_confirmed_at, now()),
      confirmation_token = coalesce(confirmation_token, ''),
      recovery_token = coalesce(recovery_token, ''),
      email_change_token_new = coalesce(email_change_token_new, ''),
      email_change = coalesce(email_change, ''),
      email_change_token_current = coalesce(email_change_token_current, ''),
      reauthentication_token = coalesce(reauthentication_token, ''),
      email_change_confirm_status = coalesce(email_change_confirm_status, 0),
      is_sso_user = false,
      is_anonymous = false,
      raw_app_meta_data = jsonb_build_object('provider', 'email', 'providers', ARRAY['email']),
      raw_user_meta_data = coalesce(raw_user_meta_data, '{}'::jsonb) ||
        jsonb_build_object('username', v_admin_username, 'full_name', 'Administrator'),
      updated_at = now()
    WHERE id = v_admin_id;
  END IF;

  INSERT INTO auth.identities (
    id,
    user_id,
    provider_id,
    identity_data,
    provider,
    created_at,
    updated_at,
    last_sign_in_at
  ) VALUES (
    gen_random_uuid(),
    v_admin_id,
    v_admin_email,
    jsonb_build_object(
      'sub', v_admin_id::text,
      'email', v_admin_email,
      'email_verified', true
    ),
    'email',
    now(),
    now(),
    now()
  )
  ON CONFLICT (provider_id, provider)
  DO UPDATE SET
    user_id = excluded.user_id,
    identity_data = excluded.identity_data,
    updated_at = now();

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

  INSERT INTO public.profiles (
    id,
    full_name,
    birth_date,
    username,
    role,
    account_status,
    internal_email,
    updated_at
  ) VALUES (
    v_admin_id,
    'Administrator',
    v_admin_birth_date,
    v_admin_username,
    'admin',
    'active',
    v_admin_email,
    now()
  )
  ON CONFLICT (id)
  DO UPDATE SET
    full_name = excluded.full_name,
    birth_date = excluded.birth_date,
    username = excluded.username,
    role = 'admin',
    account_status = 'active',
    internal_email = excluded.internal_email,
    updated_at = now();
  
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
