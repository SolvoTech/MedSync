# Supabase Setup (MEDISNA)

## Local prerequisites
- Supabase CLI installed
- Authenticated to your Supabase account

## Link project
```bash
supabase login
supabase link --project-ref <your-project-ref>
```

## Run migration
```bash
supabase db push
```

## Deploy edge functions
```bash
supabase functions deploy daily-task-check
```

## Required secrets for edge functions
```bash
supabase secrets set SUPABASE_URL=<url>
supabase secrets set SUPABASE_SERVICE_ROLE_KEY=<service-role-key>
```

## Auth email templates (all templates)
This repository includes a complete, styled set of Supabase Auth email templates:
- `supabase/templates/auth_email_templates.json`

Apply them to your Supabase project using:

```bash
export SUPABASE_ACCESS_TOKEN=<your-supabase-management-token>
export PROJECT_REF=givfjbxoqtougorolymn
./tooling/apply_supabase_auth_templates.sh
```

Notes:
- Create `SUPABASE_ACCESS_TOKEN` from: https://supabase.com/dashboard/account/tokens
- The script saves API responses to:
	- `/tmp/supabase_auth_template_patch_response.json`
	- `/tmp/supabase_auth_template_current_config.json`
